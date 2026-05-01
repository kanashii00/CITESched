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
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as _i4;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i5;
import 'ai_chat_message.dart' as _i6;
import 'ai_chat_session.dart' as _i7;
import 'chat_history.dart' as _i8;
import 'chat_session_summary.dart' as _i9;
import 'dashboard_stats.dart' as _i10;
import 'day_of_week.dart' as _i11;
import 'distribution_data.dart' as _i12;
import 'employment_status.dart' as _i13;
import 'faculty.dart' as _i14;
import 'faculty_availability.dart' as _i15;
import 'faculty_load_data.dart' as _i16;
import 'faculty_shift_preference.dart' as _i17;
import 'generate_schedule_request.dart' as _i18;
import 'generate_schedule_response.dart' as _i19;
import 'greetings/greeting.dart' as _i20;
import 'nlp_intent.dart' as _i21;
import 'nlp_response.dart' as _i22;
import 'program.dart' as _i23;
import 'reports/conflict_summary_report.dart' as _i24;
import 'reports/faculty_load_report.dart' as _i25;
import 'reports/room_utilization_report.dart' as _i26;
import 'reports/schedule_overview_report.dart' as _i27;
import 'room.dart' as _i28;
import 'room_type.dart' as _i29;
import 'schedule.dart' as _i30;
import 'schedule_conflict.dart' as _i31;
import 'schedule_info.dart' as _i32;
import 'section.dart' as _i33;
import 'student.dart' as _i34;
import 'student_academic_status.dart' as _i35;
import 'subject.dart' as _i36;
import 'subject_type.dart' as _i37;
import 'timeslot.dart' as _i38;
import 'timetable_filter_request.dart' as _i39;
import 'timetable_summary.dart' as _i40;
import 'user_role.dart' as _i41;
import 'package:citesched_server/src/generated/user_role.dart' as _i42;
import 'package:citesched_server/src/generated/faculty.dart' as _i43;
import 'package:citesched_server/src/generated/student.dart' as _i44;
import 'package:citesched_server/src/generated/room.dart' as _i45;
import 'package:citesched_server/src/generated/subject.dart' as _i46;
import 'package:citesched_server/src/generated/timeslot.dart' as _i47;
import 'package:citesched_server/src/generated/schedule.dart' as _i48;
import 'package:citesched_server/src/generated/schedule_conflict.dart' as _i49;
import 'package:citesched_server/src/generated/reports/faculty_load_report.dart'
    as _i50;
import 'package:citesched_server/src/generated/reports/room_utilization_report.dart'
    as _i51;
import 'package:citesched_server/src/generated/section.dart' as _i52;
import 'package:citesched_server/src/generated/faculty_availability.dart'
    as _i53;
import 'package:citesched_server/src/generated/chat_history.dart' as _i54;
import 'package:citesched_server/src/generated/chat_session_summary.dart'
    as _i55;
import 'package:citesched_server/src/generated/ai_chat_message.dart' as _i56;
import 'package:citesched_server/src/generated/schedule_info.dart' as _i57;
export 'ai_chat_message.dart';
export 'ai_chat_session.dart';
export 'chat_history.dart';
export 'chat_session_summary.dart';
export 'dashboard_stats.dart';
export 'day_of_week.dart';
export 'distribution_data.dart';
export 'employment_status.dart';
export 'faculty.dart';
export 'faculty_availability.dart';
export 'faculty_load_data.dart';
export 'faculty_shift_preference.dart';
export 'generate_schedule_request.dart';
export 'generate_schedule_response.dart';
export 'greetings/greeting.dart';
export 'nlp_intent.dart';
export 'nlp_response.dart';
export 'program.dart';
export 'reports/conflict_summary_report.dart';
export 'reports/faculty_load_report.dart';
export 'reports/room_utilization_report.dart';
export 'reports/schedule_overview_report.dart';
export 'room.dart';
export 'room_type.dart';
export 'schedule.dart';
export 'schedule_conflict.dart';
export 'schedule_info.dart';
export 'section.dart';
export 'student.dart';
export 'student_academic_status.dart';
export 'subject.dart';
export 'subject_type.dart';
export 'timeslot.dart';
export 'timetable_filter_request.dart';
export 'timetable_summary.dart';
export 'user_role.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'chat_history',
      dartName: 'ChatHistory',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'chat_history_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'sessionId',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'sessionTitle',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'sender',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'text',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'intent',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'metadataJson',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'chat_history_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'chat_messages',
      dartName: 'AiChatMessage',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'chat_messages_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'sessionRecordId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'sender',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'message',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'timestamp',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'chat_messages_fk_0',
          columns: ['sessionRecordId'],
          referenceTable: 'chat_sessions',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'chat_messages_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'chat_messages_session_timestamp_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sessionRecordId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'timestamp',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'chat_sessions',
      dartName: 'AiChatSession',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'chat_sessions_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'roleType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'chat_sessions_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'chat_sessions_user_role_updated_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'roleType',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'updatedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'faculty',
      dartName: 'Faculty',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'faculty_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'maxLoad',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'employmentStatus',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:EmploymentStatus?',
        ),
        _i2.ColumnDefinition(
          name: 'shiftPreference',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:FacultyShiftPreference?',
        ),
        _i2.ColumnDefinition(
          name: 'preferredHours',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'facultyId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'userInfoId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'program',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:Program?',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'currentLoad',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'faculty_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'faculty_email_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'faculty_id_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'facultyId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'faculty_availability',
      dartName: 'FacultyAvailability',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'faculty_availability_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'facultyId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'dayOfWeek',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DayOfWeek',
        ),
        _i2.ColumnDefinition(
          name: 'startTime',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'endTime',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'isPreferred',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'faculty_availability_fk_0',
          columns: ['facultyId'],
          referenceTable: 'faculty',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'faculty_availability_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'room',
      dartName: 'Room',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'room_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'capacity',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:RoomType',
        ),
        _i2.ColumnDefinition(
          name: 'program',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:Program',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'room_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'room_name_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'name',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'schedule',
      dartName: 'Schedule',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'schedule_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'subjectId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'facultyId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'roomId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'timeslotId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'section',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'sectionId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'loadTypes',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<protocol:SubjectType>?',
        ),
        _i2.ColumnDefinition(
          name: 'units',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _i2.ColumnDefinition(
          name: 'hours',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'schedule_fk_0',
          columns: ['subjectId'],
          referenceTable: 'subject',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'schedule_fk_1',
          columns: ['facultyId'],
          referenceTable: 'faculty',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'schedule_fk_2',
          columns: ['roomId'],
          referenceTable: 'room',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'schedule_fk_3',
          columns: ['timeslotId'],
          referenceTable: 'timeslot',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
        _i2.ForeignKeyDefinition(
          constraintName: 'schedule_fk_4',
          columns: ['sectionId'],
          referenceTable: 'section',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'schedule_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'section',
      dartName: 'Section',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'section_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'program',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:Program',
        ),
        _i2.ColumnDefinition(
          name: 'yearLevel',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'sectionCode',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'academicYear',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'semester',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'section_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'section_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'program',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'yearLevel',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'sectionCode',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'academicYear',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'semester',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'student',
      dartName: 'Student',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'student_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'email',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'studentNumber',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'course',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'yearLevel',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'section',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'sectionId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'userInfoId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'academicStatus',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:StudentAcademicStatus',
          columnDefault: '\'active\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [
        _i2.ForeignKeyDefinition(
          constraintName: 'student_fk_0',
          columns: ['sectionId'],
          referenceTable: 'section',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _i2.ForeignKeyAction.noAction,
          onDelete: _i2.ForeignKeyAction.noAction,
          matchType: null,
        ),
      ],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'student_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'student_email_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'email',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'student_number_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'studentNumber',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'subject',
      dartName: 'Subject',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'subject_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'code',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'units',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'hours',
          columnType: _i2.ColumnType.doublePrecision,
          isNullable: true,
          dartType: 'double?',
        ),
        _i2.ColumnDefinition(
          name: 'yearLevel',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'term',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'facultyId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'types',
          columnType: _i2.ColumnType.json,
          isNullable: false,
          dartType: 'List<protocol:SubjectType>',
        ),
        _i2.ColumnDefinition(
          name: 'program',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:Program',
        ),
        _i2.ColumnDefinition(
          name: 'studentsCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'isActive',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'subject_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'timeslot',
      dartName: 'Timeslot',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'timeslot_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'day',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:DayOfWeek',
        ),
        _i2.ColumnDefinition(
          name: 'startTime',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'endTime',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'label',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'updatedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'timeslot_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'user_role',
      dartName: 'UserRole',
      schema: 'public',
      module: 'citesched',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'user_role_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'user_role_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_role_user_id_unique_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i5.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i6.AiChatMessage) {
      return _i6.AiChatMessage.fromJson(data) as T;
    }
    if (t == _i7.AiChatSession) {
      return _i7.AiChatSession.fromJson(data) as T;
    }
    if (t == _i8.ChatHistory) {
      return _i8.ChatHistory.fromJson(data) as T;
    }
    if (t == _i9.ChatSessionSummary) {
      return _i9.ChatSessionSummary.fromJson(data) as T;
    }
    if (t == _i10.DashboardStats) {
      return _i10.DashboardStats.fromJson(data) as T;
    }
    if (t == _i11.DayOfWeek) {
      return _i11.DayOfWeek.fromJson(data) as T;
    }
    if (t == _i12.DistributionData) {
      return _i12.DistributionData.fromJson(data) as T;
    }
    if (t == _i13.EmploymentStatus) {
      return _i13.EmploymentStatus.fromJson(data) as T;
    }
    if (t == _i14.Faculty) {
      return _i14.Faculty.fromJson(data) as T;
    }
    if (t == _i15.FacultyAvailability) {
      return _i15.FacultyAvailability.fromJson(data) as T;
    }
    if (t == _i16.FacultyLoadData) {
      return _i16.FacultyLoadData.fromJson(data) as T;
    }
    if (t == _i17.FacultyShiftPreference) {
      return _i17.FacultyShiftPreference.fromJson(data) as T;
    }
    if (t == _i18.GenerateScheduleRequest) {
      return _i18.GenerateScheduleRequest.fromJson(data) as T;
    }
    if (t == _i19.GenerateScheduleResponse) {
      return _i19.GenerateScheduleResponse.fromJson(data) as T;
    }
    if (t == _i20.Greeting) {
      return _i20.Greeting.fromJson(data) as T;
    }
    if (t == _i21.NLPIntent) {
      return _i21.NLPIntent.fromJson(data) as T;
    }
    if (t == _i22.NLPResponse) {
      return _i22.NLPResponse.fromJson(data) as T;
    }
    if (t == _i23.Program) {
      return _i23.Program.fromJson(data) as T;
    }
    if (t == _i24.ConflictSummaryReport) {
      return _i24.ConflictSummaryReport.fromJson(data) as T;
    }
    if (t == _i25.FacultyLoadReport) {
      return _i25.FacultyLoadReport.fromJson(data) as T;
    }
    if (t == _i26.RoomUtilizationReport) {
      return _i26.RoomUtilizationReport.fromJson(data) as T;
    }
    if (t == _i27.ScheduleOverviewReport) {
      return _i27.ScheduleOverviewReport.fromJson(data) as T;
    }
    if (t == _i28.Room) {
      return _i28.Room.fromJson(data) as T;
    }
    if (t == _i29.RoomType) {
      return _i29.RoomType.fromJson(data) as T;
    }
    if (t == _i30.Schedule) {
      return _i30.Schedule.fromJson(data) as T;
    }
    if (t == _i31.ScheduleConflict) {
      return _i31.ScheduleConflict.fromJson(data) as T;
    }
    if (t == _i32.ScheduleInfo) {
      return _i32.ScheduleInfo.fromJson(data) as T;
    }
    if (t == _i33.Section) {
      return _i33.Section.fromJson(data) as T;
    }
    if (t == _i34.Student) {
      return _i34.Student.fromJson(data) as T;
    }
    if (t == _i35.StudentAcademicStatus) {
      return _i35.StudentAcademicStatus.fromJson(data) as T;
    }
    if (t == _i36.Subject) {
      return _i36.Subject.fromJson(data) as T;
    }
    if (t == _i37.SubjectType) {
      return _i37.SubjectType.fromJson(data) as T;
    }
    if (t == _i38.Timeslot) {
      return _i38.Timeslot.fromJson(data) as T;
    }
    if (t == _i39.TimetableFilterRequest) {
      return _i39.TimetableFilterRequest.fromJson(data) as T;
    }
    if (t == _i40.TimetableSummary) {
      return _i40.TimetableSummary.fromJson(data) as T;
    }
    if (t == _i41.UserRole) {
      return _i41.UserRole.fromJson(data) as T;
    }
    if (t == _i1.getType<_i6.AiChatMessage?>()) {
      return (data != null ? _i6.AiChatMessage.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AiChatSession?>()) {
      return (data != null ? _i7.AiChatSession.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.ChatHistory?>()) {
      return (data != null ? _i8.ChatHistory.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ChatSessionSummary?>()) {
      return (data != null ? _i9.ChatSessionSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.DashboardStats?>()) {
      return (data != null ? _i10.DashboardStats.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.DayOfWeek?>()) {
      return (data != null ? _i11.DayOfWeek.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.DistributionData?>()) {
      return (data != null ? _i12.DistributionData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.EmploymentStatus?>()) {
      return (data != null ? _i13.EmploymentStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.Faculty?>()) {
      return (data != null ? _i14.Faculty.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.FacultyAvailability?>()) {
      return (data != null ? _i15.FacultyAvailability.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.FacultyLoadData?>()) {
      return (data != null ? _i16.FacultyLoadData.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.FacultyShiftPreference?>()) {
      return (data != null ? _i17.FacultyShiftPreference.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i18.GenerateScheduleRequest?>()) {
      return (data != null ? _i18.GenerateScheduleRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.GenerateScheduleResponse?>()) {
      return (data != null
              ? _i19.GenerateScheduleResponse.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i20.Greeting?>()) {
      return (data != null ? _i20.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.NLPIntent?>()) {
      return (data != null ? _i21.NLPIntent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.NLPResponse?>()) {
      return (data != null ? _i22.NLPResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.Program?>()) {
      return (data != null ? _i23.Program.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.ConflictSummaryReport?>()) {
      return (data != null ? _i24.ConflictSummaryReport.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i25.FacultyLoadReport?>()) {
      return (data != null ? _i25.FacultyLoadReport.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.RoomUtilizationReport?>()) {
      return (data != null ? _i26.RoomUtilizationReport.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i27.ScheduleOverviewReport?>()) {
      return (data != null ? _i27.ScheduleOverviewReport.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i28.Room?>()) {
      return (data != null ? _i28.Room.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i29.RoomType?>()) {
      return (data != null ? _i29.RoomType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.Schedule?>()) {
      return (data != null ? _i30.Schedule.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.ScheduleConflict?>()) {
      return (data != null ? _i31.ScheduleConflict.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.ScheduleInfo?>()) {
      return (data != null ? _i32.ScheduleInfo.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.Section?>()) {
      return (data != null ? _i33.Section.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.Student?>()) {
      return (data != null ? _i34.Student.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.StudentAcademicStatus?>()) {
      return (data != null ? _i35.StudentAcademicStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i36.Subject?>()) {
      return (data != null ? _i36.Subject.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.SubjectType?>()) {
      return (data != null ? _i37.SubjectType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.Timeslot?>()) {
      return (data != null ? _i38.Timeslot.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.TimetableFilterRequest?>()) {
      return (data != null ? _i39.TimetableFilterRequest.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i40.TimetableSummary?>()) {
      return (data != null ? _i40.TimetableSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.UserRole?>()) {
      return (data != null ? _i41.UserRole.fromJson(data) : null) as T;
    }
    if (t == List<_i16.FacultyLoadData>) {
      return (data as List)
              .map((e) => deserialize<_i16.FacultyLoadData>(e))
              .toList()
          as T;
    }
    if (t == List<_i31.ScheduleConflict>) {
      return (data as List)
              .map((e) => deserialize<_i31.ScheduleConflict>(e))
              .toList()
          as T;
    }
    if (t == List<_i12.DistributionData>) {
      return (data as List)
              .map((e) => deserialize<_i12.DistributionData>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i30.Schedule>) {
      return (data as List).map((e) => deserialize<_i30.Schedule>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i30.Schedule>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i30.Schedule>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _i1.getType<List<_i31.ScheduleConflict>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i31.ScheduleConflict>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == List<_i37.SubjectType>) {
      return (data as List)
              .map((e) => deserialize<_i37.SubjectType>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i37.SubjectType>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i37.SubjectType>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i42.UserRole>) {
      return (data as List).map((e) => deserialize<_i42.UserRole>(e)).toList()
          as T;
    }
    if (t == List<_i43.Faculty>) {
      return (data as List).map((e) => deserialize<_i43.Faculty>(e)).toList()
          as T;
    }
    if (t == List<_i44.Student>) {
      return (data as List).map((e) => deserialize<_i44.Student>(e)).toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i45.Room>) {
      return (data as List).map((e) => deserialize<_i45.Room>(e)).toList() as T;
    }
    if (t == List<_i46.Subject>) {
      return (data as List).map((e) => deserialize<_i46.Subject>(e)).toList()
          as T;
    }
    if (t == List<_i47.Timeslot>) {
      return (data as List).map((e) => deserialize<_i47.Timeslot>(e)).toList()
          as T;
    }
    if (t == List<_i48.Schedule>) {
      return (data as List).map((e) => deserialize<_i48.Schedule>(e)).toList()
          as T;
    }
    if (t == List<_i49.ScheduleConflict>) {
      return (data as List)
              .map((e) => deserialize<_i49.ScheduleConflict>(e))
              .toList()
          as T;
    }
    if (t == List<_i50.FacultyLoadReport>) {
      return (data as List)
              .map((e) => deserialize<_i50.FacultyLoadReport>(e))
              .toList()
          as T;
    }
    if (t == List<_i51.RoomUtilizationReport>) {
      return (data as List)
              .map((e) => deserialize<_i51.RoomUtilizationReport>(e))
              .toList()
          as T;
    }
    if (t == List<_i52.Section>) {
      return (data as List).map((e) => deserialize<_i52.Section>(e)).toList()
          as T;
    }
    if (t == List<_i53.FacultyAvailability>) {
      return (data as List)
              .map((e) => deserialize<_i53.FacultyAvailability>(e))
              .toList()
          as T;
    }
    if (t == List<_i54.ChatHistory>) {
      return (data as List)
              .map((e) => deserialize<_i54.ChatHistory>(e))
              .toList()
          as T;
    }
    if (t == List<_i55.ChatSessionSummary>) {
      return (data as List)
              .map((e) => deserialize<_i55.ChatSessionSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i56.AiChatMessage>) {
      return (data as List)
              .map((e) => deserialize<_i56.AiChatMessage>(e))
              .toList()
          as T;
    }
    if (t == List<_i57.ScheduleInfo>) {
      return (data as List)
              .map((e) => deserialize<_i57.ScheduleInfo>(e))
              .toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i5.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i6.AiChatMessage => 'AiChatMessage',
      _i7.AiChatSession => 'AiChatSession',
      _i8.ChatHistory => 'ChatHistory',
      _i9.ChatSessionSummary => 'ChatSessionSummary',
      _i10.DashboardStats => 'DashboardStats',
      _i11.DayOfWeek => 'DayOfWeek',
      _i12.DistributionData => 'DistributionData',
      _i13.EmploymentStatus => 'EmploymentStatus',
      _i14.Faculty => 'Faculty',
      _i15.FacultyAvailability => 'FacultyAvailability',
      _i16.FacultyLoadData => 'FacultyLoadData',
      _i17.FacultyShiftPreference => 'FacultyShiftPreference',
      _i18.GenerateScheduleRequest => 'GenerateScheduleRequest',
      _i19.GenerateScheduleResponse => 'GenerateScheduleResponse',
      _i20.Greeting => 'Greeting',
      _i21.NLPIntent => 'NLPIntent',
      _i22.NLPResponse => 'NLPResponse',
      _i23.Program => 'Program',
      _i24.ConflictSummaryReport => 'ConflictSummaryReport',
      _i25.FacultyLoadReport => 'FacultyLoadReport',
      _i26.RoomUtilizationReport => 'RoomUtilizationReport',
      _i27.ScheduleOverviewReport => 'ScheduleOverviewReport',
      _i28.Room => 'Room',
      _i29.RoomType => 'RoomType',
      _i30.Schedule => 'Schedule',
      _i31.ScheduleConflict => 'ScheduleConflict',
      _i32.ScheduleInfo => 'ScheduleInfo',
      _i33.Section => 'Section',
      _i34.Student => 'Student',
      _i35.StudentAcademicStatus => 'StudentAcademicStatus',
      _i36.Subject => 'Subject',
      _i37.SubjectType => 'SubjectType',
      _i38.Timeslot => 'Timeslot',
      _i39.TimetableFilterRequest => 'TimetableFilterRequest',
      _i40.TimetableSummary => 'TimetableSummary',
      _i41.UserRole => 'UserRole',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('citesched.', '');
    }

    switch (data) {
      case _i6.AiChatMessage():
        return 'AiChatMessage';
      case _i7.AiChatSession():
        return 'AiChatSession';
      case _i8.ChatHistory():
        return 'ChatHistory';
      case _i9.ChatSessionSummary():
        return 'ChatSessionSummary';
      case _i10.DashboardStats():
        return 'DashboardStats';
      case _i11.DayOfWeek():
        return 'DayOfWeek';
      case _i12.DistributionData():
        return 'DistributionData';
      case _i13.EmploymentStatus():
        return 'EmploymentStatus';
      case _i14.Faculty():
        return 'Faculty';
      case _i15.FacultyAvailability():
        return 'FacultyAvailability';
      case _i16.FacultyLoadData():
        return 'FacultyLoadData';
      case _i17.FacultyShiftPreference():
        return 'FacultyShiftPreference';
      case _i18.GenerateScheduleRequest():
        return 'GenerateScheduleRequest';
      case _i19.GenerateScheduleResponse():
        return 'GenerateScheduleResponse';
      case _i20.Greeting():
        return 'Greeting';
      case _i21.NLPIntent():
        return 'NLPIntent';
      case _i22.NLPResponse():
        return 'NLPResponse';
      case _i23.Program():
        return 'Program';
      case _i24.ConflictSummaryReport():
        return 'ConflictSummaryReport';
      case _i25.FacultyLoadReport():
        return 'FacultyLoadReport';
      case _i26.RoomUtilizationReport():
        return 'RoomUtilizationReport';
      case _i27.ScheduleOverviewReport():
        return 'ScheduleOverviewReport';
      case _i28.Room():
        return 'Room';
      case _i29.RoomType():
        return 'RoomType';
      case _i30.Schedule():
        return 'Schedule';
      case _i31.ScheduleConflict():
        return 'ScheduleConflict';
      case _i32.ScheduleInfo():
        return 'ScheduleInfo';
      case _i33.Section():
        return 'Section';
      case _i34.Student():
        return 'Student';
      case _i35.StudentAcademicStatus():
        return 'StudentAcademicStatus';
      case _i36.Subject():
        return 'Subject';
      case _i37.SubjectType():
        return 'SubjectType';
      case _i38.Timeslot():
        return 'Timeslot';
      case _i39.TimetableFilterRequest():
        return 'TimetableFilterRequest';
      case _i40.TimetableSummary():
        return 'TimetableSummary';
      case _i41.UserRole():
        return 'UserRole';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth.$className';
    }
    className = _i5.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AiChatMessage') {
      return deserialize<_i6.AiChatMessage>(data['data']);
    }
    if (dataClassName == 'AiChatSession') {
      return deserialize<_i7.AiChatSession>(data['data']);
    }
    if (dataClassName == 'ChatHistory') {
      return deserialize<_i8.ChatHistory>(data['data']);
    }
    if (dataClassName == 'ChatSessionSummary') {
      return deserialize<_i9.ChatSessionSummary>(data['data']);
    }
    if (dataClassName == 'DashboardStats') {
      return deserialize<_i10.DashboardStats>(data['data']);
    }
    if (dataClassName == 'DayOfWeek') {
      return deserialize<_i11.DayOfWeek>(data['data']);
    }
    if (dataClassName == 'DistributionData') {
      return deserialize<_i12.DistributionData>(data['data']);
    }
    if (dataClassName == 'EmploymentStatus') {
      return deserialize<_i13.EmploymentStatus>(data['data']);
    }
    if (dataClassName == 'Faculty') {
      return deserialize<_i14.Faculty>(data['data']);
    }
    if (dataClassName == 'FacultyAvailability') {
      return deserialize<_i15.FacultyAvailability>(data['data']);
    }
    if (dataClassName == 'FacultyLoadData') {
      return deserialize<_i16.FacultyLoadData>(data['data']);
    }
    if (dataClassName == 'FacultyShiftPreference') {
      return deserialize<_i17.FacultyShiftPreference>(data['data']);
    }
    if (dataClassName == 'GenerateScheduleRequest') {
      return deserialize<_i18.GenerateScheduleRequest>(data['data']);
    }
    if (dataClassName == 'GenerateScheduleResponse') {
      return deserialize<_i19.GenerateScheduleResponse>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i20.Greeting>(data['data']);
    }
    if (dataClassName == 'NLPIntent') {
      return deserialize<_i21.NLPIntent>(data['data']);
    }
    if (dataClassName == 'NLPResponse') {
      return deserialize<_i22.NLPResponse>(data['data']);
    }
    if (dataClassName == 'Program') {
      return deserialize<_i23.Program>(data['data']);
    }
    if (dataClassName == 'ConflictSummaryReport') {
      return deserialize<_i24.ConflictSummaryReport>(data['data']);
    }
    if (dataClassName == 'FacultyLoadReport') {
      return deserialize<_i25.FacultyLoadReport>(data['data']);
    }
    if (dataClassName == 'RoomUtilizationReport') {
      return deserialize<_i26.RoomUtilizationReport>(data['data']);
    }
    if (dataClassName == 'ScheduleOverviewReport') {
      return deserialize<_i27.ScheduleOverviewReport>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_i28.Room>(data['data']);
    }
    if (dataClassName == 'RoomType') {
      return deserialize<_i29.RoomType>(data['data']);
    }
    if (dataClassName == 'Schedule') {
      return deserialize<_i30.Schedule>(data['data']);
    }
    if (dataClassName == 'ScheduleConflict') {
      return deserialize<_i31.ScheduleConflict>(data['data']);
    }
    if (dataClassName == 'ScheduleInfo') {
      return deserialize<_i32.ScheduleInfo>(data['data']);
    }
    if (dataClassName == 'Section') {
      return deserialize<_i33.Section>(data['data']);
    }
    if (dataClassName == 'Student') {
      return deserialize<_i34.Student>(data['data']);
    }
    if (dataClassName == 'StudentAcademicStatus') {
      return deserialize<_i35.StudentAcademicStatus>(data['data']);
    }
    if (dataClassName == 'Subject') {
      return deserialize<_i36.Subject>(data['data']);
    }
    if (dataClassName == 'SubjectType') {
      return deserialize<_i37.SubjectType>(data['data']);
    }
    if (dataClassName == 'Timeslot') {
      return deserialize<_i38.Timeslot>(data['data']);
    }
    if (dataClassName == 'TimetableFilterRequest') {
      return deserialize<_i39.TimetableFilterRequest>(data['data']);
    }
    if (dataClassName == 'TimetableSummary') {
      return deserialize<_i40.TimetableSummary>(data['data']);
    }
    if (dataClassName == 'UserRole') {
      return deserialize<_i41.UserRole>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth.')) {
      data['className'] = dataClassName.substring(15);
      return _i4.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i5.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i5.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i6.AiChatMessage:
        return _i6.AiChatMessage.t;
      case _i7.AiChatSession:
        return _i7.AiChatSession.t;
      case _i8.ChatHistory:
        return _i8.ChatHistory.t;
      case _i14.Faculty:
        return _i14.Faculty.t;
      case _i15.FacultyAvailability:
        return _i15.FacultyAvailability.t;
      case _i28.Room:
        return _i28.Room.t;
      case _i30.Schedule:
        return _i30.Schedule.t;
      case _i33.Section:
        return _i33.Section.t;
      case _i34.Student:
        return _i34.Student.t;
      case _i36.Subject:
        return _i36.Subject.t;
      case _i38.Timeslot:
        return _i38.Timeslot.t;
      case _i41.UserRole:
        return _i41.UserRole.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'citesched';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i5.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
