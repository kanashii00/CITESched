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
import 'subject.dart' as _i2;
import 'faculty.dart' as _i3;
import 'room.dart' as _i4;
import 'timeslot.dart' as _i5;
import 'section.dart' as _i6;
import 'subject_type.dart' as _i7;
import 'package:citesched_client/src/protocol/protocol.dart' as _i8;

abstract class Schedule implements _i1.SerializableModel {
  Schedule._({
    this.id,
    required this.subjectId,
    this.subject,
    required this.facultyId,
    this.faculty,
    this.roomId,
    this.room,
    this.timeslotId,
    this.timeslot,
    required this.section,
    this.sectionId,
    this.sectionRef,
    this.loadTypes,
    this.units,
    this.hours,
    bool? isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : isActive = isActive ?? true;

  factory Schedule({
    int? id,
    required int subjectId,
    _i2.Subject? subject,
    required int facultyId,
    _i3.Faculty? faculty,
    int? roomId,
    _i4.Room? room,
    int? timeslotId,
    _i5.Timeslot? timeslot,
    required String section,
    int? sectionId,
    _i6.Section? sectionRef,
    List<_i7.SubjectType>? loadTypes,
    double? units,
    double? hours,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _ScheduleImpl;

  factory Schedule.fromJson(Map<String, dynamic> jsonSerialization) {
    return Schedule(
      id: jsonSerialization['id'] as int?,
      subjectId: jsonSerialization['subjectId'] as int,
      subject: jsonSerialization['subject'] == null
          ? null
          : _i8.Protocol().deserialize<_i2.Subject>(
              jsonSerialization['subject'],
            ),
      facultyId: jsonSerialization['facultyId'] as int,
      faculty: jsonSerialization['faculty'] == null
          ? null
          : _i8.Protocol().deserialize<_i3.Faculty>(
              jsonSerialization['faculty'],
            ),
      roomId: jsonSerialization['roomId'] as int?,
      room: jsonSerialization['room'] == null
          ? null
          : _i8.Protocol().deserialize<_i4.Room>(jsonSerialization['room']),
      timeslotId: jsonSerialization['timeslotId'] as int?,
      timeslot: jsonSerialization['timeslot'] == null
          ? null
          : _i8.Protocol().deserialize<_i5.Timeslot>(
              jsonSerialization['timeslot'],
            ),
      section: jsonSerialization['section'] as String,
      sectionId: jsonSerialization['sectionId'] as int?,
      sectionRef: jsonSerialization['sectionRef'] == null
          ? null
          : _i8.Protocol().deserialize<_i6.Section>(
              jsonSerialization['sectionRef'],
            ),
      loadTypes: jsonSerialization['loadTypes'] == null
          ? null
          : _i8.Protocol().deserialize<List<_i7.SubjectType>>(
              jsonSerialization['loadTypes'],
            ),
      units: (jsonSerialization['units'] as num?)?.toDouble(),
      hours: (jsonSerialization['hours'] as num?)?.toDouble(),
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

  int subjectId;

  _i2.Subject? subject;

  int facultyId;

  _i3.Faculty? faculty;

  int? roomId;

  _i4.Room? room;

  int? timeslotId;

  _i5.Timeslot? timeslot;

  String section;

  int? sectionId;

  _i6.Section? sectionRef;

  List<_i7.SubjectType>? loadTypes;

  double? units;

  double? hours;

  bool isActive;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Schedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Schedule copyWith({
    int? id,
    int? subjectId,
    _i2.Subject? subject,
    int? facultyId,
    _i3.Faculty? faculty,
    int? roomId,
    _i4.Room? room,
    int? timeslotId,
    _i5.Timeslot? timeslot,
    String? section,
    int? sectionId,
    _i6.Section? sectionRef,
    List<_i7.SubjectType>? loadTypes,
    double? units,
    double? hours,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Schedule',
      if (id != null) 'id': id,
      'subjectId': subjectId,
      if (subject != null) 'subject': subject?.toJson(),
      'facultyId': facultyId,
      if (faculty != null) 'faculty': faculty?.toJson(),
      if (roomId != null) 'roomId': roomId,
      if (room != null) 'room': room?.toJson(),
      if (timeslotId != null) 'timeslotId': timeslotId,
      if (timeslot != null) 'timeslot': timeslot?.toJson(),
      'section': section,
      if (sectionId != null) 'sectionId': sectionId,
      if (sectionRef != null) 'sectionRef': sectionRef?.toJson(),
      if (loadTypes != null)
        'loadTypes': loadTypes?.toJson(valueToJson: (v) => v.toJson()),
      if (units != null) 'units': units,
      if (hours != null) 'hours': hours,
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

class _ScheduleImpl extends Schedule {
  _ScheduleImpl({
    int? id,
    required int subjectId,
    _i2.Subject? subject,
    required int facultyId,
    _i3.Faculty? faculty,
    int? roomId,
    _i4.Room? room,
    int? timeslotId,
    _i5.Timeslot? timeslot,
    required String section,
    int? sectionId,
    _i6.Section? sectionRef,
    List<_i7.SubjectType>? loadTypes,
    double? units,
    double? hours,
    bool? isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         subjectId: subjectId,
         subject: subject,
         facultyId: facultyId,
         faculty: faculty,
         roomId: roomId,
         room: room,
         timeslotId: timeslotId,
         timeslot: timeslot,
         section: section,
         sectionId: sectionId,
         sectionRef: sectionRef,
         loadTypes: loadTypes,
         units: units,
         hours: hours,
         isActive: isActive,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Schedule]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Schedule copyWith({
    Object? id = _Undefined,
    int? subjectId,
    Object? subject = _Undefined,
    int? facultyId,
    Object? faculty = _Undefined,
    Object? roomId = _Undefined,
    Object? room = _Undefined,
    Object? timeslotId = _Undefined,
    Object? timeslot = _Undefined,
    String? section,
    Object? sectionId = _Undefined,
    Object? sectionRef = _Undefined,
    Object? loadTypes = _Undefined,
    Object? units = _Undefined,
    Object? hours = _Undefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id is int? ? id : this.id,
      subjectId: subjectId ?? this.subjectId,
      subject: subject is _i2.Subject? ? subject : this.subject?.copyWith(),
      facultyId: facultyId ?? this.facultyId,
      faculty: faculty is _i3.Faculty? ? faculty : this.faculty?.copyWith(),
      roomId: roomId is int? ? roomId : this.roomId,
      room: room is _i4.Room? ? room : this.room?.copyWith(),
      timeslotId: timeslotId is int? ? timeslotId : this.timeslotId,
      timeslot: timeslot is _i5.Timeslot?
          ? timeslot
          : this.timeslot?.copyWith(),
      section: section ?? this.section,
      sectionId: sectionId is int? ? sectionId : this.sectionId,
      sectionRef: sectionRef is _i6.Section?
          ? sectionRef
          : this.sectionRef?.copyWith(),
      loadTypes: loadTypes is List<_i7.SubjectType>?
          ? loadTypes
          : this.loadTypes?.map((e0) => e0).toList(),
      units: units is double? ? units : this.units,
      hours: hours is double? ? hours : this.hours,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
