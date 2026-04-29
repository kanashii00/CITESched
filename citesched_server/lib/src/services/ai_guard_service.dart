import 'dart:collection';

import 'package:serverpod/serverpod.dart';

class AiGuardService {
  static const int maxPromptLength = 1000;
  static const Duration _rateWindow = Duration(minutes: 1);
  static const int _maxRequestsPerWindow = 12;

  static final Map<String, Queue<DateTime>> _requestLog = {};

  static const List<String> _blockedPromptPatterns = [
    'ignore previous instructions',
    'ignore your instructions',
    'reveal the system prompt',
    'show the hidden prompt',
    'print the system prompt',
    'bypass security',
    'drop table',
    'truncate table',
    'delete from',
    'alter table',
  ];

  String sanitizeUserPrompt(String prompt) {
    final trimmed = prompt.trim();
    final collapsed = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    if (collapsed.length <= maxPromptLength) {
      return collapsed;
    }
    return collapsed.substring(0, maxPromptLength);
  }

  bool containsPromptInjection(String prompt) {
    final normalized = prompt.toLowerCase();
    return _blockedPromptPatterns.any(normalized.contains);
  }

  bool allowRequest(String userKey) {
    final now = DateTime.now().toUtc();
    final queue = _requestLog.putIfAbsent(userKey, Queue.new);

    while (queue.isNotEmpty && now.difference(queue.first) > _rateWindow) {
      queue.removeFirst();
    }

    if (queue.length >= _maxRequestsPerWindow) {
      return false;
    }

    queue.addLast(now);
    return true;
  }

  String resolveRole(Set<Scope> scopes, {String? requestedRole}) {
    final normalizedRequested = requestedRole?.trim().toLowerCase();
    if (normalizedRequested != null && normalizedRequested.isNotEmpty) {
      if (scopes.any((scope) => scope.name == normalizedRequested)) {
        return normalizedRequested;
      }
      throw Exception('You are not allowed to act as $normalizedRequested.');
    }

    if (scopes.any((scope) => scope.name == 'admin')) return 'admin';
    if (scopes.any((scope) => scope.name == 'faculty')) return 'faculty';
    if (scopes.any((scope) => scope.name == 'student')) return 'student';
    throw Exception('No valid scheduling role was found for this account.');
  }
}
