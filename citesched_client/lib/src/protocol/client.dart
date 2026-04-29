/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import 'dart:async' as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:citesched_client/src/protocol/user_role.dart' as _i5;
import 'package:citesched_client/src/protocol/faculty.dart' as _i6;
import 'package:citesched_client/src/protocol/student.dart' as _i7;
import 'package:citesched_client/src/protocol/room.dart' as _i8;
import 'package:citesched_client/src/protocol/subject.dart' as _i9;
import 'package:citesched_client/src/protocol/timeslot.dart' as _i10;
import 'package:citesched_client/src/protocol/schedule.dart' as _i11;
import 'package:citesched_client/src/protocol/generate_schedule_response.dart'
    as _i12;
import 'package:citesched_client/src/protocol/generate_schedule_request.dart'
    as _i13;
import 'package:citesched_client/src/protocol/dashboard_stats.dart' as _i14;
import 'package:citesched_client/src/protocol/schedule_conflict.dart' as _i15;
import 'package:citesched_client/src/protocol/reports/faculty_load_report.dart'
    as _i16;
import 'package:citesched_client/src/protocol/reports/room_utilization_report.dart'
    as _i17;
import 'package:citesched_client/src/protocol/reports/conflict_summary_report.dart'
    as _i18;
import 'package:citesched_client/src/protocol/reports/schedule_overview_report.dart'
    as _i19;
import 'package:citesched_client/src/protocol/section.dart' as _i20;
import 'package:citesched_client/src/protocol/faculty_availability.dart'
    as _i21;
import 'package:citesched_client/src/protocol/chat_history.dart' as _i22;
import 'package:citesched_client/src/protocol/chat_session_summary.dart'
    as _i23;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i24;
import 'package:citesched_client/src/protocol/schedule_info.dart' as _i25;
import 'package:citesched_client/src/protocol/timetable_filter_request.dart'
    as _i26;
import 'package:citesched_client/src/protocol/timetable_summary.dart' as _i27;
import 'package:citesched_client/src/protocol/greetings/greeting.dart' as _i28;
import 'package:citesched_client/src/protocol/nlp_response.dart' as _i30;
import 'package:citesched_client/src/protocol/ai_chat_session.dart' as _i31;
import 'package:citesched_client/src/protocol/ai_chat_message.dart' as _i32;
import 'package:citesched_client/src/protocol/day_of_week.dart' as _i33;
import 'package:citesched_client/src/protocol/program.dart' as _i34;
import 'protocol.dart' as _i29;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointEmailIdpBase {
  EndpointEmailIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  @override
  _i3.Future<_i2.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  @override
  _i3.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i3.Future<_i2.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i3.Future<String> verifyRegistrationCode({
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i3.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i3.Future<String> verifyPasswordResetCode({
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  @override
  _i3.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [GoogleIdpBaseEndpoint], the Google identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointGoogleIdp extends _i1.EndpointGoogleIdpBase {
  EndpointGoogleIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'googleIdp';

  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String idToken,
    required String? accessToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'googleIdp',
    'login',
    {
      'idToken': idToken,
      'accessToken': accessToken,
    },
  );

  @override
  _i3.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'googleIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i3.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// Admin-only endpoint for managing scheduling data and user roles.
/// Only users with the 'admin' scope can access these methods.
/// {@category Endpoint}
class EndpointAdmin extends _i2.EndpointRef {
  EndpointAdmin(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'admin';

  /// Get aggregated dashboard statistics. ─────────────────────────────────────────────────
  /// Assign or change a user's role (admin, faculty, student).
  _i3.Future<_i5.UserRole> assignRole({
    required String userId,
    required String role,
  }) => caller.callServerEndpoint<_i5.UserRole>(
    'admin',
    'assignRole',
    {
      'userId': userId,
      'role': role,
    },
  );

  /// Get all user roles.
  _i3.Future<List<_i5.UserRole>> getAllUserRoles() =>
      caller.callServerEndpoint<List<_i5.UserRole>>(
        'admin',
        'getAllUserRoles',
        {},
      );

  /// Create a new faculty member with validation.
  _i3.Future<_i6.Faculty> createFaculty(_i6.Faculty faculty) =>
      caller.callServerEndpoint<_i6.Faculty>(
        'admin',
        'createFaculty',
        {'faculty': faculty},
      );

  /// Get all faculty members.
  _i3.Future<List<_i6.Faculty>> getAllFaculty({required bool isActive}) =>
      caller.callServerEndpoint<List<_i6.Faculty>>(
        'admin',
        'getAllFaculty',
        {'isActive': isActive},
      );

  /// Update a faculty member with validation.
  _i3.Future<_i6.Faculty> updateFaculty(_i6.Faculty faculty) =>
      caller.callServerEndpoint<_i6.Faculty>(
        'admin',
        'updateFaculty',
        {'faculty': faculty},
      );

  /// Delete a faculty member by ID.
  /// Checks for active schedules before deletion and cleans up related records.
  _i3.Future<bool> deleteFaculty(int id) => caller.callServerEndpoint<bool>(
    'admin',
    'deleteFaculty',
    {'id': id},
  );

  /// Create a new student with validation.
  _i3.Future<_i7.Student> createStudent(_i7.Student student) =>
      caller.callServerEndpoint<_i7.Student>(
        'admin',
        'createStudent',
        {'student': student},
      );

  /// Get all students.
  _i3.Future<List<_i7.Student>> getAllStudents({required bool isActive}) =>
      caller.callServerEndpoint<List<_i7.Student>>(
        'admin',
        'getAllStudents',
        {'isActive': isActive},
      );

  /// Update a student with validation and section synchronization.
  _i3.Future<_i7.Student> updateStudent(_i7.Student student) =>
      caller.callServerEndpoint<_i7.Student>(
        'admin',
        'updateStudent',
        {'student': student},
      );

  /// Get all unique section codes currently assigned to students.
  _i3.Future<List<String>> getDistinctStudentSections() =>
      caller.callServerEndpoint<List<String>>(
        'admin',
        'getDistinctStudentSections',
        {},
      );

  /// Delete a student by ID.
  _i3.Future<bool> deleteStudent(int id) => caller.callServerEndpoint<bool>(
    'admin',
    'deleteStudent',
    {'id': id},
  );

  /// Create a new room with validation.
  _i3.Future<_i8.Room> createRoom(_i8.Room room) =>
      caller.callServerEndpoint<_i8.Room>(
        'admin',
        'createRoom',
        {'room': room},
      );

  /// Get all rooms.
  _i3.Future<List<_i8.Room>> getAllRooms({required bool isActive}) =>
      caller.callServerEndpoint<List<_i8.Room>>(
        'admin',
        'getAllRooms',
        {'isActive': isActive},
      );

  /// Update a room with validation.
  _i3.Future<_i8.Room> updateRoom(_i8.Room room) =>
      caller.callServerEndpoint<_i8.Room>(
        'admin',
        'updateRoom',
        {'room': room},
      );

  /// Delete a room by ID.
  /// Checks for active schedules before deletion.
  _i3.Future<bool> deleteRoom(int id) => caller.callServerEndpoint<bool>(
    'admin',
    'deleteRoom',
    {'id': id},
  );

  /// Create a new subject with validation.
  _i3.Future<_i9.Subject> createSubject(_i9.Subject subject) =>
      caller.callServerEndpoint<_i9.Subject>(
        'admin',
        'createSubject',
        {'subject': subject},
      );

  /// Get all subjects.
  _i3.Future<List<_i9.Subject>> getAllSubjects({required bool isActive}) =>
      caller.callServerEndpoint<List<_i9.Subject>>(
        'admin',
        'getAllSubjects',
        {'isActive': isActive},
      );

  /// Update a subject with validation.
  _i3.Future<_i9.Subject> updateSubject(_i9.Subject subject) =>
      caller.callServerEndpoint<_i9.Subject>(
        'admin',
        'updateSubject',
        {'subject': subject},
      );

  /// Delete a subject by ID.
  /// Checks for active schedules before deletion.
  _i3.Future<bool> deleteSubject(int id) => caller.callServerEndpoint<bool>(
    'admin',
    'deleteSubject',
    {'id': id},
  );

  /// Create a new timeslot with validation.
  _i3.Future<_i10.Timeslot> createTimeslot(_i10.Timeslot timeslot) =>
      caller.callServerEndpoint<_i10.Timeslot>(
        'admin',
        'createTimeslot',
        {'timeslot': timeslot},
      );

  /// Get all timeslots.
  _i3.Future<List<_i10.Timeslot>> getAllTimeslots() =>
      caller.callServerEndpoint<List<_i10.Timeslot>>(
        'admin',
        'getAllTimeslots',
        {},
      );

  /// Update a timeslot with validation.
  _i3.Future<_i10.Timeslot> updateTimeslot(_i10.Timeslot timeslot) =>
      caller.callServerEndpoint<_i10.Timeslot>(
        'admin',
        'updateTimeslot',
        {'timeslot': timeslot},
      );

  /// Delete a timeslot by ID.
  /// Checks for active schedules before deletion.
  _i3.Future<bool> deleteTimeslot(int id) => caller.callServerEndpoint<bool>(
    'admin',
    'deleteTimeslot',
    {'id': id},
  );

  /// Create a new schedule entry with conflict detection.
  _i3.Future<_i11.Schedule> createSchedule(_i11.Schedule schedule) =>
      caller.callServerEndpoint<_i11.Schedule>(
        'admin',
        'createSchedule',
        {'schedule': schedule},
      );

  _i3.Future<String> testMaxLoadValidation(
    int facultyId,
    double units,
  ) => caller.callServerEndpoint<String>(
    'admin',
    'testMaxLoadValidation',
    {
      'facultyId': facultyId,
      'units': units,
    },
  );

  /// Get all schedule entries.
  _i3.Future<List<_i11.Schedule>> getAllSchedules({bool? isActive}) =>
      caller.callServerEndpoint<List<_i11.Schedule>>(
        'admin',
        'getAllSchedules',
        {'isActive': isActive},
      );

  /// Get schedule for a specific faculty with includes.
  _i3.Future<List<_i11.Schedule>> getFacultySchedule(
    int facultyId, {
    bool? isActive,
  }) => caller.callServerEndpoint<List<_i11.Schedule>>(
    'admin',
    'getFacultySchedule',
    {
      'facultyId': facultyId,
      'isActive': isActive,
    },
  );

  /// Get schedule for a specific subject with includes.
  _i3.Future<List<_i11.Schedule>> getSubjectSchedule(
    int subjectId, {
    bool? isActive,
  }) => caller.callServerEndpoint<List<_i11.Schedule>>(
    'admin',
    'getSubjectSchedule',
    {
      'subjectId': subjectId,
      'isActive': isActive,
    },
  );

  /// Get schedule for a specific room with includes.
  _i3.Future<List<_i11.Schedule>> getRoomSchedule(
    int roomId, {
    bool? isActive,
  }) => caller.callServerEndpoint<List<_i11.Schedule>>(
    'admin',
    'getRoomSchedule',
    {
      'roomId': roomId,
      'isActive': isActive,
    },
  );

  /// Update a schedule entry with conflict detection.
  _i3.Future<_i11.Schedule> updateSchedule(_i11.Schedule schedule) =>
      caller.callServerEndpoint<_i11.Schedule>(
        'admin',
        'updateSchedule',
        {'schedule': schedule},
      );

  /// Delete a schedule entry by ID.
  _i3.Future<bool> deleteSchedule(int id) => caller.callServerEndpoint<bool>(
    'admin',
    'deleteSchedule',
    {'id': id},
  );

  /// Generate schedules using the scheduling service.
  _i3.Future<_i12.GenerateScheduleResponse> generateSchedule(
    _i13.GenerateScheduleRequest request,
  ) => caller.callServerEndpoint<_i12.GenerateScheduleResponse>(
    'admin',
    'generateSchedule',
    {'request': request},
  );

  /// Get aggregated dashboard statistics.
  _i3.Future<_i14.DashboardStats> getDashboardStats() =>
      caller.callServerEndpoint<_i14.DashboardStats>(
        'admin',
        'getDashboardStats',
        {},
      );

  _i3.Future<List<_i15.ScheduleConflict>> validateSchedule(
    _i11.Schedule schedule,
  ) => caller.callServerEndpoint<List<_i15.ScheduleConflict>>(
    'admin',
    'validateSchedule',
    {'schedule': schedule},
  );

  /// Retrieves all detected conflicts in the current schedule.
  _i3.Future<List<_i15.ScheduleConflict>> getAllConflicts() =>
      caller.callServerEndpoint<List<_i15.ScheduleConflict>>(
        'admin',
        'getAllConflicts',
        {},
      );

  /// Generates the Faculty Load Report.
  _i3.Future<List<_i16.FacultyLoadReport>> getFacultyLoadReport() =>
      caller.callServerEndpoint<List<_i16.FacultyLoadReport>>(
        'admin',
        'getFacultyLoadReport',
        {},
      );

  /// Generates the Room Utilization Report.
  _i3.Future<List<_i17.RoomUtilizationReport>> getRoomUtilizationReport() =>
      caller.callServerEndpoint<List<_i17.RoomUtilizationReport>>(
        'admin',
        'getRoomUtilizationReport',
        {},
      );

  /// Generates the Conflict Summary Report.
  _i3.Future<_i18.ConflictSummaryReport> getConflictSummaryReport() =>
      caller.callServerEndpoint<_i18.ConflictSummaryReport>(
        'admin',
        'getConflictSummaryReport',
        {},
      );

  /// Generates the Schedule Overview Report.
  _i3.Future<_i19.ScheduleOverviewReport> getScheduleOverviewReport() =>
      caller.callServerEndpoint<_i19.ScheduleOverviewReport>(
        'admin',
        'getScheduleOverviewReport',
        {},
      );

  /// Create a new section with validation.
  _i3.Future<_i20.Section> createSection(_i20.Section section) =>
      caller.callServerEndpoint<_i20.Section>(
        'admin',
        'createSection',
        {'section': section},
      );

  /// Get all sections.
  _i3.Future<List<_i20.Section>> getAllSections() =>
      caller.callServerEndpoint<List<_i20.Section>>(
        'admin',
        'getAllSections',
        {},
      );

  /// Update a section.
  _i3.Future<_i20.Section> updateSection(_i20.Section section) =>
      caller.callServerEndpoint<_i20.Section>(
        'admin',
        'updateSection',
        {'section': section},
      );

  /// Delete a section by ID.
  _i3.Future<bool> deleteSection(int id) => caller.callServerEndpoint<bool>(
    'admin',
    'deleteSection',
    {'id': id},
  );

  /// Set faculty availability (creates or replaces entries for a faculty).
  _i3.Future<List<_i21.FacultyAvailability>> setFacultyAvailability(
    int facultyId,
    List<_i21.FacultyAvailability> availabilities,
  ) => caller.callServerEndpoint<List<_i21.FacultyAvailability>>(
    'admin',
    'setFacultyAvailability',
    {
      'facultyId': facultyId,
      'availabilities': availabilities,
    },
  );

  _i3.Future<List<_i21.FacultyAvailability>> setFacultyAvailabilityImpl(
    int facultyId,
    List<_i21.FacultyAvailability> availabilities,
  ) => caller.callServerEndpoint<List<_i21.FacultyAvailability>>(
    'admin',
    'setFacultyAvailabilityImpl',
    {
      'facultyId': facultyId,
      'availabilities': availabilities,
    },
  );

  /// Get all availability entries for a specific faculty.
  _i3.Future<List<_i21.FacultyAvailability>> getFacultyAvailability(
    int facultyId,
  ) => caller.callServerEndpoint<List<_i21.FacultyAvailability>>(
    'admin',
    'getFacultyAvailability',
    {'facultyId': facultyId},
  );

  /// Get all faculty availabilities.
  _i3.Future<List<_i21.FacultyAvailability>> getAllFacultyAvailabilities() =>
      caller.callServerEndpoint<List<_i21.FacultyAvailability>>(
        'admin',
        'getAllFacultyAvailabilities',
        {},
      );

  /// Delete a single faculty availability entry.
  _i3.Future<bool> deleteFacultyAvailability(int id) =>
      caller.callServerEndpoint<bool>(
        'admin',
        'deleteFacultyAvailability',
        {'id': id},
      );

  /// Pre-check readiness for schedule generation.
  /// Returns a map with readiness status and any missing items.
  _i3.Future<_i12.GenerateScheduleResponse> precheckSchedule() =>
      caller.callServerEndpoint<_i12.GenerateScheduleResponse>(
        'admin',
        'precheckSchedule',
        {},
      );

  /// Regenerate all schedules using the AI scheduling engine.
  /// Clears existing schedules, then generates new ones respecting all constraints.
  _i3.Future<_i12.GenerateScheduleResponse> regenerateSchedule() =>
      caller.callServerEndpoint<_i12.GenerateScheduleResponse>(
        'admin',
        'regenerateSchedule',
        {},
      );
}

/// {@category Endpoint}
class EndpointChatHistory extends _i2.EndpointRef {
  EndpointChatHistory(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'chatHistory';

  _i3.Future<List<_i22.ChatHistory>> getMyHistory({
    String? role,
    required int limit,
  }) => caller.callServerEndpoint<List<_i22.ChatHistory>>(
    'chatHistory',
    'getMyHistory',
    {
      'role': role,
      'limit': limit,
    },
  );

  _i3.Future<List<_i23.ChatSessionSummary>> getMySessions({
    String? role,
    required int limit,
  }) => caller.callServerEndpoint<List<_i23.ChatSessionSummary>>(
    'chatHistory',
    'getMySessions',
    {
      'role': role,
      'limit': limit,
    },
  );

  _i3.Future<List<_i22.ChatHistory>> getSessionHistory({
    required String sessionId,
    String? role,
    required int limit,
  }) => caller.callServerEndpoint<List<_i22.ChatHistory>>(
    'chatHistory',
    'getSessionHistory',
    {
      'sessionId': sessionId,
      'role': role,
      'limit': limit,
    },
  );

  _i3.Future<bool> deleteSession({
    required String sessionId,
    String? role,
  }) => caller.callServerEndpoint<bool>(
    'chatHistory',
    'deleteSession',
    {
      'sessionId': sessionId,
      'role': role,
    },
  );
}

/// {@category Endpoint}
class EndpointCustomAuth extends _i2.EndpointRef {
  EndpointCustomAuth(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'customAuth';

  /// Logs in a user using their ID (Student ID or Faculty ID) and password.
  _i3.Future<_i24.AuthenticationResponse> loginWithId({
    required String id,
    required String password,
    required String role,
  }) => caller.callServerEndpoint<_i24.AuthenticationResponse>(
    'customAuth',
    'loginWithId',
    {
      'id': id,
      'password': password,
      'role': role,
    },
  );
}

/// {@category Endpoint}
class EndpointDebug extends _i2.EndpointRef {
  EndpointDebug(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'debug';

  _i3.Future<String> getSessionInfo() => caller.callServerEndpoint<String>(
    'debug',
    'getSessionInfo',
    {},
  );
}

/// {@category Endpoint}
class EndpointFaculty extends _i2.EndpointRef {
  EndpointFaculty(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'faculty';

  /// Fetches the schedule for the logged-in faculty.
  _i3.Future<List<_i11.Schedule>> getMySchedule() =>
      caller.callServerEndpoint<List<_i11.Schedule>>(
        'faculty',
        'getMySchedule',
        {},
      );

  /// Get personal profile
  _i3.Future<_i6.Faculty?> getMyProfile() =>
      caller.callServerEndpoint<_i6.Faculty?>(
        'faculty',
        'getMyProfile',
        {},
      );
}

/// {@category Endpoint}
class EndpointNLP extends _i2.EndpointRef {
  EndpointNLP(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'nLP';

  _i3.Future<_i30.NLPResponse> query(
    String text, {
    String? sessionId,
    String? sessionTitle,
  }) => caller.callServerEndpoint<_i30.NLPResponse>(
    'nLP',
    'query',
    {
      'text': text,
      'sessionId': sessionId,
      'sessionTitle': sessionTitle,
    },
  );

  _i3.Future<List<_i11.Schedule>> getFacultyLoad({required int facultyId}) =>
      caller.callServerEndpoint<List<_i11.Schedule>>(
        'nLP',
        'getFacultyLoad',
        {'facultyId': facultyId},
      );

  _i3.Future<List<_i11.Schedule>> getStudentSchedule({
    required int studentId,
  }) => caller.callServerEndpoint<List<_i11.Schedule>>(
    'nLP',
    'getStudentSchedule',
    {'studentId': studentId},
  );

  _i3.Future<List<_i11.Schedule>> getSectionSchedule({
    required int sectionId,
  }) => caller.callServerEndpoint<List<_i11.Schedule>>(
    'nLP',
    'getSectionSchedule',
    {'sectionId': sectionId},
  );

  _i3.Future<List<_i11.Schedule>> getRoomAvailability({
    required int roomId,
    required _i33.DayOfWeek day,
  }) => caller.callServerEndpoint<List<_i11.Schedule>>(
    'nLP',
    'getRoomAvailability',
    {
      'roomId': roomId,
      'day': day,
    },
  );

  _i3.Future<List<_i9.Subject>> getSubjectCatalog({
    required _i34.Program program,
    int? yearLevel,
  }) => caller.callServerEndpoint<List<_i9.Subject>>(
    'nLP',
    'getSubjectCatalog',
    {
      'program': program,
      'yearLevel': yearLevel,
    },
  );

  _i3.Future<List<_i15.ScheduleConflict>> getScheduleConflicts() =>
      caller.callServerEndpoint<List<_i15.ScheduleConflict>>(
        'nLP',
        'getScheduleConflicts',
        {},
      );

  _i3.Future<List<String>> generateScheduleSuggestions() =>
      caller.callServerEndpoint<List<String>>(
        'nLP',
        'generateScheduleSuggestions',
        {},
      );

  _i3.Future<List<_i11.Schedule>> searchSchedules({required String query}) =>
      caller.callServerEndpoint<List<_i11.Schedule>>(
        'nLP',
        'searchSchedules',
        {'query': query},
      );

  _i3.Future<_i31.AiChatSession> createChatSession({
    String? userId,
    String? role,
    String? title,
  }) => caller.callServerEndpoint<_i31.AiChatSession>(
    'nLP',
    'createChatSession',
    {
      'userId': userId,
      'role': role,
      'title': title,
    },
  );

  _i3.Future<List<_i23.ChatSessionSummary>> getChatHistory({
    String? userId,
    String? role,
    int limit = 30,
  }) => caller.callServerEndpoint<List<_i23.ChatSessionSummary>>(
    'nLP',
    'getChatHistory',
    {
      'userId': userId,
      'role': role,
      'limit': limit,
    },
  );

  _i3.Future<List<_i32.AiChatMessage>> getChatMessages({
    required String sessionId,
    String? role,
    int limit = 200,
  }) => caller.callServerEndpoint<List<_i32.AiChatMessage>>(
    'nLP',
    'getChatMessages',
    {
      'sessionId': sessionId,
      'role': role,
      'limit': limit,
    },
  );

  _i3.Future<_i32.AiChatMessage> saveChatMessage({
    required String sessionId,
    required String sender,
    required String message,
    String? role,
  }) => caller.callServerEndpoint<_i32.AiChatMessage>(
    'nLP',
    'saveChatMessage',
    {
      'sessionId': sessionId,
      'sender': sender,
      'message': message,
      'role': role,
    },
  );

  _i3.Future<bool> deleteChatSession({
    required String sessionId,
    String? role,
  }) => caller.callServerEndpoint<bool>(
    'nLP',
    'deleteChatSession',
    {
      'sessionId': sessionId,
      'role': role,
    },
  );
}

/// {@category Endpoint}
class EndpointSetup extends _i2.EndpointRef {
  EndpointSetup(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'setup';

  _i3.Future<bool> createAccount({
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
  }) => caller.callServerEndpoint<bool>(
    'setup',
    'createAccount',
    {
      'userName': userName,
      'email': email,
      'password': password,
      'role': role,
      'studentId': studentId,
      'facultyId': facultyId,
      'course': course,
      'section': section,
      'maxLoad': maxLoad,
      'employmentStatus': employmentStatus,
      'shiftPreference': shiftPreference,
      'program': program,
    },
  );

  /// Fetches a UserInfo by email (case-insensitive).
  _i3.Future<_i24.UserInfo?> getUserInfoByEmail({required String email}) =>
      caller.callServerEndpoint<_i24.UserInfo?>(
        'setup',
        'getUserInfoByEmail',
        {'email': email},
      );

  _i3.Future<_i7.Student?> getStudentProfileByEmail({required String email}) =>
      caller.callServerEndpoint<_i7.Student?>(
        'setup',
        'getStudentProfileByEmail',
        {'email': email},
      );

  _i3.Future<String?> getExistingAccountRoleByEmail({required String email}) =>
      caller.callServerEndpoint<String?>(
        'setup',
        'getExistingAccountRoleByEmail',
        {'email': email},
      );

  _i3.Future<String?> getExistingAccountRoleByEmailImpl({
    required String email,
  }) => caller.callServerEndpoint<String?>(
    'setup',
    'getExistingAccountRoleByEmailImpl',
    {'email': email},
  );

  _i3.Future<String?> adoptExistingAccountByEmail({required String email}) =>
      caller.callServerEndpoint<String?>(
        'setup',
        'adoptExistingAccountByEmail',
        {'email': email},
      );
}

/// Student endpoint for viewing schedules and managing the logged-in user's
/// linked student profile.
/// {@category Endpoint}
class EndpointStudent extends _i2.EndpointRef {
  EndpointStudent(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'student';

  /// Get all available schedules (read-only for students).
  _i3.Future<List<_i11.Schedule>> getSchedules() =>
      caller.callServerEndpoint<List<_i11.Schedule>>(
        'student',
        'getSchedules',
        {},
      );

  /// Get a specific schedule by ID.
  _i3.Future<_i11.Schedule?> getScheduleById(int id) =>
      caller.callServerEndpoint<_i11.Schedule?>(
        'student',
        'getScheduleById',
        {'id': id},
      );

  /// Get the current student's profile by their auth user ID.
  _i3.Future<_i7.Student?> getMyProfile() =>
      caller.callServerEndpoint<_i7.Student?>(
        'student',
        'getMyProfile',
        {},
      );

  /// Update the current student's profile.
  _i3.Future<_i7.Student?> updateMyProfile(_i7.Student updatedProfile) =>
      caller.callServerEndpoint<_i7.Student?>(
        'student',
        'updateMyProfile',
        {'updatedProfile': updatedProfile},
      );

  /// Get all faculty members (read-only).
  _i3.Future<List<_i6.Faculty>> getFaculty() =>
      caller.callServerEndpoint<List<_i6.Faculty>>(
        'student',
        'getFaculty',
        {},
      );

  /// Get all rooms (read-only).
  _i3.Future<List<_i8.Room>> getRooms() =>
      caller.callServerEndpoint<List<_i8.Room>>(
        'student',
        'getRooms',
        {},
      );

  /// Get all subjects (read-only).
  _i3.Future<List<_i9.Subject>> getSubjects() =>
      caller.callServerEndpoint<List<_i9.Subject>>(
        'student',
        'getSubjects',
        {},
      );

  /// Get all timeslots (read-only).
  _i3.Future<List<_i10.Timeslot>> getTimeslots() =>
      caller.callServerEndpoint<List<_i10.Timeslot>>(
        'student',
        'getTimeslots',
        {},
      );
}

/// {@category Endpoint}
class EndpointStudentSchedule extends _i2.EndpointRef {
  EndpointStudentSchedule(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'studentSchedule';

  /// Fetches the schedule for the logged-in student based on their section.
  _i3.Future<List<_i11.Schedule>> fetchMySchedule() =>
      caller.callServerEndpoint<List<_i11.Schedule>>(
        'studentSchedule',
        'fetchMySchedule',
        {},
      );
}

/// {@category Endpoint}
class EndpointTimetable extends _i2.EndpointRef {
  EndpointTimetable(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'timetable';

  _i3.Future<List<_i25.ScheduleInfo>> getSchedules(
    _i26.TimetableFilterRequest filter,
  ) => caller.callServerEndpoint<List<_i25.ScheduleInfo>>(
    'timetable',
    'getSchedules',
    {'filter': filter},
  );

  _i3.Future<_i27.TimetableSummary> getSummary(
    _i26.TimetableFilterRequest filter,
  ) => caller.callServerEndpoint<_i27.TimetableSummary>(
    'timetable',
    'getSummary',
    {'filter': filter},
  );

  _i3.Future<List<_i25.ScheduleInfo>> getPersonalSchedule() =>
      caller.callServerEndpoint<List<_i25.ScheduleInfo>>(
        'timetable',
        'getPersonalSchedule',
        {},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i2.EndpointRef {
  EndpointGreeting(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i3.Future<_i28.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i28.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    auth = _i24.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i24.Caller auth;

  late final _i4.Caller serverpod_auth_core;
}

class Client extends _i2.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i2.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i2.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i29.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    emailIdp = EndpointEmailIdp(this);
    googleIdp = EndpointGoogleIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    admin = EndpointAdmin(this);
    chatHistory = EndpointChatHistory(this);
    customAuth = EndpointCustomAuth(this);
    debug = EndpointDebug(this);
    faculty = EndpointFaculty(this);
    nLP = EndpointNLP(this);
    setup = EndpointSetup(this);
    student = EndpointStudent(this);
    studentSchedule = EndpointStudentSchedule(this);
    timetable = EndpointTimetable(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointGoogleIdp googleIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAdmin admin;

  late final EndpointChatHistory chatHistory;

  late final EndpointCustomAuth customAuth;

  late final EndpointDebug debug;

  late final EndpointFaculty faculty;

  late final EndpointNLP nLP;

  late final EndpointSetup setup;

  late final EndpointStudent student;

  late final EndpointStudentSchedule studentSchedule;

  late final EndpointTimetable timetable;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'googleIdp': googleIdp,
    'jwtRefresh': jwtRefresh,
    'admin': admin,
    'chatHistory': chatHistory,
    'customAuth': customAuth,
    'debug': debug,
    'faculty': faculty,
    'nLP': nLP,
    'setup': setup,
    'student': student,
    'studentSchedule': studentSchedule,
    'timetable': timetable,
    'greeting': greeting,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'auth': modules.auth,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
