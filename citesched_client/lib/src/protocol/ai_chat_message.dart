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
import 'ai_chat_session.dart' as _i2;
import 'package:citesched_client/src/protocol/protocol.dart' as _i3;

abstract class AiChatMessage implements _i1.SerializableModel {
  AiChatMessage._({
    this.id,
    required this.sessionRecordId,
    this.sessionRecord,
    required this.sender,
    required this.message,
    required this.timestamp,
  });

  factory AiChatMessage({
    int? id,
    required int sessionRecordId,
    _i2.AiChatSession? sessionRecord,
    required String sender,
    required String message,
    required DateTime timestamp,
  }) = _AiChatMessageImpl;

  factory AiChatMessage.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiChatMessage(
      id: jsonSerialization['id'] as int?,
      sessionRecordId: jsonSerialization['sessionRecordId'] as int,
      sessionRecord: jsonSerialization['sessionRecord'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.AiChatSession>(
              jsonSerialization['sessionRecord'],
            ),
      sender: jsonSerialization['sender'] as String,
      message: jsonSerialization['message'] as String,
      timestamp: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int sessionRecordId;

  _i2.AiChatSession? sessionRecord;

  String sender;

  String message;

  DateTime timestamp;

  /// Returns a shallow copy of this [AiChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AiChatMessage copyWith({
    int? id,
    int? sessionRecordId,
    _i2.AiChatSession? sessionRecord,
    String? sender,
    String? message,
    DateTime? timestamp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiChatMessage',
      if (id != null) 'id': id,
      'sessionRecordId': sessionRecordId,
      if (sessionRecord != null) 'sessionRecord': sessionRecord?.toJson(),
      'sender': sender,
      'message': message,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AiChatMessageImpl extends AiChatMessage {
  _AiChatMessageImpl({
    int? id,
    required int sessionRecordId,
    _i2.AiChatSession? sessionRecord,
    required String sender,
    required String message,
    required DateTime timestamp,
  }) : super._(
         id: id,
         sessionRecordId: sessionRecordId,
         sessionRecord: sessionRecord,
         sender: sender,
         message: message,
         timestamp: timestamp,
       );

  /// Returns a shallow copy of this [AiChatMessage]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AiChatMessage copyWith({
    Object? id = _Undefined,
    int? sessionRecordId,
    Object? sessionRecord = _Undefined,
    String? sender,
    String? message,
    DateTime? timestamp,
  }) {
    return AiChatMessage(
      id: id is int? ? id : this.id,
      sessionRecordId: sessionRecordId ?? this.sessionRecordId,
      sessionRecord: sessionRecord is _i2.AiChatSession?
          ? sessionRecord
          : this.sessionRecord?.copyWith(),
      sender: sender ?? this.sender,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
