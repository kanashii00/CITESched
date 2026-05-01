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
import 'package:serverpod/serverpod.dart' as _i1;
import '../auth/email_idp_endpoint.dart' as _i2;
import '../auth/google_idp_endpoint.dart' as _i3;
import '../auth/jwt_refresh_endpoint.dart' as _i4;
import '../endpoints/admin_endpoint.dart' as _i5;
import '../endpoints/chat_history_endpoint.dart' as _i6;
import '../endpoints/custom_auth_endpoint.dart' as _i7;
import '../endpoints/debug_endpoint.dart' as _i8;
import '../endpoints/faculty_endpoint.dart' as _i9;
import '../endpoints/nlp_endpoint.dart' as _i10;
import '../endpoints/setup_endpoint.dart' as _i11;
import '../endpoints/student_endpoint.dart' as _i12;
import '../endpoints/student_schedule_endpoint.dart' as _i13;
import '../endpoints/timetable_endpoint.dart' as _i14;
import '../greetings/greeting_endpoint.dart' as _i15;
import 'package:citesched_server/src/generated/faculty.dart' as _i16;
import 'package:citesched_server/src/generated/student.dart' as _i17;
import 'package:citesched_server/src/generated/room.dart' as _i18;
import 'package:citesched_server/src/generated/subject.dart' as _i19;
import 'package:citesched_server/src/generated/timeslot.dart' as _i20;
import 'package:citesched_server/src/generated/schedule.dart' as _i21;
import 'package:citesched_server/src/generated/generate_schedule_request.dart'
    as _i22;
import 'package:citesched_server/src/generated/section.dart' as _i23;
import 'package:citesched_server/src/generated/faculty_availability.dart'
    as _i24;
import 'package:citesched_server/src/generated/day_of_week.dart' as _i25;
import 'package:citesched_server/src/generated/program.dart' as _i26;
import 'package:citesched_server/src/generated/timetable_filter_request.dart'
    as _i27;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i28;
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as _i29;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i30;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'emailIdp': _i2.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'googleIdp': _i3.GoogleIdpEndpoint()
        ..initialize(
          server,
          'googleIdp',
          null,
        ),
      'jwtRefresh': _i4.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'admin': _i5.AdminEndpoint()
        ..initialize(
          server,
          'admin',
          null,
        ),
      'chatHistory': _i6.ChatHistoryEndpoint()
        ..initialize(
          server,
          'chatHistory',
          null,
        ),
      'customAuth': _i7.CustomAuthEndpoint()
        ..initialize(
          server,
          'customAuth',
          null,
        ),
      'debug': _i8.DebugEndpoint()
        ..initialize(
          server,
          'debug',
          null,
        ),
      'faculty': _i9.FacultyEndpoint()
        ..initialize(
          server,
          'faculty',
          null,
        ),
      'nLP': _i10.NLPEndpoint()
        ..initialize(
          server,
          'nLP',
          null,
        ),
      'setup': _i11.SetupEndpoint()
        ..initialize(
          server,
          'setup',
          null,
        ),
      'student': _i12.StudentEndpoint()
        ..initialize(
          server,
          'student',
          null,
        ),
      'studentSchedule': _i13.StudentScheduleEndpoint()
        ..initialize(
          server,
          'studentSchedule',
          null,
        ),
      'timetable': _i14.TimetableEndpoint()
        ..initialize(
          server,
          'timetable',
          null,
        ),
      'greeting': _i15.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };
    connectors['emailIdp'] = _i1.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'startPasswordReset': _i1.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'finishPasswordReset': _i1.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _i1.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'newPassword': _i1.ParameterDescription(
              name: 'newPassword',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint).login(
                session,
                email: params['email'],
                password: params['password'],
              ),
        ),
        'startRegistration': _i1.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _i1.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _i1.ParameterDescription(
              name: 'accountRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _i1.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _i1.ParameterDescription(
              name: 'registrationToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'verifyPasswordResetCode': _i1.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _i1.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _i1.ParameterDescription(
              name: 'verificationCode',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _i2.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['googleIdp'] = _i1.EndpointConnector(
      name: 'googleIdp',
      endpoint: endpoints['googleIdp']!,
      methodConnectors: {
        'login': _i1.MethodConnector(
          name: 'login',
          params: {
            'idToken': _i1.ParameterDescription(
              name: 'idToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'accessToken': _i1.ParameterDescription(
              name: 'accessToken',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['googleIdp'] as _i3.GoogleIdpEndpoint).login(
                    session,
                    idToken: params['idToken'],
                    accessToken: params['accessToken'],
                  ),
        ),
        'hasAccount': _i1.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['googleIdp'] as _i3.GoogleIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _i1.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _i1.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _i1.ParameterDescription(
              name: 'refreshToken',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['jwtRefresh'] as _i4.JwtRefreshEndpoint)
                  .refreshAccessToken(
                    session,
                    refreshToken: params['refreshToken'],
                  ),
        ),
      },
    );
    connectors['admin'] = _i1.EndpointConnector(
      name: 'admin',
      endpoint: endpoints['admin']!,
      methodConnectors: {
        'assignRole': _i1.MethodConnector(
          name: 'assignRole',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).assignRole(
                session,
                userId: params['userId'],
                role: params['role'],
              ),
        ),
        'getAllUserRoles': _i1.MethodConnector(
          name: 'getAllUserRoles',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getAllUserRoles(session),
        ),
        'createFaculty': _i1.MethodConnector(
          name: 'createFaculty',
          params: {
            'faculty': _i1.ParameterDescription(
              name: 'faculty',
              type: _i1.getType<_i16.Faculty>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).createFaculty(
                    session,
                    params['faculty'],
                  ),
        ),
        'getAllFaculty': _i1.MethodConnector(
          name: 'getAllFaculty',
          params: {
            'isActive': _i1.ParameterDescription(
              name: 'isActive',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).getAllFaculty(
                    session,
                    isActive: params['isActive'],
                  ),
        ),
        'updateFaculty': _i1.MethodConnector(
          name: 'updateFaculty',
          params: {
            'faculty': _i1.ParameterDescription(
              name: 'faculty',
              type: _i1.getType<_i16.Faculty>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).updateFaculty(
                    session,
                    params['faculty'],
                  ),
        ),
        'deleteFaculty': _i1.MethodConnector(
          name: 'deleteFaculty',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).deleteFaculty(
                    session,
                    params['id'],
                  ),
        ),
        'createStudent': _i1.MethodConnector(
          name: 'createStudent',
          params: {
            'student': _i1.ParameterDescription(
              name: 'student',
              type: _i1.getType<_i17.Student>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).createStudent(
                    session,
                    params['student'],
                  ),
        ),
        'getAllStudents': _i1.MethodConnector(
          name: 'getAllStudents',
          params: {
            'isActive': _i1.ParameterDescription(
              name: 'isActive',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).getAllStudents(
                    session,
                    isActive: params['isActive'],
                  ),
        ),
        'updateStudent': _i1.MethodConnector(
          name: 'updateStudent',
          params: {
            'student': _i1.ParameterDescription(
              name: 'student',
              type: _i1.getType<_i17.Student>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).updateStudent(
                    session,
                    params['student'],
                  ),
        ),
        'getDistinctStudentSections': _i1.MethodConnector(
          name: 'getDistinctStudentSections',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getDistinctStudentSections(session),
        ),
        'deleteStudent': _i1.MethodConnector(
          name: 'deleteStudent',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).deleteStudent(
                    session,
                    params['id'],
                  ),
        ),
        'createRoom': _i1.MethodConnector(
          name: 'createRoom',
          params: {
            'room': _i1.ParameterDescription(
              name: 'room',
              type: _i1.getType<_i18.Room>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).createRoom(
                session,
                params['room'],
              ),
        ),
        'getAllRooms': _i1.MethodConnector(
          name: 'getAllRooms',
          params: {
            'isActive': _i1.ParameterDescription(
              name: 'isActive',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).getAllRooms(
                session,
                isActive: params['isActive'],
              ),
        ),
        'updateRoom': _i1.MethodConnector(
          name: 'updateRoom',
          params: {
            'room': _i1.ParameterDescription(
              name: 'room',
              type: _i1.getType<_i18.Room>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).updateRoom(
                session,
                params['room'],
              ),
        ),
        'deleteRoom': _i1.MethodConnector(
          name: 'deleteRoom',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint).deleteRoom(
                session,
                params['id'],
              ),
        ),
        'createSubject': _i1.MethodConnector(
          name: 'createSubject',
          params: {
            'subject': _i1.ParameterDescription(
              name: 'subject',
              type: _i1.getType<_i19.Subject>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).createSubject(
                    session,
                    params['subject'],
                  ),
        ),
        'getAllSubjects': _i1.MethodConnector(
          name: 'getAllSubjects',
          params: {
            'isActive': _i1.ParameterDescription(
              name: 'isActive',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).getAllSubjects(
                    session,
                    isActive: params['isActive'],
                  ),
        ),
        'updateSubject': _i1.MethodConnector(
          name: 'updateSubject',
          params: {
            'subject': _i1.ParameterDescription(
              name: 'subject',
              type: _i1.getType<_i19.Subject>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).updateSubject(
                    session,
                    params['subject'],
                  ),
        ),
        'deleteSubject': _i1.MethodConnector(
          name: 'deleteSubject',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).deleteSubject(
                    session,
                    params['id'],
                  ),
        ),
        'createTimeslot': _i1.MethodConnector(
          name: 'createTimeslot',
          params: {
            'timeslot': _i1.ParameterDescription(
              name: 'timeslot',
              type: _i1.getType<_i20.Timeslot>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).createTimeslot(
                    session,
                    params['timeslot'],
                  ),
        ),
        'getAllTimeslots': _i1.MethodConnector(
          name: 'getAllTimeslots',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getAllTimeslots(session),
        ),
        'updateTimeslot': _i1.MethodConnector(
          name: 'updateTimeslot',
          params: {
            'timeslot': _i1.ParameterDescription(
              name: 'timeslot',
              type: _i1.getType<_i20.Timeslot>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).updateTimeslot(
                    session,
                    params['timeslot'],
                  ),
        ),
        'deleteTimeslot': _i1.MethodConnector(
          name: 'deleteTimeslot',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).deleteTimeslot(
                    session,
                    params['id'],
                  ),
        ),
        'createSchedule': _i1.MethodConnector(
          name: 'createSchedule',
          params: {
            'schedule': _i1.ParameterDescription(
              name: 'schedule',
              type: _i1.getType<_i21.Schedule>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).createSchedule(
                    session,
                    params['schedule'],
                  ),
        ),
        'testMaxLoadValidation': _i1.MethodConnector(
          name: 'testMaxLoadValidation',
          params: {
            'facultyId': _i1.ParameterDescription(
              name: 'facultyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'units': _i1.ParameterDescription(
              name: 'units',
              type: _i1.getType<double>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .testMaxLoadValidation(
                    session,
                    params['facultyId'],
                    params['units'],
                  ),
        ),
        'getAllSchedules': _i1.MethodConnector(
          name: 'getAllSchedules',
          params: {
            'isActive': _i1.ParameterDescription(
              name: 'isActive',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).getAllSchedules(
                    session,
                    isActive: params['isActive'],
                  ),
        ),
        'getFacultySchedule': _i1.MethodConnector(
          name: 'getFacultySchedule',
          params: {
            'facultyId': _i1.ParameterDescription(
              name: 'facultyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'isActive': _i1.ParameterDescription(
              name: 'isActive',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).getFacultySchedule(
                    session,
                    params['facultyId'],
                    isActive: params['isActive'],
                  ),
        ),
        'getSubjectSchedule': _i1.MethodConnector(
          name: 'getSubjectSchedule',
          params: {
            'subjectId': _i1.ParameterDescription(
              name: 'subjectId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'isActive': _i1.ParameterDescription(
              name: 'isActive',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).getSubjectSchedule(
                    session,
                    params['subjectId'],
                    isActive: params['isActive'],
                  ),
        ),
        'getRoomSchedule': _i1.MethodConnector(
          name: 'getRoomSchedule',
          params: {
            'roomId': _i1.ParameterDescription(
              name: 'roomId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'isActive': _i1.ParameterDescription(
              name: 'isActive',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).getRoomSchedule(
                    session,
                    params['roomId'],
                    isActive: params['isActive'],
                  ),
        ),
        'updateSchedule': _i1.MethodConnector(
          name: 'updateSchedule',
          params: {
            'schedule': _i1.ParameterDescription(
              name: 'schedule',
              type: _i1.getType<_i21.Schedule>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).updateSchedule(
                    session,
                    params['schedule'],
                  ),
        ),
        'deleteSchedule': _i1.MethodConnector(
          name: 'deleteSchedule',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).deleteSchedule(
                    session,
                    params['id'],
                  ),
        ),
        'generateSchedule': _i1.MethodConnector(
          name: 'generateSchedule',
          params: {
            'request': _i1.ParameterDescription(
              name: 'request',
              type: _i1.getType<_i22.GenerateScheduleRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).generateSchedule(
                    session,
                    params['request'],
                  ),
        ),
        'getDashboardStats': _i1.MethodConnector(
          name: 'getDashboardStats',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getDashboardStats(session),
        ),
        'validateSchedule': _i1.MethodConnector(
          name: 'validateSchedule',
          params: {
            'schedule': _i1.ParameterDescription(
              name: 'schedule',
              type: _i1.getType<_i21.Schedule>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).validateSchedule(
                    session,
                    params['schedule'],
                  ),
        ),
        'getAllConflicts': _i1.MethodConnector(
          name: 'getAllConflicts',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getAllConflicts(session),
        ),
        'getFacultyLoadReport': _i1.MethodConnector(
          name: 'getFacultyLoadReport',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getFacultyLoadReport(session),
        ),
        'getRoomUtilizationReport': _i1.MethodConnector(
          name: 'getRoomUtilizationReport',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getRoomUtilizationReport(session),
        ),
        'getConflictSummaryReport': _i1.MethodConnector(
          name: 'getConflictSummaryReport',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getConflictSummaryReport(session),
        ),
        'getScheduleOverviewReport': _i1.MethodConnector(
          name: 'getScheduleOverviewReport',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getScheduleOverviewReport(session),
        ),
        'createSection': _i1.MethodConnector(
          name: 'createSection',
          params: {
            'section': _i1.ParameterDescription(
              name: 'section',
              type: _i1.getType<_i23.Section>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).createSection(
                    session,
                    params['section'],
                  ),
        ),
        'getAllSections': _i1.MethodConnector(
          name: 'getAllSections',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getAllSections(session),
        ),
        'updateSection': _i1.MethodConnector(
          name: 'updateSection',
          params: {
            'section': _i1.ParameterDescription(
              name: 'section',
              type: _i1.getType<_i23.Section>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).updateSection(
                    session,
                    params['section'],
                  ),
        ),
        'deleteSection': _i1.MethodConnector(
          name: 'deleteSection',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['admin'] as _i5.AdminEndpoint).deleteSection(
                    session,
                    params['id'],
                  ),
        ),
        'setFacultyAvailability': _i1.MethodConnector(
          name: 'setFacultyAvailability',
          params: {
            'facultyId': _i1.ParameterDescription(
              name: 'facultyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'availabilities': _i1.ParameterDescription(
              name: 'availabilities',
              type: _i1.getType<List<_i24.FacultyAvailability>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .setFacultyAvailability(
                    session,
                    params['facultyId'],
                    params['availabilities'],
                  ),
        ),
        'setFacultyAvailabilityImpl': _i1.MethodConnector(
          name: 'setFacultyAvailabilityImpl',
          params: {
            'facultyId': _i1.ParameterDescription(
              name: 'facultyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'availabilities': _i1.ParameterDescription(
              name: 'availabilities',
              type: _i1.getType<List<_i24.FacultyAvailability>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .setFacultyAvailabilityImpl(
                    session,
                    params['facultyId'],
                    params['availabilities'],
                  ),
        ),
        'getFacultyAvailability': _i1.MethodConnector(
          name: 'getFacultyAvailability',
          params: {
            'facultyId': _i1.ParameterDescription(
              name: 'facultyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getFacultyAvailability(
                    session,
                    params['facultyId'],
                  ),
        ),
        'getAllFacultyAvailabilities': _i1.MethodConnector(
          name: 'getAllFacultyAvailabilities',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .getAllFacultyAvailabilities(session),
        ),
        'deleteFacultyAvailability': _i1.MethodConnector(
          name: 'deleteFacultyAvailability',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .deleteFacultyAvailability(
                    session,
                    params['id'],
                  ),
        ),
        'precheckSchedule': _i1.MethodConnector(
          name: 'precheckSchedule',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .precheckSchedule(session),
        ),
        'regenerateSchedule': _i1.MethodConnector(
          name: 'regenerateSchedule',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['admin'] as _i5.AdminEndpoint)
                  .regenerateSchedule(session),
        ),
      },
    );
    connectors['chatHistory'] = _i1.EndpointConnector(
      name: 'chatHistory',
      endpoint: endpoints['chatHistory']!,
      methodConnectors: {
        'getMyHistory': _i1.MethodConnector(
          name: 'getMyHistory',
          params: {
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chatHistory'] as _i6.ChatHistoryEndpoint)
                  .getMyHistory(
                    session,
                    role: params['role'],
                    limit: params['limit'],
                  ),
        ),
        'getMySessions': _i1.MethodConnector(
          name: 'getMySessions',
          params: {
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chatHistory'] as _i6.ChatHistoryEndpoint)
                  .getMySessions(
                    session,
                    role: params['role'],
                    limit: params['limit'],
                  ),
        ),
        'getSessionHistory': _i1.MethodConnector(
          name: 'getSessionHistory',
          params: {
            'sessionId': _i1.ParameterDescription(
              name: 'sessionId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chatHistory'] as _i6.ChatHistoryEndpoint)
                  .getSessionHistory(
                    session,
                    sessionId: params['sessionId'],
                    role: params['role'],
                    limit: params['limit'],
                  ),
        ),
        'deleteSession': _i1.MethodConnector(
          name: 'deleteSession',
          params: {
            'sessionId': _i1.ParameterDescription(
              name: 'sessionId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chatHistory'] as _i6.ChatHistoryEndpoint)
                  .deleteSession(
                    session,
                    sessionId: params['sessionId'],
                    role: params['role'],
                  ),
        ),
      },
    );
    connectors['customAuth'] = _i1.EndpointConnector(
      name: 'customAuth',
      endpoint: endpoints['customAuth']!,
      methodConnectors: {
        'loginWithId': _i1.MethodConnector(
          name: 'loginWithId',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['customAuth'] as _i7.CustomAuthEndpoint)
                  .loginWithId(
                    session,
                    id: params['id'],
                    password: params['password'],
                    role: params['role'],
                  ),
        ),
      },
    );
    connectors['debug'] = _i1.EndpointConnector(
      name: 'debug',
      endpoint: endpoints['debug']!,
      methodConnectors: {
        'getSessionInfo': _i1.MethodConnector(
          name: 'getSessionInfo',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['debug'] as _i8.DebugEndpoint)
                  .getSessionInfo(session),
        ),
      },
    );
    connectors['faculty'] = _i1.EndpointConnector(
      name: 'faculty',
      endpoint: endpoints['faculty']!,
      methodConnectors: {
        'getMySchedule': _i1.MethodConnector(
          name: 'getMySchedule',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['faculty'] as _i9.FacultyEndpoint)
                  .getMySchedule(session),
        ),
        'getMyProfile': _i1.MethodConnector(
          name: 'getMyProfile',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['faculty'] as _i9.FacultyEndpoint)
                  .getMyProfile(session),
        ),
      },
    );
    connectors['nLP'] = _i1.EndpointConnector(
      name: 'nLP',
      endpoint: endpoints['nLP']!,
      methodConnectors: {
        'query': _i1.MethodConnector(
          name: 'query',
          params: {
            'text': _i1.ParameterDescription(
              name: 'text',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'sessionId': _i1.ParameterDescription(
              name: 'sessionId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'sessionTitle': _i1.ParameterDescription(
              name: 'sessionTitle',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nLP'] as _i10.NLPEndpoint).query(
                session,
                params['text'],
                sessionId: params['sessionId'],
                sessionTitle: params['sessionTitle'],
              ),
        ),
        'getFacultyLoad': _i1.MethodConnector(
          name: 'getFacultyLoad',
          params: {
            'facultyId': _i1.ParameterDescription(
              name: 'facultyId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nLP'] as _i10.NLPEndpoint).getFacultyLoad(
                session,
                facultyId: params['facultyId'],
              ),
        ),
        'getStudentSchedule': _i1.MethodConnector(
          name: 'getStudentSchedule',
          params: {
            'studentId': _i1.ParameterDescription(
              name: 'studentId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['nLP'] as _i10.NLPEndpoint).getStudentSchedule(
                    session,
                    studentId: params['studentId'],
                  ),
        ),
        'getSectionSchedule': _i1.MethodConnector(
          name: 'getSectionSchedule',
          params: {
            'sectionId': _i1.ParameterDescription(
              name: 'sectionId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['nLP'] as _i10.NLPEndpoint).getSectionSchedule(
                    session,
                    sectionId: params['sectionId'],
                  ),
        ),
        'getRoomAvailability': _i1.MethodConnector(
          name: 'getRoomAvailability',
          params: {
            'roomId': _i1.ParameterDescription(
              name: 'roomId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'day': _i1.ParameterDescription(
              name: 'day',
              type: _i1.getType<_i25.DayOfWeek>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['nLP'] as _i10.NLPEndpoint).getRoomAvailability(
                    session,
                    roomId: params['roomId'],
                    day: params['day'],
                  ),
        ),
        'getSubjectCatalog': _i1.MethodConnector(
          name: 'getSubjectCatalog',
          params: {
            'program': _i1.ParameterDescription(
              name: 'program',
              type: _i1.getType<_i26.Program>(),
              nullable: false,
            ),
            'yearLevel': _i1.ParameterDescription(
              name: 'yearLevel',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['nLP'] as _i10.NLPEndpoint).getSubjectCatalog(
                    session,
                    program: params['program'],
                    yearLevel: params['yearLevel'],
                  ),
        ),
        'getScheduleConflicts': _i1.MethodConnector(
          name: 'getScheduleConflicts',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nLP'] as _i10.NLPEndpoint)
                  .getScheduleConflicts(session),
        ),
        'generateScheduleSuggestions': _i1.MethodConnector(
          name: 'generateScheduleSuggestions',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nLP'] as _i10.NLPEndpoint)
                  .generateScheduleSuggestions(session),
        ),
        'searchSchedules': _i1.MethodConnector(
          name: 'searchSchedules',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nLP'] as _i10.NLPEndpoint).searchSchedules(
                session,
                query: params['query'],
              ),
        ),
        'createChatSession': _i1.MethodConnector(
          name: 'createChatSession',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'title': _i1.ParameterDescription(
              name: 'title',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['nLP'] as _i10.NLPEndpoint).createChatSession(
                    session,
                    userId: params['userId'],
                    role: params['role'],
                    title: params['title'],
                  ),
        ),
        'getChatHistory': _i1.MethodConnector(
          name: 'getChatHistory',
          params: {
            'userId': _i1.ParameterDescription(
              name: 'userId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nLP'] as _i10.NLPEndpoint).getChatHistory(
                session,
                userId: params['userId'],
                role: params['role'],
                limit: params['limit'],
              ),
        ),
        'getChatMessages': _i1.MethodConnector(
          name: 'getChatMessages',
          params: {
            'sessionId': _i1.ParameterDescription(
              name: 'sessionId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nLP'] as _i10.NLPEndpoint).getChatMessages(
                session,
                sessionId: params['sessionId'],
                role: params['role'],
                limit: params['limit'],
              ),
        ),
        'saveChatMessage': _i1.MethodConnector(
          name: 'saveChatMessage',
          params: {
            'sessionId': _i1.ParameterDescription(
              name: 'sessionId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'sender': _i1.ParameterDescription(
              name: 'sender',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'message': _i1.ParameterDescription(
              name: 'message',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nLP'] as _i10.NLPEndpoint).saveChatMessage(
                session,
                sessionId: params['sessionId'],
                sender: params['sender'],
                message: params['message'],
                role: params['role'],
              ),
        ),
        'deleteChatSession': _i1.MethodConnector(
          name: 'deleteChatSession',
          params: {
            'sessionId': _i1.ParameterDescription(
              name: 'sessionId',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['nLP'] as _i10.NLPEndpoint).deleteChatSession(
                    session,
                    sessionId: params['sessionId'],
                    role: params['role'],
                  ),
        ),
      },
    );
    connectors['setup'] = _i1.EndpointConnector(
      name: 'setup',
      endpoint: endpoints['setup']!,
      methodConnectors: {
        'createAccount': _i1.MethodConnector(
          name: 'createAccount',
          params: {
            'userName': _i1.ParameterDescription(
              name: 'userName',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'password': _i1.ParameterDescription(
              name: 'password',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'role': _i1.ParameterDescription(
              name: 'role',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'studentId': _i1.ParameterDescription(
              name: 'studentId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'facultyId': _i1.ParameterDescription(
              name: 'facultyId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'course': _i1.ParameterDescription(
              name: 'course',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'section': _i1.ParameterDescription(
              name: 'section',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'maxLoad': _i1.ParameterDescription(
              name: 'maxLoad',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'employmentStatus': _i1.ParameterDescription(
              name: 'employmentStatus',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'shiftPreference': _i1.ParameterDescription(
              name: 'shiftPreference',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'program': _i1.ParameterDescription(
              name: 'program',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['setup'] as _i11.SetupEndpoint).createAccount(
                    session,
                    userName: params['userName'],
                    email: params['email'],
                    password: params['password'],
                    role: params['role'],
                    studentId: params['studentId'],
                    facultyId: params['facultyId'],
                    course: params['course'],
                    section: params['section'],
                    maxLoad: params['maxLoad'],
                    employmentStatus: params['employmentStatus'],
                    shiftPreference: params['shiftPreference'],
                    program: params['program'],
                  ),
        ),
        'getUserInfoByEmail': _i1.MethodConnector(
          name: 'getUserInfoByEmail',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['setup'] as _i11.SetupEndpoint).getUserInfoByEmail(
                    session,
                    email: params['email'],
                  ),
        ),
        'getStudentProfileByEmail': _i1.MethodConnector(
          name: 'getStudentProfileByEmail',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['setup'] as _i11.SetupEndpoint)
                  .getStudentProfileByEmail(
                    session,
                    email: params['email'],
                  ),
        ),
        'getExistingAccountRoleByEmail': _i1.MethodConnector(
          name: 'getExistingAccountRoleByEmail',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['setup'] as _i11.SetupEndpoint)
                  .getExistingAccountRoleByEmail(
                    session,
                    email: params['email'],
                  ),
        ),
        'getExistingAccountRoleByEmailImpl': _i1.MethodConnector(
          name: 'getExistingAccountRoleByEmailImpl',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['setup'] as _i11.SetupEndpoint)
                  .getExistingAccountRoleByEmailImpl(
                    session,
                    email: params['email'],
                  ),
        ),
        'adoptExistingAccountByEmail': _i1.MethodConnector(
          name: 'adoptExistingAccountByEmail',
          params: {
            'email': _i1.ParameterDescription(
              name: 'email',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['setup'] as _i11.SetupEndpoint)
                  .adoptExistingAccountByEmail(
                    session,
                    email: params['email'],
                  ),
        ),
      },
    );
    connectors['student'] = _i1.EndpointConnector(
      name: 'student',
      endpoint: endpoints['student']!,
      methodConnectors: {
        'getSchedules': _i1.MethodConnector(
          name: 'getSchedules',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['student'] as _i12.StudentEndpoint)
                  .getSchedules(session),
        ),
        'getScheduleById': _i1.MethodConnector(
          name: 'getScheduleById',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['student'] as _i12.StudentEndpoint)
                  .getScheduleById(
                    session,
                    params['id'],
                  ),
        ),
        'getMyProfile': _i1.MethodConnector(
          name: 'getMyProfile',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['student'] as _i12.StudentEndpoint)
                  .getMyProfile(session),
        ),
        'updateMyProfile': _i1.MethodConnector(
          name: 'updateMyProfile',
          params: {
            'updatedProfile': _i1.ParameterDescription(
              name: 'updatedProfile',
              type: _i1.getType<_i17.Student>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['student'] as _i12.StudentEndpoint)
                  .updateMyProfile(
                    session,
                    params['updatedProfile'],
                  ),
        ),
        'getFaculty': _i1.MethodConnector(
          name: 'getFaculty',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['student'] as _i12.StudentEndpoint)
                  .getFaculty(session),
        ),
        'getRooms': _i1.MethodConnector(
          name: 'getRooms',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['student'] as _i12.StudentEndpoint)
                  .getRooms(session),
        ),
        'getSubjects': _i1.MethodConnector(
          name: 'getSubjects',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['student'] as _i12.StudentEndpoint)
                  .getSubjects(session),
        ),
        'getTimeslots': _i1.MethodConnector(
          name: 'getTimeslots',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['student'] as _i12.StudentEndpoint)
                  .getTimeslots(session),
        ),
      },
    );
    connectors['studentSchedule'] = _i1.EndpointConnector(
      name: 'studentSchedule',
      endpoint: endpoints['studentSchedule']!,
      methodConnectors: {
        'fetchMySchedule': _i1.MethodConnector(
          name: 'fetchMySchedule',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['studentSchedule'] as _i13.StudentScheduleEndpoint)
                      .fetchMySchedule(session),
        ),
      },
    );
    connectors['timetable'] = _i1.EndpointConnector(
      name: 'timetable',
      endpoint: endpoints['timetable']!,
      methodConnectors: {
        'getSchedules': _i1.MethodConnector(
          name: 'getSchedules',
          params: {
            'filter': _i1.ParameterDescription(
              name: 'filter',
              type: _i1.getType<_i27.TimetableFilterRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['timetable'] as _i14.TimetableEndpoint)
                  .getSchedules(
                    session,
                    params['filter'],
                  ),
        ),
        'getSummary': _i1.MethodConnector(
          name: 'getSummary',
          params: {
            'filter': _i1.ParameterDescription(
              name: 'filter',
              type: _i1.getType<_i27.TimetableFilterRequest>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['timetable'] as _i14.TimetableEndpoint).getSummary(
                    session,
                    params['filter'],
                  ),
        ),
        'getPersonalSchedule': _i1.MethodConnector(
          name: 'getPersonalSchedule',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['timetable'] as _i14.TimetableEndpoint)
                  .getPersonalSchedule(session),
        ),
      },
    );
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['greeting'] as _i15.GreetingEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _i28.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth'] = _i29.Endpoints()..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _i30.Endpoints()
      ..initializeEndpoints(server);
  }
}
