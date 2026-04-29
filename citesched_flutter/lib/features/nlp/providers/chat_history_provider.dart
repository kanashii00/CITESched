import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

String? _activeRole(Ref ref) {
  return ref.read(authProvider.notifier).selectedRole;
}

bool _matchesActiveRole({
  required String? activeRole,
  required String? itemRole,
}) {
  if (activeRole == null || activeRole.isEmpty) return true;
  return itemRole == activeRole;
}

bool _matchesSessionRole({
  required String? activeRole,
  required ChatSessionSummary summary,
}) {
  if (activeRole == null || activeRole.isEmpty) return true;

  final normalizedTitle = summary.title.trim().toLowerCase();
  final normalizedSessionId = summary.sessionId.trim().toLowerCase();
  return normalizedTitle.startsWith('$activeRole chat ') ||
      normalizedSessionId.startsWith('${activeRole}_chat_');
}

final chatHistoryProvider = FutureProvider.family<List<ChatHistory>, int>((
  ref,
  limit,
) async {
  final activeRole = _activeRole(ref);
  final items = await client.chatHistory.getMyHistory(
    role: activeRole,
    limit: 200,
  );
  final filtered = items
      .where(
        (entry) => _matchesActiveRole(
          activeRole: activeRole,
          itemRole: entry.role,
        ),
      )
      .take(limit)
      .toList();
  return filtered;
});

final chatHistorySessionsProvider =
    FutureProvider.family<List<ChatSessionSummary>, int>((
  ref,
  limit,
) async {
  final activeRole = _activeRole(ref);
  final sessions = await client.chatHistory.getMySessions(
    role: activeRole,
    limit: 200,
  );
  final filtered = sessions
      .where(
        (entry) => _matchesSessionRole(
          activeRole: activeRole,
          summary: entry,
        ),
      )
      .take(limit)
      .toList();
  return filtered;
});

final chatHistorySessionProvider =
    FutureProvider.family<List<ChatHistory>, String>((
  ref,
  sessionId,
) async {
  final activeRole = _activeRole(ref);
  final items = await client.chatHistory.getSessionHistory(
    sessionId: sessionId,
    role: activeRole,
    limit: 200,
  );
  return items
      .where(
        (entry) => _matchesActiveRole(
          activeRole: activeRole,
          itemRole: entry.role,
        ),
      )
      .toList();
});

final chatHistoryDeleteProvider = FutureProvider.family<bool, String>((
  ref,
  sessionId,
) async {
  return await client.nLP.deleteChatSession(
    sessionId: sessionId,
    role: _activeRole(ref),
  );
});
