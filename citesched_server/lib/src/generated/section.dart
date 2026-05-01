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
import 'program.dart' as _i2;

abstract class Section
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Section._({
    this.id,
    required this.program,
    required this.yearLevel,
    required this.sectionCode,
    required this.academicYear,
    required this.semester,
    bool? isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : isActive = isActive ?? true;

  factory Section({
    int? id,
    required _i2.Program program,
    required int yearLevel,
    required String sectionCode,
    required String academicYear,
    required int semester,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SectionImpl;

  factory Section.fromJson(Map<String, dynamic> jsonSerialization) {
    return Section(
      id: jsonSerialization['id'] as int?,
      program: _i2.Program.fromJson((jsonSerialization['program'] as String)),
      yearLevel: jsonSerialization['yearLevel'] as int,
      sectionCode: jsonSerialization['sectionCode'] as String,
      academicYear: jsonSerialization['academicYear'] as String,
      semester: jsonSerialization['semester'] as int,
      isActive: jsonSerialization['isActive'] as bool?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = SectionTable();

  static const db = SectionRepository._();

  @override
  int? id;

  _i2.Program program;

  int yearLevel;

  String sectionCode;

  String academicYear;

  int semester;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Section]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Section copyWith({
    int? id,
    _i2.Program? program,
    int? yearLevel,
    String? sectionCode,
    String? academicYear,
    int? semester,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Section',
      if (id != null) 'id': id,
      'program': program.toJson(),
      'yearLevel': yearLevel,
      'sectionCode': sectionCode,
      'academicYear': academicYear,
      'semester': semester,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Section',
      if (id != null) 'id': id,
      'program': program.toJson(),
      'yearLevel': yearLevel,
      'sectionCode': sectionCode,
      'academicYear': academicYear,
      'semester': semester,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static SectionInclude include() {
    return SectionInclude._();
  }

  static SectionIncludeList includeList({
    _i1.WhereExpressionBuilder<SectionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SectionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SectionTable>? orderByList,
    SectionInclude? include,
  }) {
    return SectionIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Section.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Section.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SectionImpl extends Section {
  _SectionImpl({
    int? id,
    required _i2.Program program,
    required int yearLevel,
    required String sectionCode,
    required String academicYear,
    required int semester,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         program: program,
         yearLevel: yearLevel,
         sectionCode: sectionCode,
         academicYear: academicYear,
         semester: semester,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Section]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Section copyWith({
    Object? id = _Undefined,
    _i2.Program? program,
    int? yearLevel,
    String? sectionCode,
    String? academicYear,
    int? semester,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Section(
      id: id is int? ? id : this.id,
      program: program ?? this.program,
      yearLevel: yearLevel ?? this.yearLevel,
      sectionCode: sectionCode ?? this.sectionCode,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SectionUpdateTable extends _i1.UpdateTable<SectionTable> {
  SectionUpdateTable(super.table);

  _i1.ColumnValue<_i2.Program, _i2.Program> program(_i2.Program value) =>
      _i1.ColumnValue(
        table.program,
        value,
      );

  _i1.ColumnValue<int, int> yearLevel(int value) => _i1.ColumnValue(
    table.yearLevel,
    value,
  );

  _i1.ColumnValue<String, String> sectionCode(String value) => _i1.ColumnValue(
    table.sectionCode,
    value,
  );

  _i1.ColumnValue<String, String> academicYear(String value) => _i1.ColumnValue(
    table.academicYear,
    value,
  );

  _i1.ColumnValue<int, int> semester(int value) => _i1.ColumnValue(
    table.semester,
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

class SectionTable extends _i1.Table<int?> {
  SectionTable({super.tableRelation}) : super(tableName: 'section') {
    updateTable = SectionUpdateTable(this);
    program = _i1.ColumnEnum(
      'program',
      this,
      _i1.EnumSerialization.byName,
    );
    yearLevel = _i1.ColumnInt(
      'yearLevel',
      this,
    );
    sectionCode = _i1.ColumnString(
      'sectionCode',
      this,
    );
    academicYear = _i1.ColumnString(
      'academicYear',
      this,
    );
    semester = _i1.ColumnInt(
      'semester',
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

  late final SectionUpdateTable updateTable;

  late final _i1.ColumnEnum<_i2.Program> program;

  late final _i1.ColumnInt yearLevel;

  late final _i1.ColumnString sectionCode;

  late final _i1.ColumnString academicYear;

  late final _i1.ColumnInt semester;

  late final _i1.ColumnBool isActive;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    program,
    yearLevel,
    sectionCode,
    academicYear,
    semester,
    isActive,
    createdAt,
    updatedAt,
  ];
}

class SectionInclude extends _i1.IncludeObject {
  SectionInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Section.t;
}

class SectionIncludeList extends _i1.IncludeList {
  SectionIncludeList._({
    _i1.WhereExpressionBuilder<SectionTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Section.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Section.t;
}

class SectionRepository {
  const SectionRepository._();

  /// Returns a list of [Section]s matching the given query parameters.
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
  Future<List<Section>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SectionTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SectionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SectionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Section>(
      where: where?.call(Section.t),
      orderBy: orderBy?.call(Section.t),
      orderByList: orderByList?.call(Section.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Section] matching the given query parameters.
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
  Future<Section?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SectionTable>? where,
    int? offset,
    _i1.OrderByBuilder<SectionTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<SectionTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Section>(
      where: where?.call(Section.t),
      orderBy: orderBy?.call(Section.t),
      orderByList: orderByList?.call(Section.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Section] by its [id] or null if no such row exists.
  Future<Section?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Section>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Section]s in the list and returns the inserted rows.
  ///
  /// The returned [Section]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Section>> insert(
    _i1.Session session,
    List<Section> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Section>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Section] and returns the inserted row.
  ///
  /// The returned [Section] will have its `id` field set.
  Future<Section> insertRow(
    _i1.Session session,
    Section row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Section>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Section]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Section>> update(
    _i1.Session session,
    List<Section> rows, {
    _i1.ColumnSelections<SectionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Section>(
      rows,
      columns: columns?.call(Section.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Section]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Section> updateRow(
    _i1.Session session,
    Section row, {
    _i1.ColumnSelections<SectionTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Section>(
      row,
      columns: columns?.call(Section.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Section] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Section?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<SectionUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Section>(
      id,
      columnValues: columnValues(Section.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Section]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Section>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<SectionUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<SectionTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<SectionTable>? orderBy,
    _i1.OrderByListBuilder<SectionTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Section>(
      columnValues: columnValues(Section.t.updateTable),
      where: where(Section.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Section.t),
      orderByList: orderByList?.call(Section.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Section]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Section>> delete(
    _i1.Session session,
    List<Section> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Section>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Section].
  Future<Section> deleteRow(
    _i1.Session session,
    Section row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Section>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Section>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<SectionTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Section>(
      where: where(Section.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<SectionTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Section>(
      where: where?.call(Section.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
