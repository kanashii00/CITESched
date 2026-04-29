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
import 'section.dart' as _i2;
import 'package:citesched_server/src/generated/protocol.dart' as _i3;

abstract class Student
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Student._({
    this.id,
    required this.name,
    required this.email,
    required this.studentNumber,
    required this.course,
    required this.yearLevel,
    this.section,
    this.sectionId,
    this.sectionRef,
    required this.userInfoId,
    bool? isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : isActive = isActive ?? true;

  factory Student({
    int? id,
    required String name,
    required String email,
    required String studentNumber,
    required String course,
    required int yearLevel,
    String? section,
    int? sectionId,
    _i2.Section? sectionRef,
    required int userInfoId,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StudentImpl;

  factory Student.fromJson(Map<String, dynamic> jsonSerialization) {
    return Student(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      studentNumber: jsonSerialization['studentNumber'] as String,
      course: jsonSerialization['course'] as String,
      yearLevel: jsonSerialization['yearLevel'] as int,
      section: jsonSerialization['section'] as String?,
      sectionId: jsonSerialization['sectionId'] as int?,
      sectionRef: jsonSerialization['sectionRef'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.Section>(
              jsonSerialization['sectionRef'],
            ),
      userInfoId: jsonSerialization['userInfoId'] as int,
      isActive: jsonSerialization['isActive'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isActive']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = StudentTable();

  static const db = StudentRepository._();

  @override
  int? id;

  String name;

  String email;

  String studentNumber;

  String course;

  int yearLevel;

  String? section;

  int? sectionId;

  _i2.Section? sectionRef;

  int userInfoId;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Student]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Student copyWith({
    int? id,
    String? name,
    String? email,
    String? studentNumber,
    String? course,
    int? yearLevel,
    String? section,
    int? sectionId,
    _i2.Section? sectionRef,
    int? userInfoId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Student',
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'studentNumber': studentNumber,
      'course': course,
      'yearLevel': yearLevel,
      if (section != null) 'section': section,
      if (sectionId != null) 'sectionId': sectionId,
      if (sectionRef != null) 'sectionRef': sectionRef?.toJson(),
      'userInfoId': userInfoId,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Student',
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'studentNumber': studentNumber,
      'course': course,
      'yearLevel': yearLevel,
      if (section != null) 'section': section,
      if (sectionId != null) 'sectionId': sectionId,
      if (sectionRef != null) 'sectionRef': sectionRef?.toJsonForProtocol(),
      'userInfoId': userInfoId,
      'isActive': isActive,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static StudentInclude include({_i2.SectionInclude? sectionRef}) {
    return StudentInclude._(sectionRef: sectionRef);
  }

  static StudentIncludeList includeList({
    _i1.WhereExpressionBuilder<StudentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<StudentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<StudentTable>? orderByList,
    StudentInclude? include,
  }) {
    return StudentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Student.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Student.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _StudentImpl extends Student {
  _StudentImpl({
    int? id,
    required String name,
    required String email,
    required String studentNumber,
    required String course,
    required int yearLevel,
    String? section,
    int? sectionId,
    _i2.Section? sectionRef,
    required int userInfoId,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         name: name,
         email: email,
         studentNumber: studentNumber,
         course: course,
         yearLevel: yearLevel,
         section: section,
         sectionId: sectionId,
         sectionRef: sectionRef,
         userInfoId: userInfoId,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Student]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Student copyWith({
    Object? id = _Undefined,
    String? name,
    String? email,
    String? studentNumber,
    String? course,
    int? yearLevel,
    Object? section = _Undefined,
    Object? sectionId = _Undefined,
    Object? sectionRef = _Undefined,
    int? userInfoId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentNumber: studentNumber ?? this.studentNumber,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      section: section is String? ? section : this.section,
      sectionId: sectionId is int? ? sectionId : this.sectionId,
      sectionRef: sectionRef is _i2.Section?
          ? sectionRef
          : this.sectionRef?.copyWith(),
      userInfoId: userInfoId ?? this.userInfoId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StudentUpdateTable extends _i1.UpdateTable<StudentTable> {
  StudentUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> email(String value) => _i1.ColumnValue(
    table.email,
    value,
  );

  _i1.ColumnValue<String, String> studentNumber(String value) =>
      _i1.ColumnValue(
        table.studentNumber,
        value,
      );

  _i1.ColumnValue<String, String> course(String value) => _i1.ColumnValue(
    table.course,
    value,
  );

  _i1.ColumnValue<int, int> yearLevel(int value) => _i1.ColumnValue(
    table.yearLevel,
    value,
  );

  _i1.ColumnValue<String, String> section(String? value) => _i1.ColumnValue(
    table.section,
    value,
  );

  _i1.ColumnValue<int, int> sectionId(int? value) => _i1.ColumnValue(
    table.sectionId,
    value,
  );

  _i1.ColumnValue<int, int> userInfoId(int value) => _i1.ColumnValue(
    table.userInfoId,
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

class StudentTable extends _i1.Table<int?> {
  StudentTable({super.tableRelation}) : super(tableName: 'student') {
    updateTable = StudentUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    email = _i1.ColumnString(
      'email',
      this,
    );
    studentNumber = _i1.ColumnString(
      'studentNumber',
      this,
    );
    course = _i1.ColumnString(
      'course',
      this,
    );
    yearLevel = _i1.ColumnInt(
      'yearLevel',
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
    userInfoId = _i1.ColumnInt(
      'userInfoId',
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

  late final StudentUpdateTable updateTable;

  late final _i1.ColumnString name;

  late final _i1.ColumnString email;

  late final _i1.ColumnString studentNumber;

  late final _i1.ColumnString course;

  late final _i1.ColumnInt yearLevel;

  late final _i1.ColumnString section;

  late final _i1.ColumnInt sectionId;

  _i2.SectionTable? _sectionRef;

  late final _i1.ColumnInt userInfoId;

  late final _i1.ColumnBool isActive;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  _i2.SectionTable get sectionRef {
    if (_sectionRef != null) return _sectionRef!;
    _sectionRef = _i1.createRelationTable(
      relationFieldName: 'sectionRef',
      field: Student.t.sectionId,
      foreignField: _i2.Section.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.SectionTable(tableRelation: foreignTableRelation),
    );
    return _sectionRef!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    email,
    studentNumber,
    course,
    yearLevel,
    section,
    sectionId,
    userInfoId,
    isActive,
    createdAt,
    updatedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'sectionRef') {
      return sectionRef;
    }
    return null;
  }
}

class StudentInclude extends _i1.IncludeObject {
  StudentInclude._({_i2.SectionInclude? sectionRef}) {
    _sectionRef = sectionRef;
  }

  _i2.SectionInclude? _sectionRef;

  @override
  Map<String, _i1.Include?> get includes => {'sectionRef': _sectionRef};

  @override
  _i1.Table<int?> get table => Student.t;
}

class StudentIncludeList extends _i1.IncludeList {
  StudentIncludeList._({
    _i1.WhereExpressionBuilder<StudentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Student.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Student.t;
}

class StudentRepository {
  const StudentRepository._();

  final attachRow = const StudentAttachRowRepository._();

  final detachRow = const StudentDetachRowRepository._();

  /// Returns a list of [Student]s matching the given query parameters.
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
  Future<List<Student>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<StudentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<StudentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<StudentTable>? orderByList,
    _i1.Transaction? transaction,
    StudentInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Student>(
      where: where?.call(Student.t),
      orderBy: orderBy?.call(Student.t),
      orderByList: orderByList?.call(Student.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Student] matching the given query parameters.
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
  Future<Student?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<StudentTable>? where,
    int? offset,
    _i1.OrderByBuilder<StudentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<StudentTable>? orderByList,
    _i1.Transaction? transaction,
    StudentInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Student>(
      where: where?.call(Student.t),
      orderBy: orderBy?.call(Student.t),
      orderByList: orderByList?.call(Student.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Student] by its [id] or null if no such row exists.
  Future<Student?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    StudentInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Student>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Student]s in the list and returns the inserted rows.
  ///
  /// The returned [Student]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Student>> insert(
    _i1.DatabaseSession session,
    List<Student> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Student>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Student] and returns the inserted row.
  ///
  /// The returned [Student] will have its `id` field set.
  Future<Student> insertRow(
    _i1.DatabaseSession session,
    Student row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Student>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Student]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Student>> update(
    _i1.DatabaseSession session,
    List<Student> rows, {
    _i1.ColumnSelections<StudentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Student>(
      rows,
      columns: columns?.call(Student.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Student]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Student> updateRow(
    _i1.DatabaseSession session,
    Student row, {
    _i1.ColumnSelections<StudentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Student>(
      row,
      columns: columns?.call(Student.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Student] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Student?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<StudentUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Student>(
      id,
      columnValues: columnValues(Student.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Student]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Student>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<StudentUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<StudentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<StudentTable>? orderBy,
    _i1.OrderByListBuilder<StudentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Student>(
      columnValues: columnValues(Student.t.updateTable),
      where: where(Student.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Student.t),
      orderByList: orderByList?.call(Student.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Student]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Student>> delete(
    _i1.DatabaseSession session,
    List<Student> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Student>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Student].
  Future<Student> deleteRow(
    _i1.DatabaseSession session,
    Student row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Student>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Student>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<StudentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Student>(
      where: where(Student.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<StudentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Student>(
      where: where?.call(Student.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Student] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<StudentTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Student>(
      where: where(Student.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class StudentAttachRowRepository {
  const StudentAttachRowRepository._();

  /// Creates a relation between the given [Student] and [Section]
  /// by setting the [Student]'s foreign key `sectionId` to refer to the [Section].
  Future<void> sectionRef(
    _i1.DatabaseSession session,
    Student student,
    _i2.Section sectionRef, {
    _i1.Transaction? transaction,
  }) async {
    if (student.id == null) {
      throw ArgumentError.notNull('student.id');
    }
    if (sectionRef.id == null) {
      throw ArgumentError.notNull('sectionRef.id');
    }

    var $student = student.copyWith(sectionId: sectionRef.id);
    await session.db.updateRow<Student>(
      $student,
      columns: [Student.t.sectionId],
      transaction: transaction,
    );
  }
}

class StudentDetachRowRepository {
  const StudentDetachRowRepository._();

  /// Detaches the relation between this [Student] and the [Section] set in `sectionRef`
  /// by setting the [Student]'s foreign key `sectionId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> sectionRef(
    _i1.DatabaseSession session,
    Student student, {
    _i1.Transaction? transaction,
  }) async {
    if (student.id == null) {
      throw ArgumentError.notNull('student.id');
    }

    var $student = student.copyWith(sectionId: null);
    await session.db.updateRow<Student>(
      $student,
      columns: [Student.t.sectionId],
      transaction: transaction,
    );
  }
}
