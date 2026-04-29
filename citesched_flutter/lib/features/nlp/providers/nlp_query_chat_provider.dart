import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/nlp/providers/chat_history_provider.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final nlpQueryChatProvider =
    NotifierProvider<NLPQueryChatNotifier, NLPQueryChatState>(
      NLPQueryChatNotifier.new,
    );

class NLPQueryChatState {
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final String? sessionId;
  final String? sessionTitle;

  NLPQueryChatState({
    this.messages = const [],
    this.isLoading = false,
    this.sessionId,
    this.sessionTitle,
  });

  NLPQueryChatState copyWith({
    List<Map<String, dynamic>>? messages,
    bool? isLoading,
    String? sessionId,
    String? sessionTitle,
  }) {
    return NLPQueryChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      sessionId: sessionId ?? this.sessionId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
    );
  }
}

class NLPQueryChatNotifier extends Notifier<NLPQueryChatState> {
  static const _weeklySchedule = 'weekly schedule';
  static const List<({String from, String to})> _queryAliases = [
    (from: 'iskedyul', to: 'schedule'),
    (from: 'edyul', to: 'schedule'),
    (from: 'orasan', to: 'timetable'),
    (from: 'pakita', to: 'show'),
    (from: 'ipakita', to: 'show'),
    (from: 'tingnan', to: 'show'),
    (from: 'ano', to: 'what'),
    (from: 'anong', to: 'what'),
    (from: 'unsa', to: 'what'),
    (from: 'asa', to: 'where'),
    (from: 'nasaan', to: 'where'),
    (from: 'saan', to: 'where'),
    (from: 'bukas', to: 'tomorrow'),
    (from: 'ugma', to: 'tomorrow'),
    (from: 'ngayon', to: 'today'),
    (from: 'karon', to: 'today'),
    (from: 'klase', to: 'class'),
    (from: 'subject', to: 'subject'),
    (from: 'asignatura', to: 'subject'),
    (from: 'seksyon', to: 'section'),
    (from: 'kwarto', to: 'room'),
    (from: 'silid', to: 'room'),
    (from: 'konflikto', to: 'conflict'),
    (from: 'salungatan', to: 'conflict'),
    (from: 'libre', to: 'free'),
    (from: 'bakante', to: 'vacant'),
    (from: 'sunod', to: 'next'),
    (from: 'susunod', to: 'next'),
  ];
  bool _initialized = false;
  bool _pendingTimetable = false;
  String? _pendingScheduleView;

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
  NLPQueryChatState build() {
    if (!_initialized) {
      _initialized = true;
      return NLPQueryChatState(
        messages: [
          {
            'isUser': false,
            'text':
                "Hello! I'm your CITESched Assistant. I can help with schedules, teaching loads, timetables, room assignments, and conflict checks.",
          },
        ],
        sessionTitle: _generateSessionTitle(),
      );
    }
    return NLPQueryChatState();
  }

  void clearChat() {
    _pendingTimetable = false;
    _pendingScheduleView = null;
    state = NLPQueryChatState(
      messages: [
        {
          'isUser': false,
          'text':
              "Hello! I'm your CITESched Assistant. I can help with schedules, teaching loads, timetables, room assignments, and conflict checks.",
        },
      ],
      isLoading: false,
      sessionTitle: _generateSessionTitle(),
    );
  }

  void closeDeletedSession(String sessionId) {
    if (state.sessionId?.trim() != sessionId.trim()) return;
    clearChat();
  }

  void setActiveSession(String sessionId, String? sessionTitle) {
    _pendingTimetable = false;
    _pendingScheduleView = null;
    state = state.copyWith(
      sessionId: sessionId,
      sessionTitle: sessionTitle ?? state.sessionTitle,
    );
  }

  void loadSessionHistory({
    required String sessionId,
    String? sessionTitle,
    required List<ChatHistory> history,
  }) {
    _pendingTimetable = false;
    _pendingScheduleView = null;
    final restoredMessages = history
        .map(
          (entry) => <String, dynamic>{
            'isUser': entry.sender == 'user',
            'text': entry.text,
          },
        )
        .toList();

    state = NLPQueryChatState(
      messages: restoredMessages,
      isLoading: false,
      sessionId: sessionId,
      sessionTitle: sessionTitle ?? state.sessionTitle,
    );
  }

  Future<void> sendQuery(String query) async {
    if (query.trim().isEmpty) return;

    final userQuery = query.trim();
    final rawNormalized = _normalizeQuery(userQuery);
    final bypassRewrite = _isInformationalQuery(rawNormalized);
    var outbound = bypassRewrite ? userQuery : _rewriteSimpleQuery(userQuery);
    final normalized = _normalizeQuery(outbound);
    _pendingScheduleView = _detectRequestedScheduleView(normalized);
    if (_isTimetableQuery(normalized)) {
      _pendingTimetable = true;
      if (!_hasExplicitScheduleTarget(normalized) && !_isAdmin()) {
        outbound = _isStudent()
            ? 'section schedule $outbound'
            : 'my schedule $outbound';
      }
    }

    state = state.copyWith(
      messages: [
        ...state.messages,
        {'isUser': true, 'text': userQuery},
      ],
      isLoading: true,
    );

    try {
      await _ensureSession();
      final response = await client.nLP.query(
        outbound,
        sessionId: state.sessionId,
        sessionTitle: state.sessionTitle,
      );
      final dataJson = response.dataJson;
      final message = {
        'isUser': false,
        'text': response.text,
        'intent': response.intent,
        'schedules': response.schedules,
        'dataJson': dataJson,
      };
      if (_pendingTimetable) {
        message['showTimetable'] = true;
        if (_pendingScheduleView != null) {
          message['scheduleView'] = _pendingScheduleView;
        }
        _pendingTimetable = false;
        _pendingScheduleView = null;
      }
      state = state.copyWith(
        messages: [
          ...state.messages,
          message,
        ],
        isLoading: false,
      );
      ref.invalidate(chatHistorySessionsProvider);
      if (state.sessionId != null) {
        ref.invalidate(chatHistorySessionProvider(state.sessionId!));
      }
    } catch (_) {
      _pendingTimetable = false;
      _pendingScheduleView = null;
      state = state.copyWith(
        messages: [
          ...state.messages,
          {
            'isUser': false,
            'text':
                "I encountered an error while processing your request. Please try again later.",
            'isError': true,
          },
        ],
        isLoading: false,
      );
      ref.invalidate(chatHistorySessionsProvider);
      if (state.sessionId != null) {
        ref.invalidate(chatHistorySessionProvider(state.sessionId!));
      }
    }
  }

  Future<void> _ensureSession() async {
    if (state.sessionId != null && state.sessionId!.trim().isNotEmpty) {
      return;
    }

    final session = await client.nLP.createChatSession(
      role: _effectiveRole(),
      title: state.sessionTitle ?? _generateSessionTitle(),
    );

    state = state.copyWith(
      sessionId: session.id?.toString(),
      sessionTitle: session.title,
    );
  }

  bool _isTimetableQuery(String query) {
    return query.contains('timetable') ||
        query.contains('calendar') ||
        query.contains('table view') ||
        query.contains('calendar view') ||
        query.contains(_weeklySchedule);
  }

  String? _detectRequestedScheduleView(String query) {
    if (query.contains('calendar view') || query.contains('calendar')) {
      return 'calendar';
    }
    if (query.contains('table view') || query.contains('tabular')) {
      return 'table';
    }
    if (query.contains('timetable') || query.contains(_weeklySchedule)) {
      return 'calendar';
    }
    return null;
  }

  bool _hasExplicitScheduleTarget(String query) {
    if (query.contains('my ')) return true;
    if (query.contains('our ')) return true;
    if (query.contains('section')) return true;
    if (query.contains('prof') ||
        query.contains('sir') ||
        query.contains('maam')) {
      return true;
    }
    final sectionRegex = RegExp(r'\b([a-zA-Z]{1,4})?\s?\d[a-zA-Z]\b');
    return sectionRegex.hasMatch(query);
  }

  String _normalizeQuery(String query) {
    var normalized = query.toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
    for (final alias in _queryAliases) {
      normalized = normalized.replaceAllMapped(
        RegExp(r'\b' + RegExp.escape(alias.from) + r'\b'),
        (_) => alias.to,
      );
    }
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _rewriteSimpleQuery(String query) {
    var normalized = _normalizeQuery(query);
    final auth = ref.read(authProvider);
    final scopes = auth?.scopeNames ?? const [];
    final selectedRole = _selectedRole();
    final isStudent =
        selectedRole == 'student' ||
        (selectedRole == null && scopes.contains('student'));
    final isFaculty =
        selectedRole == 'faculty' ||
        (selectedRole == null && scopes.contains('faculty'));

    final asksSchedule = RegExp(
      r'\b(schedule|schedules|class schedule|classes|timetable|calendar|routine)\b',
    ).hasMatch(normalized);
    final asksConflict = RegExp(
      r'\b(conflict|conflicts|overlap|clash)\b',
    ).hasMatch(normalized);
    final asksLoad = RegExp(
      r'\b(load|units|teaching load)\b',
    ).hasMatch(normalized);
    final asksRoom = RegExp(r'\b(room|classroom|venue)\b').hasMatch(normalized);
    final asksSection = RegExp(r'\b(section)\b').hasMatch(normalized);
    final hasDayContext = RegExp(
      r'\b(today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
    ).hasMatch(normalized);
    final asksConflictExplanation = _isConflictExplanationQuery(normalized);

    if (asksSchedule) {
      normalized = _rewriteScheduleIntent(
        normalized: normalized,
        isStudent: isStudent,
        isFaculty: isFaculty,
        asksSection: asksSection,
        hasDayContext: hasDayContext,
      );
    }

    if (asksConflict && !asksConflictExplanation) {
      normalized = _rewriteConflictIntent(
        isStudent: isStudent,
        isFaculty: isFaculty,
      );
    }

    if (isFaculty && asksLoad && !normalized.contains('teaching load')) {
      normalized = 'my teaching load';
    }

    if (isStudent && asksRoom) {
      normalized = _rewriteStudentRoomIntent(normalized);
    }

    return normalized;
  }

  bool _isInformationalQuery(String query) {
    final asksConflictExplanation = _isConflictExplanationQuery(query);
    final asksSystemAbout = RegExp(
      r'\b(what|exactly|about|system|citesched|does|manage|purpose)\b',
    ).hasMatch(query);
    final asksCapability = RegExp(
      r'\b(can|help|ask|do)\b',
    ).hasMatch(query) &&
        RegExp(r'\b(system|citesched|you)\b').hasMatch(query);
    final asksDashboardFeatures = RegExp(
      r'\b(admin|student|faculty)\b',
    ).hasMatch(query) &&
        RegExp(
          r'\b(dashboard|side|portal|panel|feature|features|module|modules|list)\b',
        ).hasMatch(query);
    final asksFormatOnly = RegExp(
      r'\b(bullet|bullets|format|formatted)\b',
    ).hasMatch(query);

    return asksConflictExplanation ||
        asksSystemAbout ||
        asksCapability ||
        asksDashboardFeatures ||
        asksFormatOnly;
  }

  String _rewriteScheduleIntent({
    required String normalized,
    required bool isStudent,
    required bool isFaculty,
    required bool asksSection,
    required bool hasDayContext,
  }) {
    var rewritten = normalized
        .replaceAll('schedules', 'schedule')
        .replaceAll('timetable', _weeklySchedule)
        .replaceAll('calendar', _weeklySchedule)
        .replaceAll('routine', 'schedule');

    if (isStudent) {
      rewritten = rewritten
          .replaceAll('my schedule', 'section schedule')
          .replaceAll('my class schedule', 'section schedule')
          .replaceAll('my $_weeklySchedule', 'section $_weeklySchedule');
      if (!rewritten.contains('section') && !asksSection) {
        rewritten = 'section $rewritten';
      }
    } else if (isFaculty && !rewritten.contains('my')) {
      rewritten = 'my $rewritten';
    }

    if (hasDayContext && !rewritten.contains('on ')) {
      rewritten = rewritten.replaceFirst(' schedule ', ' schedule on ');
    }
    return rewritten;
  }

  String _rewriteConflictIntent({
    required bool isStudent,
    required bool isFaculty,
  }) {
    if (isStudent) return 'check conflicts for section';
    if (isFaculty) return 'check my teaching conflicts';
    return 'check conflicts';
  }

  bool _isConflictExplanationQuery(String query) {
    final asksConflict = RegExp(r'\b(conflict|conflicts|overlap|clash)\b')
        .hasMatch(query);
    final asksExplanation = RegExp(
      r'\b(how|why|what if|manage|handled|handle|resolve|fix|avoid|prevent)\b',
    ).hasMatch(query);
    return asksConflict && asksExplanation;
  }

  String _rewriteStudentRoomIntent(String normalized) {
    final asksNextClass =
        normalized.contains('next') && normalized.contains('class');
    if (asksNextClass) {
      return 'what is the next class for section';
    }
    return 'show section schedule';
  }

  bool _isAdmin() {
    final selectedRole = _selectedRole();
    if (selectedRole != null) return selectedRole == 'admin';
    final auth = ref.read(authProvider);
    final scopes = auth?.scopeNames ?? const [];
    return scopes.contains('admin');
  }

  bool _isStudent() {
    final selectedRole = _selectedRole();
    if (selectedRole != null) return selectedRole == 'student';
    final auth = ref.read(authProvider);
    final scopes = auth?.scopeNames ?? const [];
    return scopes.contains('student');
  }

  String _generateSessionTitle() {
    final role = _effectiveRole();
    final now = DateTime.now();
    final dateLabel =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (role == 'admin') return 'Admin Chat $dateLabel';
    if (role == 'faculty') return 'Faculty Chat $dateLabel';
    if (role == 'student') return 'Student Chat $dateLabel';
    return 'Chat $dateLabel';
  }
}
