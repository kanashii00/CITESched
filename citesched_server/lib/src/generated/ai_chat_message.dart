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
import 'ai_chat_session.dart' as _i2;
import 'package:citesched_server/src/generated/protocol.dart' as _i3;

abstract class AiChatMessage
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  AiChatMessage._({
    this.id,
    required this.sessionRecordId,
    this.sessionRecord,
    required this.sender,
    required this.message,
    required this.timestamp,
  });

  factory AiChatMessage({
    int? id,
    required int sessionRecordId,
    _i2.AiChatSession? sessionRecord,
    required String sender,
    required String message,
    required DateTime timestamp,
  }) = _AiChatMessageImpl;

  factory AiChatMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiChatMessage(
      id: jsonSerialization['id'] as int?,
      sessionRecordId: jsonSerialization['sessionRecordId'] as int,
      sessionRecord: jsonSerialization['sessionRecord'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.AiChatSession>(
              jsonSerialization['sessionRecord'],
            ),
      sender: jsonSerialization['sender'] as String,
      message: jsonSerialization['message'] as String,
      timestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
    );
  }

  static final t = AiChatMessageTable();

  static const db = AiChatMessageRepository._();

  @override
  int? id;

  int sessionRecordId;

  _i2.AiChatSession? sessionRecord;

  String sender;

  String message;

  DateTime timestamp;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [AiChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AiChatMessage copyWith({
    int? id,
    int? sessionRecordId,
    _i2.AiChatSession? sessionRecord,
    String? sender,
    String? message,
    DateTime? timestamp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiChatMessage',
      if (id != null) 'id': id,
      'sessionRecordId': sessionRecordId,
      if (sessionRecord != null) 'sessionRecord': sessionRecord?.toJson(),
      'sender': sender,
      'message': message,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AiChatMessage',
      if (id != null) 'id': id,
      'sessionRecordId': sessionRecordId,
      if (sessionRecord != null)
        'sessionRecord': sessionRecord?.toJsonForProtocol(),
      'sender': sender,
      'message': message,
      'timestamp': timestamp.toJson(),
    };
  }

  static AiChatMessageInclude include({
    _i2.AiChatSessionInclude? sessionRecord,
  }) {
    return AiChatMessageInclude._(sessionRecord: sessionRecord);
  }

  static AiChatMessageIncludeList includeList({
    _i1.WhereExpressionBuilder<AiChatMessageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AiChatMessageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AiChatMessageTable>? orderByList,
    AiChatMessageInclude? include,
  }) {
    return AiChatMessageIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiChatMessage.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(AiChatMessage.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AiChatMessageImpl extends AiChatMessage {
  _AiChatMessageImpl({
    int? id,
    required int sessionRecordId,
    _i2.AiChatSession? sessionRecord,
    required String sender,
    required String message,
    required DateTime timestamp,
  }) : super._(
         id: id,
         sessionRecordId: sessionRecordId,
         sessionRecord: sessionRecord,
         sender: sender,
         message: message,
         timestamp: timestamp,
       );

  /// Returns a shallow copy of this [AiChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AiChatMessage copyWith({
    Object? id = _Undefined,
    int? sessionRecordId,
    Object? sessionRecord = _Undefined,
    String? sender,
    String? message,
    DateTime? timestamp,
  }) {
    return AiChatMessage(
      id: id is int? ? id : this.id,
      sessionRecordId: sessionRecordId ?? this.sessionRecordId,
      sessionRecord: sessionRecord is _i2.AiChatSession?
          ? sessionRecord
          : this.sessionRecord?.copyWith(),
      sender: sender ?? this.sender,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class AiChatMessageUpdateTable extends _i1.UpdateTable<AiChatMessageTable> {
  AiChatMessageUpdateTable(super.table);

  _i1.ColumnValue<int, int> sessionRecordId(int value) => _i1.ColumnValue(
    table.sessionRecordId,
    value,
  );

  _i1.ColumnValue<String, String> sender(String value) => _i1.ColumnValue(
    table.sender,
    value,
  );

  _i1.ColumnValue<String, String> message(String value) => _i1.ColumnValue(
    table.message,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> timestamp(DateTime value) =>
      _i1.ColumnValue(
        table.timestamp,
        value,
      );
}

class AiChatMessageTable extends _i1.Table<int?> {
  AiChatMessageTable({super.tableRelation})
    : super(tableName: 'chat_messages') {
    updateTable = AiChatMessageUpdateTable(this);
    sessionRecordId = _i1.ColumnInt(
      'sessionRecordId',
      this,
    );
    sender = _i1.ColumnString(
      'sender',
      this,
    );
    message = _i1.ColumnString(
      'message',
      this,
    );
    timestamp = _i1.ColumnDateTime(
      'timestamp',
      this,
    );
  }

  late final AiChatMessageUpdateTable updateTable;

  late final _i1.ColumnInt sessionRecordId;

  _i2.AiChatSessionTable? _sessionRecord;

  late final _i1.ColumnString sender;

  late final _i1.ColumnString message;

  late final _i1.ColumnDateTime timestamp;

  _i2.AiChatSessionTable get sessionRecord {
    if (_sessionRecord != null) return _sessionRecord!;
    _sessionRecord = _i1.createRelationTable(
      relationFieldName: 'sessionRecord',
      field: AiChatMessage.t.sessionRecordId,
      foreignField: _i2.AiChatSession.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.AiChatSessionTable(tableRelation: foreignTableRelation),
    );
    return _sessionRecord!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    sessionRecordId,
    sender,
    message,
    timestamp,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'sessionRecord') {
      return sessionRecord;
    }
    return null;
  }
}

class AiChatMessageInclude extends _i1.IncludeObject {
  AiChatMessageInclude._({_i2.AiChatSessionInclude? sessionRecord}) {
    _sessionRecord = sessionRecord;
  }

  _i2.AiChatSessionInclude? _sessionRecord;

  @override
  Map<String, _i1.Include?> get includes => {'sessionRecord': _sessionRecord};

  @override
  _i1.Table<int?> get table => AiChatMessage.t;
}

class AiChatMessageIncludeList extends _i1.IncludeList {
  AiChatMessageIncludeList._({
    _i1.WhereExpressionBuilder<AiChatMessageTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(AiChatMessage.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => AiChatMessage.t;
}

class AiChatMessageRepository {
  const AiChatMessageRepository._();

  final attachRow = const AiChatMessageAttachRowRepository._();

  /// Returns a list of [AiChatMessage]s matching the given query parameters.
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
  Future<List<AiChatMessage>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AiChatMessageTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AiChatMessageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AiChatMessageTable>? orderByList,
    _i1.Transaction? transaction,
    AiChatMessageInclude? include,
  }) async {
    return session.db.find<AiChatMessage>(
      where: where?.call(AiChatMessage.t),
      orderBy: orderBy?.call(AiChatMessage.t),
      orderByList: orderByList?.call(AiChatMessage.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
    );
  }

  /// Returns the first matching [AiChatMessage] matching the given query parameters.
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
  Future<AiChatMessage?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AiChatMessageTable>? where,
    int? offset,
    _i1.OrderByBuilder<AiChatMessageTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AiChatMessageTable>? orderByList,
    _i1.Transaction? transaction,
    AiChatMessageInclude? include,
  }) async {
    return session.db.findFirstRow<AiChatMessage>(
      where: where?.call(AiChatMessage.t),
      orderBy: orderBy?.call(AiChatMessage.t),
      orderByList: orderByList?.call(AiChatMessage.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
    );
  }

  /// Finds a single [AiChatMessage] by its [id] or null if no such row exists.
  Future<AiChatMessage?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
    AiChatMessageInclude? include,
  }) async {
    return session.db.findById<AiChatMessage>(
      id,
      transaction: transaction,
      include: include,
    );
  }

  /// Inserts all [AiChatMessage]s in the list and returns the inserted rows.
  ///
  /// The returned [AiChatMessage]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<AiChatMessage>> insert(
    _i1.Session session,
    List<AiChatMessage> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<AiChatMessage>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [AiChatMessage] and returns the inserted row.
  ///
  /// The returned [AiChatMessage] will have its `id` field set.
  Future<AiChatMessage> insertRow(
    _i1.Session session,
    AiChatMessage row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<AiChatMessage>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [AiChatMessage]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<AiChatMessage>> update(
    _i1.Session session,
    List<AiChatMessage> rows, {
    _i1.ColumnSelections<AiChatMessageTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<AiChatMessage>(
      rows,
      columns: columns?.call(AiChatMessage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AiChatMessage]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<AiChatMessage> updateRow(
    _i1.Session session,
    AiChatMessage row, {
    _i1.ColumnSelections<AiChatMessageTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<AiChatMessage>(
      row,
      columns: columns?.call(AiChatMessage.t),
      transaction: transaction,
    );
  }

  /// Updates a single [AiChatMessage] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<AiChatMessage?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<AiChatMessageUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<AiChatMessage>(
      id,
      columnValues: columnValues(AiChatMessage.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [AiChatMessage]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<AiChatMessage>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<AiChatMessageUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AiChatMessageTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AiChatMessageTable>? orderBy,
    _i1.OrderByListBuilder<AiChatMessageTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<AiChatMessage>(
      columnValues: columnValues(AiChatMessage.t.updateTable),
      where: where(AiChatMessage.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(AiChatMessage.t),
      orderByList: orderByList?.call(AiChatMessage.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [AiChatMessage]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<AiChatMessage>> delete(
    _i1.Session session,
    List<AiChatMessage> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<AiChatMessage>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [AiChatMessage].
  Future<AiChatMessage> deleteRow(
    _i1.Session session,
    AiChatMessage row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<AiChatMessage>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<AiChatMessage>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<AiChatMessageTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<AiChatMessage>(
      where: where(AiChatMessage.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<AiChatMessageTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<AiChatMessage>(
      where: where?.call(AiChatMessage.t),
      limit: limit,
      transaction: transaction,
    );
  }
}

class AiChatMessageAttachRowRepository {
  const AiChatMessageAttachRowRepository._();

  /// Creates a relation between the given [AiChatMessage] and [AiChatSession]
  /// by setting the [AiChatMessage]'s foreign key `sessionRecordId` to refer to the [AiChatSession].
  Future<void> sessionRecord(
    _i1.Session session,
    AiChatMessage aiChatMessage,
    _i2.AiChatSession sessionRecord, {
    _i1.Transaction? transaction,
  }) async {
    if (aiChatMessage.id == null) {
      throw ArgumentError.notNull('aiChatMessage.id');
    }
    if (sessionRecord.id == null) {
      throw ArgumentError.notNull('sessionRecord.id');
    }

    var $aiChatMessage = aiChatMessage.copyWith(
      sessionRecordId: sessionRecord.id,
    );
    await session.db.updateRow<AiChatMessage>(
      $aiChatMessage,
      columns: [AiChatMessage.t.sessionRecordId],
      transaction: transaction,
    );
  }
}
