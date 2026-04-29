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
import 'section.dart' as _i2;
import 'package:citesched_client/src/protocol/protocol.dart' as _i3;

abstract class Student implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
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
