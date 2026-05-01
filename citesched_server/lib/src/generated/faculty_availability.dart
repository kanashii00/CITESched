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
import 'faculty.dart' as _i2;
import 'day_of_week.dart' as _i3;
import 'package:citesched_server/src/generated/protocol.dart' as _i4;

abstract class FacultyAvailability
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  FacultyAvailability._({
    this.id,
    required this.facultyId,
    this.faculty,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isPreferred,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FacultyAvailability({
    int? id,
    required int facultyId,
    _i2.Faculty? faculty,
    required _i3.DayOfWeek dayOfWeek,
    required String startTime,
    required String endTime,
    required bool isPreferred,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FacultyAvailabilityImpl;

  factory FacultyAvailability.fromJson(Map<String, dynamic> jsonSerialization) {
    return FacultyAvailability(
      id: jsonSerialization['id'] as int?,
      facultyId: jsonSerialization['facultyId'] as int,
      faculty: jsonSerialization['faculty'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.Faculty>(
              jsonSerialization['faculty'],
            ),
      dayOfWeek: _i3.DayOfWeek.fromJson(
        (jsonSerialization['dayOfWeek'] as String),
      ),
      startTime: jsonSerialization['startTime'] as String,
      endTime: jsonSerialization['endTime'] as String,
      isPreferred: jsonSerialization['isPreferred'] as bool,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = FacultyAvailabilityTable();

  static const db = FacultyAvailabilityRepository._();

  @override
  int? id;

  int facultyId;

  _i2.Faculty? faculty;

  _i3.DayOfWeek dayOfWeek;

  String startTime;

  String endTime;

  bool isPreferred;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [FacultyAvailability]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  FacultyAvailability copyWith({
    int? id,
    int? facultyId,
    _i2.Faculty? faculty,
    _i3.DayOfWeek? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isPreferred,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'FacultyAvailability',
      if (id != null) 'id': id,
      'facultyId': facultyId,
      if (faculty != null) 'faculty': faculty?.toJson(),
      'dayOfWeek': dayOfWeek.toJson(),
      'startTime': startTime,
      'endTime': endTime,
      'isPreferred': isPreferred,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'FacultyAvailability',
      if (id != null) 'id': id,
      'facultyId': facultyId,
      if (faculty != null) 'faculty': faculty?.toJsonForProtocol(),
      'dayOfWeek': dayOfWeek.toJson(),
      'startTime': startTime,
      'endTime': endTime,
      'isPreferred': isPreferred,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static FacultyAvailabilityInclude include({_i2.FacultyInclude? faculty}) {
    return FacultyAvailabilityInclude._(faculty: faculty);
  }

  static FacultyAvailabilityIncludeList includeList({
    _i1.WhereExpressionBuilder<FacultyAvailabilityTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FacultyAvailabilityTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FacultyAvailabilityTable>? orderByList,
    FacultyAvailabilityInclude? include,
  }) {
    return FacultyAvailabilityIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FacultyAvailability.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(FacultyAvailability.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FacultyAvailabilityImpl extends FacultyAvailability {
  _FacultyAvailabilityImpl({
    int? id,
    required int facultyId,
    _i2.Faculty? faculty,
    required _i3.DayOfWeek dayOfWeek,
    required String startTime,
    required String endTime,
    required bool isPreferred,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         facultyId: facultyId,
         faculty: faculty,
         dayOfWeek: dayOfWeek,
         startTime: startTime,
         endTime: endTime,
         isPreferred: isPreferred,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [FacultyAvailability]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  FacultyAvailability copyWith({
    Object? id = _Undefined,
    int? facultyId,
    Object? faculty = _Undefined,
    _i3.DayOfWeek? dayOfWeek,
    String? startTime,
    String? endTime,
    bool? isPreferred,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FacultyAvailability(
      id: id is int? ? id : this.id,
      facultyId: facultyId ?? this.facultyId,
      faculty: faculty is _i2.Faculty? ? faculty : this.faculty?.copyWith(),
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isPreferred: isPreferred ?? this.isPreferred,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FacultyAvailabilityUpdateTable
    extends _i1.UpdateTable<FacultyAvailabilityTable> {
  FacultyAvailabilityUpdateTable(super.table);

  _i1.ColumnValue<int, int> facultyId(int value) => _i1.ColumnValue(
    table.facultyId,
    value,
  );

  _i1.ColumnValue<_i3.DayOfWeek, _i3.DayOfWeek> dayOfWeek(
    _i3.DayOfWeek value,
  ) => _i1.ColumnValue(
    table.dayOfWeek,
    value,
  );

  _i1.ColumnValue<String, String> startTime(String value) => _i1.ColumnValue(
    table.startTime,
    value,
  );

  _i1.ColumnValue<String, String> endTime(String value) => _i1.ColumnValue(
    table.endTime,
    value,
  );

  _i1.ColumnValue<bool, bool> isPreferred(bool value) => _i1.ColumnValue(
    table.isPreferred,
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

class FacultyAvailabilityTable extends _i1.Table<int?> {
  FacultyAvailabilityTable({super.tableRelation})
    : super(tableName: 'faculty_availability') {
    updateTable = FacultyAvailabilityUpdateTable(this);
    facultyId = _i1.ColumnInt(
      'facultyId',
      this,
    );
    dayOfWeek = _i1.ColumnEnum(
      'dayOfWeek',
      this,
      _i1.EnumSerialization.byName,
    );
    startTime = _i1.ColumnString(
      'startTime',
      this,
    );
    endTime = _i1.ColumnString(
      'endTime',
      this,
    );
    isPreferred = _i1.ColumnBool(
      'isPreferred',
      this,
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

  late final FacultyAvailabilityUpdateTable updateTable;

  late final _i1.ColumnInt facultyId;

  _i2.FacultyTable? _faculty;

  late final _i1.ColumnEnum<_i3.DayOfWeek> dayOfWeek;

  late final _i1.ColumnString startTime;

  late final _i1.ColumnString endTime;

  late final _i1.ColumnBool isPreferred;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  _i2.FacultyTable get faculty {
    if (_faculty != null) return _faculty!;
    _faculty = _i1.createRelationTable(
      relationFieldName: 'faculty',
      field: FacultyAvailability.t.facultyId,
      foreignField: _i2.Faculty.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.FacultyTable(tableRelation: foreignTableRelation),
    );
    return _faculty!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    facultyId,
    dayOfWeek,
    startTime,
    endTime,
    isPreferred,
    createdAt,
    updatedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'faculty') {
      return faculty;
    }
    return null;
  }
}

class FacultyAvailabilityInclude extends _i1.IncludeObject {
  FacultyAvailabilityInclude._({_i2.FacultyInclude? faculty}) {
    _faculty = faculty;
  }

  _i2.FacultyInclude? _faculty;

  @override
  Map<String, _i1.Include?> get includes => {'faculty': _faculty};

  @override
  _i1.Table<int?> get table => FacultyAvailability.t;
}

class FacultyAvailabilityIncludeList extends _i1.IncludeList {
  FacultyAvailabilityIncludeList._({
    _i1.WhereExpressionBuilder<FacultyAvailabilityTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(FacultyAvailability.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => FacultyAvailability.t;
}

class FacultyAvailabilityRepository {
  const FacultyAvailabilityRepository._();

  final attachRow = const FacultyAvailabilityAttachRowRepository._();

  /// Returns a list of [FacultyAvailability]s matching the given query parameters.
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
  Future<List<FacultyAvailability>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FacultyAvailabilityTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FacultyAvailabilityTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FacultyAvailabilityTable>? orderByList,
    _i1.Transaction? transaction,
    FacultyAvailabilityInclude? include,
  }) async {
    return session.db.find<FacultyAvailability>(
      where: where?.call(FacultyAvailability.t),
      orderBy: orderBy?.call(FacultyAvailability.t),
      orderByList: orderByList?.call(FacultyAvailability.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
    );
  }

  /// Returns the first matching [FacultyAvailability] matching the given query parameters.
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
  Future<FacultyAvailability?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FacultyAvailabilityTable>? where,
    int? offset,
    _i1.OrderByBuilder<FacultyAvailabilityTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FacultyAvailabilityTable>? orderByList,
    _i1.Transaction? transaction,
    FacultyAvailabilityInclude? include,
  }) async {
    return session.db.findFirstRow<FacultyAvailability>(
      where: where?.call(FacultyAvailability.t),
      orderBy: orderBy?.call(FacultyAvailability.t),
      orderByList: orderByList?.call(FacultyAvailability.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
    );
  }

  /// Finds a single [FacultyAvailability] by its [id] or null if no such row exists.
  Future<FacultyAvailability?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    FacultyAvailabilityInclude? include,
  }) async {
    return session.db.findById<FacultyAvailability>(
      id,
      transaction: transaction,
      include: include,
    );
  }

  /// Inserts all [FacultyAvailability]s in the list and returns the inserted rows.
  ///
  /// The returned [FacultyAvailability]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<FacultyAvailability>> insert(
    _i1.Session session,
    List<FacultyAvailability> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<FacultyAvailability>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [FacultyAvailability] and returns the inserted row.
  ///
  /// The returned [FacultyAvailability] will have its `id` field set.
  Future<FacultyAvailability> insertRow(
    _i1.Session session,
    FacultyAvailability row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<FacultyAvailability>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [FacultyAvailability]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<FacultyAvailability>> update(
    _i1.Session session,
    List<FacultyAvailability> rows, {
    _i1.ColumnSelections<FacultyAvailabilityTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<FacultyAvailability>(
      rows,
      columns: columns?.call(FacultyAvailability.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FacultyAvailability]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<FacultyAvailability> updateRow(
    _i1.Session session,
    FacultyAvailability row, {
    _i1.ColumnSelections<FacultyAvailabilityTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<FacultyAvailability>(
      row,
      columns: columns?.call(FacultyAvailability.t),
      transaction: transaction,
    );
  }

  /// Updates a single [FacultyAvailability] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<FacultyAvailability?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<FacultyAvailabilityUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<FacultyAvailability>(
      id,
      columnValues: columnValues(FacultyAvailability.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [FacultyAvailability]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<FacultyAvailability>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<FacultyAvailabilityUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<FacultyAvailabilityTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FacultyAvailabilityTable>? orderBy,
    _i1.OrderByListBuilder<FacultyAvailabilityTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<FacultyAvailability>(
      columnValues: columnValues(FacultyAvailability.t.updateTable),
      where: where(FacultyAvailability.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(FacultyAvailability.t),
      orderByList: orderByList?.call(FacultyAvailability.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [FacultyAvailability]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<FacultyAvailability>> delete(
    _i1.Session session,
    List<FacultyAvailability> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<FacultyAvailability>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [FacultyAvailability].
  Future<FacultyAvailability> deleteRow(
    _i1.Session session,
    FacultyAvailability row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<FacultyAvailability>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<FacultyAvailability>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<FacultyAvailabilityTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<FacultyAvailability>(
      where: where(FacultyAvailability.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FacultyAvailabilityTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<FacultyAvailability>(
      where: where?.call(FacultyAvailability.t),
      limit: limit,
      transaction: transaction,
    );
  }
}

class FacultyAvailabilityAttachRowRepository {
  const FacultyAvailabilityAttachRowRepository._();

  /// Creates a relation between the given [FacultyAvailability] and [Faculty]
  /// by setting the [FacultyAvailability]'s foreign key `facultyId` to refer to the [Faculty].
  Future<void> faculty(
    _i1.Session session,
    FacultyAvailability facultyAvailability,
    _i2.Faculty faculty, {
    _i1.Transaction? transaction,
  }) async {
    if (facultyAvailability.id == null) {
      throw ArgumentError.notNull('facultyAvailability.id');
    }
    if (faculty.id == null) {
      throw ArgumentError.notNull('faculty.id');
    }

    var $facultyAvailability = facultyAvailability.copyWith(
      facultyId: faculty.id,
    );
    await session.db.updateRow<FacultyAvailability>(
      $facultyAvailability,
      columns: [FacultyAvailability.t.facultyId],
      transaction: transaction,
    );
  }
}
