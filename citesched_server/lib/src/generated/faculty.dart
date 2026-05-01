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
import 'employment_status.dart' as _i2;
import 'faculty_shift_preference.dart' as _i3;
import 'program.dart' as _i4;

abstract class Faculty
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Faculty._({
    this.id,
    required this.name,
    required this.email,
    this.maxLoad,
    this.employmentStatus,
    this.shiftPreference,
    this.preferredHours,
    required this.facultyId,
    required this.userInfoId,
    this.program,
    required this.isActive,
    this.currentLoad,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Faculty({
    int? id,
    required String name,
    required String email,
    int? maxLoad,
    _i2.EmploymentStatus? employmentStatus,
    _i3.FacultyShiftPreference? shiftPreference,
    String? preferredHours,
    required String facultyId,
    required int userInfoId,
    _i4.Program? program,
    required bool isActive,
    double? currentLoad,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _FacultyImpl;

  factory Faculty.fromJson(Map<String, dynamic> jsonSerialization) {
    return Faculty(
      id: jsonSerialization['id'] as int?,
      name: jsonSerialization['name'] as String,
      email: jsonSerialization['email'] as String,
      maxLoad: jsonSerialization['maxLoad'] as int?,
      employmentStatus: jsonSerialization['employmentStatus'] == null
          ? null
          : _i2.EmploymentStatus.fromJson(
              (jsonSerialization['employmentStatus'] as String),
            ),
      shiftPreference: jsonSerialization['shiftPreference'] == null
          ? null
          : _i3.FacultyShiftPreference.fromJson(
              (jsonSerialization['shiftPreference'] as String),
            ),
      preferredHours: jsonSerialization['preferredHours'] as String?,
      facultyId: jsonSerialization['facultyId'] as String,
      userInfoId: jsonSerialization['userInfoId'] as int,
      program: jsonSerialization['program'] == null
          ? null
          : _i4.Program.fromJson((jsonSerialization['program'] as String)),
      isActive: jsonSerialization['isActive'] as bool,
      currentLoad: (jsonSerialization['currentLoad'] as num?)?.toDouble(),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = FacultyTable();

  static const db = FacultyRepository._();

  @override
  int? id;

  String name;

  String email;

  int? maxLoad;

  _i2.EmploymentStatus? employmentStatus;

  _i3.FacultyShiftPreference? shiftPreference;

  String? preferredHours;

  String facultyId;

  int userInfoId;

  _i4.Program? program;

  bool isActive;

  double? currentLoad;

  DateTime createdAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Faculty]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Faculty copyWith({
    int? id,
    String? name,
    String? email,
    int? maxLoad,
    _i2.EmploymentStatus? employmentStatus,
    _i3.FacultyShiftPreference? shiftPreference,
    String? preferredHours,
    String? facultyId,
    int? userInfoId,
    _i4.Program? program,
    bool? isActive,
    double? currentLoad,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Faculty',
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      if (maxLoad != null) 'maxLoad': maxLoad,
      if (employmentStatus != null)
        'employmentStatus': employmentStatus?.toJson(),
      if (shiftPreference != null) 'shiftPreference': shiftPreference?.toJson(),
      if (preferredHours != null) 'preferredHours': preferredHours,
      'facultyId': facultyId,
      'userInfoId': userInfoId,
      if (program != null) 'program': program?.toJson(),
      'isActive': isActive,
      if (currentLoad != null) 'currentLoad': currentLoad,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Faculty',
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      if (maxLoad != null) 'maxLoad': maxLoad,
      if (employmentStatus != null)
        'employmentStatus': employmentStatus?.toJson(),
      if (shiftPreference != null) 'shiftPreference': shiftPreference?.toJson(),
      if (preferredHours != null) 'preferredHours': preferredHours,
      'facultyId': facultyId,
      'userInfoId': userInfoId,
      if (program != null) 'program': program?.toJson(),
      'isActive': isActive,
      if (currentLoad != null) 'currentLoad': currentLoad,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  static FacultyInclude include() {
    return FacultyInclude._();
  }

  static FacultyIncludeList includeList({
    _i1.WhereExpressionBuilder<FacultyTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FacultyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FacultyTable>? orderByList,
    FacultyInclude? include,
  }) {
    return FacultyIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Faculty.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Faculty.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _FacultyImpl extends Faculty {
  _FacultyImpl({
    int? id,
    required String name,
    required String email,
    int? maxLoad,
    _i2.EmploymentStatus? employmentStatus,
    _i3.FacultyShiftPreference? shiftPreference,
    String? preferredHours,
    required String facultyId,
    required int userInfoId,
    _i4.Program? program,
    required bool isActive,
    double? currentLoad,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         name: name,
         email: email,
         maxLoad: maxLoad,
         employmentStatus: employmentStatus,
         shiftPreference: shiftPreference,
         preferredHours: preferredHours,
         facultyId: facultyId,
         userInfoId: userInfoId,
         program: program,
         isActive: isActive,
         currentLoad: currentLoad,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Faculty]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Faculty copyWith({
    Object? id = _Undefined,
    String? name,
    String? email,
    Object? maxLoad = _Undefined,
    Object? employmentStatus = _Undefined,
    Object? shiftPreference = _Undefined,
    Object? preferredHours = _Undefined,
    String? facultyId,
    int? userInfoId,
    Object? program = _Undefined,
    bool? isActive,
    Object? currentLoad = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Faculty(
      id: id is int? ? id : this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      maxLoad: maxLoad is int? ? maxLoad : this.maxLoad,
      employmentStatus: employmentStatus is _i2.EmploymentStatus?
          ? employmentStatus
          : this.employmentStatus,
      shiftPreference: shiftPreference is _i3.FacultyShiftPreference?
          ? shiftPreference
          : this.shiftPreference,
      preferredHours: preferredHours is String?
          ? preferredHours
          : this.preferredHours,
      facultyId: facultyId ?? this.facultyId,
      userInfoId: userInfoId ?? this.userInfoId,
      program: program is _i4.Program? ? program : this.program,
      isActive: isActive ?? this.isActive,
      currentLoad: currentLoad is double? ? currentLoad : this.currentLoad,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FacultyUpdateTable extends _i1.UpdateTable<FacultyTable> {
  FacultyUpdateTable(super.table);

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> email(String value) => _i1.ColumnValue(
    table.email,
    value,
  );

  _i1.ColumnValue<int, int> maxLoad(int? value) => _i1.ColumnValue(
    table.maxLoad,
    value,
  );

  _i1.ColumnValue<_i2.EmploymentStatus, _i2.EmploymentStatus> employmentStatus(
    _i2.EmploymentStatus? value,
  ) => _i1.ColumnValue(
    table.employmentStatus,
    value,
  );

  _i1.ColumnValue<_i3.FacultyShiftPreference, _i3.FacultyShiftPreference>
  shiftPreference(_i3.FacultyShiftPreference? value) => _i1.ColumnValue(
    table.shiftPreference,
    value,
  );

  _i1.ColumnValue<String, String> preferredHours(String? value) =>
      _i1.ColumnValue(
        table.preferredHours,
        value,
      );

  _i1.ColumnValue<String, String> facultyId(String value) => _i1.ColumnValue(
    table.facultyId,
    value,
  );

  _i1.ColumnValue<int, int> userInfoId(int value) => _i1.ColumnValue(
    table.userInfoId,
    value,
  );

  _i1.ColumnValue<_i4.Program, _i4.Program> program(_i4.Program? value) =>
      _i1.ColumnValue(
        table.program,
        value,
      );

  _i1.ColumnValue<bool, bool> isActive(bool value) => _i1.ColumnValue(
    table.isActive,
    value,
  );

  _i1.ColumnValue<double, double> currentLoad(double? value) => _i1.ColumnValue(
    table.currentLoad,
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

class FacultyTable extends _i1.Table<int?> {
  FacultyTable({super.tableRelation}) : super(tableName: 'faculty') {
    updateTable = FacultyUpdateTable(this);
    name = _i1.ColumnString(
      'name',
      this,
    );
    email = _i1.ColumnString(
      'email',
      this,
    );
    maxLoad = _i1.ColumnInt(
      'maxLoad',
      this,
    );
    employmentStatus = _i1.ColumnEnum(
      'employmentStatus',
      this,
      _i1.EnumSerialization.byName,
    );
    shiftPreference = _i1.ColumnEnum(
      'shiftPreference',
      this,
      _i1.EnumSerialization.byName,
    );
    preferredHours = _i1.ColumnString(
      'preferredHours',
      this,
    );
    facultyId = _i1.ColumnString(
      'facultyId',
      this,
    );
    userInfoId = _i1.ColumnInt(
      'userInfoId',
      this,
    );
    program = _i1.ColumnEnum(
      'program',
      this,
      _i1.EnumSerialization.byName,
    );
    isActive = _i1.ColumnBool(
      'isActive',
      this,
    );
    currentLoad = _i1.ColumnDouble(
      'currentLoad',
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

  late final FacultyUpdateTable updateTable;

  late final _i1.ColumnString name;

  late final _i1.ColumnString email;

  late final _i1.ColumnInt maxLoad;

  late final _i1.ColumnEnum<_i2.EmploymentStatus> employmentStatus;

  late final _i1.ColumnEnum<_i3.FacultyShiftPreference> shiftPreference;

  late final _i1.ColumnString preferredHours;

  late final _i1.ColumnString facultyId;

  late final _i1.ColumnInt userInfoId;

  late final _i1.ColumnEnum<_i4.Program> program;

  late final _i1.ColumnBool isActive;

  late final _i1.ColumnDouble currentLoad;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    name,
    email,
    maxLoad,
    employmentStatus,
    shiftPreference,
    preferredHours,
    facultyId,
    userInfoId,
    program,
    isActive,
    currentLoad,
    createdAt,
    updatedAt,
  ];
}

class FacultyInclude extends _i1.IncludeObject {
  FacultyInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Faculty.t;
}

class FacultyIncludeList extends _i1.IncludeList {
  FacultyIncludeList._({
    _i1.WhereExpressionBuilder<FacultyTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Faculty.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Faculty.t;
}

class FacultyRepository {
  const FacultyRepository._();

  /// Returns a list of [Faculty]s matching the given query parameters.
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
  Future<List<Faculty>> find(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FacultyTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FacultyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FacultyTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.find<Faculty>(
      where: where?.call(Faculty.t),
      orderBy: orderBy?.call(Faculty.t),
      orderByList: orderByList?.call(Faculty.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Returns the first matching [Faculty] matching the given query parameters.
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
  Future<Faculty?> findFirstRow(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FacultyTable>? where,
    int? offset,
    _i1.OrderByBuilder<FacultyTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<FacultyTable>? orderByList,
    _i1.Transaction? transaction,
  }) async {
    return session.db.findFirstRow<Faculty>(
      where: where?.call(Faculty.t),
      orderBy: orderBy?.call(Faculty.t),
      orderByList: orderByList?.call(Faculty.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
    );
  }

  /// Finds a single [Faculty] by its [id] or null if no such row exists.
  Future<Faculty?> findById(
    _i1.Session session,
    int id, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.findById<Faculty>(
      id,
      transaction: transaction,
    );
  }

  /// Inserts all [Faculty]s in the list and returns the inserted rows.
  ///
  /// The returned [Faculty]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  Future<List<Faculty>> insert(
    _i1.Session session,
    List<Faculty> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insert<Faculty>(
      rows,
      transaction: transaction,
    );
  }

  /// Inserts a single [Faculty] and returns the inserted row.
  ///
  /// The returned [Faculty] will have its `id` field set.
  Future<Faculty> insertRow(
    _i1.Session session,
    Faculty row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Faculty>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Faculty]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Faculty>> update(
    _i1.Session session,
    List<Faculty> rows, {
    _i1.ColumnSelections<FacultyTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Faculty>(
      rows,
      columns: columns?.call(Faculty.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Faculty]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Faculty> updateRow(
    _i1.Session session,
    Faculty row, {
    _i1.ColumnSelections<FacultyTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Faculty>(
      row,
      columns: columns?.call(Faculty.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Faculty] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Faculty?> updateById(
    _i1.Session session,
    int id, {
    required _i1.ColumnValueListBuilder<FacultyUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Faculty>(
      id,
      columnValues: columnValues(Faculty.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Faculty]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Faculty>> updateWhere(
    _i1.Session session, {
    required _i1.ColumnValueListBuilder<FacultyUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<FacultyTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<FacultyTable>? orderBy,
    _i1.OrderByListBuilder<FacultyTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Faculty>(
      columnValues: columnValues(Faculty.t.updateTable),
      where: where(Faculty.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Faculty.t),
      orderByList: orderByList?.call(Faculty.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Faculty]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Faculty>> delete(
    _i1.Session session,
    List<Faculty> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Faculty>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Faculty].
  Future<Faculty> deleteRow(
    _i1.Session session,
    Faculty row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Faculty>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Faculty>> deleteWhere(
    _i1.Session session, {
    required _i1.WhereExpressionBuilder<FacultyTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Faculty>(
      where: where(Faculty.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.Session session, {
    _i1.WhereExpressionBuilder<FacultyTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Faculty>(
      where: where?.call(Faculty.t),
      limit: limit,
      transaction: transaction,
    );
  }
}
