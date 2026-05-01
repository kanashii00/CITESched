/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import 'subject.dart' as _i2;
import 'faculty.dart' as _i3;
import 'room.dart' as _i4;
import 'timeslot.dart' as _i5;
import 'section.dart' as _i6;
import 'subject_type.dart' as _i7;
import 'package:citesched_server/src/generated/protocol.dart' as _i8;

abstract class Schedule
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Schedule._({
    this.id,
    required this.subjectId,
    this.subject,
    required this.facultyId,
    this.faculty,
    this.roomId,
    this.room,
    this.timeslotId,
    this.timeslot,
    required this.section,
    this.sectionId,
    this.sectionRef,
    this.loadTypes,
    this.units,
    this.hours,
    bool? isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : isActive = isActive ?? true;

  factory Schedule({
    int? id,
    required int subjectId,
    _i2.Subject? subject,
    required int facultyId,
    _i3.Faculty? faculty,
    int? roomId,
    _i4.Room? room,
    int? timeslotId,
    _i5.Timeslot? timeslot,
    required String section,
    int? sectionId,
    _i6.Section? sectionRef,
    List<_i7.SubjectType>? loadTypes,
    double? units,
    double? hours,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ScheduleImpl;

  factory Schedule.fromJson(Map<String, dynamic> jsonSerialization) {
    return Schedule(
      id: jsonSerialization['id'] as int?,
      subjectId: jsonSerialization['subjectId'] as int,
      subject: jsonSerialization['subject'] == null
          ? null
          : _i8.Protocol().deserialize<_i2.Subject>(
              jsonSerialization['subject'],
            ),
      facultyId: jsonSerialization['facultyId'] as int,
      faculty: jsonSerialization['faculty'] == null
          ? null
          : _i8.Protocol().deserialize<_i3.Faculty>(
              jsonSerialization['faculty'],
            ),
      roomId: jsonSerialization['roomId'] as int?,
      room: jsonSerialization['room'] == null
          ? null
          : _i8.Protocol().deserialize<_i4.Room>(jsonSerialization['room']),
      timeslotId: jsonSerialization['timeslotId'] as int?,
      timeslot: jsonSerialization['timeslot'] == null
          ? null
          : _i8.Protocol().deserialize<_i5.Timeslot>(
              jsonSerialization['timeslot'],
            ),
      section: jsonSerialization['section'] as String,
      sectionId: jsonSerialization['sectionId'] as int?,
      sectionRef: jsonSerialization['sectionRef'] == null
          ? null
          : _i8.Protocol().deserialize<_i6.Section>(
              jsonSerialization['sectionRef'],
            ),
      loadTypes: jsonSerialization['loadTypes'] == null
          ? null
          : _i8.Protocol().deserialize<List<_i7.SubjectType>>(
              jsonSerialization['loadTypes'],
            ),
      units: (jsonSerialization['units'] as num?)?.toDouble(),
      hours: (jsonSerialization['hours'] as num?)?.toDouble(),
      isActive: jsonSerialization['isActive'] as bool?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = ScheduleTable();

  static const db = ScheduleRepository._();

  @override
  int? id;

  int subjectId;

  _i2.Subject? subject;

  int facultyId;

  _i3.Faculty? faculty;

  int? roomId;

  _i4.Room? room;

  int? timeslotId;

  _i5.Timeslot? timeslot;

  String section;

  int? sectionId;

  _i6.Section? sectionRef;

  List<_i7.SubjectType>? loadTypes;

  double? units;

  double? hours;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Schedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Schedule copyWith({
    int? id,
    int? subjectId,
    _i2.Subject? subject,
    int? facultyId,
    _i3.Faculty? faculty,
    int? roomId,
    _i4.Room? room,
    int? timeslotId,
    _i5.Timeslot? timeslot,
    String? section,
    int? sectionId,
    _i6.Section? sectionRef,
    List<_i7.SubjectType>? loadTypes,
    double? units,
    double? hours,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Schedule',
      if (id != null) 'id': id,
      'subjectId': subjectId,
      if (subject != null) 'subject': subject?.toJson(),
      'facultyId': facultyId,
      if (faculty != null) 'faculty': faculty?.toJson(),
      if (roomId != null) 'roomId': roomId,
      if (room != null) 'room': room?.toJson(),
      if (timeslotId != null) 'timeslotId': timeslotId,
      if (timeslot != null) 'timeslot': timeslot?.toJson(),
      'section': section,
      if (sectionId != null) 'sectionId': sectionId,
      if (sectionRef != null) 'sectionRef': sectionRef?.toJson(),
      if (loadTypes != null)
        'loadTypes': loadTypes?.toJson(valueToJson: (v) => v.toJson()),
      if (units != null) 'units': units,
      if (hours != null) 'hours': hours,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Schedule',
      if (id != null) 'id': id,
      'subjectId': subjectId,
      if (subject != null) 'subject': subject?.toJsonForProtocol(),
      'facultyId': facultyId,
      if (faculty != null) 'faculty': faculty?.toJsonForProtocol(),
      if (roomId != null) 'roomId': roomId,
      if (room != null) 'room': room?.toJsonForProtocol(),
      if (timeslotId != null) 'timeslotId': timeslotId,
      if (timeslot != null) 'timeslot': timeslot?.toJsonForProtocol(),
      'section': section,
      if (sectionId != null) 'sectionId': sectionId,
      if (sectionRef != null) 'sectionRef': sectionRef?.toJsonForProtocol(),
      if (loadTypes != null)
        'loadTypes': loadTypes?.toJson(valueToJson: (v) => v.toJson()),
      if (units != null) 'units': units,
      if (hours != null) 'hours': hours,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static ScheduleInclude include({
    _i2.SubjectInclude? subject,
    _i3.FacultyInclude? faculty,
    _i4.RoomInclude? room,
    _i5.TimeslotInclude? timeslot,
    _i6.SectionInclude? sectionRef,
  }) {
    return ScheduleInclude._(
      subject: subject,
      faculty: faculty,
      room: room,
      timeslot: timeslot,
      sectionRef: sectionRef,
    );
  }

  static ScheduleIncludeList includeList({
    _i1.WhereExpressionBuilder<ScheduleTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ScheduleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ScheduleTable>? orderByList,
    ScheduleInclude? include,
  }) {
    return ScheduleIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Schedule.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Schedule.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ScheduleImpl extends Schedule {
  _ScheduleImpl({
    int? id,
    required int subjectId,
    _i2.Subject? subject,
    required int facultyId,
    _i3.Faculty? faculty,
    int? roomId,
    _i4.Room? room,
    int? timeslotId,
    _i5.Timeslot? timeslot,
    required String section,
    int? sectionId,
    _i6.Section? sectionRef,
    List<_i7.SubjectType>? loadTypes,
    double? units,
    double? hours,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         subjectId: subjectId,
         subject: subject,
         facultyId: facultyId,
         faculty: faculty,
         roomId: roomId,
         room: room,
         timeslotId: timeslotId,
         timeslot: timeslot,
         section: section,
         sectionId: sectionId,
         sectionRef: sectionRef,
         loadTypes: loadTypes,
         units: units,
         hours: hours,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Schedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Schedule copyWith({
    Object? id = _Undefined,
    int? subjectId,
    Object? subject = _Undefined,
    int? facultyId,
    Object? faculty = _Undefined,
    Object? roomId = _Undefined,
    Object? room = _Undefined,
    Object? timeslotId = _Undefined,
    Object? timeslot = _Undefined,
    String? section,
    Object? sectionId = _Undefined,
    Object? sectionRef = _Undefined,
    Object? loadTypes = _Undefined,
    Object? units = _Undefined,
    Object? hours = _Undefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id is int? ? id : this.id,
      subjectId: subjectId ?? this.subjectId,
      subject: subject is _i2.Subject? ? subject : this.subject?.copyWith(),
      facultyId: facultyId ?? this.facultyId,
      faculty: faculty is _i3.Faculty? ? faculty : this.faculty?.copyWith(),
      roomId: roomId is int? ? roomId : this.roomId,
      room: room is _i4.Room? ? room : this.room?.copyWith(),
      timeslotId: timeslotId is int? ? timeslotId : this.timeslotId,
      timeslot: timeslot is _i5.Timeslot?
          ? timeslot
          : this.timeslot?.copyWith(),
      section: section ?? this.section,
      sectionId: sectionId is int? ? sectionId : this.sectionId,
      sectionRef: sectionRef is _i6.Section?
          ? sectionRef
          : this.sectionRef?.copyWith(),
      loadTypes: loadTypes is List<_i7.SubjectType>?
          ? loadTypes
          : this.loadTypes?.map((e0) => e0).toList(),
      units: units is double? ? units : this.units,
      hours: hours is double? ? hours : this.hours,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ScheduleUpdateTable extends _i1.UpdateTable<ScheduleTable> {
  ScheduleUpdateTable(super.table);

  _i1.ColumnValue<int, int> subjectId(int value) => _i1.ColumnValue(
    table.subjectId,
    value,
  );

  _i1.ColumnValue<int, int> facultyId(int value) => _i1.ColumnValue(
    table.facultyId,
    value,
  );

  _i1.ColumnValue<int, int> roomId(int? value) => _i1.ColumnValue(
    table.roomId,
    value,
  );

  _i1.ColumnValue<int, int> timeslotId(int? value) => _i1.ColumnValue(
    table.timeslotId,
    value,
  );

  _i1.ColumnValue<String, String> section(String value) => _i1.ColumnValue(
    table.section,
    value,
  );

  _i1.ColumnValue<int, int> sectionId(int? value) => _i1.ColumnValue(
    table.sectionId,
    value,
  );

  _i1.ColumnValue<List<_i7.SubjectType>, List<_i7.SubjectType>> loadTypes(
    List<_i7.SubjectType>? value,
  ) => _i1.ColumnValue(
    table.loadTypes,
    value,
  );

  _i1.ColumnValue<double, double> units(double? value) => _i1.ColumnValue(
    table.units,
    value,
  );

  _i1.ColumnValue<double, double> hours(double? value) => _i1.ColumnValue(
    table.hours,
    value,
  );

  _i1.ColumnValue<bool, bool> isActive(bool value) => _i1.ColumnValue(
    table.isActive,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class ScheduleTable extends _i1.Table<int?> {
  ScheduleTable({super.tableRelation}) : super(tableName: 'schedule') {
    updateTable = ScheduleUpdateTable(this);
    subjectId = _i1.ColumnInt(
      'subjectId',
      this,
    );
    facultyId = _i1.ColumnInt(
      'facultyId',
      this,
    );
    roomId = _i1.ColumnInt(
      'roomId',
      this,
    );
    timeslotId = _i1.ColumnInt(
      'timeslotId',
      this,
    );
    section = _i1.ColumnString(
      'section',
      this,
    );
    sectionId = _i1.ColumnInt(
      'sectionId',
      this,
    );
    loadTypes = _i1.ColumnSerializable<List<_i7.SubjectType>>(
      'loadTypes',
      this,
    );
    units = _i1.ColumnDouble(
      'units',
      this,
    );
    hours = _i1.ColumnDouble(
      'hours',
      this,
    );
    isActive = _i1.ColumnBool(
      'isActive',
      this,
      hasDefault: true,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final ScheduleUpdateTable updateTable;

  late final _i1.ColumnInt subjectId;

  _i2.SubjectTable? _subject;

  late final _i1.ColumnInt facultyId;

  _i3.FacultyTable? _faculty;

  late final _i1.ColumnInt roomId;

  _i4.RoomTable? _room;

  late final _i1.ColumnInt timeslotId;

  _i5.TimeslotTable? _timeslot;

  late final _i1.ColumnString section;

  late final _i1.ColumnInt sectionId;

  _i6.SectionTable? _sectionRef;

  late final _i1.ColumnSerializable<List<_i7.SubjectType>> loadTypes;

  late final _i1.ColumnDouble units;

  late final _i1.ColumnDouble hours;

  late final _i1.ColumnBool isActive;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  _i2.SubjectTable get subject {
    if (_subject != null) return _subject!;
    _subject = _i1.createRelationTable(
      relationFieldName: 'subject',
      field: Schedule.t.subjectId,
      foreignField: _i2.Subject.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.SubjectTable(tableRelation: foreignTableRelation),
    );
    return _subject!;
  }

  _i3.FacultyTable get faculty {
    if (_faculty != null) return _faculty!;
    _faculty = _i1.createRelationTable(
      relationFieldName: 'faculty',
      field: Schedule.t.facultyId,
      foreignField: _i3.Faculty.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.FacultyTable(tableRelation: foreignTableRelation),
    );
    return _faculty!;
  }

  _i4.RoomTable get room {
    if (_room != null) return _room!;
    _room = _i1.createRelationTable(
      relationFieldName: 'room',
      field: Schedule.t.roomId,
      foreignField: _i4.Room.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.RoomTable(tableRelation: foreignTableRelation),
    );
    return _room!;
  }

  _i5.TimeslotTable get timeslot {
    if (_timeslot != null) return _timeslot!;
    _timeslot = _i1.createRelationTable(
      relationFieldName: 'timeslot',
      field: Schedule.t.timeslotId,
      foreignField: _i5.Timeslot.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i5.TimeslotTable(tableRelation: foreignTableRelation),
    );
    return _timeslot!;
  }

  _i6.SectionTable get sectionRef {
    if (_sectionRef != null) return _sectionRef!;
    _sectionRef = _i1.createRelationTable(
      relationFieldName: 'sectionRef',
      field: Schedule.t.sectionId,
      foreignField: _i6.Section.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i6.SectionTable(tableRelation: foreignTableRelation),
    );
    return _sectionRef!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    subjectId,
    facultyId,
    roomId,
    timeslotId,
    section,
    sectionId,
    loadTypes,
    units,
    hours,
    isActive,
    createdAt,
    updatedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'subject') {
      return subject;
    }
    if (relationField == 'faculty') {
      return faculty;
    }
    if (relationField == 'room') {
      return room;
    }
    if (relationField == 'timeslot') {
      return timeslot;
    }
    if (relationField == 'sectionRef') {
      return sectionRef;
    }
    return null;
  }
}

class ScheduleInclude extends _i1.IncludeObject {
  ScheduleInclude._({
    _i2.SubjectInclude? subject,
    _i3.FacultyInclude? faculty,
    _i4.RoomInclude? room,
    _i5.TimeslotInclude? timeslot,
    _i6.SectionInclude? sectionRef,
  }) {
    _subject = subject;
    _faculty = faculty;
    _room = room;
    _timeslot = timeslot;
    _sectionRef = sectionRef;
  }

  _i2.SubjectInclude? _subject;

  _i3.FacultyInclude? _faculty;

  _i4.RoomInclude? _room;

  _i5.TimeslotInclude? _timeslot;

  _i6.SectionInclude? _sectionRef;

  @override
  Map<String, _i1.Include?> get includes => {
    'subject': _subject,
    'faculty': _faculty,
    'room': _room,
    'timeslot': _timeslot,
    'sectionRef': _sectionRef,
  };

  @override
  _i1.Table<int?> get table => Schedule.t;
}

class ScheduleIncludeList extends _i1.IncludeList {
  ScheduleIncludeList._({
    _i1.WhereExpressionBuilder<ScheduleTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Schedule.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Schedule.t;
}

class ScheduleRepository {
  const ScheduleRepository._();

  final attachRow = const ScheduleAttachRowRepository._();

  final detachRow = const ScheduleDetachRowRepository._();

  /// Returns a list of [Schedule]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Schedule>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ScheduleTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ScheduleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ScheduleTable>? orderByList,
    _i1.Transaction? transaction,
    ScheduleInclude? include,
  }) async {
    return session.db.find<Schedule>(
      where: where?.call(Schedule.t),
      orderBy: orderBy?.call(Schedule.t),
      orderByList: orderByList?.call(Schedule.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
    );
  }

  /// Returns the first matching [Schedule] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Schedule?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ScheduleTable>? where,
    int? offset,
    _i1.OrderByBuilder<ScheduleTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ScheduleTable>? orderByList,
    _i1.Transaction? transaction,
    ScheduleInclude? include,
  }) async {
    return session.db.findFirstRow<Schedule>(
      where: where?.call(Schedule.t),
      orderBy: orderBy?.call(Schedule.t),
      orderByList: orderByList?.call(Schedule.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
    );
  }

  /// Finds a single [Schedule] by its [id] or null if no such row exists.
  Future<Schedule?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    ScheduleInclude? include,
  }) async {
    return session.db.findById<Schedule>(
      id,
      transaction: transaction,
      include: include,
    );
  }

  /// Inserts all [Schedule]s in the list and returns the inserted rows.
  ///
  /// The returned [Schedule]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Schedule>> insert(
    _i1.Session session,
    List<Schedule> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Schedule>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Schedule] and returns the inserted row.
  ///
  /// The returned [Schedule] will have its `id` field set.
  Future<Schedule> insertRow(
    _i1.Session session,
    Schedule row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Schedule>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Schedule]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Schedule>> update(
    _i1.Session session,
    List<Schedule> rows, {
    _i1.ColumnSelections<ScheduleTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Schedule>(
      rows,
      columns: columns?.call(Schedule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Schedule]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Schedule> updateRow(
    _i1.Session session,
    Schedule row, {
    _i1.ColumnSelections<ScheduleTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Schedule>(
      row,
      columns: columns?.call(Schedule.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Schedule] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Schedule?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<ScheduleUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Schedule>(
      id,
      columnValues: columnValues(Schedule.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Schedule]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Schedule>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<ScheduleUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ScheduleTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ScheduleTable>? orderBy,
    _i1.OrderByListBuilder<ScheduleTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Schedule>(
      columnValues: columnValues(Schedule.t.updateTable),
      where: where(Schedule.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Schedule.t),
      orderByList: orderByList?.call(Schedule.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Schedule]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Schedule>> delete(
    _i1.Session session,
    List<Schedule> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Schedule>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Schedule].
  Future<Schedule> deleteRow(
    _i1.Session session,
    Schedule row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Schedule>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Schedule>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<ScheduleTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Schedule>(
      where: where(Schedule.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<ScheduleTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Schedule>(
      where: where?.call(Schedule.t),
      limit: limit,
      transaction: transaction,
    );
  }
}

class ScheduleAttachRowRepository {
  const ScheduleAttachRowRepository._();

  /// Creates a relation between the given [Schedule] and [Subject]
  /// by setting the [Schedule]'s foreign key `subjectId` to refer to the [Subject].
  Future<void> subject(
    _i1.Session session,
    Schedule schedule,
    _i2.Subject subject, {
    _i1.Transaction? transaction,
  }) async {
    if (schedule.id == null) {
      throw ArgumentError.notNull('schedule.id');
    }
    if (subject.id == null) {
      throw ArgumentError.notNull('subject.id');
    }

    var $schedule = schedule.copyWith(subjectId: subject.id);
    await session.db.updateRow<Schedule>(
      $schedule,
      columns: [Schedule.t.subjectId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [Schedule] and [Faculty]
  /// by setting the [Schedule]'s foreign key `facultyId` to refer to the [Faculty].
  Future<void> faculty(
    _i1.Session session,
    Schedule schedule,
    _i3.Faculty faculty, {
    _i1.Transaction? transaction,
  }) async {
    if (schedule.id == null) {
      throw ArgumentError.notNull('schedule.id');
    }
    if (faculty.id == null) {
      throw ArgumentError.notNull('faculty.id');
    }

    var $schedule = schedule.copyWith(facultyId: faculty.id);
    await session.db.updateRow<Schedule>(
      $schedule,
      columns: [Schedule.t.facultyId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [Schedule] and [Room]
  /// by setting the [Schedule]'s foreign key `roomId` to refer to the [Room].
  Future<void> room(
    _i1.Session session,
    Schedule schedule,
    _i4.Room room, {
    _i1.Transaction? transaction,
  }) async {
    if (schedule.id == null) {
      throw ArgumentError.notNull('schedule.id');
    }
    if (room.id == null) {
      throw ArgumentError.notNull('room.id');
    }

    var $schedule = schedule.copyWith(roomId: room.id);
    await session.db.updateRow<Schedule>(
      $schedule,
      columns: [Schedule.t.roomId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [Schedule] and [Timeslot]
  /// by setting the [Schedule]'s foreign key `timeslotId` to refer to the [Timeslot].
  Future<void> timeslot(
    _i1.Session session,
    Schedule schedule,
    _i5.Timeslot timeslot, {
    _i1.Transaction? transaction,
  }) async {
    if (schedule.id == null) {
      throw ArgumentError.notNull('schedule.id');
    }
    if (timeslot.id == null) {
      throw ArgumentError.notNull('timeslot.id');
    }

    var $schedule = schedule.copyWith(timeslotId: timeslot.id);
    await session.db.updateRow<Schedule>(
      $schedule,
      columns: [Schedule.t.timeslotId],
      transaction: transaction,
    );
  }

  /// Creates a relation between the given [Schedule] and [Section]
  /// by setting the [Schedule]'s foreign key `sectionId` to refer to the [Section].
  Future<void> sectionRef(
    _i1.Session session,
    Schedule schedule,
    _i6.Section sectionRef, {
    _i1.Transaction? transaction,
  }) async {
    if (schedule.id == null) {
      throw ArgumentError.notNull('schedule.id');
    }
    if (sectionRef.id == null) {
      throw ArgumentError.notNull('sectionRef.id');
    }

    var $schedule = schedule.copyWith(sectionId: sectionRef.id);
    await session.db.updateRow<Schedule>(
      $schedule,
      columns: [Schedule.t.sectionId],
      transaction: transaction,
    );
  }
}

class ScheduleDetachRowRepository {
  const ScheduleDetachRowRepository._();

  /// Detaches the relation between this [Schedule] and the [Room] set in `room`
  /// by setting the [Schedule]'s foreign key `roomId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> room(
    _i1.Session session,
    Schedule schedule, {
    _i1.Transaction? transaction,
  }) async {
    if (schedule.id == null) {
      throw ArgumentError.notNull('schedule.id');
    }

    var $schedule = schedule.copyWith(roomId: null);
    await session.db.updateRow<Schedule>(
      $schedule,
      columns: [Schedule.t.roomId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [Schedule] and the [Timeslot] set in `timeslot`
  /// by setting the [Schedule]'s foreign key `timeslotId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> timeslot(
    _i1.Session session,
    Schedule schedule, {
    _i1.Transaction? transaction,
  }) async {
    if (schedule.id == null) {
      throw ArgumentError.notNull('schedule.id');
    }

    var $schedule = schedule.copyWith(timeslotId: null);
    await session.db.updateRow<Schedule>(
      $schedule,
      columns: [Schedule.t.timeslotId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [Schedule] and the [Section] set in `sectionRef`
  /// by setting the [Schedule]'s foreign key `sectionId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> sectionRef(
    _i1.Session session,
    Schedule schedule, {
    _i1.Transaction? transaction,
  }) async {
    if (schedule.id == null) {
      throw ArgumentError.notNull('schedule.id');
    }

    var $schedule = schedule.copyWith(sectionId: null);
    await session.db.updateRow<Schedule>(
      $schedule,
      columns: [Schedule.t.sectionId],
      transaction: transaction,
    );
  }
}
