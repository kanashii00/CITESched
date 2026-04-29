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

abstract class AiChatSession implements _i1.SerializableModel {
  AiChatSession._({
    this.id,
    required this.userId,
    required this.roleType,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AiChatSession({
    int? id,
    required String userId,
    required String roleType,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AiChatSessionImpl;

  factory AiChatSession.fromJson(Map<String, dynamic> jsonSerialization) {
    return AiChatSession(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as String,
      roleType: jsonSerialization['roleType'] as String,
      title: jsonSerialization['title'] as String,
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

  String userId;

  String roleType;

  String title;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [AiChatSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AiChatSession copyWith({
    int? id,
    String? userId,
    String? roleType,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AiChatSession',
      if (id != null) 'id': id,
      'userId': userId,
      'roleType': roleType,
      'title': title,
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

class _AiChatSessionImpl extends AiChatSession {
  _AiChatSessionImpl({
    int? id,
    required String userId,
    required String roleType,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         roleType: roleType,
         title: title,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [AiChatSession]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AiChatSession copyWith({
    Object? id = _Undefined,
    String? userId,
    String? roleType,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiChatSession(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      roleType: roleType ?? this.roleType,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
