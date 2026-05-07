import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';

import '../generated/protocol.dart';
import '../services/scheduling_service.dart';
import '../services/conflict_service.dart';
import '../services/report_service.dart';

/// Admin-only endpoint for managing scheduling data and user roles.
/// Only users with the 'admin' scope can access these methods.
class AdminEndpoint extends Endpoint {
  @override
  @override
  bool get requireLogin => false;

  @override
  Set<Scope> get requiredScopes => {};

  Future<void> _ensureStudentSchema(Session session) async {
    final result = await session.db.unsafeQuery(
      '''
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'student'
        AND column_name IN ('sectionId', 'academicStatus')
      ''',
    );
    final existingColumns = result
        .map((row) => row.toColumnMap()['column_name'] as String?)
        .whereType<String>()
        .toSet();

    if (!existingColumns.contains('sectionId')) {
      session.log(
        'Student schema repair: adding missing "sectionId" column.',
      );
      await session.db.unsafeExecute(
        'ALTER TABLE "student" ADD COLUMN "sectionId" bigint',
      );
    }

    if (!existingColumns.contains('academicStatus')) {
      session.log(
        'Student schema repair: adding missing "academicStatus" column.',
      );
      await session.db.unsafeExecute(
        """
        ALTER TABLE "student"
        ADD COLUMN "academicStatus" text NOT NULL DEFAULT 'active'
        """,
      );
    }
  }

  Future<void> _ensureSectionSchema(Session session) async {
    final result = await session.db.unsafeQuery(
      '''
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = 'section'
        AND column_name = 'availabilityJson'
      ''',
    );
    final hasAvailabilityJson = result.any(
      (row) => row.toColumnMap()['column_name'] == 'availabilityJson',
    );

    if (!hasAvailabilityJson) {
      session.log(
        'Section schema repair: adding missing "availabilityJson" column.',
      );
      await session.db.unsafeExecute(
        'ALTER TABLE "section" ADD COLUMN "availabilityJson" text',
      );
    }
  }

  Program _programFromStudentCourse(String? course) {
    final normalized = course?.trim().toUpperCase() ?? '';
    if (normalized == 'BSEMC' || normalized == 'EMC') {
      return Program.emc;
    }
    return Program.it;
  }

  int _yearLevelFromSectionCode(String? sectionCode, {int fallback = 1}) {
    final match = RegExp(r'\d+').firstMatch(sectionCode ?? '');
    if (match == null) return fallback;
    return int.tryParse(match.group(0)!) ?? fallback;
  }

  int _resolveYearLevel(int parsedYearLevel, int studentYearLevel) {
    if (parsedYearLevel > 0) return parsedYearLevel;
    if (studentYearLevel > 0) return studentYearLevel;
    return 1;
  }

  String _normalizeSubjectCode(String code) {
    return code.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
  }

  String _compactSubjectCode(String code) {
    return code.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  bool _isGeneralEducationSubject(Subject subject) {
    return _compactSubjectCode(subject.code).startsWith('GE');
  }

  Future<void> _validateSubjectCodeUniqueness(
    Session session,
    Subject subject, {
    int? excludeId,
    String? originalCode,
  }) async {
    final normalizedCode = _normalizeSubjectCode(subject.code);
    if (originalCode != null &&
        _normalizeSubjectCode(originalCode) == normalizedCode) {
      return;
    }
    final existingSubjects = excludeId == null
        ? await Subject.db.find(session)
        : await Subject.db.find(
            session,
            where: (t) => t.id.notEquals(excludeId),
          );

    for (final existing in existingSubjects) {
      if (_normalizeSubjectCode(existing.code) == normalizedCode) {
        throw Exception('Subject code ${subject.code.trim()} already exists');
      }
    }
  }

  Future<void> _validateSubjectFaculty(
    Session session,
    Subject subject,
  ) async {
    if (subject.facultyId == null) return;
    if (!subject.isActive) return;

    final faculty = await Faculty.db.findById(session, subject.facultyId!);
    if (faculty == null) {
      throw Exception('Selected faculty is invalid');
    }
    if (subject.isActive && !faculty.isActive) {
      throw Exception('Selected faculty is invalid or inactive');
    }
    if (!_facultyCanTeachSubjectProgram(faculty.program, subject.program)) {
      throw Exception(
        'Selected faculty program does not match the subject program.',
      );
    }
  }

  bool _facultyCanTeachSubjectProgram(
    Program? facultyProgram,
    Program subjectProgram,
  ) {
    if (facultyProgram == null) return true;
    if (facultyProgram == Program.both) return true;
    if (facultyProgram == subjectProgram) return true;
    if (facultyProgram == Program.emc && subjectProgram == Program.it) {
      return true;
    }
    return false;
  }

  int _parseTimeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid time format: $value');
    }
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return (hour * 60) + minute;
  }

  int _dayOrder(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 1;
      case DayOfWeek.tue:
        return 2;
      case DayOfWeek.wed:
        return 3;
      case DayOfWeek.thu:
        return 4;
      case DayOfWeek.fri:
        return 5;
      case DayOfWeek.sat:
        return 6;
      case DayOfWeek.sun:
        return 7;
    }
  }

  bool _requiresLaboratoryRoomForSchedule(Subject subject, Schedule schedule) {
    final loadTypes = schedule.loadTypes ?? const <SubjectType>[];
    if (loadTypes.isNotEmpty) {
      final hasLecture = loadTypes.contains(SubjectType.lecture);
      final hasLab = loadTypes.contains(SubjectType.laboratory);
      if (hasLab && !hasLecture) return true;
      if (hasLecture && !hasLab) return false;
    }

    return subject.types.contains(SubjectType.laboratory) ||
        subject.types.contains(SubjectType.blended);
  }

  bool _roomSupportsSubject(Room room, Subject subject, Schedule schedule) {
    final requiresLab = _requiresLaboratoryRoomForSchedule(subject, schedule);
    final roomMatchesType = requiresLab
        ? room.type == RoomType.laboratory
        : room.type == RoomType.lecture;
    final roomMatchesProgram =
        room.program == Program.both || room.program == subject.program;
    return room.isActive && roomMatchesType && roomMatchesProgram;
  }

  bool _timeslotMatchesAvailability(
    Timeslot timeslot,
    List<FacultyAvailability> availability,
  ) {
    final slotStart = _parseTimeToMinutes(timeslot.startTime);
    final slotEnd = _parseTimeToMinutes(timeslot.endTime);

    for (final avail in availability) {
      if (avail.dayOfWeek != timeslot.day) continue;
      final availStart = _parseTimeToMinutes(avail.startTime);
      final availEnd = _parseTimeToMinutes(avail.endTime);
      if (slotStart >= availStart && slotEnd <= availEnd) {
        return true;
      }
    }

    return false;
  }

  List<_SectionAvailabilityWindow> _parseSectionAvailability(String? rawJson) {
    if (rawJson == null || rawJson.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is! List) return const [];

      final entries = <_SectionAvailabilityWindow>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final dayValue = item['day']?.toString();
        final startTime = item['startTime']?.toString();
        final endTime = item['endTime']?.toString();
        if (dayValue == null || startTime == null || endTime == null) {
          continue;
        }

        DayOfWeek? day;
        for (final value in DayOfWeek.values) {
          if (value.name == dayValue) {
            day = value;
            break;
          }
        }
        if (day == null) continue;

        entries.add(
          _SectionAvailabilityWindow(
            day: day,
            startTime: startTime,
            endTime: endTime,
          ),
        );
      }
      return entries;
    } catch (_) {
      return const [];
    }
  }

  bool _timeslotMatchesSectionAvailability(
    Timeslot timeslot,
    List<_SectionAvailabilityWindow> availability,
  ) {
    if (availability.isEmpty) return true;
    final slotStart = _parseTimeToMinutes(timeslot.startTime);
    final slotEnd = _parseTimeToMinutes(timeslot.endTime);

    for (final avail in availability) {
      if (avail.day != timeslot.day) continue;
      final availStart = _parseTimeToMinutes(avail.startTime);
      final availEnd = _parseTimeToMinutes(avail.endTime);
      if (slotStart >= availStart && slotEnd <= availEnd) {
        return true;
      }
    }

    return false;
  }

  int _requiredScheduleMinutes(Subject subject, Schedule schedule) {
    if (schedule.hours != null && schedule.hours! > 0) {
      return (schedule.hours! * 60).round();
    }
    if (subject.hours != null && subject.hours! > 0) {
      return (subject.hours! * 60).round();
    }

    final loadTypes = schedule.loadTypes ?? const <SubjectType>[];
    if (loadTypes.contains(SubjectType.laboratory) &&
        !loadTypes.contains(SubjectType.lecture)) {
      return 180;
    }
    if (loadTypes.contains(SubjectType.lecture) &&
        !loadTypes.contains(SubjectType.laboratory)) {
      return _isGeneralEducationSubject(subject) ? 90 : 120;
    }
    if (subject.types.contains(SubjectType.laboratory) &&
        !subject.types.contains(SubjectType.lecture) &&
        !subject.types.contains(SubjectType.blended)) {
      return 180;
    }
    return _isGeneralEducationSubject(subject) ? 90 : 120;
  }

  Future<void> _resolveAutoAssignedSchedule(
    Session session,
    Schedule schedule, {
    int? excludeScheduleId,
  }) async {
    await _ensureSectionSchema(session);
    final subject = await Subject.db.findById(session, schedule.subjectId);
    if (subject == null) {
      throw Exception('Subject not found for auto-assignment.');
    }

    final availability = await FacultyAvailability.db.find(
      session,
      where: (t) => t.facultyId.equals(schedule.facultyId),
    );
    if (availability.isEmpty) {
      throw Exception(
        'Auto-assign requires faculty availability before choosing room and timeslot.',
      );
    }

    final allTimeslots = await Timeslot.db.find(session);
    if (allTimeslots.isEmpty) {
      throw Exception('No timeslots available for auto-assignment.');
    }

    Section? sectionRecord;
    if (schedule.sectionId != null) {
      sectionRecord = await Section.db.findById(session, schedule.sectionId!);
    }
    sectionRecord ??= await Section.db.findFirstRow(
      session,
      where: (t) => t.sectionCode.equals(schedule.section),
    );
    final sectionAvailability = _parseSectionAvailability(
      sectionRecord?.availabilityJson,
    );

    final requiredMinutes = _requiredScheduleMinutes(subject, schedule);
    final candidateTimeslots =
        allTimeslots.where((timeslot) {
          final slotMinutes =
              _parseTimeToMinutes(timeslot.endTime) -
              _parseTimeToMinutes(timeslot.startTime);
          return slotMinutes == requiredMinutes &&
              _timeslotMatchesAvailability(timeslot, availability) &&
              _timeslotMatchesSectionAvailability(
                timeslot,
                sectionAvailability,
              );
        }).toList()..sort((a, b) {
          final dayCompare = _dayOrder(a.day).compareTo(_dayOrder(b.day));
          if (dayCompare != 0) return dayCompare;
          return _parseTimeToMinutes(a.startTime).compareTo(
            _parseTimeToMinutes(b.startTime),
          );
        });

    if (candidateTimeslots.isEmpty) {
      throw Exception(
        'No available timeslot matches this faculty\'s availability for auto-assignment.',
      );
    }

    final allRooms = await Room.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    final preferredRoomId = schedule.roomId;
    List<Room> candidateRooms;
    if (preferredRoomId != null) {
      final preferredRoom = allRooms
          .where((room) => room.id == preferredRoomId)
          .firstOrNull;
      if (preferredRoom == null) {
        throw Exception(
          'Selected room is no longer available for auto-assignment.',
        );
      }
      if (!_roomSupportsSubject(preferredRoom, subject, schedule)) {
        throw Exception(
          'Selected room is not eligible for this subject assignment.',
        );
      }
      candidateRooms = [preferredRoom];
    } else {
      candidateRooms =
          allRooms
              .where(
                (room) => _roomSupportsSubject(room, subject, schedule),
              )
              .toList()
            ..sort((a, b) => a.capacity.compareTo(b.capacity));
    }

    if (candidateRooms.isEmpty) {
      throw Exception('No eligible room found for auto-assignment.');
    }

    final conflictService = ConflictService();

    for (final timeslot in candidateTimeslots) {
      for (final room in candidateRooms) {
        final candidate = schedule.copyWith(
          roomId: room.id,
          timeslotId: timeslot.id,
        );
        final conflicts = await conflictService.validateSchedule(
          session,
          candidate,
          excludeScheduleId: excludeScheduleId,
        );
        if (conflicts.isEmpty) {
          schedule.roomId = room.id;
          schedule.timeslotId = timeslot.id;
          return;
        }
      }
    }

    throw Exception(
      'No conflict-free room and timeslot combination found for auto-assignment.',
    );
  }

  Future<int?> _resolveStudentSectionId(
    Session session,
    Student student,
  ) async {
    final rawSection = student.section?.trim();
    if (rawSection == null || rawSection.isEmpty) {
      return student.sectionId;
    }

    final program = _programFromStudentCourse(student.course);
    final parsedYearLevel = _yearLevelFromSectionCode(rawSection, fallback: 0);
    final yearLevel = _resolveYearLevel(parsedYearLevel, student.yearLevel);

    final existingSection = await Section.db.findFirstRow(
      session,
      where: (t) =>
          t.sectionCode.equals(rawSection) &
          t.program.equals(program) &
          t.yearLevel.equals(yearLevel),
    );

    if (existingSection != null) {
      return existingSection.id;
    }

    final sameProgramSection = await Section.db.findFirstRow(
      session,
      where: (t) =>
          t.sectionCode.equals(rawSection) & t.program.equals(program),
    );
    if (sameProgramSection != null) {
      return sameProgramSection.id;
    }

    final newSection = await Section.db.insertRow(
      session,
      Section(
        sectionCode: rawSection,
        program: program,
        yearLevel: yearLevel,
        semester: 1,
        academicYear: '${DateTime.now().year}-${DateTime.now().year + 1}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return newSection.id;
  }

  Future<void> _repairStudentSectionRelation(
    Session session,
    Student student,
  ) async {
    if ((student.section?.trim().isEmpty ?? true) || student.id == null) {
      return;
    }

    final resolvedSectionId = await _resolveStudentSectionId(session, student);
    if (resolvedSectionId != null && resolvedSectionId != student.sectionId) {
      student.sectionId = resolvedSectionId;
      student.updatedAt = DateTime.now();
      await Student.db.updateRow(session, student);
    }
  }

  Future<void> _syncUserInfoScopesForRole(
    Session session, {
    required String userId,
    required String role,
  }) async {
    final parsedUserInfoId = int.tryParse(userId);
    if (parsedUserInfoId == null) return;

    final userInfo = await UserInfo.db.findById(session, parsedUserInfoId);
    if (userInfo == null) return;

    final updatedScopes = userInfo.scopeNames.toSet();
    switch (role) {
      case 'faculty':
        updatedScopes
          ..remove('faculty_pending')
          ..remove('faculty_declined')
          ..add('faculty');
        break;
      case 'faculty_pending':
        updatedScopes
          ..remove('faculty')
          ..remove('faculty_declined')
          ..add('faculty_pending');
        break;
      case 'faculty_declined':
        updatedScopes
          ..remove('faculty')
          ..remove('faculty_pending')
          ..add('faculty_declined');
        break;
      case 'student':
        updatedScopes.add('student');
        break;
      case 'admin':
        updatedScopes.add('admin');
        break;
    }

    if (updatedScopes.length == userInfo.scopeNames.length &&
        updatedScopes.containsAll(userInfo.scopeNames)) {
      return;
    }

    userInfo.scopeNames = updatedScopes.toList();
    await UserInfo.db.updateRow(session, userInfo);
  }

  /// Get aggregated dashboard statistics. ─────────────────────────────────────────────────

  // ─── Role Management ─────────────────────────────────────────────────

  /// Assign or change a user's role (admin, faculty, student).
  Future<UserRole> assignRole(
    Session session, {
    required String userId,
    required String role,
  }) async {
    // Validate the role
    const allowedRoles = {
      'admin',
      'faculty',
      'student',
      'faculty_pending',
      'faculty_declined',
    };
    if (!allowedRoles.contains(role)) {
      throw Exception(
        'Invalid role: $role. Must be one of: ${allowedRoles.join(", ")}.',
      );
    }

    // Check if a role already exists for this user
    var existing = await UserRole.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );

    if (existing != null) {
      // Update the existing role
      existing.role = role;
      final updatedRole = await UserRole.db.updateRow(session, existing);
      await _syncUserInfoScopesForRole(
        session,
        userId: userId,
        role: role,
      );
      return updatedRole;
    } else {
      // Create a new role entry
      final createdRole = await UserRole.db.insertRow(
        session,
        UserRole(userId: userId, role: role),
      );
      await _syncUserInfoScopesForRole(
        session,
        userId: userId,
        role: role,
      );
      return createdRole;
    }
  }

  /// Get all user roles.
  Future<List<UserRole>> getAllUserRoles(Session session) async {
    return await UserRole.db.find(session);
  }

  // ─── Faculty CRUD ────────────────────────────────────────────────────

  /// Create a new faculty member with validation.
  Future<Faculty> createFaculty(Session session, Faculty faculty) async {
    try {
      print('--- CREATE FACULTY DEBUG ---');
      print('Name: ${faculty.name}');
      print('Email: ${faculty.email}');
      print('FacultyID: ${faculty.facultyId}');
      print('userInfoId: ${faculty.userInfoId}');

      // Validate email format
      if (!_isValidEmail(faculty.email)) {
        print('FAIL: Invalid email format');
        throw Exception('Invalid email format: ${faculty.email}');
      }

      // Check email uniqueness in Faculty table
      var existingEmail = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.email.equals(faculty.email),
      );
      if (existingEmail != null) {
        print('FAIL: Email already exists in Faculty table');
        throw Exception('Faculty with email ${faculty.email} already exists');
      }

      // Check facultyId uniqueness
      var existingId = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.facultyId.equals(faculty.facultyId),
      );
      if (existingId != null) {
        print('FAIL: Faculty ID already exists');
        throw Exception('Faculty with ID ${faculty.facultyId} already exists');
      }

      // --- HANDLE USER ACCOUNT CREATION ---
      // We need a real UserInfo record. If the frontend sent 0 or nothing, we create one.
      UserInfo? userInfo;

      // Try to find if a UserInfo already exists for this email
      userInfo = await UserInfo.db.findFirstRow(
        session,
        where: (t) => t.email.equals(faculty.email),
      );

      if (userInfo == null) {
        print('CREATING NEW UserInfo for ${faculty.email}...');
        // Create a new user account with a default password (same as facultyId or random)
        // Note: In a real app, you'd send a reset link, but here we'll use a placeholder.
        userInfo = await Emails.createUser(
          session,
          faculty.name,
          faculty.email,
          'JMC-${faculty.facultyId}', // Default password
        );

        if (userInfo == null) {
          throw Exception('Failed to create UserInfo for ${faculty.email}');
        }
      }

      // Ensure the user has the 'faculty' role scope
      var currentScopes = userInfo.scopeNames.toSet();
      if (!currentScopes.contains('faculty')) {
        currentScopes.add('faculty');
        userInfo.scopeNames = currentScopes.toList();
        await UserInfo.db.updateRow(session, userInfo);
      }

      // Also ensure a UserRole record exists (used by the custom login)
      var userIdStr = userInfo.id?.toString() ?? '';
      var existingRole = await UserRole.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(userIdStr),
      );
      if (existingRole == null && userIdStr.isNotEmpty) {
        await UserRole.db.insertRow(
          session,
          UserRole(userId: userIdStr, role: 'faculty'),
        );
      }

      // Set the correct userInfoId
      faculty.userInfoId = userInfo.id!;

      // Validate maxLoad
      if ((faculty.maxLoad ?? 0) <= 0) {
        print('FAIL: Invalid maxLoad');
        throw Exception('Max load must be greater than 0');
      }

      // Set timestamps
      faculty.createdAt = DateTime.now();
      faculty.updatedAt = DateTime.now();

      final created = await Faculty.db.insertRow(session, faculty);
      print('SUCCESS: Created faculty with database ID: ${created.id}');
      return created;
    } catch (e, stack) {
      print('CRITICAL ERROR IN createFaculty: $e');
      print(stack);
      rethrow;
    }
  }

  /// Get all faculty members.
  Future<List<Faculty>> getAllFaculty(
    Session session, {
    bool isActive = true,
  }) async {
    final faculty = await Faculty.db.find(
      session,
      where: (t) => t.isActive.equals(isActive),
    );

    if (!isActive) return faculty;

    final allFacultyRows = await Faculty.db.find(session);
    final presentUserInfoIds = allFacultyRows.map((f) => f.userInfoId).toSet();
    final roleRows = await UserRole.db.find(
      session,
      where: (t) => t.role.equals('faculty') | t.role.equals('admin'),
    );
    final missingRoleUserIds = roleRows
        .map((row) => int.tryParse(row.userId))
        .whereType<int>()
        .where((id) => !presentUserInfoIds.contains(id))
        .toList();

    if (missingRoleUserIds.isNotEmpty) {
      final missingRoleUserIdSet = missingRoleUserIds.toSet();
      final fallbackUserInfos = await UserInfo.db.find(
        session,
        where: (t) => t.id.inSet(missingRoleUserIdSet),
      );

      for (final userInfo in fallbackUserInfos) {
        if (userInfo.blocked || userInfo.id == null) continue;

        final normalizedEmail = (userInfo.email ?? userInfo.userIdentifier)
            .trim()
            .toLowerCase();
        final existingFaculty = await Faculty.db.findFirstRow(
          session,
          where: (t) =>
              t.userInfoId.equals(userInfo.id!) |
              t.email.equals(normalizedEmail),
        );

        if (existingFaculty != null) {
          continue;
        }

        await Faculty.db.insertRow(
          session,
          Faculty(
            name: userInfo.userName ?? normalizedEmail,
            email: normalizedEmail,
            maxLoad: 21,
            employmentStatus: EmploymentStatus.fullTime,
            shiftPreference: FacultyShiftPreference.any,
            facultyId: userInfo.userIdentifier,
            userInfoId: userInfo.id!,
            program: Program.it,
            isActive: true,
            createdAt: userInfo.created,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    return await Faculty.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
  }

  /// Update a faculty member with validation.
  Future<Faculty> updateFaculty(Session session, Faculty faculty) async {
    // Ensure faculty exists
    var existing = await Faculty.db.findById(session, faculty.id!);
    if (existing == null) {
      throw Exception('Faculty not found with ID: ${faculty.id}');
    }

    // Validate email format
    if (!_isValidEmail(faculty.email)) {
      throw Exception('Invalid email format: ${faculty.email}');
    }

    // Check email uniqueness (excluding current faculty)
    var emailConflict = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(faculty.email),
    );
    if (emailConflict != null &&
        emailConflict.id != faculty.id &&
        emailConflict.userInfoId != faculty.userInfoId) {
      throw Exception('Faculty with email ${faculty.email} already exists');
    }

    // Check facultyId uniqueness (excluding current faculty)
    var facultyIdConflict = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.facultyId.equals(faculty.facultyId),
    );
    if (facultyIdConflict != null &&
        facultyIdConflict.id != faculty.id &&
        facultyIdConflict.userInfoId != faculty.userInfoId) {
      throw Exception('Faculty with ID ${faculty.facultyId} already exists');
    }

    // Validate maxLoad
    if ((faculty.maxLoad ?? 0) <= 0) {
      throw Exception('Max load must be greater than 0');
    }

    // Update timestamp
    faculty.updatedAt = DateTime.now();

    return await Faculty.db.updateRow(session, faculty);
  }

  /// Delete a faculty member by ID.
  /// Checks for active schedules before deletion and cleans up related records.
  Future<bool> deleteFaculty(Session session, int id) async {
    var faculty = await Faculty.db.findById(session, id);
    if (faculty == null) return false;

    // Check for active schedules
    var schedules = await Schedule.db.find(
      session,
      where: (t) => t.facultyId.equals(id),
    );
    if (schedules.isNotEmpty) {
      throw Exception(
        'Cannot delete faculty: ${schedules.length} active schedule(s) exist. '
        'Please remove or reassign schedules first.',
      );
    }

    // Clean up availability records
    await FacultyAvailability.db.deleteWhere(
      session,
      where: (t) => t.facultyId.equals(id),
    );

    // Clean up UserRole
    await UserRole.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(faculty.userInfoId.toString()),
    );

    await Faculty.db.deleteRow(session, faculty);
    return true;
  }

  // ─── Student CRUD ────────────────────────────────────────────────────

  /// Create a new student with validation.
  Future<Student> createStudent(Session session, Student student) async {
    await _ensureStudentSchema(session);
    try {
      // Validate email format
      if (!_isValidEmail(student.email)) {
        throw Exception('Invalid email format: ${student.email}');
      }

      // Check email uniqueness
      var existing = await Student.db.findFirstRow(
        session,
        where: (t) => t.email.equals(student.email),
      );
      if (existing != null) {
        throw Exception('Student with email ${student.email} already exists');
      }

      // Check student number uniqueness
      var existingNumber = await Student.db.findFirstRow(
        session,
        where: (t) => t.studentNumber.equals(student.studentNumber),
      );
      if (existingNumber != null) {
        throw Exception(
          'Student with number ${student.studentNumber} already exists',
        );
      }

      // --- HANDLE USER ACCOUNT CREATION ---
      UserInfo? userInfo;

      // Try to find if a UserInfo already exists for this email
      userInfo = await UserInfo.db.findFirstRow(
        session,
        where: (t) => t.email.equals(student.email),
      );

      if (userInfo == null) {
        // Create a new user account with a default password
        userInfo = await Emails.createUser(
          session,
          student.name,
          student.email,
          'JMC-${student.studentNumber}', // Default password
        );

        if (userInfo == null) {
          throw Exception('Failed to create UserInfo for ${student.email}');
        }
      }

      // Ensure the user has the 'student' role scope
      var currentScopes = userInfo.scopeNames.toSet();
      if (!currentScopes.contains('student')) {
        currentScopes.add('student');
        userInfo.scopeNames = currentScopes.toList();
        await UserInfo.db.updateRow(session, userInfo);
      }

      // Also ensure a UserRole record exists (used by the custom login)
      var userIdStr = userInfo.id?.toString() ?? '';
      var existingRole = await UserRole.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(userIdStr),
      );
      if (existingRole == null && userIdStr.isNotEmpty) {
        await UserRole.db.insertRow(
          session,
          UserRole(userId: userIdStr, role: 'student'),
        );
      }

      // Set the correct userInfoId
      student.userInfoId = userInfo.id!;

      try {
        student.sectionId = await _resolveStudentSectionId(session, student);
      } catch (e) {
        session.log('Error syncing section during create: $e');
      }

      // Set timestamps
      student.createdAt = DateTime.now();
      student.updatedAt = DateTime.now();

      return await Student.db.insertRow(session, student);
    } catch (e) {
      print('ERROR IN createStudent: $e');
      rethrow;
    }
  }

  /// Get all students.
  Future<List<Student>> getAllStudents(
    Session session, {
    bool isActive = true,
  }) async {
    await _ensureStudentSchema(session);
    final students = await Student.db.find(
      session,
      where: (t) => t.isActive.equals(isActive),
    );

    for (final student in students) {
      try {
        await _repairStudentSectionRelation(session, student);
      } catch (e) {
        session.log('Error repairing student section ${student.id}: $e');
      }
    }

    if (!isActive) return students;

    final allStudentRows = await Student.db.find(session);
    final presentUserInfoIds = allStudentRows.map((s) => s.userInfoId).toSet();
    final roleRows = await UserRole.db.find(
      session,
      where: (t) => t.role.equals('student'),
    );
    final missingRoleUserIds = roleRows
        .map((row) => int.tryParse(row.userId))
        .whereType<int>()
        .where((id) => !presentUserInfoIds.contains(id))
        .toList();

    if (missingRoleUserIds.isNotEmpty) {
      final missingRoleUserIdSet = missingRoleUserIds.toSet();
      final fallbackUserInfos = await UserInfo.db.find(
        session,
        where: (t) => t.id.inSet(missingRoleUserIdSet),
      );

      for (final userInfo in fallbackUserInfos) {
        if (userInfo.blocked || userInfo.id == null) continue;

        final normalizedEmail = (userInfo.email ?? userInfo.userIdentifier)
            .trim()
            .toLowerCase();
        final existingStudent = await Student.db.findFirstRow(
          session,
          where: (t) =>
              t.userInfoId.equals(userInfo.id!) |
              t.email.equals(normalizedEmail),
        );

        if (existingStudent != null) {
          continue;
        }

        await Student.db.insertRow(
          session,
          Student(
            name: userInfo.userName ?? normalizedEmail,
            email: normalizedEmail,
            studentNumber: userInfo.userIdentifier,
            course: 'BSIT',
            yearLevel: 1,
            userInfoId: userInfo.id!,
            academicStatus: StudentAcademicStatus.active,
            isActive: true,
            createdAt: userInfo.created,
            updatedAt: DateTime.now(),
          ),
        );
      }
    }

    return await Student.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
  }

  /// Update a student with validation and section synchronization.
  Future<Student> updateStudent(Session session, Student student) async {
    await _ensureStudentSchema(session);
    // Ensure student exists
    var existing = await Student.db.findById(session, student.id!);
    if (existing == null) {
      throw Exception('Student not found with ID: ${student.id}');
    }

    // Validate email format
    if (!_isValidEmail(student.email)) {
      throw Exception('Invalid email format: ${student.email}');
    }

    // Check email uniqueness (excluding current student)
    var emailConflict = await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(student.email),
    );
    if (emailConflict != null &&
        emailConflict.id != student.id &&
        emailConflict.userInfoId != student.userInfoId) {
      throw Exception('Student with email ${student.email} already exists');
    }

    // Check student number uniqueness (excluding current student)
    var numberConflict = await Student.db.findFirstRow(
      session,
      where: (t) => t.studentNumber.equals(student.studentNumber),
    );
    if (numberConflict != null &&
        numberConflict.id != student.id &&
        numberConflict.userInfoId != student.userInfoId) {
      throw Exception(
        'Student with number ${student.studentNumber} already exists',
      );
    }

    // Keep the section relation aligned with student.course and section code.
    if (student.section != existing.section ||
        student.sectionId == null ||
        student.course != existing.course ||
        student.yearLevel != existing.yearLevel) {
      if (student.section != null && student.section!.isNotEmpty) {
        try {
          student.sectionId = await _resolveStudentSectionId(session, student);
        } catch (e) {
          session.log('Error syncing section during update: $e');
        }
      } else {
        student.sectionId = null;
      }
    }

    // Update timestamp
    student.updatedAt = DateTime.now();

    return await Student.db.updateRow(session, student);
  }

  /// Get all unique section codes currently assigned to students.
  Future<List<String>> getDistinctStudentSections(Session session) async {
    await _ensureStudentSchema(session);
    final students = await Student.db.find(
      session,
      where: (t) => t.section.notEquals(null) & t.isActive.equals(true),
    );
    final sections = students
        .map((s) => s.section!)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    sections.sort();
    return sections;
  }

  /// Delete a student by ID.
  Future<bool> deleteStudent(Session session, int id) async {
    await _ensureStudentSchema(session);
    var student = await Student.db.findById(session, id);
    if (student == null) return false;

    // Clean up UserRole
    await UserRole.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(student.userInfoId.toString()),
    );

    await Student.db.deleteRow(session, student);
    return true;
  }

  // ─── Room CRUD ───────────────────────────────────────────────────────

  /// Create a new room with validation.
  Future<Room> createRoom(Session session, Room room) async {
    _validateRoomCatalogRules(room);

    // Validate capacity
    if (room.capacity <= 0) {
      throw Exception('Room capacity must be greater than 0');
    }

    // Check room name uniqueness
    var existing = await Room.db.findFirstRow(
      session,
      where: (t) => t.name.equals(room.name),
    );
    if (existing != null) {
      throw Exception(
        'Room ${room.name} already exists',
      );
    }

    // Set timestamps
    room.createdAt = DateTime.now();
    room.updatedAt = DateTime.now();

    return await Room.db.insertRow(session, room);
  }

  /// Get all rooms.
  Future<List<Room>> getAllRooms(
    Session session, {
    bool isActive = true,
  }) async {
    return await Room.db.find(
      session,
      where: (t) => t.isActive.equals(isActive),
    );
  }

  /// Update a room with validation.
  Future<Room> updateRoom(Session session, Room room) async {
    // Ensure room exists
    var existing = await Room.db.findById(session, room.id!);
    if (existing == null) {
      throw Exception('Room not found with ID: ${room.id}');
    }

    _validateRoomCatalogRules(room);

    // Validate capacity
    if (room.capacity <= 0) {
      throw Exception('Room capacity must be greater than 0');
    }

    // Check room name uniqueness (excluding current room)
    var nameConflict = await Room.db.findFirstRow(
      session,
      where: (t) => t.name.equals(room.name),
    );
    if (nameConflict != null && nameConflict.id != room.id) {
      throw Exception(
        'Room ${room.name} already exists',
      );
    }

    // Update timestamp
    room.updatedAt = DateTime.now();

    return await Room.db.updateRow(session, room);
  }

  /// Delete a room by ID.
  /// Checks for active schedules before deletion.
  Future<bool> deleteRoom(Session session, int id) async {
    var room = await Room.db.findById(session, id);
    if (room == null) return false;

    // Check for active schedules
    var schedules = await Schedule.db.find(
      session,
      where: (t) => t.roomId.equals(id),
    );
    if (schedules.isNotEmpty) {
      throw Exception(
        'Cannot delete room: ${schedules.length} active schedule(s) exist. '
        'Please remove or reassign schedules first.',
      );
    }

    await Room.db.deleteRow(session, room);
    return true;
  }

  // ─── Subject CRUD ────────────────────────────────────────────────────

  /// Create a new subject with validation.
  Future<Subject> createSubject(Session session, Subject subject) async {
    // Validate subject code format (basic check)
    subject.code = subject.code.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (subject.code.isEmpty) {
      throw Exception('Subject code cannot be empty');
    }

    // Validate units
    if (subject.units <= 0) {
      throw Exception('Subject units must be greater than 0');
    }

    // Validate hours when provided
    if (subject.hours != null && subject.hours! <= 0) {
      throw Exception('Subject hours must be greater than 0');
    }

    // Validate term when provided
    if (subject.term != null && (subject.term! < 1 || subject.term! > 3)) {
      throw Exception(
        'Subject term must be 1 (1st Semester), 2 (2nd Semester), or 3 (Summer Class)',
      );
    }

    // Validate student count
    if (subject.studentsCount < 0) {
      throw Exception('Student count cannot be negative');
    }

    await _validateSubjectCodeUniqueness(session, subject);
    await _validateSubjectFaculty(session, subject);

    // Set timestamps
    subject.createdAt = DateTime.now();
    subject.updatedAt = DateTime.now();

    return await Subject.db.insertRow(session, subject);
  }

  /// Get all subjects.
  Future<List<Subject>> getAllSubjects(
    Session session, {
    bool isActive = true,
  }) async {
    return await Subject.db.find(
      session,
      where: (t) => t.isActive.equals(isActive),
    );
  }

  /// Update a subject with validation.
  Future<Subject> updateSubject(Session session, Subject subject) async {
    // Ensure subject exists
    var existing = await Subject.db.findById(session, subject.id!);
    if (existing == null) {
      throw Exception('Subject not found with ID: ${subject.id}');
    }

    // Validate subject code
    subject.code = subject.code.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (subject.code.isEmpty) {
      throw Exception('Subject code cannot be empty');
    }

    // Validate units
    if (subject.units <= 0) {
      throw Exception('Subject units must be greater than 0');
    }

    // Validate hours when provided
    if (subject.hours != null && subject.hours! <= 0) {
      throw Exception('Subject hours must be greater than 0');
    }

    // Validate term when provided
    if (subject.term != null && (subject.term! < 1 || subject.term! > 3)) {
      throw Exception(
        'Subject term must be 1 (1st Semester), 2 (2nd Semester), or 3 (Summer Class)',
      );
    }

    // Validate student count
    if (subject.studentsCount < 0) {
      throw Exception('Student count cannot be negative');
    }

    await _validateSubjectCodeUniqueness(
      session,
      subject,
      excludeId: subject.id,
      originalCode: existing.code,
    );
    await _validateSubjectFaculty(session, subject);

    // Update timestamp
    subject.updatedAt = DateTime.now();

    return await Subject.db.updateRow(session, subject);
  }

  /// Delete a subject by ID.
  /// Checks for active schedules before deletion.
  Future<bool> deleteSubject(Session session, int id) async {
    var subject = await Subject.db.findById(session, id);
    if (subject == null) return false;

    // Check for active schedules
    var schedules = await Schedule.db.find(
      session,
      where: (t) => t.subjectId.equals(id),
    );
    if (schedules.isNotEmpty) {
      throw Exception(
        'Cannot delete subject: ${schedules.length} active schedule(s) exist. '
        'Please remove schedules first.',
      );
    }

    await Subject.db.deleteRow(session, subject);
    return true;
  }

  // ─── Timeslot CRUD ───────────────────────────────────────────────────

  /// Create a new timeslot with validation.
  Future<Timeslot> createTimeslot(Session session, Timeslot timeslot) async {
    // Validate time format and logic
    if (!_isValidTimeFormat(timeslot.startTime)) {
      throw Exception(
        'Invalid start time format: ${timeslot.startTime}. Use HH:mm format.',
      );
    }
    if (!_isValidTimeFormat(timeslot.endTime)) {
      throw Exception(
        'Invalid end time format: ${timeslot.endTime}. Use HH:mm format.',
      );
    }

    // Ensure start time is before end time
    if (!_isStartBeforeEnd(timeslot.startTime, timeslot.endTime)) {
      throw Exception('Start time must be before end time');
    }

    // Prevent duplicate day/time windows.
    final duplicate = await _findDuplicateTimeslot(
      session,
      day: timeslot.day,
      startTime: timeslot.startTime,
      endTime: timeslot.endTime,
    );
    if (duplicate != null) {
      throw Exception(
        'Timeslot already exists for ${timeslot.day.name.toUpperCase()} '
        '${timeslot.startTime}-${timeslot.endTime}.',
      );
    }

    // Set timestamps
    timeslot.createdAt = DateTime.now();
    timeslot.updatedAt = DateTime.now();

    return await Timeslot.db.insertRow(session, timeslot);
  }

  /// Get all timeslots.
  Future<List<Timeslot>> getAllTimeslots(Session session) async {
    return await Timeslot.db.find(session);
  }

  /// Update a timeslot with validation.
  Future<Timeslot> updateTimeslot(Session session, Timeslot timeslot) async {
    // Ensure timeslot exists
    var existing = await Timeslot.db.findById(session, timeslot.id!);
    if (existing == null) {
      throw Exception('Timeslot not found with ID: ${timeslot.id}');
    }

    // Validate time format and logic
    if (!_isValidTimeFormat(timeslot.startTime)) {
      throw Exception(
        'Invalid start time format: ${timeslot.startTime}. Use HH:mm format.',
      );
    }
    if (!_isValidTimeFormat(timeslot.endTime)) {
      throw Exception(
        'Invalid end time format: ${timeslot.endTime}. Use HH:mm format.',
      );
    }

    // Ensure start time is before end time
    if (!_isStartBeforeEnd(timeslot.startTime, timeslot.endTime)) {
      throw Exception('Start time must be before end time');
    }

    // Prevent duplicate day/time windows (excluding current row).
    final duplicate = await _findDuplicateTimeslot(
      session,
      day: timeslot.day,
      startTime: timeslot.startTime,
      endTime: timeslot.endTime,
    );
    if (duplicate != null && duplicate.id != timeslot.id) {
      throw Exception(
        'Another timeslot already exists for '
        '${timeslot.day.name.toUpperCase()} '
        '${timeslot.startTime}-${timeslot.endTime}.',
      );
    }

    // Update timestamp
    timeslot.updatedAt = DateTime.now();

    return await Timeslot.db.updateRow(session, timeslot);
  }

  /// Delete a timeslot by ID.
  /// Checks for active schedules before deletion.
  Future<bool> deleteTimeslot(Session session, int id) async {
    var timeslot = await Timeslot.db.findById(session, id);
    if (timeslot == null) return false;

    // Check for active schedules
    var schedules = await Schedule.db.find(
      session,
      where: (t) => t.timeslotId.equals(id),
    );
    if (schedules.isNotEmpty) {
      throw Exception(
        'Cannot delete timeslot: ${schedules.length} active schedule(s) exist. '
        'Please remove schedules first.',
      );
    }

    await Timeslot.db.deleteRow(session, timeslot);
    return true;
  }

  // ─── Schedule CRUD ───────────────────────────────────────────────────

  /// Create a new schedule entry with conflict detection.
  Future<Schedule> createSchedule(Session session, Schedule schedule) async {
    // Normalize sentinel values from frontend
    if (schedule.roomId == -1) schedule.roomId = null;
    if (schedule.timeslotId == -1) schedule.timeslotId = null;
    final subject = await Subject.db.findById(session, schedule.subjectId);
    if (subject == null) {
      throw Exception('Subject not found with ID: ${schedule.subjectId}');
    }
    schedule.units ??= subject.units.toDouble();
    schedule.hours ??= subject.hours;
    await _syncScheduleSectionReference(session, schedule);
    if (schedule.roomId == null || schedule.timeslotId == null) {
      schedule.timeslotId = null;
      await _resolveAutoAssignedSchedule(session, schedule);
    }

    // Validate schedule entry against all conflicts
    var conflicts = await ConflictService().validateSchedule(session, schedule);

    if (conflicts.isNotEmpty) {
      var messages = conflicts.map((c) => c.message).join('; ');
      throw Exception('Schedule validation failed: $messages');
    }

    // Set timestamps
    schedule.createdAt = DateTime.now();
    schedule.updatedAt = DateTime.now();

    try {
      return await Schedule.db.insertRow(session, schedule);
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('schedule_instructor_no_overlap')) {
        throw Exception('Instructor already has a class during this time.');
      }
      if (message.contains('schedule_room_no_overlap')) {
        throw Exception('Room is already booked during this time.');
      }
      if (message.contains('schedule_section_no_overlap')) {
        throw Exception('Section already has a class during this time.');
      }
      rethrow;
    }
  }

  // TEST ENDPOINT to bypass auth and trigger checkFacultyMaxLoad
  Future<String> testMaxLoadValidation(
    Session session,
    int facultyId,
    double units,
  ) async {
    var schedule = Schedule(
      subjectId: 1,
      facultyId: facultyId,
      section: 'A',
      units: units == -1.0 ? null : units,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      var conflicts = await ConflictService().validateSchedule(
        session,
        schedule,
      );
      if (conflicts.isNotEmpty) {
        return 'Conflicts: ${conflicts.map((c) => c.message).join(', ')}';
      }
      return 'No conflicts!';
    } catch (e) {
      return 'Exception: $e';
    }
  }

  /// Get all schedule entries.
  Future<List<Schedule>> getAllSchedules(
    Session session, {
    bool? isActive = true,
  }) async {
    return await Schedule.db.find(
      session,
      where: (t) =>
          isActive == null ? Constant.bool(true) : t.isActive.equals(isActive),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
        sectionRef: Section.include(),
      ),
    );
  }

  /// Get schedule for a specific faculty with includes.
  Future<List<Schedule>> getFacultySchedule(
    Session session,
    int facultyId, {
    bool? isActive = true,
  }) async {
    return await Schedule.db.find(
      session,
      where: (t) =>
          t.facultyId.equals(facultyId) &
          (isActive == null
              ? Constant.bool(true)
              : t.isActive.equals(isActive)),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
      orderBy: (s) => s.timeslotId,
    );
  }

  /// Get schedule for a specific subject with includes.
  Future<List<Schedule>> getSubjectSchedule(
    Session session,
    int subjectId, {
    bool? isActive = true,
  }) async {
    return await Schedule.db.find(
      session,
      where: (t) =>
          t.subjectId.equals(subjectId) &
          (isActive == null
              ? Constant.bool(true)
              : t.isActive.equals(isActive)),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
      orderBy: (s) => s.timeslotId,
    );
  }

  /// Get schedule for a specific room with includes.
  Future<List<Schedule>> getRoomSchedule(
    Session session,
    int roomId, {
    bool? isActive = true,
  }) async {
    return await Schedule.db.find(
      session,
      where: (t) =>
          t.roomId.equals(roomId) &
          (isActive == null
              ? Constant.bool(true)
              : t.isActive.equals(isActive)),
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
      orderBy: (s) => s.timeslotId,
    );
  }

  /// Update a schedule entry with conflict detection.
  Future<Schedule> updateSchedule(Session session, Schedule schedule) async {
    // Normalize sentinel values from frontend
    if (schedule.roomId == -1) schedule.roomId = null;
    if (schedule.timeslotId == -1) schedule.timeslotId = null;

    // Ensure schedule exists
    var existing = await Schedule.db.findById(session, schedule.id!);
    if (existing == null) {
      throw Exception('Schedule not found with ID: ${schedule.id}');
    }
    final subject = await Subject.db.findById(session, schedule.subjectId);
    if (subject == null) {
      throw Exception('Subject not found with ID: ${schedule.subjectId}');
    }
    schedule.units ??= subject.units.toDouble();
    schedule.hours ??= subject.hours;

    final isArchiving = existing.isActive && !schedule.isActive;
    await _syncScheduleSectionReference(session, schedule);
    if (!isArchiving &&
        (schedule.roomId == null || schedule.timeslotId == null)) {
      schedule.timeslotId = null;
      await _resolveAutoAssignedSchedule(
        session,
        schedule,
        excludeScheduleId: schedule.id,
      );
    }

    // Archiving only flips the active flag, so it should not be blocked by
    // conflict validation for room, faculty, or section rules.
    if (!isArchiving) {
      // Validate schedule entry (excluding current schedule from conflict checks)
      var conflicts = await ConflictService().validateSchedule(
        session,
        schedule,
        excludeScheduleId: schedule.id,
      );

      if (conflicts.isNotEmpty) {
        var messages = conflicts.map((c) => c.message).join('; ');
        throw Exception('Schedule validation failed: $messages');
      }
    }

    // Update timestamp
    schedule.updatedAt = DateTime.now();

    try {
      return await Schedule.db.updateRow(session, schedule);
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('schedule_instructor_no_overlap')) {
        throw Exception('Instructor already has a class during this time.');
      }
      if (message.contains('schedule_room_no_overlap')) {
        throw Exception('Room is already booked during this time.');
      }
      if (message.contains('schedule_section_no_overlap')) {
        throw Exception('Section already has a class during this time.');
      }
      rethrow;
    }
  }

  /// Delete a schedule entry by ID.
  Future<bool> deleteSchedule(Session session, int id) async {
    var schedule = await Schedule.db.findById(session, id);
    if (schedule == null) return false;

    await Schedule.db.deleteRow(session, schedule);
    return true;
  }

  // ─── Schedule Generation ─────────────────────────────────────────────

  /// Generate schedules using the scheduling service.
  Future<GenerateScheduleResponse> generateSchedule(
    Session session,
    GenerateScheduleRequest request,
  ) async {
    await _ensureSectionSchema(session);
    final schedulableFacultyIds = await _getSchedulableFacultyIds(session);
    final filteredFacultyIds = request.facultyIds
        .where((id) => schedulableFacultyIds.contains(id))
        .toSet()
        .toList();
    if (filteredFacultyIds.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message:
            'No schedulable faculty found in request. Admin-linked faculty cannot be auto-assigned.',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: request.subjectIds.length,
      );
    }

    final studentSections = await getDistinctStudentSections(session);
    String normalizeSection(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    final requestedSections = request.sections
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final requestedNormalized = requestedSections
        .map(normalizeSection)
        .where((s) => s.isNotEmpty)
        .toSet();
    final studentBackedSections = studentSections
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .where(
          (s) =>
              requestedNormalized.isEmpty ||
              requestedNormalized.contains(normalizeSection(s)),
        )
        .toSet()
        .toList();

    if (studentBackedSections.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message:
            'No student-backed sections found for this generation request. Add active students to the target sections first.',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: request.subjectIds.length,
      );
    }

    final sanitizedRequest = request.copyWith(
      facultyIds: filteredFacultyIds,
      sections: studentBackedSections,
    );
    var schedulingService = SchedulingService();
    return await schedulingService.generateSchedule(session, sanitizedRequest);
  }

  // ─── Helper Methods ──────────────────────────────────────────────────

  /// Validate email format using a simple regex.
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate time format (HH:mm).
  bool _isValidTimeFormat(String time) {
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  /// Check if start time is before end time.
  bool _isStartBeforeEnd(String startTime, String endTime) {
    try {
      var startParts = startTime.split(':');
      var endParts = endTime.split(':');

      var startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      var endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      return startMinutes < endMinutes;
    } catch (e) {
      return false;
    }
  }

  Future<Timeslot?> _findDuplicateTimeslot(
    Session session, {
    required DayOfWeek day,
    required String startTime,
    required String endTime,
  }) async {
    return await Timeslot.db.findFirstRow(
      session,
      where: (t) =>
          t.day.equals(day) &
          t.startTime.equals(startTime) &
          t.endTime.equals(endTime),
    );
  }

  String _normalizedRoomName(String value) => value.trim().toUpperCase();

  void _validateRoomCatalogRules(Room room) {
    final roomName = _normalizedRoomName(room.name);

    if (roomName.isEmpty) {
      throw Exception('Room name is required.');
    }
  }

  Future<void> _syncScheduleSectionReference(
    Session session,
    Schedule schedule,
  ) async {
    await _ensureSectionSchema(session);
    schedule.section = schedule.section.trim();
    if (schedule.sectionId != null) {
      final byId = await Section.db.findById(session, schedule.sectionId!);
      if (byId != null) {
        schedule.section = byId.sectionCode.trim();
        schedule.sectionId = byId.id;
        return;
      }
    }

    if (schedule.section.isEmpty) {
      schedule.sectionId = null;
      return;
    }

    var section = await Section.db.findFirstRow(
      session,
      where: (t) => t.sectionCode.equals(schedule.section),
    );

    section ??= await _findSectionByNormalizedCode(session, schedule.section);

    if (section != null) {
      schedule.section = section.sectionCode.trim();
    }
    schedule.sectionId = section?.id;
  }

  Future<Section?> _findSectionByNormalizedCode(
    Session session,
    String rawCode,
  ) async {
    final normalizedTarget = _normalizeSectionCode(rawCode);
    if (normalizedTarget.isEmpty) return null;

    final sections = await Section.db.find(session);
    for (final section in sections) {
      if (_normalizeSectionCode(section.sectionCode) == normalizedTarget) {
        return section;
      }
    }
    return null;
  }

  String _normalizeSectionCode(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
  // ─── Dashboard Stats ─────────────────────────────────────────────────

  /// Get aggregated dashboard statistics.
  Future<DashboardStats> getDashboardStats(Session session) async {
    try {
      var totalSchedules = await Schedule.db.count(session);
      var totalFaculty = await Faculty.db.count(
        session,
        where: (t) => t.isActive.equals(true),
      );
      var totalStudents = await Student.db.count(session);
      var totalSubjects = await Subject.db.count(session);
      var totalRooms = await Room.db.count(session);

      // 2. Calculate Faculty Load
      print('[DEBUG] getDashboardStats: Step 2 - Fetching all data');
      var allSchedules = await Schedule.db.find(session);
      var allFaculty = await Faculty.db.find(
        session,
        where: (t) => t.isActive.equals(true),
      );
      var allSubjects = await Subject.db.find(session);
      print(
        '[DEBUG] getDashboardStats: Fetched ${allSchedules.length} schedules, ${allFaculty.length} faculty',
      );
      for (var f in allFaculty) {
        print('[DEBUG] Faculty ${f.id}: name=${f.name}, maxLoad=${f.maxLoad}');
      }

      // Map subject ID to units for quick lookup
      var subjectUnits = <int, double>{
        for (var s in allSubjects)
          if (s.id != null) s.id!: s.units.toDouble(),
      };

      List<FacultyLoadData> facultyLoad = [];
      for (var faculty in allFaculty) {
        double currentLoad = 0;
        var facultySchedules = allSchedules.where(
          (s) => s.facultyId == faculty.id,
        );

        for (var schedule in facultySchedules) {
          currentLoad += subjectUnits[schedule.subjectId] ?? 3.0;
        }

        facultyLoad.add(
          FacultyLoadData(
            facultyName: faculty.name,
            currentLoad: currentLoad,
            maxLoad: (faculty.maxLoad ?? 0).toDouble(),
          ),
        );
      }
      print('[DEBUG] getDashboardStats: Step 2 complete');

      // 3. Integrity Check (Conflicts)
      print('[DEBUG] getDashboardStats: Step 3 - Calculating conflicts');
      List<ScheduleConflict> conflicts = await ConflictService()
          .getAllConflicts(session);

      print(
        '[DEBUG] getDashboardStats: Step 3 complete. Found ${conflicts.length} conflicts.',
      );

      // 4. Distribution Summaries
      var sectionCounts = <String, int>{};
      var yearLevelCounts = <String, int>{};

      for (var schedule in allSchedules) {
        // Section Distribution
        sectionCounts[schedule.section] =
            (sectionCounts[schedule.section] ?? 0) + 1;

        // Year Level Distribution (lookup from subject)
        var subject = allSubjects.firstWhere(
          (s) => s.id == schedule.subjectId,
          orElse: () => Subject(
            code: 'N/A',
            name: 'N/A',
            units: 0,
            studentsCount: 0,
            program: Program.it,
            types: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        var yearLevel = subject.yearLevel?.toString() ?? 'N/A';
        yearLevelCounts[yearLevel] = (yearLevelCounts[yearLevel] ?? 0) + 1;
      }

      List<DistributionData> sectionDistribution = sectionCounts.entries
          .map((e) => DistributionData(label: e.key, count: e.value))
          .toList();
      List<DistributionData> yearLevelDistribution = yearLevelCounts.entries
          .map((e) => DistributionData(label: 'Year ${e.key}', count: e.value))
          .toList();

      return DashboardStats(
        totalSchedules: totalSchedules,
        totalFaculty: totalFaculty,
        totalStudents: totalStudents,
        totalSubjects: totalSubjects,
        totalRooms: totalRooms,
        totalConflicts: conflicts.length,
        facultyLoad: facultyLoad,
        recentConflicts: conflicts,
        sectionDistribution: sectionDistribution,
        yearLevelDistribution: yearLevelDistribution,
      );
    } catch (e, stack) {
      print('[ERROR] getDashboardStats failed: $e');
      print('[ERROR] Stack trace: \n$stack');
      rethrow;
    }
  }
  // ─── Conflict & Reports ──────────────────────────────────────────────

  Future<List<ScheduleConflict>> validateSchedule(
    Session session,
    Schedule schedule,
  ) async {
    return await ConflictService().validateSchedule(session, schedule);
  }

  /// Retrieves all detected conflicts in the current schedule.
  Future<List<ScheduleConflict>> getAllConflicts(Session session) async {
    return await ConflictService().getAllConflicts(session);
  }

  /// Generates the Faculty Load Report.
  Future<List<FacultyLoadReport>> getFacultyLoadReport(Session session) async {
    return await ReportService().generateFacultyLoadReport(session);
  }

  /// Generates the Room Utilization Report.
  Future<List<RoomUtilizationReport>> getRoomUtilizationReport(
    Session session,
  ) async {
    return await ReportService().generateRoomUtilizationReport(session);
  }

  /// Generates the Conflict Summary Report.
  Future<ConflictSummaryReport> getConflictSummaryReport(
    Session session,
  ) async {
    return await ReportService().generateConflictSummary(session);
  }

  /// Generates the Schedule Overview Report.
  Future<ScheduleOverviewReport> getScheduleOverviewReport(
    Session session,
  ) async {
    return await ReportService().generateScheduleOverview(session);
  }

  // ─── Section CRUD ───────────────────────────────────────────────────

  /// Create a new section with validation.
  Future<Section> createSection(Session session, Section section) async {
    await _ensureSectionSchema(session);
    // Validate fields
    if (section.sectionCode.trim().isEmpty) {
      throw Exception('Section code cannot be empty');
    }
    if (section.yearLevel < 1 || section.yearLevel > 6) {
      throw Exception('Year level must be between 1 and 6');
    }
    if (section.semester < 1 || section.semester > 3) {
      throw Exception('Semester must be 1, 2, or 3');
    }

    // Check uniqueness
    var existing = await Section.db.findFirstRow(
      session,
      where: (t) =>
          t.program.equals(section.program) &
          t.yearLevel.equals(section.yearLevel) &
          t.sectionCode.equals(section.sectionCode) &
          t.academicYear.equals(section.academicYear) &
          t.semester.equals(section.semester),
    );
    if (existing != null) {
      throw Exception(
        'Section ${section.sectionCode} already exists for this program/year/semester',
      );
    }

    section.createdAt = DateTime.now();
    section.updatedAt = DateTime.now();
    return await Section.db.insertRow(session, section);
  }

  /// Get all sections.
  Future<List<Section>> getAllSections(Session session) async {
    await _ensureSectionSchema(session);
    final students = await Student.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    for (final student in students) {
      try {
        await _repairStudentSectionRelation(session, student);
      } catch (e) {
        session.log('Error repairing section before getAllSections: $e');
      }
    }

    return await Section.db.find(session);
  }

  /// Update a section.
  Future<Section> updateSection(Session session, Section section) async {
    await _ensureSectionSchema(session);
    var existing = await Section.db.findById(session, section.id!);
    if (existing == null) {
      throw Exception('Section not found with ID: ${section.id}');
    }

    if (section.sectionCode.trim().isEmpty) {
      throw Exception('Section code cannot be empty');
    }

    section.updatedAt = DateTime.now();
    return await Section.db.updateRow(session, section);
  }

  /// Delete a section by ID.
  Future<bool> deleteSection(Session session, int id) async {
    var section = await Section.db.findById(session, id);
    if (section == null) return false;

    // Check for students assigned to this section
    var students = await Student.db.find(
      session,
      where: (t) => t.sectionId.equals(id),
    );
    if (students.isNotEmpty) {
      throw Exception(
        'Cannot delete section: ${students.length} student(s) assigned. '
        'Please reassign students first.',
      );
    }

    await Section.db.deleteRow(session, section);
    return true;
  }

  // ─── Faculty Availability CRUD ──────────────────────────────────────

  /// Set faculty availability (creates or replaces entries for a faculty).
  Future<List<FacultyAvailability>> setFacultyAvailability(
    Session session,
    int facultyId,
    List<FacultyAvailability> availabilities,
  ) async => setFacultyAvailabilityImpl(
    session,
    facultyId,
    availabilities,
  );

  Future<List<FacultyAvailability>> setFacultyAvailabilityImpl(
    Session session,
    int facultyId,
    List<FacultyAvailability> availabilities,
  ) async {
    try {
      print('--- SET FACULTY AVAILABILITY DEBUG ---');
      print('FacultyID: $facultyId');
      print('Availabilities count: ${availabilities.length}');

      // Validate faculty exists
      var faculty = await Faculty.db.findById(session, facultyId);
      if (faculty == null) {
        throw Exception('Faculty not found with ID: $facultyId');
      }

      // Validate each availability entry
      for (var avail in availabilities) {
        if (!_isValidTimeFormat(avail.startTime)) {
          throw Exception('Invalid start time: ${avail.startTime}');
        }
        if (!_isValidTimeFormat(avail.endTime)) {
          throw Exception('Invalid end time: ${avail.endTime}');
        }
        if (!_isStartBeforeEnd(avail.startTime, avail.endTime)) {
          throw Exception(
            'Start time must be before end time: ${avail.startTime} - ${avail.endTime}',
          );
        }
      }

      // Check for overlapping availability for same faculty on same day
      for (var i = 0; i < availabilities.length; i++) {
        for (var j = i + 1; j < availabilities.length; j++) {
          if (availabilities[i].dayOfWeek == availabilities[j].dayOfWeek) {
            if (_timesOverlap(
              availabilities[i].startTime,
              availabilities[i].endTime,
              availabilities[j].startTime,
              availabilities[j].endTime,
            )) {
              throw Exception(
                'Overlapping availability on ${availabilities[i].dayOfWeek.name}: '
                '${availabilities[i].startTime}-${availabilities[i].endTime} and '
                '${availabilities[j].startTime}-${availabilities[j].endTime}',
              );
            }
          }
        }
      }

      // Delete existing availability for this faculty
      var existing = await FacultyAvailability.db.find(
        session,
        where: (t) => t.facultyId.equals(facultyId),
      );
      for (var e in existing) {
        await FacultyAvailability.db.deleteRow(session, e);
      }

      // Insert new entries
      var now = DateTime.now();
      var results = <FacultyAvailability>[];
      for (var avail in availabilities) {
        avail.facultyId = facultyId;
        avail.createdAt = now;
        avail.updatedAt = now;
        results.add(await FacultyAvailability.db.insertRow(session, avail));
      }

      return results;
    } catch (e, stack) {
      print('CRITICAL ERROR IN setFacultyAvailability: $e');
      print(stack);
      rethrow;
    }
  }

  /// Get all availability entries for a specific faculty.
  Future<List<FacultyAvailability>> getFacultyAvailability(
    Session session,
    int facultyId,
  ) async {
    return await FacultyAvailability.db.find(
      session,
      where: (t) => t.facultyId.equals(facultyId),
    );
  }

  /// Get all faculty availabilities.
  Future<List<FacultyAvailability>> getAllFacultyAvailabilities(
    Session session,
  ) async {
    return await FacultyAvailability.db.find(session);
  }

  /// Delete a single faculty availability entry.
  Future<bool> deleteFacultyAvailability(Session session, int id) async {
    var avail = await FacultyAvailability.db.findById(session, id);
    if (avail == null) return false;
    await FacultyAvailability.db.deleteRow(session, avail);
    return true;
  }

  // ─── Schedule Pre-Check & Regeneration ──────────────────────────────

  /// Pre-check readiness for schedule generation.
  /// Returns a map with readiness status and any missing items.
  Future<GenerateScheduleResponse> precheckSchedule(
    Session session,
  ) async {
    var missing = <String>[];

    var schedulableFaculty = await _getSchedulableFaculty(session);
    var facultyCount = schedulableFaculty.length;
    if (facultyCount == 0) missing.add('No faculty members defined');

    var subjectCount = await Subject.db.count(session);
    if (subjectCount == 0) missing.add('No subjects defined');

    var roomCount = await Room.db.count(session);
    if (roomCount == 0) missing.add('No rooms defined');

    var sectionCount = await Section.db.count(session);
    if (sectionCount == 0) missing.add('No sections defined');

    var availabilityCount = await FacultyAvailability.db.count(session);
    if (availabilityCount == 0) {
      missing.add('No faculty availability defined');
    }

    if (missing.isNotEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'Not ready: ${missing.join(", ")}',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: 0,
      );
    }

    return GenerateScheduleResponse(
      success: true,
      message:
          'Ready to generate. Faculty: $facultyCount, '
          'Subjects: $subjectCount, Rooms: $roomCount, '
          'Sections: $sectionCount, '
          'Availabilities: $availabilityCount',
      totalAssigned: 0,
      conflictsDetected: 0,
      unassignedSubjects: 0,
    );
  }

  /// Regenerate all schedules using the AI scheduling engine.
  /// Clears existing schedules, then generates new ones respecting all constraints.
  Future<GenerateScheduleResponse> regenerateSchedule(
    Session session,
  ) async {
    await _ensureSectionSchema(session);
    // 1. Pre-check
    var precheck = await precheckSchedule(session);
    if (!precheck.success) {
      return precheck;
    }

    // 2. Clear existing schedules
    var existingSchedules = await Schedule.db.find(session);
    for (var s in existingSchedules) {
      await Schedule.db.deleteRow(session, s);
    }

    // 3. Fetch all entities
    var allFaculty = await _getSchedulableFaculty(session);
    var allSubjects = await Subject.db.find(session);
    var allRooms = await Room.db.find(session);
    var allTimeslots = await Timeslot.db.find(session);
    var allSections = await Section.db.find(session);
    var allStudents = await Student.db.find(
      session,
      where: (t) => t.isActive.equals(true) & t.section.notEquals(null),
    );
    final studentSections = allStudents
        .map((s) => s.section?.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toSet();
    final sectionCodes = <String>{
      ...allSections.map((s) => s.sectionCode),
      ...studentSections,
    };
    var allAvailabilities = await FacultyAvailability.db.find(session);

    // Build availability lookup: facultyId -> list of availability windows
    var availabilityMap = <int, List<FacultyAvailability>>{};
    for (var a in allAvailabilities) {
      availabilityMap.putIfAbsent(a.facultyId, () => []);
      availabilityMap[a.facultyId]!.add(a);
    }

    // 4. Run AI scheduling algorithm
    var request = GenerateScheduleRequest(
      subjectIds: allSubjects.map((s) => s.id!).toList(),
      facultyIds: allFaculty.map((f) => f.id!).toList(),
      roomIds: allRooms.map((r) => r.id!).toList(),
      timeslotIds: allTimeslots.map((t) => t.id!).toList(),
      sections: sectionCodes.toList(),
    );

    var result = await SchedulingService().generateSchedule(session, request);

    // 5. Recalculate conflicts
    var conflicts = await ConflictService().getAllConflicts(session);

    // 6. Return summary
    return GenerateScheduleResponse(
      success: result.success,
      schedules: result.schedules,
      conflicts: conflicts,
      message: result.message,
      totalAssigned: result.schedules?.length ?? 0,
      conflictsDetected: conflicts.length,
      unassignedSubjects: result.conflicts?.length ?? 0,
    );
  }

  Future<Set<int>> _getSchedulableFacultyIds(Session session) async {
    final faculty = await _getSchedulableFaculty(session);
    return faculty.map((f) => f.id!).toSet();
  }

  Future<List<Faculty>> _getSchedulableFaculty(Session session) async {
    final faculty = await Faculty.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    if (faculty.isEmpty) return const [];

    final adminRoleRows = await UserRole.db.find(
      session,
      where: (t) => t.role.equals('admin'),
    );
    final adminUserIds = adminRoleRows.map((r) => r.userId).toSet();

    return faculty.where((f) {
      final key = (f.userInfoId).toString();
      return !adminUserIds.contains(key);
    }).toList();
  }

  /// Check if two time ranges overlap.
  bool _timesOverlap(
    String start1,
    String end1,
    String start2,
    String end2,
  ) {
    try {
      var s1 = _timeToMinutes(start1);
      var e1 = _timeToMinutes(end1);
      var s2 = _timeToMinutes(start2);
      var e2 = _timeToMinutes(end2);
      return s1 < e2 && s2 < e1;
    } catch (e) {
      return false;
    }
  }

  /// Convert time string to minutes since midnight.
  int _timeToMinutes(String time) {
    var parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}

class _SectionAvailabilityWindow {
  final DayOfWeek day;
  final String startTime;
  final String endTime;

  const _SectionAvailabilityWindow({
    required this.day,
    required this.startTime,
    required this.endTime,
  });
}
