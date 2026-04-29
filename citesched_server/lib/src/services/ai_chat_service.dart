import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class AiChatService {
  Future<AiChatSession> createSession(
    Session session, {
    required String userId,
    required String roleType,
    required String title,
  }) async {
    final now = DateTime.now().toUtc();
    return AiChatSession.db.insertRow(
      session,
      AiChatSession(
        userId: userId,
        roleType: roleType,
        title: title,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<AiChatSession?> getOwnedSession(
    Session session, {
    required int sessionId,
    required String userId,
    required String roleType,
  }) {
    return AiChatSession.db.findFirstRow(
      session,
      where: (t) =>
          t.id.equals(sessionId) &
          t.userId.equals(userId) &
          t.roleType.equals(roleType),
    );
  }

  Future<void> touchSession(
    Session session,
    AiChatSession chatSession, {
    String? title,
  }) async {
    await AiChatSession.db.updateRow(
      session,
      chatSession.copyWith(
        title: title ?? chatSession.title,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<AiChatMessage> saveMessage(
    Session session, {
    required int sessionId,
    required String sender,
    required String message,
  }) async {
    final inserted = await AiChatMessage.db.insertRow(
      session,
      AiChatMessage(
        sessionRecordId: sessionId,
        sender: sender,
        message: message,
        timestamp: DateTime.now().toUtc(),
      ),
    );

    final chatSession = await AiChatSession.db.findById(session, sessionId);
    if (chatSession != null) {
      await touchSession(session, chatSession);
    }

    return inserted;
  }

  Future<List<AiChatMessage>> getMessages(
    Session session, {
    required int sessionId,
    int limit = 100,
  }) {
    return AiChatMessage.db.find(
      session,
      where: (t) => t.sessionRecordId.equals(sessionId),
      orderBy: (t) => t.timestamp,
      orderDescending: false,
      limit: limit.clamp(1, 500),
    );
  }

  Future<List<AiChatSession>> getSessions(
    Session session, {
    required String userId,
    required String roleType,
    int limit = 30,
  }) {
    return AiChatSession.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.roleType.equals(roleType),
      orderBy: (t) => t.updatedAt,
      orderDescending: true,
      limit: limit.clamp(1, 200),
    );
  }

  Future<bool> deleteSession(
    Session session, {
    required int sessionId,
    required String userId,
    required String roleType,
  }) async {
    final owned = await getOwnedSession(
      session,
      sessionId: sessionId,
      userId: userId,
      roleType: roleType,
    );
    if (owned == null) return false;

    await AiChatMessage.db.deleteWhere(
      session,
      where: (t) => t.sessionRecordId.equals(sessionId),
    );
    await AiChatSession.db.deleteRow(session, owned);
    return true;
  }

  List<Map<String, String>> toConversationHistory(List<AiChatMessage> messages) {
    return messages
        .map(
          (message) => <String, String>{
            'role': message.sender == 'assistant' ? 'assistant' : 'user',
            'text': message.message,
          },
        )
        .toList();
  }
}
