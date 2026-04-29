import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../services/ai_chat_service.dart';
import '../services/ai_guard_service.dart';

class ChatHistoryEndpoint extends Endpoint {
  static const String _authenticationRequiredMessage =
      'Authentication required.';

  final AiGuardService _guardService = AiGuardService();
  final AiChatService _chatService = AiChatService();

  @override
  bool get requireLogin => true;

  Future<List<ChatHistory>> getMyHistory(
    Session session, {
    String? role,
    int limit = 30,
  }) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception(_authenticationRequiredMessage);
    }

    final resolvedRole = _guardService.resolveRole(
      authInfo.scopes,
      requestedRole: role,
    );
    final userId = authInfo.userIdentifier.toString();

    return ChatHistory.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.role.equals(resolvedRole),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit.clamp(1, 200),
    );
  }

  Future<List<ChatSessionSummary>> getMySessions(
    Session session, {
    String? role,
    int limit = 30,
  }) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception(_authenticationRequiredMessage);
    }

    final resolvedRole = _guardService.resolveRole(
      authInfo.scopes,
      requestedRole: role,
    );
    final userId = authInfo.userIdentifier.toString();
    final rows = await ChatHistory.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.role.equals(resolvedRole),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 500,
    );

    final summaries = <String, ChatSessionSummary>{};
    for (final row in rows) {
      final rawSessionId = row.sessionId;
      final sessionId =
          (rawSessionId == null || rawSessionId.isEmpty)
              ? _legacySessionId(row.createdAt)
              : rawSessionId;
      if (summaries.containsKey(sessionId)) continue;

      summaries[sessionId] = ChatSessionSummary(
        sessionId: sessionId,
        title: row.sessionTitle ?? _defaultTitle(row.role, row.createdAt),
        lastMessageAt: row.createdAt,
        lastMessageText: row.text,
      );
    }

    final sorted = summaries.values.toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    return sorted.take(limit.clamp(1, 200)).toList();
  }

  Future<List<ChatHistory>> getSessionHistory(
    Session session, {
    required String sessionId,
    String? role,
    int limit = 200,
  }) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception(_authenticationRequiredMessage);
    }

    final resolvedRole = _guardService.resolveRole(
      authInfo.scopes,
      requestedRole: role,
    );
    final userId = authInfo.userIdentifier.toString();
    if (_isLegacySessionId(sessionId)) {
      final legacyRange = _legacyRangeFromSessionId(sessionId);
      return ChatHistory.db.find(
        session,
        where: (t) =>
            t.userId.equals(userId) &
            t.role.equals(resolvedRole) &
            t.sessionId.equals(null) &
            t.createdAt.between(legacyRange.$1, legacyRange.$2),
        orderBy: (t) => t.createdAt,
        orderDescending: false,
        limit: limit.clamp(1, 500),
      );
    }

    return ChatHistory.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) &
          t.role.equals(resolvedRole) &
          t.sessionId.equals(sessionId),
      orderBy: (t) => t.createdAt,
      orderDescending: false,
      limit: limit.clamp(1, 500),
    );
  }

  Future<bool> deleteSession(
    Session session, {
    required String sessionId,
    String? role,
  }) async {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception(_authenticationRequiredMessage);
    }

    final resolvedRole = _guardService.resolveRole(
      authInfo.scopes,
      requestedRole: role,
    );
    final userId = authInfo.userIdentifier.toString();
    final rows = _isLegacySessionId(sessionId)
        ? await ChatHistory.db.find(
            session,
            where: (t) =>
                t.userId.equals(userId) &
                t.role.equals(resolvedRole) &
                t.sessionId.equals(null) &
                t.createdAt.between(
                  _legacyRangeFromSessionId(sessionId).$1,
                  _legacyRangeFromSessionId(sessionId).$2,
                ),
            limit: 1000,
          )
        : await ChatHistory.db.find(
            session,
            where: (t) =>
                t.userId.equals(userId) &
                t.role.equals(resolvedRole) &
                t.sessionId.equals(sessionId),
            limit: 1000,
          );

    for (final row in rows) {
      await ChatHistory.db.deleteRow(session, row);
    }

    final parsedId = int.tryParse(sessionId);
    if (parsedId != null) {
      await _chatService.deleteSession(
        session,
        sessionId: parsedId,
        userId: userId,
        roleType: resolvedRole,
      );
    }

    return true;
  }

  String _defaultTitle(String role, DateTime createdAt) {
    final dateLabel =
        '${createdAt.year.toString().padLeft(4, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
    switch (role) {
      case 'admin':
        return 'Admin Chat $dateLabel';
      case 'faculty':
        return 'Faculty Chat $dateLabel';
      case 'student':
        return 'Student Chat $dateLabel';
      default:
        return 'Chat $dateLabel';
    }
  }

  bool _isLegacySessionId(String sessionId) {
    return sessionId.startsWith('legacy-');
  }

  String _legacySessionId(DateTime createdAt) {
    return 'legacy-${createdAt.year.toString().padLeft(4, '0')}${createdAt.month.toString().padLeft(2, '0')}${createdAt.day.toString().padLeft(2, '0')}';
  }

  (DateTime, DateTime) _legacyRangeFromSessionId(String sessionId) {
    final datePart = sessionId.replaceFirst('legacy-', '');
    if (datePart.length != 8) {
      final now = DateTime.now().toUtc();
      return (
        DateTime.utc(now.year, now.month, now.day),
        DateTime.utc(now.year, now.month, now.day + 1),
      );
    }
    final year = int.tryParse(datePart.substring(0, 4)) ?? 1970;
    final month = int.tryParse(datePart.substring(4, 6)) ?? 1;
    final day = int.tryParse(datePart.substring(6, 8)) ?? 1;
    final start = DateTime.utc(year, month, day);
    final end = start.add(const Duration(days: 1));
    return (start, end);
  }
}
