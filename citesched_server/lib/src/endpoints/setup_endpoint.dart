import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/src/generated/providers/google/models/google_account.dart'
    as auth_google;
import '../generated/protocol.dart';

class SetupEndpoint extends Endpoint {
  static const List<String> _allowedCourses = ['BSIT', 'BSEMC'];

  @override
  bool get requireLogin => false;

  String _normalizeSectionCode(String input) {
    final match = RegExp(
      r'^\s*(\d+)\s*([A-Za-z][A-Za-z0-9]*)\s*$',
    ).firstMatch(input);
    if (match == null) return input.trim().toUpperCase();
    final year = match.group(1)!;
    final suffix = match.group(2)!.toUpperCase();
    return '$year$suffix';
  }

  int? _extractYearLevelFromSection(String input) {
    final match = RegExp(
      r'^\s*(\d+)\s*[A-Za-z][A-Za-z0-9]*\s*$',
    ).firstMatch(input);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  Program _programFromCourse(String? course) {
    final normalized = course?.trim().toUpperCase();
    if (normalized == 'BSEMC') return Program.emc;
    return Program.it;
  }

  EmploymentStatus _employmentStatusFromString(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'parttime' || normalized == 'part_time') {
      return EmploymentStatus.partTime;
    }
    return EmploymentStatus.fullTime;
  }

  FacultyShiftPreference _shiftPreferenceFromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'morning':
        return FacultyShiftPreference.morning;
      case 'afternoon':
        return FacultyShiftPreference.afternoon;
      case 'evening':
        return FacultyShiftPreference.evening;
      case 'custom':
        return FacultyShiftPreference.custom;
      default:
        return FacultyShiftPreference.any;
    }
  }

  Program _programFromString(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == 'emc') return Program.emc;
    return Program.it;
  }

  Future<UserInfo?> _ensureUserInfo(
    Session session, {
    required String userName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    UserInfo? userInfo;
    try {
      userInfo = await Emails.createUser(
        session,
        userName,
        normalizedEmail,
        password,
      );
    } catch (e) {
      session.log(
        'Emails.createUser failed for $normalizedEmail, trying existing user lookup: $e',
      );
    }
    if (userInfo != null) return userInfo;

    session.log(
      'User $normalizedEmail might already exist. Trying to reuse it.',
    );
    userInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );
    if (userInfo == null) {
      session.log(
        'Failed to find user $normalizedEmail after createUser did not return a user.',
      );
    }
    return userInfo;
  }

  Future<UserInfo> _ensureLegacyUserInfoForAuthUser(
    Session session, {
    required String authIdentifier,
    required String email,
    required String? fallbackName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final byIdentifier = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.userIdentifier.equals(authIdentifier),
    );
    if (byIdentifier != null) {
      if (byIdentifier.email != normalizedEmail) {
        byIdentifier.email = normalizedEmail;
        await UserInfo.db.updateRow(session, byIdentifier);
      }
      return byIdentifier;
    }

    final byEmail = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );
    if (byEmail != null) {
      if (byEmail.userIdentifier != authIdentifier) {
        byEmail.userIdentifier = authIdentifier;
      }
      if ((byEmail.userName?.trim().isEmpty ?? true) && fallbackName != null) {
        byEmail.userName = fallbackName.trim();
      }
      await UserInfo.db.updateRow(session, byEmail);
      return byEmail;
    }

    final displayName = (fallbackName?.trim().isNotEmpty ?? false)
        ? fallbackName!.trim()
        : normalizedEmail.split('@').first;

    return await UserInfo.db.insertRow(
      session,
      UserInfo(
        userIdentifier: authIdentifier,
        userName: displayName,
        fullName: fallbackName?.trim().isNotEmpty == true
            ? fallbackName!.trim()
            : displayName,
        email: normalizedEmail,
        scopeNames: const [],
        blocked: false,
        created: DateTime.now(),
      ),
    );
  }

  Future<void> _ensureEmailAuth(
    Session session,
    UserInfo userInfo, {
    required String email,
    required String password,
  }) async {
    final emailLower = email.toLowerCase();
    final newHash = await defaultGeneratePasswordHash(password);
    EmailAuth? existingAuth = await EmailAuth.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userInfo.id!),
    );
    existingAuth ??= await EmailAuth.db.findFirstRow(
      session,
      where: (t) => t.email.equals(emailLower),
    );
    if (existingAuth == null) {
      await EmailAuth.db.insertRow(
        session,
        EmailAuth(
          userId: userInfo.id!,
          email: emailLower,
          hash: newHash,
        ),
      );
    } else {
      existingAuth.email = emailLower;
      existingAuth.hash = newHash;
      await EmailAuth.db.updateRow(session, existingAuth);
    }
  }

  Future<void> _syncRoleScope(
    Session session,
    UserInfo userInfo, {
    required String role,
  }) async {
    final currentScopes = userInfo.scopeNames.toSet();
    if (currentScopes.contains(role)) return;
    currentScopes.add(role);
    userInfo.scopeNames = currentScopes.toList();
    await UserInfo.db.updateRow(session, userInfo);
  }

  Future<int?> _resolveSectionId(
    Session session, {
    required String section,
    String? course,
  }) async {
    try {
      final existingSection = await Section.db.findFirstRow(
        session,
        where: (t) => t.sectionCode.equals(section),
      );
      if (existingSection != null) return existingSection.id;

      var prog = _programFromCourse(course);
      var year = 1;
      final yearMatch = RegExp(r'\d').firstMatch(section);
      if (yearMatch != null) {
        year = int.parse(yearMatch.group(0)!);
      }

      final newSection = await Section.db.insertRow(
        session,
        Section(
          sectionCode: section,
          program: prog,
          yearLevel: year,
          semester: 1,
          academicYear: '${DateTime.now().year}-${DateTime.now().year + 1}',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return newSection.id;
    } catch (e) {
      session.log('Error syncing section: $e');
      return null;
    }
  }

  Future<void> _ensureStudentProfile(
    Session session,
    UserInfo userInfo, {
    required String userName,
    required String email,
    required String studentId,
    required String course,
    required String? section,
  }) async {
    final existingStudent = await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    final normalizedCourse = _allowedCourses.contains(course.trim().toUpperCase())
        ? course.trim().toUpperCase()
        : 'BSIT';
    final normalizedSection = section == null || section.trim().isEmpty
        ? null
        : _normalizeSectionCode(section);
    final yearLevel = normalizedSection == null
        ? 1
        : (_extractYearLevelFromSection(normalizedSection) ?? 1);

    int? sectionId;
    if (normalizedSection != null && normalizedSection.isNotEmpty) {
      sectionId = await _resolveSectionId(
        session,
        section: normalizedSection,
        course: normalizedCourse,
      );
    }

    if (existingStudent != null) {
      existingStudent
        ..name = userName
        ..email = email
        ..studentNumber = studentId
        ..course = normalizedCourse
        ..yearLevel = yearLevel
        ..section = normalizedSection
        ..sectionId = sectionId
        ..userInfoId = userInfo.id!
        ..academicStatus = StudentAcademicStatus.active
        ..isActive = true
        ..updatedAt = DateTime.now();
      await Student.db.updateRow(session, existingStudent);
      return;
    }

    await Student.db.insertRow(
      session,
      Student(
        name: userName,
        email: email,
        studentNumber: studentId,
        course: normalizedCourse,
        yearLevel: yearLevel,
        section: normalizedSection,
        sectionId: sectionId,
        userInfoId: userInfo.id!,
        academicStatus: StudentAcademicStatus.active,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _ensureFacultyProfile(
    Session session,
    UserInfo userInfo, {
    required String userName,
    required String email,
    required String facultyId,
    required int maxLoad,
    required EmploymentStatus employmentStatus,
    required FacultyShiftPreference shiftPreference,
    required Program program,
    required bool isActive,
  }) async {
    final existingFaculty = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email),
    );
    if (existingFaculty != null) {
      existingFaculty
        ..name = userName
        ..email = email
        ..maxLoad = maxLoad
        ..employmentStatus = employmentStatus
        ..shiftPreference = shiftPreference
        ..facultyId = facultyId
        ..userInfoId = userInfo.id!
        ..program = program
        ..isActive = isActive
        ..updatedAt = DateTime.now();
      await Faculty.db.updateRow(session, existingFaculty);
      return;
    }

    await Faculty.db.insertRow(
      session,
      Faculty(
        name: userName,
        email: email,
        maxLoad: maxLoad,
        employmentStatus: employmentStatus,
        shiftPreference: shiftPreference,
        facultyId: facultyId,
        userInfoId: userInfo.id!,
        program: program,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _ensureUserRole(
    Session session,
    UserInfo userInfo, {
    required String role,
  }) async {
    final userIdStr = userInfo.id!.toString();
    final existingRole = await UserRole.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userIdStr),
    );

    if (existingRole == null) {
      await UserRole.db.insertRow(
        session,
        UserRole(
          userId: userIdStr,
          role: role,
        ),
      );
    } else if (existingRole.role != role) {
      existingRole.role = role;
      await UserRole.db.updateRow(session, existingRole);
    }
  }

  Future<bool> createAccount(
    Session session, {
    required String userName,
    required String email,
    required String password,
    required String role,
    String? studentId,
    String? facultyId,
    String? course,
    String? section,
    int? maxLoad,
    String? employmentStatus,
    String? shiftPreference,
    String? program,
  }) async {
    try {
      final normalizedRole = role.trim().toLowerCase();
      final requestedByAdmin =
          session.authenticated?.scopes.any((scope) => scope.name == 'admin') ??
          false;
      final needsFacultyApproval =
          normalizedRole == 'faculty' && !requestedByAdmin;

      final userInfo = await _ensureUserInfo(
        session,
        userName: userName,
        email: email,
        password: password,
      );
      if (userInfo == null) return false;

      await _ensureEmailAuth(
        session,
        userInfo,
        email: email,
        password: password,
      );

      // Do not grant immediate faculty scope for self-registered faculty.
      if (!needsFacultyApproval) {
        await _syncRoleScope(session, userInfo, role: normalizedRole);
      }

      // Create linked profile based on role
      if (normalizedRole == 'student' && studentId != null) {
        await _ensureStudentProfile(
          session,
          userInfo,
          userName: userName,
          email: email,
          studentId: studentId,
          course: course ?? 'BSIT',
          section: section,
        );
      } else if ((normalizedRole == 'faculty' || normalizedRole == 'admin') &&
          facultyId != null) {
        await _ensureFacultyProfile(
          session,
          userInfo,
          userName: userName,
          email: email,
          facultyId: facultyId,
          maxLoad: maxLoad ?? 18,
          employmentStatus: _employmentStatusFromString(employmentStatus),
          shiftPreference: _shiftPreferenceFromString(shiftPreference),
          program: _programFromString(program),
          isActive: normalizedRole == 'admin' ? true : !needsFacultyApproval,
        );
      }

      // Add UserRole entry to ensure authenticationHandler picks it up
      await _ensureUserRole(
        session,
        userInfo,
        role: needsFacultyApproval ? 'faculty_pending' : normalizedRole,
      );

      session.log(
        'Created user $email with role ${needsFacultyApproval ? "faculty_pending" : normalizedRole} and ID ${studentId ?? facultyId}',
      );
      return true;
    } catch (e) {
      session.log('Error creating user: $e');
      return false;
    }
  }

  /// Fetches a UserInfo by email (case-insensitive).
  Future<UserInfo?> getUserInfoByEmail(
    Session session, {
    required String email,
  }) async {
    final emailLower = email.toLowerCase();
    return await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.email.equals(emailLower),
    );
  }

  Future<Student?> getStudentProfileByEmail(
    Session session, {
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    return await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );
  }

  Future<String?> getExistingAccountRoleByEmail(
    Session session, {
    required String email,
  }) async =>
      getExistingAccountRoleByEmailImpl(
        session,
        email: email,
      );

  Future<String?> getExistingAccountRoleByEmailImpl(
    Session session, {
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    final activeFaculty = await Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail) & t.isActive.equals(true),
    );
    final activeStudent = await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail) & t.isActive.equals(true),
    );

    final userInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );

    if (userInfo != null && userInfo.id != null) {
      final existingUserInfo = userInfo;
      final userRole = await UserRole.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(existingUserInfo.id!.toString()),
      );
      final explicitRole = userRole?.role.trim().toLowerCase();
      if (explicitRole == 'admin') {
        return 'admin';
      }
      if (explicitRole == 'faculty_pending') {
        return 'faculty_pending';
      }
      if (explicitRole == 'faculty_declined') {
        return 'faculty_declined';
      }
      if (explicitRole == 'faculty' && activeFaculty != null) {
        return 'faculty';
      }
      if (explicitRole == 'student' && activeStudent != null) {
        return 'student';
      }
      final scopes = existingUserInfo.scopeNames
          .map((scope) => scope.toLowerCase())
          .toSet();
      if (scopes.contains('admin')) return 'admin';
      if (scopes.contains('faculty') && activeFaculty != null) return 'faculty';
      if (scopes.contains('student') && activeStudent != null) return 'student';
    }

    if (activeFaculty != null) return 'faculty';
    if (activeStudent != null) return 'student';

    return null;
  }

  Future<String?> adoptExistingAccountByEmail(
    Session session, {
    required String email,
  }) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception('Unauthorized');
    }

    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    final authIdentifier = authInfo.userIdentifier.toString();
    auth_core.UserProfile? authCoreProfile;
    auth_google.GoogleAccount? googleAccount;
    try {
      final authUserId = UuidValue.withValidation(authIdentifier);
      authCoreProfile = await auth_core.UserProfile.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(authUserId),
      );
      googleAccount = await auth_google.GoogleAccount.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(authUserId),
      );
    } catch (_) {}

    UserInfo? currentUserInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.userIdentifier.equals(authIdentifier),
    );
    currentUserInfo ??= await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.email.equals(normalizedEmail),
    );
    currentUserInfo ??= await _ensureLegacyUserInfoForAuthUser(
      session,
      authIdentifier: authIdentifier,
      email: authCoreProfile?.email ?? googleAccount?.email ?? normalizedEmail,
      fallbackName: authCoreProfile?.fullName,
    );
    if (currentUserInfo == null) {
      return null;
    }

    final resolvedRole = await getExistingAccountRoleByEmail(
      session,
      email: normalizedEmail,
    );
    if (resolvedRole == null) {
      return null;
    }
    if (resolvedRole == 'faculty_pending' || resolvedRole == 'faculty_declined') {
      return resolvedRole;
    }

    currentUserInfo.email = normalizedEmail;
    await _syncRoleScope(session, currentUserInfo, role: resolvedRole);
    await _ensureUserRole(session, currentUserInfo, role: resolvedRole);

    if (resolvedRole == 'student') {
      final student = await Student.db.findFirstRow(
        session,
        where: (t) => t.email.equals(normalizedEmail),
      );
      if (student != null) {
        student.userInfoId = currentUserInfo.id!;
        student.isActive = true;
        student.updatedAt = DateTime.now();
        await Student.db.updateRow(session, student);
      }
    } else if (resolvedRole == 'faculty' || resolvedRole == 'admin') {
      final faculty = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.email.equals(normalizedEmail),
      );
      if (faculty != null) {
        faculty.userInfoId = currentUserInfo.id!;
        faculty.isActive = true;
        faculty.updatedAt = DateTime.now();
        await Faculty.db.updateRow(session, faculty);
      }
    }

    return resolvedRole;
  }
}
