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

abstract class AiChatSession
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  AiChatSession._({
    this.id,
    required this.userId,
    required this.roleType,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiChatSession({
    int? id,
    required String userId,
    required String roleType,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AiChatSessionImpl;

  factory AiChatSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiChatSession(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      roleType: jsonSerialization['roleType'] as String,
      title: jsonSerialization['title'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = AiChatSessionTable();

  static const db = AiChatSessionRepository._();

  @override
  int? id;

  String userId;

  String roleType;

  String title;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [AiChatSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AiChatSession copyWith({
    int? id,
    String? userId,
    String? roleType,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiChatSession',
      if (id != null) 'id': id,
      'userId': userId,
      'roleType': roleType,
      'title': title,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AiChatSession',
      if (id != null) 'id': id,
      'userId': userId,
      'roleType': roleType,
      'title': title,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static AiChatSessionInclude include() {
    return AiChatSessionInclude._();
  }

  static AiChatSessionIncludeList includeList({
    _i1.WhereExpressionBuilder<AiChatSessionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AiChatSessionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AiChatSessionTable>? orderByList,
    AiChatSessionInclude? include,
  }) {
    return AiChatSessionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiChatSession.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AiChatSession.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AiChatSessionImpl extends AiChatSession {
  _AiChatSessionImpl({
    int? id,
    required String userId,
    required String roleType,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         roleType: roleType,
         title: title,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [AiChatSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AiChatSession copyWith({
    Object? id = _Undefined,
    String? userId,
    String? roleType,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiChatSession(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      roleType: roleType ?? this.roleType,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AiChatSessionUpdateTable extends _i1.UpdateTable<AiChatSessionTable> {
  AiChatSessionUpdateTable(super.table);

  _i1.ColumnValue<String, String> userId(String value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> roleType(String value) => _i1.ColumnValue(
    table.roleType,
    value,
  );

  _i1.ColumnValue<String, String> title(String value) => _i1.ColumnValue(
    table.title,
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

class AiChatSessionTable extends _i1.Table<int?> {
  AiChatSessionTable({super.tableRelation})
    : super(tableName: 'chat_sessions') {
    updateTable = AiChatSessionUpdateTable(this);
    userId = _i1.ColumnString(
      'userId',
      this,
    );
    roleType = _i1.ColumnString(
      'roleType',
      this,
    );
    title = _i1.ColumnString(
      'title',
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

  late final AiChatSessionUpdateTable updateTable;

  late final _i1.ColumnString userId;

  late final _i1.ColumnString roleType;

  late final _i1.ColumnString title;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    roleType,
    title,
    createdAt,
    updatedAt,
  ];
}

class AiChatSessionInclude extends _i1.IncludeObject {
  AiChatSessionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => AiChatSession.t;
}

class AiChatSessionIncludeList extends _i1.IncludeList {
  AiChatSessionIncludeList._({
    _i1.WhereExpressionBuilder<AiChatSessionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AiChatSession.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => AiChatSession.t;
}

class AiChatSessionRepository {
  const AiChatSessionRepository._();

  /// Returns a list of [AiChatSession]s matching the given query parameters.
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
  Future<List<AiChatSession>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AiChatSessionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AiChatSessionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AiChatSessionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<AiChatSession>(
      where: where?.call(AiChatSession.t),
      orderBy: orderBy?.call(AiChatSession.t),
      orderByList: orderByList?.call(AiChatSession.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [AiChatSession] matching the given query parameters.
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
  Future<AiChatSession?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AiChatSessionTable>? where,
    int? offset,
    _i1.OrderByBuilder<AiChatSessionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AiChatSessionTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<AiChatSession>(
      where: where?.call(AiChatSession.t),
      orderBy: orderBy?.call(AiChatSession.t),
      orderByList: orderByList?.call(AiChatSession.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [AiChatSession] by its [id] or null if no such row exists.
  Future<AiChatSession?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<AiChatSession>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [AiChatSession]s in the list and returns the inserted rows.
  ///
  /// The returned [AiChatSession]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<AiChatSession>> insert(
    _i1.DatabaseSession session,
    List<AiChatSession> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<AiChatSession>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [AiChatSession] and returns the inserted row.
  ///
  /// The returned [AiChatSession] will have its `id` field set.
  Future<AiChatSession> insertRow(
    _i1.DatabaseSession session,
    AiChatSession row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AiChatSession>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [AiChatSession]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AiChatSession>> update(
    _i1.DatabaseSession session,
    List<AiChatSession> rows, {
    _i1.ColumnSelections<AiChatSessionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AiChatSession>(
      rows,
      columns: columns?.call(AiChatSession.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AiChatSession]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AiChatSession> updateRow(
    _i1.DatabaseSession session,
    AiChatSession row, {
    _i1.ColumnSelections<AiChatSessionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<AiChatSession>(
      row,
      columns: columns?.call(AiChatSession.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AiChatSession] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AiChatSession?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<AiChatSessionUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AiChatSession>(
      id,
      columnValues: columnValues(AiChatSession.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AiChatSession]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AiChatSession>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<AiChatSessionUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AiChatSessionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AiChatSessionTable>? orderBy,
    _i1.OrderByListBuilder<AiChatSessionTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AiChatSession>(
      columnValues: columnValues(AiChatSession.t.updateTable),
      where: where(AiChatSession.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiChatSession.t),
      orderByList: orderByList?.call(AiChatSession.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AiChatSession]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AiChatSession>> delete(
    _i1.DatabaseSession session,
    List<AiChatSession> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AiChatSession>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [AiChatSession].
  Future<AiChatSession> deleteRow(
    _i1.DatabaseSession session,
    AiChatSession row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AiChatSession>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AiChatSession>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AiChatSessionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AiChatSession>(
      where: where(AiChatSession.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AiChatSessionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AiChatSession>(
      where: where?.call(AiChatSession.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [AiChatSession] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AiChatSessionTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<AiChatSession>(
      where: where(AiChatSession.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
