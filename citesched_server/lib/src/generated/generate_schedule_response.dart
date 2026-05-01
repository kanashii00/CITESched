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
import 'schedule.dart' as _i2;
import 'schedule_conflict.dart' as _i3;
import 'package:citesched_server/src/generated/protocol.dart' as _i4;

abstract class GenerateScheduleResponse
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GenerateScheduleResponse._({
    required this.success,
    this.schedules,
    this.conflicts,
    this.message,
    this.totalAssigned,
    this.conflictsDetected,
    this.unassignedSubjects,
  });

  factory GenerateScheduleResponse({
    required bool success,
    List<_i2.Schedule>? schedules,
    List<_i3.ScheduleConflict>? conflicts,
    String? message,
    int? totalAssigned,
    int? conflictsDetected,
    int? unassignedSubjects,
  }) = _GenerateScheduleResponseImpl;

  factory GenerateScheduleResponse.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GenerateScheduleResponse(
      success: jsonSerialization['success'] as bool,
      schedules: jsonSerialization['schedules'] == null
          ? null
          : _i4.Protocol().deserialize<List<_i2.Schedule>>(
              jsonSerialization['schedules'],
            ),
      conflicts: jsonSerialization['conflicts'] == null
          ? null
          : _i4.Protocol().deserialize<List<_i3.ScheduleConflict>>(
              jsonSerialization['conflicts'],
            ),
      message: jsonSerialization['message'] as String?,
      totalAssigned: jsonSerialization['totalAssigned'] as int?,
      conflictsDetected: jsonSerialization['conflictsDetected'] as int?,
      unassignedSubjects: jsonSerialization['unassignedSubjects'] as int?,
    );
  }

  bool success;

  List<_i2.Schedule>? schedules;

  List<_i3.ScheduleConflict>? conflicts;

  String? message;

  int? totalAssigned;

  int? conflictsDetected;

  int? unassignedSubjects;

  /// Returns a shallow copy of this [GenerateScheduleResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GenerateScheduleResponse copyWith({
    bool? success,
    List<_i2.Schedule>? schedules,
    List<_i3.ScheduleConflict>? conflicts,
    String? message,
    int? totalAssigned,
    int? conflictsDetected,
    int? unassignedSubjects,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GenerateScheduleResponse',
      'success': success,
      if (schedules != null)
        'schedules': schedules?.toJson(valueToJson: (v) => v.toJson()),
      if (conflicts != null)
        'conflicts': conflicts?.toJson(valueToJson: (v) => v.toJson()),
      if (message != null) 'message': message,
      if (totalAssigned != null) 'totalAssigned': totalAssigned,
      if (conflictsDetected != null) 'conflictsDetected': conflictsDetected,
      if (unassignedSubjects != null) 'unassignedSubjects': unassignedSubjects,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GenerateScheduleResponse',
      'success': success,
      if (schedules != null)
        'schedules': schedules?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (conflicts != null)
        'conflicts': conflicts?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (message != null) 'message': message,
      if (totalAssigned != null) 'totalAssigned': totalAssigned,
      if (conflictsDetected != null) 'conflictsDetected': conflictsDetected,
      if (unassignedSubjects != null) 'unassignedSubjects': unassignedSubjects,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GenerateScheduleResponseImpl extends GenerateScheduleResponse {
  _GenerateScheduleResponseImpl({
    required bool success,
    List<_i2.Schedule>? schedules,
    List<_i3.ScheduleConflict>? conflicts,
    String? message,
    int? totalAssigned,
    int? conflictsDetected,
    int? unassignedSubjects,
  }) : super._(
         success: success,
         schedules: schedules,
         conflicts: conflicts,
         message: message,
         totalAssigned: totalAssigned,
         conflictsDetected: conflictsDetected,
         unassignedSubjects: unassignedSubjects,
       );

  /// Returns a shallow copy of this [GenerateScheduleResponse]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GenerateScheduleResponse copyWith({
    bool? success,
    Object? schedules = _Undefined,
    Object? conflicts = _Undefined,
    Object? message = _Undefined,
    Object? totalAssigned = _Undefined,
    Object? conflictsDetected = _Undefined,
    Object? unassignedSubjects = _Undefined,
  }) {
    return GenerateScheduleResponse(
      success: success ?? this.success,
      schedules: schedules is List<_i2.Schedule>?
          ? schedules
          : this.schedules?.map((e0) => e0.copyWith()).toList(),
      conflicts: conflicts is List<_i3.ScheduleConflict>?
          ? conflicts
          : this.conflicts?.map((e0) => e0.copyWith()).toList(),
      message: message is String? ? message : this.message,
      totalAssigned: totalAssigned is int? ? totalAssigned : this.totalAssigned,
      conflictsDetected: conflictsDetected is int?
          ? conflictsDetected
          : this.conflictsDetected,
      unassignedSubjects: unassignedSubjects is int?
          ? unassignedSubjects
          : this.unassignedSubjects,
    );
  }
}
