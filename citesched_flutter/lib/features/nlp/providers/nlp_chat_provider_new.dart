import 'dart:convert';
import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/nlp/models/chat_message.dart';
import 'package:citesched_flutter/features/nlp/services/nlp_service.dart';
import 'package:citesched_flutter/features/nlp/utils/nlp_constants.dart';
import 'package:citesched_flutter/features/nlp/utils/nlp_query_parser.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/nlp/providers/chat_history_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nlpChatProvider = NotifierProvider<NLPChatNotifier, NLPChatState>(
  NLPChatNotifier.new,
);

class NLPChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;
  final ChatContext context;

  NLPChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    ChatContext? context,
  }) : context = context ?? const ChatContext();

  NLPChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
    ChatContext? context,
  }) {
    return NLPChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      context: context ?? this.context,
    );
  }
}

class ChatContext {
  final String? lastRoomName;
  final ScheduleContext? lastScheduleContext;

  const ChatContext({
    this.lastRoomName,
    this.lastScheduleContext,
  });

  ChatContext copyWith({
    String? lastRoomName,
    ScheduleContext? lastScheduleContext,
  }) {
    return ChatContext(
      lastRoomName: lastRoomName ?? this.lastRoomName,
      lastScheduleContext: lastScheduleContext ?? this.lastScheduleContext,
    );
  }
}

class ScheduleContext {
  final String type; // my | faculty | section
  final String value;

  const ScheduleContext({
    required this.type,
    required this.value,
  });
}

class NLPChatNotifier extends Notifier<NLPChatState> {
  bool _initialized = false;
  bool _pendingTimetable = false;
  String? _sessionId;
  String? _sessionTitle;

  String? _selectedRole() => ref.read(authProvider.notifier).selectedRole;

  String _effectiveRole() {
    final selectedRole = _selectedRole();
    if (selectedRole != null && selectedRole.isNotEmpty) return selectedRole;

    final auth = ref.read(authProvider);
    final scopes = auth?.scopeNames ?? const <String>[];
    if (scopes.contains('admin')) return 'admin';
    if (scopes.contains('faculty')) return 'faculty';
    if (scopes.contains('student')) return 'student';
    return 'chat';
  }

  @override
  NLPChatState build() {
    Future.microtask(_initializeWelcome);
    return NLPChatState();
  }

  void _initializeWelcome() {
    if (!_initialized) {
      _ensureSession();
      _addMessage(
        NLPConstants.defaultHelpMessage,
        MessageSender.assistant,
      );
      _initialized = true;
    }
  }

  /// Clears all messages from the chat history
  void clearChat() {
    _sessionId = null;
    _sessionTitle = null;
    _pendingTimetable = false;
    state = NLPChatState();
    _initializeWelcome();
  }

  void setActiveSession(String sessionId, String? sessionTitle) {
    _sessionId = sessionId;
    _sessionTitle = sessionTitle ?? _sessionTitle;
    _pendingTimetable = false;
  }

  /// Sends a user query to the NLP service
  Future<void> sendQuery(String userQuery) async {
    // Validate query
    if (!NLPQueryParser.isValidQuery(userQuery)) {
      _addMessage(
        'Please enter a valid query.',
        MessageSender.assistant,
      );
      return;
    }

    // Sanitize query
    final sanitizedQuery = NLPQueryParser.sanitizeQuery(userQuery);
    _ensureSession();
    final contextualQuery = _applyContextToQuery(
      _applyTimetableDefault(sanitizedQuery),
    );

    // Add user message
    _addMessage(contextualQuery, MessageSender.user);

    // Set loading state
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Call NLP service
      final response = await ref
          .read(nlpServiceProvider)
          .queryNLP(
            contextualQuery,
            sessionId: _sessionId,
            sessionTitle: _sessionTitle,
          );

      // Add assistant response
      final metadata =
          _parseMetadata(response.dataJson) ?? <String, dynamic>{};
      if (_pendingTimetable) {
        metadata['showTimetable'] = true;
        _pendingTimetable = false;
      }

      _addMessage(
        response.text,
        MessageSender.assistant,
        responseType: response.intent.name,
        metadata: metadata.isEmpty ? null : metadata,
        schedules: response.schedules,
      );

      _updateContextFromResponse(
        response.intent,
        response.schedules,
        response.dataJson,
      );

      state = state.copyWith(isLoading: false);
      ref.invalidate(chatHistorySessionsProvider);
      if (_sessionId != null) {
        ref.invalidate(chatHistorySessionProvider(_sessionId!));
      }
    } catch (e) {
      debugPrint('NLP Error: $e');
      _addMessage(
        'Sorry, I encountered an error processing your request. Please try again.',
        MessageSender.assistant,
      );
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      ref.invalidate(chatHistorySessionsProvider);
      if (_sessionId != null) {
        ref.invalidate(chatHistorySessionProvider(_sessionId!));
      }
    }
  }

  /// Adds a message to the chat
  void _addMessage(
    String text,
    MessageSender sender, {
    String? responseType,
    Map<String, dynamic>? metadata,
    List<Schedule>? schedules,
  }) {
    final message = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      sender: sender,
      timestamp: DateTime.now(),
      responseType: responseType,
      metadata: metadata,
      schedules: schedules,
    );

    state = state.copyWith(
      messages: [...state.messages, message],
    );
  }

  /// Parses metadata from JSON string if available
  Map<String, dynamic>? _parseMetadata(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Failed to parse metadata: $e');
      return null;
    }
  }

  String _applyTimetableDefault(String query) {
    final lowered = query.toLowerCase();
    final isTimetable = lowered.contains('timetable');
    if (!isTimetable) return query;

    _pendingTimetable = true;
    if (_hasExplicitScheduleTarget(lowered) || _isAdmin()) return query;
    return _prefixScheduleQuery(query, 'my schedule');
  }

  bool _isAdmin() {
    final auth = ref.read(authProvider);
    final scopes = auth?.scopeNames ?? const [];
    return scopes.contains('admin');
  }

  void _ensureSession() {
    if (_sessionId != null && _sessionTitle != null) return;
    final now = DateTime.now();
    final role = _effectiveRole();
    _sessionId = '${role}_chat_${now.microsecondsSinceEpoch}';
    _sessionTitle = _generateSessionTitle(now, role);
  }

  String _generateSessionTitle(DateTime now, [String? adoptedRole]) {
    final role = adoptedRole ?? _effectiveRole();
    final dateLabel =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (role == 'admin') return 'Admin Chat $dateLabel';
    if (role == 'faculty') return 'Faculty Chat $dateLabel';
    if (role == 'student') return 'Student Chat $dateLabel';
    return 'Chat $dateLabel';
  }

  void _updateContextFromResponse(
    NLPIntent intent,
    List<Schedule>? schedules,
    String? dataJson,
  ) {
    final metadata = dataJson != null ? _parseMetadata(dataJson) : null;
    var context = state.context;

    if (intent == NLPIntent.roomStatus && metadata != null) {
      final roomName = metadata['roomName'] as String?;
      if (roomName != null && roomName.isNotEmpty) {
        context = context.copyWith(lastRoomName: roomName);
      }
    }

    if (intent == NLPIntent.schedule && metadata != null) {
      final contextType = metadata['contextType'] as String?;
      final contextValue = metadata['contextValue'] as String?;
      if (contextType != null &&
          contextValue != null &&
          contextValue.isNotEmpty) {
        context = context.copyWith(
          lastScheduleContext: ScheduleContext(
            type: contextType,
            value: contextValue,
          ),
        );
      }
    }

    if (intent == NLPIntent.schedule &&
        schedules != null &&
        schedules.length == 1) {
      final roomName = schedules.first.room?.name;
      if (roomName != null && roomName.isNotEmpty) {
        context = context.copyWith(lastRoomName: roomName);
      }
    }

    state = state.copyWith(context: context);
  }

  String _applyContextToQuery(String query) {
    final lowered = query.toLowerCase();
    var updatedQuery = query;

    // Resolve "lab or lecture" without a room name using last room context.
    if (_isRoomTypeQuestion(lowered)) {
      final lastRoom = state.context.lastRoomName;
      if (lastRoom != null &&
          lastRoom.isNotEmpty &&
          !lowered.contains(lastRoom.toLowerCase())) {
        updatedQuery = 'Is $lastRoom a lab or lecture room?';
      }
    }

    // Resolve "schedule on Monday" using last schedule context.
    if (_containsDayOfWeek(lowered) &&
        _hasScheduleIntent(lowered) &&
        !_hasExplicitScheduleTarget(lowered)) {
      final scheduleContext = state.context.lastScheduleContext;
      if (scheduleContext != null) {
        if (scheduleContext.type == 'my') {
          updatedQuery = _prefixScheduleQuery(updatedQuery, 'my schedule');
        } else if (scheduleContext.type == 'faculty') {
          updatedQuery = _prefixScheduleQuery(
            updatedQuery,
            'schedule of ${scheduleContext.value}',
          );
        } else if (scheduleContext.type == 'section') {
          updatedQuery = _prefixScheduleQuery(
            updatedQuery,
            'schedule for ${scheduleContext.value}',
          );
        }
      }
    }

    return updatedQuery;
  }

  bool _isRoomTypeQuestion(String query) {
    final hasLab = query.contains('lab') || query.contains('laboratory');
    final hasLecture = query.contains('lecture');
    return hasLab && hasLecture;
  }

  bool _hasScheduleIntent(String query) {
    return query.contains('schedule') ||
        query.contains('timetable') ||
        query.contains('class') ||
        query.contains('classes');
  }

  bool _containsDayOfWeek(String query) {
    const tokens = [
      'mon',
      'monday',
      'tue',
      'tues',
      'tuesday',
      'wed',
      'wednesday',
      'thu',
      'thur',
      'thurs',
      'thursday',
      'fri',
      'friday',
      'sat',
      'saturday',
      'sun',
      'sunday',
    ];
    return tokens.any((t) => RegExp(r'\b' + t + r'\b').hasMatch(query));
  }

  bool _hasExplicitScheduleTarget(String query) {
    if (query.contains('my ')) return true;
    if (query.contains('prof') || query.contains('sir') || query.contains('maam')) {
      return true;
    }
    final sectionRegex = RegExp(r'\b([a-zA-Z]{1,4})?\s?\d[a-zA-Z]\b');
    return sectionRegex.hasMatch(query);
  }

  String _prefixScheduleQuery(String query, String prefix) {
    final scheduleRegex = RegExp(r'\bschedule\b', caseSensitive: false);
    if (scheduleRegex.hasMatch(query)) {
      return query.replaceFirst(scheduleRegex, prefix);
    }
    return '$prefix $query';
  }
}
