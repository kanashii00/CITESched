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
import 'faculty.dart' as _i2;
import 'day_of_week.dart' as _i3;
import 'package:citesched_client/src/protocol/protocol.dart' as _i4;

abstract class FacultyAvailability implements _i1.SerializableModel {
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

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int facultyId;

  _i2.Faculty? faculty;

  _i3.DayOfWeek dayOfWeek;

  String startTime;

  String endTime;

  bool isPreferred;

  DateTime createdAt;

  DateTime updatedAt;

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
