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
import 'day_of_week.dart' as _i2;

abstract class Timeslot
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Timeslot._({
    this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Timeslot({
    int? id,
    required _i2.DayOfWeek day,
    required String startTime,
    required String endTime,
    required String label,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TimeslotImpl;

  factory Timeslot.fromJson(Map<String, dynamic> jsonSerialization) {
    return Timeslot(
      id: jsonSerialization['id'] as int?,
      day: _i2.DayOfWeek.fromJson((jsonSerialization['day'] as String)),
      startTime: jsonSerialization['startTime'] as String,
      endTime: jsonSerialization['endTime'] as String,
      label: jsonSerialization['label'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = TimeslotTable();

  static const db = TimeslotRepository._();

  @override
  int? id;

  _i2.DayOfWeek day;

  String startTime;

  String endTime;

  String label;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Timeslot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Timeslot copyWith({
    int? id,
    _i2.DayOfWeek? day,
    String? startTime,
    String? endTime,
    String? label,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Timeslot',
      if (id != null) 'id': id,
      'day': day.toJson(),
      'startTime': startTime,
      'endTime': endTime,
      'label': label,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Timeslot',
      if (id != null) 'id': id,
      'day': day.toJson(),
      'startTime': startTime,
      'endTime': endTime,
      'label': label,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static TimeslotInclude include() {
    return TimeslotInclude._();
  }

  static TimeslotIncludeList includeList({
    _i1.WhereExpressionBuilder<TimeslotTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TimeslotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TimeslotTable>? orderByList,
    TimeslotInclude? include,
  }) {
    return TimeslotIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Timeslot.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Timeslot.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TimeslotImpl extends Timeslot {
  _TimeslotImpl({
    int? id,
    required _i2.DayOfWeek day,
    required String startTime,
    required String endTime,
    required String label,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         day: day,
         startTime: startTime,
         endTime: endTime,
         label: label,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Timeslot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Timeslot copyWith({
    Object? id = _Undefined,
    _i2.DayOfWeek? day,
    String? startTime,
    String? endTime,
    String? label,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Timeslot(
      id: id is int? ? id : this.id,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TimeslotUpdateTable extends _i1.UpdateTable<TimeslotTable> {
  TimeslotUpdateTable(super.table);

  _i1.ColumnValue<_i2.DayOfWeek, _i2.DayOfWeek> day(_i2.DayOfWeek value) =>
      _i1.ColumnValue(
        table.day,
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

  _i1.ColumnValue<String, String> label(String value) => _i1.ColumnValue(
    table.label,
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

class TimeslotTable extends _i1.Table<int?> {
  TimeslotTable({super.tableRelation}) : super(tableName: 'timeslot') {
    updateTable = TimeslotUpdateTable(this);
    day = _i1.ColumnEnum(
      'day',
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
    label = _i1.ColumnString(
      'label',
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

  late final TimeslotUpdateTable updateTable;

  late final _i1.ColumnEnum<_i2.DayOfWeek> day;

  late final _i1.ColumnString startTime;

  late final _i1.ColumnString endTime;

  late final _i1.ColumnString label;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    day,
    startTime,
    endTime,
    label,
    createdAt,
    updatedAt,
  ];
}

class TimeslotInclude extends _i1.IncludeObject {
  TimeslotInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Timeslot.t;
}

class TimeslotIncludeList extends _i1.IncludeList {
  TimeslotIncludeList._({
    _i1.WhereExpressionBuilder<TimeslotTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Timeslot.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Timeslot.t;
}

class TimeslotRepository {
  const TimeslotRepository._();

  /// Returns a list of [Timeslot]s matching the given query parameters.
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
  Future<List<Timeslot>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TimeslotTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TimeslotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TimeslotTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Timeslot>(
      where: where?.call(Timeslot.t),
      orderBy: orderBy?.call(Timeslot.t),
      orderByList: orderByList?.call(Timeslot.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Timeslot] matching the given query parameters.
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
  Future<Timeslot?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TimeslotTable>? where,
    int? offset,
    _i1.OrderByBuilder<TimeslotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TimeslotTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Timeslot>(
      where: where?.call(Timeslot.t),
      orderBy: orderBy?.call(Timeslot.t),
      orderByList: orderByList?.call(Timeslot.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Timeslot] by its [id] or null if no such row exists.
  Future<Timeslot?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Timeslot>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Timeslot]s in the list and returns the inserted rows.
  ///
  /// The returned [Timeslot]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Timeslot>> insert(
    _i1.Session session,
    List<Timeslot> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Timeslot>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Timeslot] and returns the inserted row.
  ///
  /// The returned [Timeslot] will have its `id` field set.
  Future<Timeslot> insertRow(
    _i1.Session session,
    Timeslot row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Timeslot>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Timeslot]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Timeslot>> update(
    _i1.Session session,
    List<Timeslot> rows, {
    _i1.ColumnSelections<TimeslotTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Timeslot>(
      rows,
      columns: columns?.call(Timeslot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Timeslot]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Timeslot> updateRow(
    _i1.Session session,
    Timeslot row, {
    _i1.ColumnSelections<TimeslotTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Timeslot>(
      row,
      columns: columns?.call(Timeslot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Timeslot] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Timeslot?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<TimeslotUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Timeslot>(
      id,
      columnValues: columnValues(Timeslot.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Timeslot]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Timeslot>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<TimeslotUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TimeslotTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TimeslotTable>? orderBy,
    _i1.OrderByListBuilder<TimeslotTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Timeslot>(
      columnValues: columnValues(Timeslot.t.updateTable),
      where: where(Timeslot.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Timeslot.t),
      orderByList: orderByList?.call(Timeslot.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Timeslot]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Timeslot>> delete(
    _i1.Session session,
    List<Timeslot> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Timeslot>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Timeslot].
  Future<Timeslot> deleteRow(
    _i1.Session session,
    Timeslot row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Timeslot>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Timeslot>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<TimeslotTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Timeslot>(
      where: where(Timeslot.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<TimeslotTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Timeslot>(
      where: where?.call(Timeslot.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
