import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Service class responsible for validating all scheduling constraints.
/// Ensures the timetable remains conflict-free.
///
/// Conflict Types (standardized codes):
///   room_conflict       – Room double-booked at same timeslot
///   faculty_conflict    – Faculty double-booked at same timeslot
///   section_conflict    – Section double-booked at same timeslot
///   program_mismatch    – Subject program ≠ Room program
///   capacity_exceeded   – Room capacity < subject student count
///   max_load_exceeded   – Faculty total units > maxLoad
///   room_inactive       – Room is marked inactive
///   faculty_unavailable – Timeslot falls outside faculty availability
class ConflictService {
  static const int _labEarliestStartMinutes = 9 * 60;

  bool _isLabSubject(Subject subject) {
    return subject.types.contains(SubjectType.laboratory);
  }

  String _normalizeSubjectCode(String code) {
    return code.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }

  bool _isStudentAvailabilityExemptSubject(Subject subject) {
    final normalized = _normalizeSubjectCode(subject.code);
    return normalized.startsWith('GE') || normalized.startsWith('SF');
  }

  bool _isBlendedSubject(Subject subject) {
    return subject.types.contains(SubjectType.blended);
  }

  bool _requiresLaboratoryRoom(Subject subject) {
    return _isLabSubject(subject) || _isBlendedSubject(subject);
  }

  bool _requiresLaboratoryRoomForSchedule(
    Subject subject,
    Schedule schedule,
  ) {
    final loadTypes = schedule.loadTypes;
    if (loadTypes != null && loadTypes.isNotEmpty) {
      final hasLab = loadTypes.contains(SubjectType.laboratory);
      final hasLecture = loadTypes.contains(SubjectType.lecture);
      if (hasLab && !hasLecture) return true;
      if (hasLecture && !hasLab) return false;
      // Blended or unspecified mix: fall back to subject type rules.
    }

    return _requiresLaboratoryRoom(subject);
  }

  bool _isLabSchedule(Subject subject, Schedule schedule, Room? room) {
    final loadTypes = schedule.loadTypes;
    if (loadTypes != null && loadTypes.isNotEmpty) {
      final hasLab = loadTypes.contains(SubjectType.laboratory);
      final hasLecture = loadTypes.contains(SubjectType.lecture);
      if (hasLab && !hasLecture) return true;
      if (hasLecture && !hasLab) return false;
    }

    if (room != null) {
      if (room.type == RoomType.laboratory) return true;
      if (room.type == RoomType.lecture) return false;
    }

    return _requiresLaboratoryRoom(subject);
  }

  List<String> _componentTagsForSchedule(Subject subject, Schedule schedule) {
    final loadTypes = schedule.loadTypes ?? const [];
    if (loadTypes.isNotEmpty) {
      final hasLab = loadTypes.contains(SubjectType.laboratory);
      final hasLecture = loadTypes.contains(SubjectType.lecture);
      if (hasLab && !hasLecture) return const ['laboratory'];
      if (hasLecture && !hasLab) return const ['lecture'];
      if (hasLab && hasLecture) return const ['lecture', 'laboratory'];
    }

    final hasLecture = subject.types.contains(SubjectType.lecture);
    final hasLab = subject.types.contains(SubjectType.laboratory);
    final hasBlended = subject.types.contains(SubjectType.blended);
    if (hasBlended || (hasLecture && hasLab)) {
      return const ['lecture', 'laboratory'];
    }
    if (hasLab) return const ['laboratory'];
    return const ['lecture'];
  }

  String _normalizeSubjectCode(String? value) {
    return (value ?? '').trim().toLowerCase();
  }

  Future<void> _appendSubjectFacultyMismatch(
    Session session,
    Schedule schedule,
    Subject? subject,
    List<ScheduleConflict> conflicts,
  ) async {
    if (subject == null) return;
    if (subject.facultyId == null) return;
    if (subject.facultyId == schedule.facultyId) return;

    final faculty = await Faculty.db.findById(session, subject.facultyId!);
    conflicts.add(
      ScheduleConflict(
        type: 'subject_faculty_mismatch',
        message: 'Subject is assigned to a different instructor',
        facultyId: schedule.facultyId,
        subjectId: schedule.subjectId,
        scheduleId: schedule.id,
        details:
            'Subject ${subject.code} is assigned to ${faculty?.name ?? 'Faculty ID ${subject.facultyId}'}, but schedule uses Faculty ID ${schedule.facultyId}.',
      ),
    );
  }

  Future<void> _appendDuplicateComponentConflict(
    Session session,
    Schedule schedule,
    Subject? subject,
    List<ScheduleConflict> conflicts, {
    int? excludeScheduleId,
  }) async {
    if (subject == null) return;
    final tags = _componentTagsForSchedule(subject, schedule);
    if (tags.isEmpty) return;

    final sectionId = schedule.sectionId;
    final sectionCode = schedule.section.trim();
    if (sectionId == null && sectionCode.isEmpty) return;
    final normalizedSubjectCode = _normalizeSubjectCode(subject.code);

    final whereClause = sectionId != null
        ? (Schedule.t.subjectId.equals(subject.id!) &
              Schedule.t.sectionId.equals(sectionId))
        : (Schedule.t.subjectId.equals(subject.id!) &
              Schedule.t.section.equals(sectionCode));

    var existing = await Schedule.db.find(
      session,
      where: (_) => whereClause,
      include: Schedule.include(subject: Subject.include()),
    );

    if (sectionId != null) {
      final sameSectionByCode = await Schedule.db.find(
        session,
        where: (t) => t.sectionId.equals(sectionId),
        include: Schedule.include(subject: Subject.include()),
      );
      existing = [...existing, ...sameSectionByCode];
    } else {
      final sameSectionByCode = await Schedule.db.find(
        session,
        where: (t) => t.section.equals(sectionCode),
        include: Schedule.include(subject: Subject.include()),
      );
      existing = [...existing, ...sameSectionByCode];
    }

    if (excludeScheduleId != null) {
      existing = existing.where((s) => s.id != excludeScheduleId).toList();
    }

    final deduped = <int?, Schedule>{};
    for (final entry in existing) {
      deduped[entry.id] = entry;
    }
    existing = deduped.values.toList();

    for (final other in existing) {
      final otherSubject =
          other.subject ?? await Subject.db.findById(session, other.subjectId);
      if (otherSubject == null) continue;
      if (_normalizeSubjectCode(otherSubject.code) != normalizedSubjectCode) {
        continue;
      }
      final otherTags = _componentTagsForSchedule(otherSubject, other).toSet();
      for (final tag in tags) {
        if (!otherTags.contains(tag)) continue;
        conflicts.add(
          ScheduleConflict(
            type: 'duplicate_component',
            message: 'Section already has a $tag schedule for this subject',
            facultyId: schedule.facultyId,
            subjectId: schedule.subjectId,
            scheduleId: schedule.id,
            conflictingScheduleId: other.id,
            details:
                '${subject.code} (${subject.name}) already has a $tag schedule for section ${sectionCode.isNotEmpty ? sectionCode : sectionId}.',
          ),
        );
        return;
      }
    }
  }

  ScheduleConflict? _buildRoomTypeConflict({
    required Schedule schedule,
    required Subject subject,
    required Room room,
  }) {
    final requiresLabRoom = _requiresLaboratoryRoomForSchedule(
      subject,
      schedule,
    );

    if (requiresLabRoom && room.type != RoomType.laboratory) {
      return ScheduleConflict(
        type: 'room_type_mismatch',
        message:
            'Laboratory or blended subjects can only be assigned to laboratory rooms',
        facultyId: schedule.facultyId,
        roomId: room.id,
        subjectId: schedule.subjectId,
        scheduleId: schedule.id,
        details:
            '${subject.name} requires a laboratory room, but was assigned to ${room.name}',
      );
    }

    if (!requiresLabRoom && room.type != RoomType.lecture) {
      return ScheduleConflict(
        type: 'room_type_mismatch',
        message: 'Lecture-only subjects can only be assigned to lecture rooms',
        facultyId: schedule.facultyId,
        roomId: room.id,
        subjectId: schedule.subjectId,
        scheduleId: schedule.id,
        details:
            '${subject.name} is non-laboratory, but was assigned to ${room.name}',
      );
    }

    return null;
  }
  // ─── Individual Conflict Checks ────────────────────────────────────

  /// Check if a room is available at a given timeslot.
  Future<Schedule?> checkRoomAvailability(
    Session session, {
    required int? roomId,
    required int? timeslotId,
    int? excludeScheduleId,
  }) async {
    if (roomId == null || timeslotId == null) return null;

    final targetTimeslot = await Timeslot.db.findById(session, timeslotId);
    if (targetTimeslot == null) return null;

    var conflicts = await Schedule.db.find(
      session,
      where: (t) =>
          t.roomId.equals(roomId) &
          t.timeslotId.notEquals(null) &
          t.isActive.equals(true),
      include: Schedule.include(timeslot: Timeslot.include()),
    );

    if (excludeScheduleId != null) {
      conflicts = conflicts.where((s) => s.id != excludeScheduleId).toList();
    }

    for (final schedule in conflicts) {
      final existing = schedule.timeslot;
      if (existing == null) continue;
      if (_timeslotsOverlap(existing, targetTimeslot)) {
        return schedule;
      }
    }

    return null;
  }

  /// Check if a faculty member is available at a given timeslot.
  Future<Schedule?> checkFacultyAvailability(
    Session session, {
    required int facultyId,
    required int? timeslotId,
    int? excludeScheduleId,
  }) async {
    if (timeslotId == null) return null;

    final targetTimeslot = await Timeslot.db.findById(session, timeslotId);
    if (targetTimeslot == null) return null;

    var conflicts = await Schedule.db.find(
      session,
      where: (t) =>
          t.facultyId.equals(facultyId) &
          t.timeslotId.notEquals(null) &
          t.isActive.equals(true),
      include: Schedule.include(timeslot: Timeslot.include()),
    );

    if (excludeScheduleId != null) {
      conflicts = conflicts.where((s) => s.id != excludeScheduleId).toList();
    }

    for (final schedule in conflicts) {
      final existing = schedule.timeslot;
      if (existing == null) continue;
      if (_timeslotsOverlap(existing, targetTimeslot)) {
        return schedule;
      }
    }

    return null;
  }

  /// Check if a section is available at a given timeslot.
  Future<Schedule?> checkSectionAvailability(
    Session session, {
    required String section,
    int? sectionId,
    required int? timeslotId,
    int? excludeScheduleId,
  }) async {
    if (timeslotId == null || section.isEmpty) return null;

    final targetTimeslot = await Timeslot.db.findById(session, timeslotId);
    if (targetTimeslot == null) return null;

    final whereClause = sectionId != null
        ? (Schedule.t.sectionId.equals(sectionId) &
              Schedule.t.timeslotId.notEquals(null) &
              Schedule.t.isActive.equals(true))
        : (Schedule.t.section.equals(section) &
              Schedule.t.timeslotId.notEquals(null) &
              Schedule.t.isActive.equals(true));

    var conflicts = await Schedule.db.find(
      session,
      where: (_) => whereClause,
      include: Schedule.include(timeslot: Timeslot.include()),
    );

    if (excludeScheduleId != null) {
      conflicts = conflicts.where((s) => s.id != excludeScheduleId).toList();
    }

    for (final schedule in conflicts) {
      final existing = schedule.timeslot;
      if (existing == null) continue;
      if (_timeslotsOverlap(existing, targetTimeslot)) {
        return schedule;
      }
    }

    return null;
  }

  /// Check if a faculty member has exceeded their maximum teaching load.
  Future<bool> checkFacultyMaxLoad(
    Session session, {
    required int facultyId,
    double newUnits = 0,
    int? excludeScheduleId,
  }) async {
    var faculty = await Faculty.db.findById(session, facultyId);
    if (faculty == null) {
      session.log(
        'Warning: Faculty not found for ID $facultyId during max load check.',
        level: LogLevel.warning,
      );
      return true;
    }

    var schedules = await Schedule.db.find(
      session,
      where: (t) => t.facultyId.equals(facultyId) & t.isActive.equals(true),
    );

    if (excludeScheduleId != null) {
      schedules = schedules.where((s) => s.id != excludeScheduleId).toList();
    }

    // Resolve subject units for rows where schedule.units is null.
    var subjectUnitsById = <int, double>{};
    var subjectIds = schedules.map((s) => s.subjectId).toSet().toList();
    if (subjectIds.isNotEmpty) {
      var subjects = await Subject.db.find(
        session,
        where: (t) => t.id.inSet(subjectIds.toSet()),
      );
      for (var subject in subjects) {
        if (subject.id != null) {
          subjectUnitsById[subject.id!] = subject.units.toDouble();
        }
      }
    }

    double currentLoad = 0;
    for (var s in schedules) {
      currentLoad += s.units ?? (subjectUnitsById[s.subjectId] ?? 0);
    }

    return (currentLoad + newUnits) <= (faculty.maxLoad ?? 0);
  }

  /// Check if a faculty member is available on the day/time of a given timeslot
  /// based on their FacultyAvailability preferences.
  /// Returns true if available (or no preferences set), false if outside preferred times.
  Future<bool> checkFacultyDayTimeAvailability(
    Session session, {
    required int facultyId,
    required int timeslotId,
  }) async {
    // Get the timeslot details
    var timeslot = await Timeslot.db.findById(session, timeslotId);
    if (timeslot == null) return true; // Can't validate without timeslot

    // Get faculty availability preferences
    var availabilities = await FacultyAvailability.db.find(
      session,
      where: (t) => t.facultyId.equals(facultyId),
    );

    // If no preferences set, faculty is available anytime
    if (availabilities.isEmpty) return true;

    // Parse timeslot day and times
    final timeslotDay = timeslot.day;
    final tsStartMinutes = _parseTimeToMinutes(timeslot.startTime);
    final tsEndMinutes = _parseTimeToMinutes(timeslot.endTime);

    // Check if any availability window covers this timeslot
    for (var avail in availabilities) {
      if (avail.dayOfWeek == timeslotDay) {
        final availStart = _parseTimeToMinutes(avail.startTime);
        final availEnd = _parseTimeToMinutes(avail.endTime);

        // Timeslot must fit within the availability window
        if (tsStartMinutes >= availStart && tsEndMinutes <= availEnd) {
          return true;
        }
      }
    }

    return false; // No matching availability window
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

        final day = DayOfWeek.values
            .where((value) => value.name == dayValue)
            .firstOrNull;
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

    for (final window in availability) {
      if (window.day != timeslot.day) continue;
      final windowStart = _parseTimeToMinutes(window.startTime);
      final windowEnd = _parseTimeToMinutes(window.endTime);
      if (slotStart >= windowStart && slotEnd <= windowEnd) {
        return true;
      }
    }

    return false;
  }

  Future<void> _appendSectionAvailabilityConflict(
    Session session,
    Schedule schedule,
    List<ScheduleConflict> conflicts,
  ) async {
    if (schedule.timeslotId == null) return;
    final subject = await Subject.db.findById(session, schedule.subjectId);
    if (subject != null && _isStudentAvailabilityExemptSubject(subject)) {
      return;
    }

    Section? sectionRecord;
    if (schedule.sectionId != null) {
      sectionRecord = await Section.db.findById(session, schedule.sectionId!);
    }
    if (sectionRecord == null && schedule.section.trim().isNotEmpty) {
      sectionRecord = await Section.db.findFirstRow(
        session,
        where: (t) => t.sectionCode.equals(schedule.section.trim()),
      );
    }
    if (sectionRecord == null) return;

    final sectionAvailability = _parseSectionAvailability(
      sectionRecord.availabilityJson,
    );
    if (sectionAvailability.isEmpty) return;

    final timeslot = await Timeslot.db.findById(session, schedule.timeslotId!);
    if (timeslot == null) return;

    if (_timeslotMatchesSectionAvailability(timeslot, sectionAvailability)) {
      return;
    }

    conflicts.add(
      ScheduleConflict(
        type: 'section_unavailable',
        message: 'Timeslot is outside section availability',
        scheduleId: schedule.id,
        facultyId: schedule.facultyId,
        roomId: schedule.roomId,
        subjectId: schedule.subjectId,
        details:
            'Section ${sectionRecord.sectionCode} allows ${sectionAvailability.where((window) => window.day == timeslot.day).map((window) => '${window.startTime}-${window.endTime}').join(', ')} on ${timeslot.day.name}, but schedule uses ${timeslot.startTime}-${timeslot.endTime}.',
      ),
    );
  }

  Future<void> _appendRoomConflicts(
    Session session,
    Schedule schedule,
    Subject? subject,
    List<ScheduleConflict> conflicts, {
    int? excludeScheduleId,
  }) async {
    final roomId = schedule.roomId;
    final timeslotId = schedule.timeslotId;
    if (roomId == null || timeslotId == null) return;

    final roomConflict = await checkRoomAvailability(
      session,
      roomId: roomId,
      timeslotId: timeslotId,
      excludeScheduleId: excludeScheduleId,
    );

    if (roomConflict != null) {
      conflicts.add(
        ScheduleConflict(
          type: 'room_conflict',
          message: 'Room is already booked for this timeslot',
          conflictingScheduleId: roomConflict.id,
          facultyId: schedule.facultyId,
          roomId: roomId,
          subjectId: schedule.subjectId,
          details:
              'Room ID $roomId is already assigned to schedule ID ${roomConflict.id}',
        ),
      );
    }

    if (subject == null) return;
    final room = await Room.db.findById(session, roomId);
    if (room == null) return;

    if (subject.program != room.program &&
        room.program != Program.both &&
        room.type != RoomType.lecture) {
      conflicts.add(
        ScheduleConflict(
          type: 'program_mismatch',
          message: 'Subject program does not match Room program',
          facultyId: schedule.facultyId,
          roomId: roomId,
          subjectId: schedule.subjectId,
          details:
              '${subject.name} (${subject.program.name.toUpperCase()}) cannot use ${room.name} (${room.program.name.toUpperCase()})',
        ),
      );
    }

    if (room.capacity < subject.studentsCount) {
      conflicts.add(
        ScheduleConflict(
          type: 'capacity_exceeded',
          message: 'Room capacity is smaller than student count',
          facultyId: schedule.facultyId,
          roomId: roomId,
          subjectId: schedule.subjectId,
          details:
              '${room.name} capacity: ${room.capacity}, ${subject.name} students: ${subject.studentsCount}',
        ),
      );
    }

    if (!room.isActive) {
      conflicts.add(
        ScheduleConflict(
          type: 'room_inactive',
          message: 'The selected room is currently inactive',
          facultyId: schedule.facultyId,
          roomId: roomId,
          subjectId: schedule.subjectId,
          details: '${room.name} must be active for assignment',
        ),
      );
    }

    final roomTypeConflict = _buildRoomTypeConflict(
      schedule: schedule,
      subject: subject,
      room: room,
    );
    if (roomTypeConflict != null) {
      conflicts.add(roomTypeConflict);
    }
  }

  Future<void> _appendFacultyTimeConflict(
    Session session,
    Schedule schedule,
    List<ScheduleConflict> conflicts, {
    int? excludeScheduleId,
  }) async {
    if (schedule.timeslotId == null) return;
    final facultyConflict = await checkFacultyAvailability(
      session,
      facultyId: schedule.facultyId,
      timeslotId: schedule.timeslotId,
      excludeScheduleId: excludeScheduleId,
    );
    if (facultyConflict == null) return;

    conflicts.add(
      ScheduleConflict(
        type: 'faculty_conflict',
        message: 'Faculty is already assigned at this timeslot',
        conflictingScheduleId: facultyConflict.id,
        facultyId: schedule.facultyId,
        roomId: schedule.roomId,
        subjectId: schedule.subjectId,
        details:
            'Faculty ID ${schedule.facultyId} already teaches at schedule ID ${facultyConflict.id}',
      ),
    );
  }

  Future<void> _appendSectionConflict(
    Session session,
    Schedule schedule,
    List<ScheduleConflict> conflicts, {
    int? excludeScheduleId,
  }) async {
    if (schedule.timeslotId == null || schedule.section.isEmpty) return;
    final sectionConflict = await checkSectionAvailability(
      session,
      section: schedule.section,
      sectionId: schedule.sectionId,
      timeslotId: schedule.timeslotId,
      excludeScheduleId: excludeScheduleId,
    );
    if (sectionConflict == null) return;

    conflicts.add(
      ScheduleConflict(
        type: 'section_conflict',
        message: 'Section is already in another class at this timeslot',
        conflictingScheduleId: sectionConflict.id,
        facultyId: schedule.facultyId,
        roomId: schedule.roomId,
        subjectId: schedule.subjectId,
        details:
            'Section ${schedule.section} is already in schedule ID ${sectionConflict.id}',
      ),
    );
  }

  Future<void> _appendMaxLoadConflict(
    Session session,
    Schedule schedule,
    List<ScheduleConflict> conflicts, {
    int? excludeScheduleId,
  }) async {
    var newUnits = schedule.units ?? 0;
    if (newUnits == 0) {
      final subject = await Subject.db.findById(session, schedule.subjectId);
      newUnits = subject?.units.toDouble() ?? 0;
    }

    final canTakeMore = await checkFacultyMaxLoad(
      session,
      facultyId: schedule.facultyId,
      newUnits: newUnits,
      excludeScheduleId: excludeScheduleId,
    );
    if (canTakeMore) return;

    final faculty = await Faculty.db.findById(session, schedule.facultyId);
    conflicts.add(
      ScheduleConflict(
        type: 'max_load_exceeded',
        message: 'Faculty has reached maximum teaching load',
        facultyId: schedule.facultyId,
        subjectId: schedule.subjectId,
        details:
            '${faculty?.name ?? 'Faculty ID ${schedule.facultyId}'} has reached max load of ${faculty?.maxLoad ?? 0} units',
      ),
    );
  }

  Future<void> _appendFacultyAvailabilityConflict(
    Session session,
    Schedule schedule,
    List<ScheduleConflict> conflicts,
  ) async {
    if (schedule.timeslotId == null) return;
    final isWithinPreference = await checkFacultyDayTimeAvailability(
      session,
      facultyId: schedule.facultyId,
      timeslotId: schedule.timeslotId!,
    );
    if (isWithinPreference) return;

    conflicts.add(
      ScheduleConflict(
        type: 'faculty_unavailable',
        message: 'Timeslot is outside faculty preferred availability',
        facultyId: schedule.facultyId,
        subjectId: schedule.subjectId,
        details:
            'Faculty ID ${schedule.facultyId} has no availability window covering this timeslot',
      ),
    );
  }

  Future<void> _appendTimeslotDurationConflicts(
    Session session,
    Schedule schedule,
    Subject subject,
    List<ScheduleConflict> conflicts,
  ) async {
    if (schedule.timeslotId == null) return;
    final timeslot = await Timeslot.db.findById(
      session,
      schedule.timeslotId!,
    );
    if (timeslot == null) return;

    final requiredHours =
        schedule.hours ?? subject.hours ?? subject.units.toDouble();
    if (requiredHours <= 0) return;
    final requiredMinutes = (requiredHours * 60).round();

    final tsMinutes =
        _parseTimeToMinutes(timeslot.endTime) -
        _parseTimeToMinutes(timeslot.startTime);
    final tsHours = tsMinutes / 60.0;
    if (tsHours + 1e-6 < requiredHours) {
      conflicts.add(
        ScheduleConflict(
          type: 'insufficient_block',
          message:
              'Timeslot ${timeslot.day.name} ${timeslot.startTime}-${timeslot.endTime} is too short for ${subject.name}',
          scheduleId: schedule.id,
          facultyId: schedule.facultyId,
          subjectId: schedule.subjectId,
          details:
              'Required continuous hours: ${requiredHours.toStringAsFixed(1)}, available: ${tsHours.toStringAsFixed(1)}',
        ),
      );
    }

    final startMinutes = _parseTimeToMinutes(timeslot.startTime);
    final endMinutes = _parseTimeToMinutes(timeslot.endTime);
    if (_overlapsLunchWindow(startMinutes, endMinutes)) {
      conflicts.add(
        ScheduleConflict(
          type: 'lunch_break_overlap',
          message:
              'Scheduled classes cannot overlap lunch time (12:00 PM-1:00 PM)',
          scheduleId: schedule.id,
          facultyId: schedule.facultyId,
          subjectId: schedule.subjectId,
          roomId: schedule.roomId,
          details:
              'Timeslot ${timeslot.day.name} ${timeslot.startTime}-${timeslot.endTime} overlaps the lunch break.',
        ),
      );
    }

    final room = schedule.roomId != null
        ? await Room.db.findById(session, schedule.roomId!)
        : null;
    final isLabSchedule = _isLabSchedule(subject, schedule, room);
    if (isLabSchedule) {
      if (startMinutes < _labEarliestStartMinutes) {
        conflicts.add(
          ScheduleConflict(
            type: 'lab_start_time',
            message: 'Laboratory classes must start at 9:00 AM or later',
            scheduleId: schedule.id,
            facultyId: schedule.facultyId,
            subjectId: schedule.subjectId,
            roomId: schedule.roomId,
            details:
                'Lab starts at ${timeslot.startTime} on ${timeslot.day.name}',
          ),
        );
      }
    }
  }

  /// Helper: parse "HH:MM" or "H:MM" to minutes since midnight.
  int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  bool _overlapsLunchWindow(int startMinutes, int endMinutes) {
    return startMinutes < 13 * 60 && endMinutes > 12 * 60;
  }

  bool _timeslotsOverlap(Timeslot a, Timeslot b) {
    if (a.day != b.day) return false;
    final aStart = _parseTimeToMinutes(a.startTime);
    final aEnd = _parseTimeToMinutes(a.endTime);
    final bStart = _parseTimeToMinutes(b.startTime);
    final bEnd = _parseTimeToMinutes(b.endTime);
    return aStart < bEnd && bStart < aEnd;
  }

  // ─── Full Schedule Validation ──────────────────────────────────────

  /// Validate a schedule entry against ALL conflict rules.
  /// Returns a list of conflicts (empty if valid).
  Future<List<ScheduleConflict>> validateSchedule(
    Session session,
    Schedule schedule, {
    int? excludeScheduleId,
  }) async {
    final conflicts = <ScheduleConflict>[];
    final subject = await Subject.db.findById(session, schedule.subjectId);

    await _appendSubjectFacultyMismatch(
      session,
      schedule,
      subject,
      conflicts,
    );
    await _appendDuplicateComponentConflict(
      session,
      schedule,
      subject,
      conflicts,
      excludeScheduleId: excludeScheduleId,
    );
    await _appendRoomConflicts(
      session,
      schedule,
      subject,
      conflicts,
      excludeScheduleId: excludeScheduleId,
    );
    await _appendFacultyTimeConflict(
      session,
      schedule,
      conflicts,
      excludeScheduleId: excludeScheduleId,
    );
    await _appendSectionConflict(
      session,
      schedule,
      conflicts,
      excludeScheduleId: excludeScheduleId,
    );
    await _appendMaxLoadConflict(
      session,
      schedule,
      conflicts,
      excludeScheduleId: excludeScheduleId,
    );
    await _appendFacultyAvailabilityConflict(
      session,
      schedule,
      conflicts,
    );
    await _appendSectionAvailabilityConflict(
      session,
      schedule,
      conflicts,
    );
    if (subject != null) {
      await _appendTimeslotDurationConflicts(
        session,
        schedule,
        subject,
        conflicts,
      );
    }

    return conflicts;
  }

  Future<_ConflictContext> _buildConflictContext(Session session) async =>
      _buildConflictContextImpl(session);

  Future<_ConflictContext> _buildConflictContextImpl(Session session) async {
    final schedules = await Schedule.db.find(session);
    final subjects = await Subject.db.find(session);
    final rooms = await Room.db.find(session);
    final faculty = await Faculty.db.find(session);
    final timeslots = await Timeslot.db.find(session);

    final subjectMap = <int, Subject>{
      for (final s in subjects)
        if (s.id != null) s.id!: s,
    };
    final roomMap = <int, Room>{
      for (final r in rooms)
        if (r.id != null) r.id!: r,
    };
    final facultyMap = <int, Faculty>{
      for (final f in faculty)
        if (f.id != null) f.id!: f,
    };
    final timeslotMap = <int, Timeslot>{
      for (final t in timeslots)
        if (t.id != null) t.id!: t,
    };

    final scheduleSlots = <_ScheduleSlot>[];
    for (final s in schedules) {
      final tid = s.timeslotId;
      if (tid == null) continue;
      final ts = timeslotMap[tid];
      if (ts == null) continue;
      scheduleSlots.add(_ScheduleSlot(schedule: s, timeslot: ts));
    }

    return _ConflictContext(
      schedules: schedules,
      subjectMap: subjectMap,
      roomMap: roomMap,
      facultyMap: facultyMap,
      timeslotMap: timeslotMap,
      scheduleSlots: scheduleSlots,
    );
  }

  void _addRoomOverlapConflicts(
    _ConflictContext context,
    List<ScheduleConflict> conflicts,
  ) {
    final byRoom = <int, List<_ScheduleSlot>>{};
    for (final slot in context.scheduleSlots) {
      final rid = slot.schedule.roomId;
      if (rid != null) {
        byRoom.putIfAbsent(rid, () => []).add(slot);
      }
    }

    byRoom.forEach((roomId, roomSchedules) {
      final room = context.roomMap[roomId];
      _addOverlapConflicts(
        conflicts: conflicts,
        slots: roomSchedules,
        config: _OverlapConflictConfig(
          type: 'room_conflict',
          resourceLabel: room?.name ?? 'Room $roomId',
          buildMessage: (a, b, slotLabel) =>
              '${room?.name ?? 'Room $roomId'} already booked at $slotLabel',
          buildDetails: (a, b) {
            final subjA =
                context.subjectMap[a.subjectId]?.code ??
                'Subject ${a.subjectId}';
            final subjB =
                context.subjectMap[b.subjectId]?.code ??
                'Subject ${b.subjectId}';
            final facA =
                context.facultyMap[a.facultyId]?.name ??
                'Faculty ${a.facultyId}';
            final facB =
                context.facultyMap[b.facultyId]?.name ??
                'Faculty ${b.facultyId}';
            return 'Conflicts: $subjA / $facA / ${a.section} <> $subjB / $facB / ${b.section}';
          },
          roomId: roomId,
        ),
      );
    });
  }

  void _addFacultyOverlapConflicts(
    _ConflictContext context,
    List<ScheduleConflict> conflicts,
  ) {
    final byFaculty = <int, List<_ScheduleSlot>>{};
    for (final slot in context.scheduleSlots) {
      byFaculty.putIfAbsent(slot.schedule.facultyId, () => []).add(slot);
    }
    byFaculty.forEach((facultyId, facSchedules) {
      final faculty = context.facultyMap[facultyId];
      _addOverlapConflicts(
        conflicts: conflicts,
        slots: facSchedules,
        config: _OverlapConflictConfig(
          type: 'faculty_conflict',
          resourceLabel: faculty?.name ?? 'Faculty $facultyId',
          buildMessage: (a, b, slotLabel) =>
              '${faculty?.name ?? 'Faculty $facultyId'} has overlapping classes at $slotLabel',
          buildDetails: (a, b) {
            final subjA =
                context.subjectMap[a.subjectId]?.code ??
                'Subject ${a.subjectId}';
            final subjB =
                context.subjectMap[b.subjectId]?.code ??
                'Subject ${b.subjectId}';
            return 'Subjects: $subjA, $subjB (Schedule IDs: ${a.id}, ${b.id})';
          },
          facultyId: facultyId,
        ),
      );
    });
  }

  void _addSectionOverlapConflicts(
    _ConflictContext context,
    List<ScheduleConflict> conflicts,
  ) {
    final bySection = <String, List<_ScheduleSlot>>{};
    for (final slot in context.scheduleSlots) {
      if (slot.schedule.section.isNotEmpty) {
        final key = slot.schedule.sectionId != null
            ? 'id:${slot.schedule.sectionId}'
            : 'code:${slot.schedule.section}';
        bySection.putIfAbsent(key, () => []).add(slot);
      }
    }
    bySection.forEach((sectionKey, secSchedules) {
      final sectionLabel = secSchedules.first.schedule.section;
      _addOverlapConflicts(
        conflicts: conflicts,
        slots: secSchedules,
        config: _OverlapConflictConfig(
          type: 'section_conflict',
          resourceLabel: 'Section $sectionLabel',
          buildMessage: (a, b, slotLabel) =>
              'Section $sectionLabel double-booked at $slotLabel',
          buildDetails: (a, b) {
            final subjA =
                context.subjectMap[a.subjectId]?.code ??
                'Subject ${a.subjectId}';
            final subjB =
                context.subjectMap[b.subjectId]?.code ??
                'Subject ${b.subjectId}';
            return 'Subjects: $subjA, $subjB (Schedule IDs: ${a.id}, ${b.id})';
          },
        ),
      );
    });
  }

  void _addRoomSubjectConflicts(
    _ConflictContext context,
    List<ScheduleConflict> conflicts,
  ) {
    for (final s in context.schedules) {
      final subject = context.subjectMap[s.subjectId];
      final room = s.roomId != null ? context.roomMap[s.roomId!] : null;
      if (subject == null || room == null) continue;

      if (subject.program != room.program &&
          room.program != Program.both &&
          room.type != RoomType.lecture) {
        conflicts.add(
          ScheduleConflict(
            type: 'program_mismatch',
            message:
                '${subject.name} (${subject.program.name.toUpperCase()}) assigned to ${room.name} (${room.program.name.toUpperCase()})',
            scheduleId: s.id,
            subjectId: s.subjectId,
            roomId: s.roomId,
            facultyId: s.facultyId,
            details: 'Subject and Room programs do not match',
          ),
        );
      }

      if (room.capacity < subject.studentsCount) {
        conflicts.add(
          ScheduleConflict(
            type: 'capacity_exceeded',
            message:
                '${room.name} (capacity ${room.capacity}) too small for ${subject.name} (${subject.studentsCount} students)',
            scheduleId: s.id,
            subjectId: s.subjectId,
            roomId: s.roomId,
            details:
                'Room capacity: ${room.capacity}, Required: ${subject.studentsCount}',
          ),
        );
      }

      final roomTypeConflict = _buildRoomTypeConflict(
        schedule: s,
        subject: subject,
        room: room,
      );
      if (roomTypeConflict != null) {
        conflicts.add(roomTypeConflict);
      }
    }
  }

  void _addFacultyMaxLoadConflicts(
    _ConflictContext context,
    List<ScheduleConflict> conflicts,
  ) {
    final facultyUnits = <int, double>{};
    for (final s in context.schedules) {
      final subject = context.subjectMap[s.subjectId];
      final units = subject?.units.toDouble() ?? (s.units ?? 0);
      facultyUnits[s.facultyId] = (facultyUnits[s.facultyId] ?? 0) + units;
    }

    facultyUnits.forEach((facultyId, totalUnits) {
      final faculty = context.facultyMap[facultyId];
      if (faculty != null && totalUnits > (faculty.maxLoad ?? 0)) {
        conflicts.add(
          ScheduleConflict(
            type: 'max_load_exceeded',
            message:
                '${faculty.name} has ${totalUnits.toStringAsFixed(1)} units (max: ${faculty.maxLoad})',
            facultyId: facultyId,
            details:
                'Total assigned: ${totalUnits.toStringAsFixed(1)}, Max load: ${faculty.maxLoad}',
          ),
        );
      }
    });
  }

  void _addRoomInactiveConflicts(
    _ConflictContext context,
    List<ScheduleConflict> conflicts,
  ) {
    for (final s in context.schedules) {
      if (s.roomId == null) continue;
      final room = context.roomMap[s.roomId!];
      if (room != null && !room.isActive) {
        conflicts.add(
          ScheduleConflict(
            type: 'room_inactive',
            message: '${room.name} is inactive but assigned to a schedule',
            scheduleId: s.id,
            roomId: s.roomId,
            facultyId: s.facultyId,
            subjectId: s.subjectId,
            details:
                'Room "${room.name}" must be set to active before being used in scheduling',
          ),
        );
      }
    }
  }

  Future<void> _addFacultyAvailabilityConflicts(
    Session session,
    _ConflictContext context,
    List<ScheduleConflict> conflicts,
  ) async {
    final allAvailabilities = await FacultyAvailability.db.find(session);
    final availByFaculty = <int, List<FacultyAvailability>>{};
    for (final a in allAvailabilities) {
      availByFaculty.putIfAbsent(a.facultyId, () => []).add(a);
    }

    for (final s in context.schedules) {
      if (s.timeslotId == null) continue;
      final avails = availByFaculty[s.facultyId];
      if (avails == null || avails.isEmpty) continue;

      final ts = context.timeslotMap[s.timeslotId!];
      if (ts == null) continue;

      final tsStart = _parseTimeToMinutes(ts.startTime);
      final tsEnd = _parseTimeToMinutes(ts.endTime);
      final tsDay = ts.day;

      final covered = avails.any((a) {
        if (a.dayOfWeek != tsDay) return false;
        final aStart = _parseTimeToMinutes(a.startTime);
        final aEnd = _parseTimeToMinutes(a.endTime);
        return tsStart >= aStart && tsEnd <= aEnd;
      });

      if (!covered) {
        final faculty = context.facultyMap[s.facultyId];
        conflicts.add(
          ScheduleConflict(
            type: 'faculty_unavailable',
            message:
                '${faculty?.name ?? 'Faculty ${s.facultyId}'} scheduled outside preferred hours',
            scheduleId: s.id,
            facultyId: s.facultyId,
            subjectId: s.subjectId,
            details:
                'Timeslot ${ts.startTime}â€“${ts.endTime} on ${ts.day.name} is outside faculty availability',
          ),
        );
      }
    }
  }

  Future<void> _addSectionAvailabilityConflicts(
    Session session,
    _ConflictContext context,
    List<ScheduleConflict> conflicts,
  ) async {
    final sections = await Section.db.find(session);
    final sectionById = <int, Section>{
      for (final section in sections)
        if (section.id != null) section.id!: section,
    };
    final sectionByNormalizedCode = <String, Section>{
      for (final section in sections)
        section.sectionCode.trim().toLowerCase(): section,
    };

    for (final schedule in context.schedules) {
      if (schedule.timeslotId == null) continue;

      final section = schedule.sectionId != null
          ? sectionById[schedule.sectionId!]
          : sectionByNormalizedCode[schedule.section.trim().toLowerCase()];
      if (section == null) continue;
      final subject = context.subjectMap[schedule.subjectId];
      if (subject != null && _isStudentAvailabilityExemptSubject(subject)) {
        continue;
      }

      final sectionAvailability = _parseSectionAvailability(
        section.availabilityJson,
      );
      if (sectionAvailability.isEmpty) continue;

      final timeslot = context.timeslotMap[schedule.timeslotId!];
      if (timeslot == null) continue;

      if (_timeslotMatchesSectionAvailability(timeslot, sectionAvailability)) {
        continue;
      }

      conflicts.add(
        ScheduleConflict(
          type: 'section_unavailable',
          message:
              'Section ${section.sectionCode} is scheduled outside its availability',
          scheduleId: schedule.id,
          facultyId: schedule.facultyId,
          roomId: schedule.roomId,
          subjectId: schedule.subjectId,
          details:
              'Timeslot ${timeslot.startTime}-${timeslot.endTime} on ${timeslot.day.name} is outside section availability.',
        ),
      );
    }
  }

  void _addContinuousBlockConflicts(
    _ConflictContext context,
    List<ScheduleConflict> conflicts,
  ) => _addContinuousBlockConflictsImpl(context, conflicts);

  void _addContinuousBlockConflictsImpl(
    _ConflictContext context,
    List<ScheduleConflict> conflicts,
  ) {
    for (final s in context.schedules) {
      if (s.timeslotId == null) continue;
      final subject = context.subjectMap[s.subjectId];
      if (subject == null) continue;
      final requiredHours =
          s.hours ?? subject.hours ?? subject.units.toDouble();
      if (requiredHours <= 0) continue;
      final ts = context.timeslotMap[s.timeslotId!];
      if (ts == null) continue;

      final tsMinutes =
          _parseTimeToMinutes(ts.endTime) - _parseTimeToMinutes(ts.startTime);
      final tsHours = tsMinutes / 60.0;
      if (tsHours + 1e-6 < requiredHours) {
        final faculty = context.facultyMap[s.facultyId];
        conflicts.add(
          ScheduleConflict(
            type: 'insufficient_block',
            message:
                '${subject.name} requires ${requiredHours.toStringAsFixed(1)}h but timeslot provides ${tsHours.toStringAsFixed(1)}h (${ts.day.name} ${ts.startTime}-${ts.endTime})',
            scheduleId: s.id,
            facultyId: s.facultyId,
            subjectId: s.subjectId,
            roomId: s.roomId,
            details:
                'Continuous block required. Faculty: ${faculty?.name ?? s.facultyId}, Section: ${s.section}, Room: ${context.roomMap[s.roomId ?? -1]?.name ?? 'N/A'}',
          ),
        );
      }

      final room = s.roomId != null ? context.roomMap[s.roomId!] : null;
      if (_isLabSchedule(subject, s, room)) {
        final startMinutes = _parseTimeToMinutes(ts.startTime);
        if (startMinutes < _labEarliestStartMinutes) {
          conflicts.add(
            ScheduleConflict(
              type: 'lab_start_time',
              message: 'Laboratory classes must start at 9:00 AM or later',
              scheduleId: s.id,
              facultyId: s.facultyId,
              subjectId: s.subjectId,
              roomId: s.roomId,
              details: 'Lab starts at ${ts.startTime} on ${ts.day.name}',
            ),
          );
        }
      }
    }
  }

  // ─── Full System Conflict Scan ─────────────────────────────────────

  /// Scans the ENTIRE schedule system for all conflict types.
  /// This is a comprehensive check that detects:
  ///   - Room conflicts (same room, same timeslot)
  ///   - Faculty conflicts (same faculty, same timeslot)
  ///   - Section conflicts (same section, same timeslot)
  ///   - Program mismatches (subject program ≠ room program)
  ///   - Capacity exceeded (room capacity < student count)
  ///   - Faculty max load exceeded
  Future<List<ScheduleConflict>> getAllConflicts(Session session) async {
    final conflicts = <ScheduleConflict>[];
    final context = await _buildConflictContext(session);

    _addRoomOverlapConflicts(context, conflicts);
    _addFacultyOverlapConflicts(context, conflicts);
    _addSectionOverlapConflicts(context, conflicts);
    _addRoomSubjectConflicts(context, conflicts);
    _addFacultyMaxLoadConflicts(context, conflicts);
    _addRoomInactiveConflicts(context, conflicts);
    await _addFacultyAvailabilityConflicts(session, context, conflicts);
    await _addSectionAvailabilityConflicts(session, context, conflicts);
    _addContinuousBlockConflicts(context, conflicts);

    return conflicts;
  }
}

class _ScheduleSlot {
  final Schedule schedule;
  final Timeslot timeslot;

  _ScheduleSlot({required this.schedule, required this.timeslot});
}

class _ConflictContext {
  final List<Schedule> schedules;
  final Map<int, Subject> subjectMap;
  final Map<int, Room> roomMap;
  final Map<int, Faculty> facultyMap;
  final Map<int, Timeslot> timeslotMap;
  final List<_ScheduleSlot> scheduleSlots;

  const _ConflictContext({
    required this.schedules,
    required this.subjectMap,
    required this.roomMap,
    required this.facultyMap,
    required this.timeslotMap,
    required this.scheduleSlots,
  });
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

class _OverlapConflictConfig {
  final String type;
  final String resourceLabel;
  final String Function(Schedule a, Schedule b, String slotLabel) buildMessage;
  final String Function(Schedule a, Schedule b) buildDetails;
  final int? roomId;
  final int? facultyId;

  const _OverlapConflictConfig({
    required this.type,
    required this.resourceLabel,
    required this.buildMessage,
    required this.buildDetails,
    this.roomId,
    this.facultyId,
  });
}

extension _OverlapHelpers on ConflictService {
  bool _overlapsSlot(_ScheduleSlot a, _ScheduleSlot b) {
    if (a.timeslot.day != b.timeslot.day) return false;
    final aStart = _parseTimeToMinutes(a.timeslot.startTime);
    final aEnd = _parseTimeToMinutes(a.timeslot.endTime);
    final bStart = _parseTimeToMinutes(b.timeslot.startTime);
    final bEnd = _parseTimeToMinutes(b.timeslot.endTime);
    return aStart < bEnd && bStart < aEnd;
  }

  String _slotLabel(Timeslot ts) {
    return '${ts.day.name} ${ts.startTime}-${ts.endTime}';
  }

  void _addOverlapConflicts({
    required List<ScheduleConflict> conflicts,
    required List<_ScheduleSlot> slots,
    required _OverlapConflictConfig config,
  }) {
    if (slots.length < 2) return;
    for (var i = 0; i < slots.length; i++) {
      for (var j = i + 1; j < slots.length; j++) {
        final a = slots[i];
        final b = slots[j];
        if (!_overlapsSlot(a, b)) continue;
        final label = _slotLabel(a.timeslot);
        conflicts.add(
          ScheduleConflict(
            type: config.type,
            message: config.buildMessage(a.schedule, b.schedule, label),
            roomId: config.roomId,
            facultyId: config.facultyId,
            details: config.buildDetails(a.schedule, b.schedule),
          ),
        );
      }
    }
  }
}
