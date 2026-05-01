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
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'program.dart' as _i2;

abstract class Section implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i2.Program program;

  int yearLevel;

  String sectionCode;

  String academicYear;

  int semester;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

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
