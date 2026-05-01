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

abstract class RoomUtilizationReport
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  RoomUtilizationReport._({
    required this.roomId,
    required this.roomName,
    required this.utilizationPercentage,
    required this.totalBookings,
    required this.isActive,
    this.program,
  });

  factory RoomUtilizationReport({
    required int roomId,
    required String roomName,
    required double utilizationPercentage,
    required int totalBookings,
    required bool isActive,
    String? program,
  }) = _RoomUtilizationReportImpl;

  factory RoomUtilizationReport.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return RoomUtilizationReport(
      roomId: jsonSerialization['roomId'] as int,
      roomName: jsonSerialization['roomName'] as String,
      utilizationPercentage: (jsonSerialization['utilizationPercentage'] as num)
          .toDouble(),
      totalBookings: jsonSerialization['totalBookings'] as int,
      isActive: jsonSerialization['isActive'] as bool,
      program: jsonSerialization['program'] as String?,
    );
  }

  int roomId;

  String roomName;

  double utilizationPercentage;

  int totalBookings;

  bool isActive;

  String? program;

  /// Returns a shallow copy of this [RoomUtilizationReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  RoomUtilizationReport copyWith({
    int? roomId,
    String? roomName,
    double? utilizationPercentage,
    int? totalBookings,
    bool? isActive,
    String? program,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomUtilizationReport',
      'roomId': roomId,
      'roomName': roomName,
      'utilizationPercentage': utilizationPercentage,
      'totalBookings': totalBookings,
      'isActive': isActive,
      if (program != null) 'program': program,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RoomUtilizationReport',
      'roomId': roomId,
      'roomName': roomName,
      'utilizationPercentage': utilizationPercentage,
      'totalBookings': totalBookings,
      'isActive': isActive,
      if (program != null) 'program': program,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomUtilizationReportImpl extends RoomUtilizationReport {
  _RoomUtilizationReportImpl({
    required int roomId,
    required String roomName,
    required double utilizationPercentage,
    required int totalBookings,
    required bool isActive,
    String? program,
  }) : super._(
         roomId: roomId,
         roomName: roomName,
         utilizationPercentage: utilizationPercentage,
         totalBookings: totalBookings,
         isActive: isActive,
         program: program,
       );

  /// Returns a shallow copy of this [RoomUtilizationReport]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  RoomUtilizationReport copyWith({
    int? roomId,
    String? roomName,
    double? utilizationPercentage,
    int? totalBookings,
    bool? isActive,
    Object? program = _Undefined,
  }) {
    return RoomUtilizationReport(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      utilizationPercentage:
          utilizationPercentage ?? this.utilizationPercentage,
      totalBookings: totalBookings ?? this.totalBookings,
      isActive: isActive ?? this.isActive,
      program: program is String? ? program : this.program,
    );
  }
}
