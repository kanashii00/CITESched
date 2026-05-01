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
import 'subject_type.dart' as _i3;

abstract class TimetableFilterRequest implements _i1.SerializableModel {
  TimetableFilterRequest._({
    this.program,
    this.schoolYear,
    this.yearLevel,
    this.section,
    this.facultyId,
    this.roomId,
    this.loadType,
    this.hasConflicts,
  });

  factory TimetableFilterRequest({
    _i2.Program? program,
    String? schoolYear,
    int? yearLevel,
    String? section,
    int? facultyId,
    int? roomId,
    _i3.SubjectType? loadType,
    bool? hasConflicts,
  }) = _TimetableFilterRequestImpl;

  factory TimetableFilterRequest.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return TimetableFilterRequest(
      program: jsonSerialization['program'] == null
          ? null
          : _i2.Program.fromJson((jsonSerialization['program'] as String)),
      schoolYear: jsonSerialization['schoolYear'] as String?,
      yearLevel: jsonSerialization['yearLevel'] as int?,
      section: jsonSerialization['section'] as String?,
      facultyId: jsonSerialization['facultyId'] as int?,
      roomId: jsonSerialization['roomId'] as int?,
      loadType: jsonSerialization['loadType'] == null
          ? null
          : _i3.SubjectType.fromJson((jsonSerialization['loadType'] as String)),
      hasConflicts: jsonSerialization['hasConflicts'] as bool?,
    );
  }

  _i2.Program? program;

  String? schoolYear;

  int? yearLevel;

  String? section;

  int? facultyId;

  int? roomId;

  _i3.SubjectType? loadType;

  bool? hasConflicts;

  /// Returns a shallow copy of this [TimetableFilterRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TimetableFilterRequest copyWith({
    _i2.Program? program,
    String? schoolYear,
    int? yearLevel,
    String? section,
    int? facultyId,
    int? roomId,
    _i3.SubjectType? loadType,
    bool? hasConflicts,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TimetableFilterRequest',
      if (program != null) 'program': program?.toJson(),
      if (schoolYear != null) 'schoolYear': schoolYear,
      if (yearLevel != null) 'yearLevel': yearLevel,
      if (section != null) 'section': section,
      if (facultyId != null) 'facultyId': facultyId,
      if (roomId != null) 'roomId': roomId,
      if (loadType != null) 'loadType': loadType?.toJson(),
      if (hasConflicts != null) 'hasConflicts': hasConflicts,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TimetableFilterRequestImpl extends TimetableFilterRequest {
  _TimetableFilterRequestImpl({
    _i2.Program? program,
    String? schoolYear,
    int? yearLevel,
    String? section,
    int? facultyId,
    int? roomId,
    _i3.SubjectType? loadType,
    bool? hasConflicts,
  }) : super._(
         program: program,
         schoolYear: schoolYear,
         yearLevel: yearLevel,
         section: section,
         facultyId: facultyId,
         roomId: roomId,
         loadType: loadType,
         hasConflicts: hasConflicts,
       );

  /// Returns a shallow copy of this [TimetableFilterRequest]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TimetableFilterRequest copyWith({
    Object? program = _Undefined,
    Object? schoolYear = _Undefined,
    Object? yearLevel = _Undefined,
    Object? section = _Undefined,
    Object? facultyId = _Undefined,
    Object? roomId = _Undefined,
    Object? loadType = _Undefined,
    Object? hasConflicts = _Undefined,
  }) {
    return TimetableFilterRequest(
      program: program is _i2.Program? ? program : this.program,
      schoolYear: schoolYear is String? ? schoolYear : this.schoolYear,
      yearLevel: yearLevel is int? ? yearLevel : this.yearLevel,
      section: section is String? ? section : this.section,
      facultyId: facultyId is int? ? facultyId : this.facultyId,
      roomId: roomId is int? ? roomId : this.roomId,
      loadType: loadType is _i3.SubjectType? ? loadType : this.loadType,
      hasConflicts: hasConflicts is bool? ? hasConflicts : this.hasConflicts,
    );
  }
}
