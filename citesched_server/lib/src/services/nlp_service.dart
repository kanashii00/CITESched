import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';
import '../generated/protocol.dart';
import 'ai_chat_service.dart';
import 'ai_grounding_service.dart';
import 'gemini_llm_provider.dart';
import 'conflict_service.dart';

class NLPService {
  final ConflictService _conflictService = ConflictService();
  final AiChatService _chatService = AiChatService();
  final AiGroundingService _groundingService = AiGroundingService();
  final LlmProvider _llmProvider;
  final DateTime Function() _now;

  static const String _facultyAccessRestrictedMessage =
      'Access restricted. Faculty accounts may only view personal schedule, load, and assigned timetable information.';
  static const String _studentAccessRestrictedMessage =
      'Access restricted. You may only access your personal academic schedule and assigned section timetable.';
  static const String _studentSectionRestrictedMessage =
      'Access restricted. Students may only view their own assigned section schedule.';
  static const String _unsupportedLanguageMessage =
      'CITESched AI currently supports English, Tagalog, and Bisaya only.';

  static const List<({String from, String to})> _multilingualPhraseAliases = [
    (from: 'tubaga ko sa bisaya', to: 'answer me in bisaya'),
    (from: 'tubag sa bisaya', to: 'answer in bisaya'),
    (from: 'tubaga ko sa tagalog', to: 'answer me in tagalog'),
    (from: 'tubag sa tagalog', to: 'answer in tagalog'),
    (from: 'tubaga ko sa english', to: 'answer me in english'),
    (from: 'tubag sa english', to: 'answer in english'),
    (from: 'tubaga ko sa ingles', to: 'answer me in english'),
    (from: 'tubag sa ingles', to: 'answer in english'),
    (from: 'unsa akong schedule', to: 'what is my schedule'),
    (from: 'ano ang schedule ko', to: 'what is my schedule'),
    (from: 'nasaan ang next class ko', to: 'where is my next class'),
    (from: 'asa ang next class nako', to: 'where is my next class'),
    (from: 'ipakita ang schedule ko', to: 'show my schedule'),
    (from: 'ipakita yung schedule ko', to: 'show my schedule'),
    (from: 'pakita ang schedule ko', to: 'show my schedule'),
    (from: 'pakita sa akong schedule', to: 'show my schedule'),
    (from: 'pakita ang timetable ko', to: 'show my timetable'),
    (from: 'show ang schedule ko', to: 'show my schedule'),
    (from: 'may conflict ba ako', to: 'do i have conflicts'),
    (from: 'naa ba koy conflict', to: 'do i have conflicts'),
    (from: 'may klase ako bukas', to: 'what classes are scheduled tomorrow'),
    (from: 'naa ba koy klase ugma', to: 'what classes are scheduled tomorrow'),
    (from: 'anong subject ko ngayon', to: 'what subjects do i have today'),
    (from: 'unsa akong subject karon', to: 'what subjects do i have today'),
  ];

  static const List<({String from, String to})> _multilingualWordAliases = [
    (from: 'iskedyul', to: 'schedule'),
    (from: 'edyul', to: 'schedule'),
    (from: 'orasan', to: 'timetable'),
    (from: 'talaan', to: 'list'),
    (from: 'kwarto', to: 'room'),
    (from: 'silid', to: 'room'),
    (from: 'klasehanan', to: 'room'),
    (from: 'asignatura', to: 'subject'),
    (from: 'kurso', to: 'subject'),
    (from: 'maestra', to: 'faculty'),
    (from: 'maestro', to: 'faculty'),
    (from: 'guro', to: 'teacher'),
    (from: 'titser', to: 'teacher'),
    (from: 'pangutana', to: 'question'),
    (from: 'mangutana', to: 'ask'),
    (from: 'tubag', to: 'answer'),
    (from: 'tubaga', to: 'answer'),
    (from: 'sagot', to: 'answer'),
    (from: 'sagutin', to: 'answer'),
    (from: 'tabang', to: 'help'),
    (from: 'pakita', to: 'show'),
    (from: 'ipakita', to: 'show'),
    (from: 'tingnan', to: 'show'),
    (from: 'makita', to: 'show'),
    (from: 'saan', to: 'where'),
    (from: 'nasaan', to: 'where'),
    (from: 'asa', to: 'where'),
    (from: 'ano', to: 'what'),
    (from: 'anong', to: 'what'),
    (from: 'unsa', to: 'what'),
    (from: 'kanus a', to: 'when'),
    (from: 'kanusa', to: 'when'),
    (from: 'bakit', to: 'why'),
    (from: 'ngano', to: 'why'),
    (from: 'paano', to: 'how'),
    (from: 'giunsa', to: 'how'),
    (from: 'meron', to: 'have'),
    (from: 'may', to: 'have'),
    (from: 'naa', to: 'have'),
    (from: 'ako', to: 'my'),
    (from: 'aking', to: 'my'),
    (from: 'ko', to: 'my'),
    (from: 'akinga', to: 'my'),
    (from: 'nako', to: 'my'),
    (from: 'akong', to: 'my'),
    (from: 'aming', to: 'our'),
    (from: 'namin', to: 'our'),
    (from: 'amo', to: 'our'),
    (from: 'namo', to: 'our'),
    (from: 'ngayon', to: 'today'),
    (from: 'karon', to: 'today'),
    (from: 'karon', to: 'today'),
    (from: 'bukas', to: 'tomorrow'),
    (from: 'ugma', to: 'tomorrow'),
    (from: 'libre', to: 'free'),
    (from: 'bakante', to: 'vacant'),
    (from: 'bakanti', to: 'vacant'),
    (from: 'sunod', to: 'next'),
    (from: 'susunod', to: 'next'),
    (from: 'klase', to: 'class'),
    (from: 'subjects', to: 'subject'),
    (from: 'mga subject', to: 'subject'),
    (from: 'kwalipikado', to: 'available'),
    (from: 'bakanteha', to: 'available'),
    (from: 'conflict', to: 'conflict'),
    (from: 'banggaan', to: 'conflict'),
    (from: 'salungatan', to: 'conflict'),
    (from: 'yunit', to: 'units'),
    (from: 'load', to: 'load'),
    (from: 'karga', to: 'load'),
    (from: 'silingang', to: 'section'),
    (from: 'seksyon', to: 'section'),
  ];

  NLPService({
    DateTime Function()? nowProvider,
    LlmProvider? llmProvider,
  }) : _now = nowProvider ?? DateTime.now,
       _llmProvider = llmProvider ?? GeminiLlmProvider();

  // Restricted keywords that should always be rejected
  static const List<String> forbiddenKeywords = [
    'drop',
    'delete',
    'password',
    'sql',
    'schema',
    'database',
    'truncate',
    'alter',
  ];

  static const String _timeTokenPattern =
      r'(\d{1,2})(?::(\d{2}))?\s?(am|pm)?';
  static const String _betweenTimeRangePattern =
      r'(between|from)\s+([0-9]{1,2}(?::[0-9]{2})?\s?(am|pm)?)\s+(and|to)\s+([0-9]{1,2}(?::[0-9]{2})?\s?(am|pm)?)';
  static const String _afterTimeRangePattern =
      r'(after)\s+([0-9]{1,2}(?::[0-9]{2})?\s?(am|pm)?)';
  static const String _beforeTimeRangePattern =
      r'(before)\s+([0-9]{1,2}(?::[0-9]{2})?\s?(am|pm)?)';

  static final RegExp _timeTokenRegex = RegExp(_timeTokenPattern);
  static final RegExp _betweenTimeRangeRegex = RegExp(_betweenTimeRangePattern);
  static final RegExp _afterTimeRangeRegex = RegExp(_afterTimeRangePattern);
  static final RegExp _beforeTimeRangeRegex = RegExp(_beforeTimeRangePattern);

  static String normalizeQueryForTest(String query) {
    final cleaned = query
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool containsForbiddenKeywordsForTest(String query) {
    final lowerQuery = query.toLowerCase();
    return forbiddenKeywords.any((keyword) => lowerQuery.contains(keyword));
  }

  static int? parseTimeTokenForTest(String? token) {
    return _parseTimeTokenValue(token);
  }

  static ({int start, int end})? extractTimeRangeForTest(String query) {
    final result = _extractTimeRangeBounds(
      query,
      keywordMatcher: _containsPlainKeyword,
    );
    return result;
  }

  static int? _parseTimeTokenValue(String? token) {
    if (token == null) return null;
    final match = _timeTokenRegex.firstMatch(token.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    var h = hour;
    final ampm = match.group(3);
    if (ampm != null) {
      if (ampm.toLowerCase() == 'pm' && h < 12) h += 12;
      if (ampm.toLowerCase() == 'am' && h == 12) h = 0;
    }
    return h * 60 + minute;
  }

  static ({int start, int end})? _extractTimeRangeBounds(
    String query, {
    required bool Function(String query, List<String> keywords) keywordMatcher,
  }) {
    final between = _matchBetweenTimeRange(query);
    if (between != null) return between;

    final after = _matchSingleEndedTimeRange(
      query,
      regex: _afterTimeRangeRegex,
      groupIndex: 2,
      isAfter: true,
    );
    if (after != null) return after;

    final before = _matchSingleEndedTimeRange(
      query,
      regex: _beforeTimeRangeRegex,
      groupIndex: 2,
      isAfter: false,
    );
    if (before != null) return before;

    final namedRange = _matchNamedTimeRange(query, keywordMatcher);
    if (namedRange != null) return namedRange;

    return _matchSingleTokenRange(query);
  }

  static ({int start, int end})? _matchBetweenTimeRange(String query) {
    final between = _betweenTimeRangeRegex.firstMatch(query);
    if (between == null) return null;

    final start = _parseTimeTokenValue(between.group(2));
    final end = _parseTimeTokenValue(between.group(5));
    if (start == null || end == null) return null;

    return (start: start, end: end);
  }

  static ({int start, int end})? _matchSingleEndedTimeRange(
    String query, {
    required RegExp regex,
    required int groupIndex,
    required bool isAfter,
  }) {
    final match = regex.firstMatch(query);
    if (match == null) return null;

    final minutes = _parseTimeTokenValue(match.group(groupIndex));
    if (minutes == null) return null;

    if (isAfter) {
      return (start: minutes, end: 24 * 60);
    }
    return (start: 0, end: minutes);
  }

  static ({int start, int end})? _matchNamedTimeRange(
    String query,
    bool Function(String query, List<String> keywords) keywordMatcher,
  ) {
    if (keywordMatcher(query, const ['morning'])) {
      return (start: 7 * 60, end: 12 * 60);
    }
    if (keywordMatcher(query, const ['afternoon'])) {
      return (start: 12 * 60, end: 17 * 60);
    }
    if (keywordMatcher(query, const ['evening'])) {
      return (start: 17 * 60, end: 21 * 60);
    }
    return null;
  }

  static ({int start, int end})? _matchSingleTokenRange(String query) {
    final matches = _timeTokenRegex.allMatches(query).toList();
    if (matches.isEmpty) return null;

    final token = matches.first.group(0);
    final start = _parseTimeTokenValue(token);
    if (start == null) return null;

    return (start: start, end: start + 60);
  }

  static bool _containsPlainKeyword(String query, List<String> keywords) {
    final loweredQuery = query.toLowerCase();
    return keywords.any(loweredQuery.contains);
  }

  Future<Student?> _findCurrentStudent(
    Session session,
    String userIdentifier,
  ) async {
    final userInfoId = int.tryParse(userIdentifier);

    if (userInfoId != null) {
      final byUserInfoId = await Student.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(userInfoId) & t.isActive.equals(true),
      );
      if (byUserInfoId != null) return byUserInfoId;
    }

    final linkedUserInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.userIdentifier.equals(userIdentifier),
    );
    if (linkedUserInfo?.id != null) {
      final resolvedLinkedUserInfo = linkedUserInfo!;
      final byLinkedUserInfo = await Student.db.findFirstRow(
        session,
        where: (t) =>
            t.userInfoId.equals(resolvedLinkedUserInfo.id!) &
            t.isActive.equals(true),
      );
      if (byLinkedUserInfo != null) return byLinkedUserInfo;

      final linkedEmail = (resolvedLinkedUserInfo.email ?? '')
          .trim()
          .toLowerCase();
      if (linkedEmail.isNotEmpty) {
        final byLinkedEmail = await Student.db.findFirstRow(
          session,
          where: (t) => t.email.equals(linkedEmail) & t.isActive.equals(true),
        );
        if (byLinkedEmail != null) return byLinkedEmail;
      }
    }

    return await Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(userIdentifier) & t.isActive.equals(true),
    );
  }

  Future<Faculty?> _findCurrentFaculty(
    Session session,
    String userIdentifier,
  ) async {
    final userInfoId = int.tryParse(userIdentifier);

    if (userInfoId != null) {
      final byUserInfoId = await Faculty.db.findFirstRow(
        session,
        where: (t) => t.userInfoId.equals(userInfoId) & t.isActive.equals(true),
      );
      if (byUserInfoId != null) return byUserInfoId;
    }

    final linkedUserInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.userIdentifier.equals(userIdentifier),
    );
    if (linkedUserInfo?.id != null) {
      final resolvedLinkedUserInfo = linkedUserInfo!;
      final byLinkedUserInfo = await Faculty.db.findFirstRow(
        session,
        where: (t) =>
            t.userInfoId.equals(resolvedLinkedUserInfo.id!) &
            t.isActive.equals(true),
      );
      if (byLinkedUserInfo != null) return byLinkedUserInfo;

      final linkedEmail = (resolvedLinkedUserInfo.email ?? '')
          .trim()
          .toLowerCase();
      if (linkedEmail.isNotEmpty) {
        final byLinkedEmail = await Faculty.db.findFirstRow(
          session,
          where: (t) => t.email.equals(linkedEmail) & t.isActive.equals(true),
        );
        if (byLinkedEmail != null) return byLinkedEmail;
      }
    }

    return await Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(userIdentifier) & t.isActive.equals(true),
    );
  }

  Future<NLPResponse> processQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    String? sessionId,
  ) async =>
      processQueryImpl(session, query, userId, scopes, sessionId);

  Future<NLPResponse> processQueryImpl(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    String? sessionId,
  ) async {
    // Sanitize and validate input
    if (query.isEmpty || query.length > 500) {
      return _unsupportedResponse('english');
    }

    final resolvedUserId = userId?.trim();
    final resolvedRole = _resolveRoleFromScopes(scopes);

    final lowerQuery = query.toLowerCase();
    final normalizedQuery = _normalizeQuery(lowerQuery);
    final requestedDays = _extractDaysOfWeek(normalizedQuery);
    final requestedDay = requestedDays.length == 1 ? requestedDays.first : null;
    final relativeDays = _extractRelativeDays(normalizedQuery);

    // Check for forbidden keywords - NEVER execute
    if (_containsForbiddenKeywords(lowerQuery)) {
      return _unsupportedResponse('english');
    }

    final preferredLanguage = await _resolvePreferredLanguage(
      session,
      query: query,
      sessionId: sessionId,
    );

    if (_isUnsupportedLanguageRequest(query)) {
      return NLPResponse(
        text: _unsupportedLanguageMessage,
        intent: NLPIntent.unknown,
      );
    }

    final informationalResponse = await _tryInformationalSystemQuery(
      session,
      normalizedQuery,
      role: resolvedRole,
      sessionId: sessionId,
      preferredLanguage: preferredLanguage,
    );
    if (informationalResponse != null) return informationalResponse;

    final greetingResponse = _tryGreetingQuery(
      normalizedQuery,
      preferredLanguage: preferredLanguage,
    );
    if (greetingResponse != null) return greetingResponse;

    final accessRestriction = await _enforceRoleQueryScope(
      session,
      normalizedQuery,
      userId: resolvedUserId,
      scopes: scopes,
      preferredLanguage: preferredLanguage,
    );
    if (accessRestriction != null) return accessRestriction;

    final simpleRoomsResponse = await _trySimpleRoomListQuery(
      session,
      normalizedQuery,
      scopes,
    );
    if (simpleRoomsResponse != null) return simpleRoomsResponse;

    final simpleTimetableResponse = await _trySimpleTimetableQuery(
      session,
      normalizedQuery,
      userId,
      scopes,
    );
    if (simpleTimetableResponse != null) return simpleTimetableResponse;

    final preferGroundedResponse = _shouldPreferGroundedResponse(
      normalizedQuery,
      requestedDay,
      requestedDays,
      relativeDays,
    );
    if (preferGroundedResponse) {
      final groundedFirstResponse = await _tryGroundedLlmFallback(
        session,
        rawQuery: query,
        normalizedQuery: normalizedQuery,
        userId: resolvedUserId,
        role: resolvedRole,
        sessionId: sessionId,
        preferredLanguage: preferredLanguage,
      );
      if (groundedFirstResponse != null &&
          groundedFirstResponse.text !=
              _llmUnavailableMessage(preferredLanguage)) {
        return groundedFirstResponse;
      }
    }

    // 1. My Schedule Queries (All authenticated users)
    if (_hasMyScheduleIntent(normalizedQuery)) {
      if (userId == null) {
        return NLPResponse(
          text: _loginRequiredMessage(
            preferredLanguage,
            purpose: 'viewSchedule',
          ),
          intent: NLPIntent.unknown,
        );
      }
      return await _handleMyScheduleQuery(
        session,
        userId,
        scopes,
        requestedDay ?? (relativeDays.length == 1 ? relativeDays.first : null),
      );
    }

    // 2. Conflict Queries (All authenticated users)
    if (_hasConflictIntent(normalizedQuery)) {
      if (userId == null) {
        return NLPResponse(
          text: _loginRequiredMessage(
            preferredLanguage,
            purpose: 'checkConflicts',
          ),
          intent: NLPIntent.unknown,
        );
      }
      return await _handleConflictQuery(session, userId, scopes);
    }

    // 3. Faculty Overload Queries (All authenticated users)
    if (_hasOverloadIntent(normalizedQuery)) {
      if (userId == null) {
        return NLPResponse(
          text: _loginRequiredMessage(
            preferredLanguage,
            purpose: 'checkFacultyLoad',
          ),
          intent: NLPIntent.unknown,
        );
      }
      return await _handleOverloadQuery(session, userId, scopes, lowerQuery);
    }

    // 3.5 Room type questions (lab vs lecture)
    final roomTypeResponse = await _tryRoomTypeQuestion(
      session,
      normalizedQuery,
    );
    if (roomTypeResponse != null) {
      return roomTypeResponse;
    }

    // 3.6 Room type schedule queries (lecture/lab on a day)
    final roomTypeScheduleResponse = await _tryRoomTypeScheduleQuery(
      session,
      normalizedQuery,
      requestedDay,
      scopes,
    );
    if (roomTypeScheduleResponse != null) {
      return roomTypeScheduleResponse;
    }

    // 4. Room Availability Queries
    if (_hasRoomIntent(normalizedQuery)) {
      final timeQueryResponse = await _tryRoomTimeQuery(
        session,
        normalizedQuery,
        relativeDays,
        scopes,
      );
      if (timeQueryResponse != null) return timeQueryResponse;

      return await _handleRoomQuery(session, normalizedQuery);
    }

    // 5. Section/Schedule Queries
    final timeRange = _extractTimeRange(normalizedQuery);
    if (_hasScheduleIntent(normalizedQuery) ||
        _containsSectionPattern(normalizedQuery) ||
        _hasScheduleQuestion(
          normalizedQuery,
          requestedDay,
          relativeDays,
          timeRange,
        )) {
      final timeQueryResponse = await _tryTimeBasedScheduleQuery(
        session,
        normalizedQuery,
        userId,
        scopes,
        requestedDay,
        relativeDays,
      );
      if (timeQueryResponse != null) return timeQueryResponse;

      final filteredResponse = await _tryFilteredScheduleQuery(
        session,
        normalizedQuery,
        userId,
        scopes,
        requestedDay,
        relativeDays,
        timeRange,
      );
      if (filteredResponse != null) return filteredResponse;

      return await _handleScheduleQuery(
        session,
        normalizedQuery,
        userId,
        scopes,
        requestedDay ?? (relativeDays.length == 1 ? relativeDays.first : null),
        requestedDays.isNotEmpty ? requestedDays : relativeDays,
      );
    }

    if (_hasSystemIntent(normalizedQuery)) {
      return NLPResponse(
        text:
            _textForLanguage(
              preferredLanguage,
              english:
                  'That action needs the admin scheduling tools. Use the Timetable or Conflict modules to generate, optimize, or resolve schedules.',
              tagalog:
                  'Kailangan ng action na iyon ang admin scheduling tools. Gamitin ang Timetable o Conflict modules para gumawa, mag-optimize, o mag-resolve ng schedules.',
              bisaya:
                  'Kana nga aksyon nanginahanglan sa admin scheduling tools. Gamita ang Timetable o Conflict modules aron maghimo, mag-optimize, o mag-resolve sa schedules.',
            ),
        intent: NLPIntent.unknown,
      );
    }

    if (_containsKeywordFuzzy(normalizedQuery, ['free', 'available']) &&
        _containsKeywordFuzzy(normalizedQuery, ['slot', 'slots', 'time'])) {
      return NLPResponse(
        text:
            _textForLanguage(
              preferredLanguage,
              english:
                  "Please specify whose availability to check (e.g., 'Show free time slots for Prof Ryan') or include a day/time.",
              tagalog:
                  "Pakisabi kung kaninong availability ang iche-check (halimbawa, 'Show free time slots for Prof Ryan') o maglagay ng araw/oras.",
              bisaya:
                  "Palihug isulti kang kinsang availability ang tan-awon (pananglitan, 'Show free time slots for Prof Ryan') o ilakip ang adlaw/oras.",
            ),
        intent: NLPIntent.schedule,
      );
    }

    if (_containsKeywordFuzzy(normalizedQuery, ['free']) &&
        _containsKeywordFuzzy(normalizedQuery, ['room'])) {
      return NLPResponse(
        text:
            _textForLanguage(
              preferredLanguage,
              english:
                  "Please specify a day and time range to find a free room (e.g., 'Find free room on Monday between 1 PM and 3 PM').",
              tagalog:
                  "Pakispecify ang araw at oras para makahanap ng bakanteng room (halimbawa, 'Find free room on Monday between 1 PM and 3 PM').",
              bisaya:
                  "Palihug ispecify ang adlaw ug time range aron makakita og bakanteng room (pananglitan, 'Find free room on Monday between 1 PM and 3 PM').",
            ),
        intent: NLPIntent.roomStatus,
      );
    }

    final llmResponse = await _tryGroundedLlmFallback(
      session,
        rawQuery: query,
        normalizedQuery: normalizedQuery,
        userId: resolvedUserId,
        role: resolvedRole,
        sessionId: sessionId,
        preferredLanguage: preferredLanguage,
      );
    if (llmResponse != null) {
      return llmResponse;
    }

    return NLPResponse(
      text:
          _textForLanguage(
            preferredLanguage,
            english:
                "I couldn't match that request. Try asking about schedules, rooms, conflicts, or faculty load. Example: 'My schedule on Monday' or 'Is IT LAB available at 2 PM?'",
            tagalog:
                "Hindi ko maitugma ang request na iyon. Subukan mong magtanong tungkol sa schedules, rooms, conflicts, o faculty load. Halimbawa: 'My schedule on Monday' o 'Is IT LAB available at 2 PM?'",
            bisaya:
                "Dili nako ma-match kana nga request. Sulayi pangutana bahin sa schedules, rooms, conflicts, o faculty load. Pananglitan: 'My schedule on Monday' o 'Is IT LAB available at 2 PM?'",
          ),
      intent: NLPIntent.unknown,
    );
  }

  Future<NLPResponse?> _tryGroundedLlmFallback(
    Session session, {
    required String rawQuery,
    required String normalizedQuery,
    required String? userId,
    required String role,
    String? sessionId,
    required String preferredLanguage,
  }) async {
    if (userId == null || userId.isEmpty) {
      return null;
    }

    final groundedContext = await _groundingService.buildContext(
      session,
      query: normalizedQuery,
      roleType: role,
      userIdentifier: userId,
    );
    if (!groundedContext.hasData) {
      return NLPResponse(
        text: AiGroundingService.fallbackNoDataMessage,
        intent: groundedContext.intent,
        dataJson: groundedContext.jsonText,
      );
    }

    final conversationHistory = await _loadConversationHistory(
      session,
      sessionId: sessionId,
      currentQuery: rawQuery,
    );

    final llmResult = await _llmProvider.generate(
      session,
      GroundedLlmRequest(
        model: _pickGeminiModel(normalizedQuery),
        systemPrompt: _systemPrompt(role, preferredLanguage: preferredLanguage),
        userPrompt: rawQuery,
        groundedJson: groundedContext.jsonText,
        history: conversationHistory,
      ),
    );
    if (llmResult == null) {
      return NLPResponse(
        text: _llmUnavailableMessage(preferredLanguage),
        intent: groundedContext.intent,
        dataJson: groundedContext.jsonText,
      );
    }

    return NLPResponse(
      text: llmResult.text,
      intent: groundedContext.intent,
      dataJson: jsonEncode({
        'provider': 'gemini',
        'model': llmResult.model,
        'groundedContext': jsonDecode(groundedContext.jsonText),
      }),
    );
  }

  String _resolveRoleFromScopes(List<String> scopes) {
    if (scopes.contains('admin')) return 'admin';
    if (scopes.contains('faculty')) return 'faculty';
    if (scopes.contains('student')) return 'student';
    return 'unknown';
  }

  String _pickGeminiModel(String query) {
    final isComplex = _containsKeywordFuzzy(
      query,
      ['generate', 'optimize', 'suggest', 'analyze', 'report'],
    );
    return isComplex ? 'gemini-2.5-flash' : 'gemini-2.5-flash-lite';
  }

  String _systemPrompt(String role, {required String preferredLanguage}) => '''
You are CITESched AI, the official scheduling assistant of Jose Maria College Foundation Inc.
Use ONLY verified CITESched system data provided to you.
Never invent schedules, rooms, faculty, students, or subjects.
Always provide accurate responses related to scheduling, faculty loading, room assignments, timetable conflicts, and student schedules.
If data is unavailable, clearly state: "I don't have enough schedule data to answer that accurately."
The active user role for this request is: $role.
Preferred response language for this conversation: ${_languageLabel(preferredLanguage)}. Follow that language unless the user explicitly asks to switch.
${_rolePromptRule(role)}
Keep answers concise, helpful, and grounded in the verified data payload.
''';

  String _rolePromptRule(String role) {
    if (role == 'faculty') {
      return 'Faculty scope rule: answer only with the current faculty account\'s personal timetable, assigned subjects, assigned sections, assigned rooms, teaching load, available teaching hours, and personal conflicts. Deny any request for other faculty data, student private schedules, institutional reports, schedule generation, or global timetable management.';
    }
    if (role == 'student') {
      return 'Student scope rule: answer only with the current student account\'s personal schedule, own assigned section timetable, own subjects, own room assignments, next class, vacant periods, and personal or section conflicts. Deny any request for other sections, other students, faculty data, admin data, institutional reports, or global room or timetable access.';
    }
    return 'Admin scope rule: full scheduling and reporting access is allowed.';
  }

  Future<NLPResponse?> _enforceRoleQueryScope(
    Session session,
    String query, {
    required String? userId,
    required List<String> scopes,
    required String preferredLanguage,
  }) async {
    if (scopes.contains('admin')) return null;
    if (scopes.contains('faculty')) {
      return _enforceFacultyQueryScope(
        session,
        query,
        userId: userId,
        preferredLanguage: preferredLanguage,
      );
    }
    if (scopes.contains('student')) {
      return _enforceStudentQueryScope(
        session,
        query,
        userId: userId,
        preferredLanguage: preferredLanguage,
      );
    }
    return null;
  }

  Future<NLPResponse?> _enforceFacultyQueryScope(
    Session session,
    String query, {
    required String? userId,
    required String preferredLanguage,
  }) async {
    if (userId == null) return null;
    final faculty = await _findCurrentFaculty(session, userId);
    if (faculty == null) return null;

    if ((_isAdminOnlyQuery(query) && !_isScheduleExportQuery(query)) ||
        _isInstitutionWideQuery(query) ||
        _isStudentPrivateDataQuery(query)) {
      return _restrictedResponse(
        _facultyAccessRestrictedMessage,
        preferredLanguage,
      );
    }

    final matchedFaculty = _matchFacultyByName(query, await Faculty.db.find(session));
    if (matchedFaculty != null && matchedFaculty.id != faculty.id) {
      return _restrictedResponse(
        _facultyAccessRestrictedMessage,
        preferredLanguage,
      );
    }

    final extractedSection = _extractSectionFromQuery(query);
    if (extractedSection != null) {
      final schedules = await Schedule.db.find(
        session,
        where: (t) => t.facultyId.equals(faculty.id!),
      );
      final allowedSections = schedules.map((s) => s.section).toSet();
      final requestedCandidates = _buildSectionCandidates(extractedSection).toSet();
      final hasAssignedSection = allowedSections.any(
        (section) => requestedCandidates.contains(section.toUpperCase()),
      );
      if (!hasAssignedSection) {
        return _restrictedResponse(
          _facultyAccessRestrictedMessage,
          preferredLanguage,
        );
      }
    }

    if (_isBroadRoomAccessQuery(query) && !_isPersonalFacultyRoomQuery(query)) {
      return _restrictedResponse(
        _facultyAccessRestrictedMessage,
        preferredLanguage,
      );
    }

    return null;
  }

  Future<NLPResponse?> _enforceStudentQueryScope(
    Session session,
    String query, {
    required String? userId,
    required String preferredLanguage,
  }) async {
    if (userId == null) return null;
    final student = await _findCurrentStudent(session, userId);
    if (student == null) return null;

    if (_hasFacultyReference(query) ||
        _isFacultyLoadQuery(query) ||
        (_isAdminOnlyQuery(query) && !_isScheduleExportQuery(query)) ||
        _isInstitutionWideQuery(query)) {
      return _restrictedResponse(
        _studentAccessRestrictedMessage,
        preferredLanguage,
      );
    }

    final extractedSection = _extractSectionFromQuery(query);
    if (extractedSection != null) {
      final allowedCandidates = _buildSectionCandidates(
        student.section ?? student.sectionRef?.sectionCode ?? '',
      ).toSet();
      final requestedCandidates = _buildSectionCandidates(extractedSection).toSet();
      final matchesOwnSection = requestedCandidates.any(allowedCandidates.contains);
      if (!matchesOwnSection) {
        return _restrictedResponse(
          _studentSectionRestrictedMessage,
          preferredLanguage,
        );
      }
    }

    if (_isBroadRoomAccessQuery(query) && !_isPersonalStudentRoomQuery(query)) {
      return _restrictedResponse(
        _studentAccessRestrictedMessage,
        preferredLanguage,
      );
    }

    return null;
  }

  NLPResponse _restrictedResponse(String message, String preferredLanguage) {
    return NLPResponse(
      text: _translateAccessMessage(message, preferredLanguage),
      intent: NLPIntent.unknown,
    );
  }

  bool _isAdminOnlyQuery(String query) {
    if (_containsKeywordFuzzy(query, [
      'generate',
      'optimize',
      'reassign',
      'analytics',
      'report',
      'reports',
      'department',
      'institutional',
      'database',
      'global',
    ])) {
      return true;
    }

    if (_containsKeywordFuzzy(query, ['admin']) &&
        _containsKeywordFuzzy(query, ['control', 'controls', 'manage'])) {
      return true;
    }

    return false;
  }

  bool _isScheduleExportQuery(String query) {
    final asksExport = _containsKeywordFuzzy(query, [
      'export',
      'csv',
      'pdf',
      'docx',
      'download',
      'print',
      'file',
      'report',
    ]);
    final asksScheduleData = _containsKeywordFuzzy(query, [
      'schedule',
      'schedules',
      'timetable',
      'subject',
      'subjects',
      'class',
      'classes',
      'room',
      'rooms',
    ]);
    return asksExport && asksScheduleData;
  }

  bool _isInstitutionWideQuery(String query) {
    final asksGlobalScope = _containsKeywordFuzzy(query, [
      'all',
      'full',
      'entire',
      'global',
      'department',
      'institutional',
      'everyone',
      'other',
      'compare',
    ]);
    final asksScheduleData = _containsKeywordFuzzy(query, [
      'schedule',
      'schedules',
      'timetable',
      'room',
      'rooms',
      'section',
      'sections',
      'classroom',
      'faculty',
      'students',
      'report',
      'reports',
    ]);
    return asksGlobalScope && asksScheduleData;
  }

  bool _isStudentPrivateDataQuery(String query) {
    return _containsKeywordFuzzy(query, ['student', 'students']) &&
        _containsKeywordFuzzy(query, ['private', 'other', 'all', 'full']);
  }

  bool _isFacultyLoadQuery(String query) {
    return _containsKeywordFuzzy(query, [
      'load',
      'units',
      'teaching',
      'overload',
      'underload',
      'hours',
    ]);
  }

  bool _isBroadRoomAccessQuery(String query) {
    final asksRoom = _containsKeywordFuzzy(query, [
      'room',
      'rooms',
      'classroom',
      'classrooms',
      'laboratory',
      'lab',
    ]);
    final asksAvailability = _containsKeywordFuzzy(query, [
      'available',
      'availability',
      'free',
      'all',
      'show',
      'list',
      'find',
      'check',
    ]);
    return asksRoom && asksAvailability;
  }

  bool _isPersonalFacultyRoomQuery(String query) {
    return _containsKeywordFuzzy(query, [
      'my',
      'next',
      'assigned',
      'subject',
      'class',
      'schedule',
      'teaching',
      'available hours',
      'laboratory',
    ]);
  }

  bool _isPersonalStudentRoomQuery(String query) {
    return _containsKeywordFuzzy(query, [
      'my',
      'next',
      'assigned',
      'subject',
      'class',
      'section',
      'schedule',
      'tomorrow',
      'today',
    ]);
  }

  NLPResponse? _tryGreetingQuery(
    String query, {
    required String preferredLanguage,
  }) {
    final isGreetingOnly =
        query == 'hello' ||
        query == 'hi' ||
        query == 'hey' ||
        query == 'good morning' ||
        query == 'good afternoon' ||
        query == 'good evening';
    if (!isGreetingOnly) return null;

    return NLPResponse(
      text: _textForLanguage(
        preferredLanguage,
        english:
            'Hello! I am CITESched AI. I can understand English, Tagalog, and Bisaya for schedule-related questions. Ask me about schedules, faculty loads, sections, rooms, or timetable conflicts.',
        tagalog:
            'Hello! Ako si CITESched AI. Naiintindihan ko ang English, Tagalog, at Bisaya para sa mga tanong tungkol sa schedule. Magtanong ka tungkol sa schedules, faculty loads, sections, rooms, o timetable conflicts.',
        bisaya:
            'Hello! Ako si CITESched AI. Makasabot ko og English, Tagalog, ug Bisaya para sa schedule-related nga mga pangutana. Pangutana bahin sa schedules, faculty loads, sections, rooms, o timetable conflicts.',
      ),
      intent: NLPIntent.unknown,
    );
  }

  Future<NLPResponse?> _tryInformationalSystemQuery(
    Session session,
    String query, {
    required String role,
    String? sessionId,
    required String preferredLanguage,
  }) async {
    final prefersBulletFormat = _prefersBulletFormat(query);

    if (role == 'faculty' &&
        (_isAdminFeatureListQuery(query) ||
            _isAdminManagementQuery(query) ||
            _isAdminMissingModuleQuery(query) ||
            _isStudentFeatureListQuery(query))) {
      return _restrictedResponse(
        _facultyAccessRestrictedMessage,
        preferredLanguage,
      );
    }

    if (role == 'student' &&
        (_isAdminFeatureListQuery(query) ||
            _isAdminManagementQuery(query) ||
            _isAdminMissingModuleQuery(query) ||
            _isFacultyFeatureListQuery(query))) {
      return _restrictedResponse(
        _studentAccessRestrictedMessage,
        preferredLanguage,
      );
    }

    final followUpResponse = await _tryFormattingFollowUp(
      session,
      query: query,
      sessionId: sessionId,
      preferredLanguage: preferredLanguage,
    );
    if (followUpResponse != null) return followUpResponse;

    if (_isAdminManagementQuery(query)) {
      return NLPResponse(
        text: _adminManagementResponse(
          prefersBulletFormat,
          preferredLanguage: preferredLanguage,
        ),
        intent: NLPIntent.unknown,
      );
    }

    if (_isAdminFeatureListQuery(query)) {
      return NLPResponse(
        text: _adminFeatureListResponse(
          prefersBulletFormat,
          preferredLanguage: preferredLanguage,
        ),
        intent: NLPIntent.unknown,
      );
    }

    if (_isStudentFeatureListQuery(query)) {
      return NLPResponse(
        text: _studentFeatureListResponse(
          prefersBulletFormat,
          preferredLanguage: preferredLanguage,
        ),
        intent: NLPIntent.unknown,
      );
    }

    if (_isFacultyFeatureListQuery(query)) {
      return NLPResponse(
        text: _facultyFeatureListResponse(
          prefersBulletFormat,
          preferredLanguage: preferredLanguage,
        ),
        intent: NLPIntent.unknown,
      );
    }

    if (_isAdminMissingModuleQuery(query)) {
      return NLPResponse(
        text: _adminMissingModuleResponse(
          prefersBulletFormat,
          preferredLanguage: preferredLanguage,
        ),
        intent: NLPIntent.unknown,
      );
    }

    if (_isSystemAboutQuery(query)) {
      return NLPResponse(
        text: _systemAboutResponse(
          prefersBulletFormat,
          preferredLanguage: preferredLanguage,
        ),
        intent: NLPIntent.unknown,
      );
    }

    if (_isConflictExplanationQuery(query)) {
      return NLPResponse(
        text: _conflictExplanationResponse(
          prefersBulletFormat,
          preferredLanguage: preferredLanguage,
        ),
        intent: NLPIntent.conflict,
      );
    }

    if (_isCapabilityQuery(query)) {
      return NLPResponse(
        text:
            _textForLanguage(
              preferredLanguage,
              english:
                  'Yes. I can help with section schedules, faculty schedules, room usage, timetable views, subject schedules, faculty load checks, and conflict-related questions based on verified CITESched data.',
              tagalog:
                  'Oo. Makakatulong ako sa section schedules, faculty schedules, room usage, timetable views, subject schedules, faculty load checks, at conflict-related questions gamit ang verified CITESched data.',
              bisaya:
                  'Oo. Makatabang ko sa section schedules, faculty schedules, room usage, timetable views, subject schedules, faculty load checks, ug conflict-related nga mga pangutana gamit ang verified CITESched data.',
            ),
        intent: NLPIntent.unknown,
      );
    }

    if (_isGeneralQuestionPrompt(query)) {
      return NLPResponse(
        text:
            _textForLanguage(
              preferredLanguage,
              english:
                  'Yes, you can ask. What would you like to know about CITESched? I can help with schedules, timetable, rooms, faculty load, and conflict checks.',
              tagalog:
                  'Oo, pwede kang magtanong. Ano ang gusto mong malaman tungkol sa CITESched? Makakatulong ako sa schedules, timetable, rooms, faculty load, at conflict checks.',
              bisaya:
                  'Oo, pwede ka mangutana. Unsay gusto nimo mahibal-an sa CITESched? Mahimo ko motabang sa schedules, timetable, rooms, faculty load, ug conflict checks.',
            ),
        intent: NLPIntent.unknown,
      );
    }

    if (_isBisayaLanguageRequest(query)) {
      return NLPResponse(
        text:
            'Sige, motubag ko sa Bisaya kung mahimo. Padayon ko ug tubag sa Bisaya hangtod nga mangayo ka ug laing pinulongan. Pangutana lang bahin sa imong schedule, timetable, subjects, rooms, o conflicts sa CITESched.',
        intent: NLPIntent.unknown,
      );
    }

    if (_isTagalogLanguageRequest(query)) {
      return NLPResponse(
        text:
            'Sige, sasagot ako sa Tagalog kung maaari. Itutuloy ko ang mga sagot sa Tagalog hanggang humiling ka ng ibang wika. Magtanong ka lang tungkol sa iyong schedule, timetable, subjects, rooms, o conflicts sa CITESched.',
        intent: NLPIntent.unknown,
      );
    }

    if (_isEnglishLanguageRequest(query)) {
      return NLPResponse(
        text:
            'Sure, I can answer in English. I will keep replying in English until you ask me to switch languages. Ask me about your schedule, timetable, subjects, rooms, or conflict checks in CITESched.',
        intent: NLPIntent.unknown,
      );
    }

    return null;
  }

  bool _isSystemAboutQuery(String query) {
    final asksWhat = _containsKeywordFuzzy(query, ['what', 'exactly']);
    final asksSystem = _containsKeywordFuzzy(query, ['system', 'citesched']);
    final asksDoes = _containsKeywordFuzzy(query, ['does', 'do', 'manage']);
    return asksSystem && (asksWhat || asksDoes);
  }

  bool _isAdminManagementQuery(String query) {
    final asksAdmin = _containsKeywordFuzzy(query, ['admin', 'administrator']);
    final asksManage = _containsKeywordFuzzy(query, [
      'manage',
      'management',
      'control',
      'use',
    ]);
    final asksSystem = _containsKeywordFuzzy(query, ['system', 'citesched']);
    return asksAdmin && asksManage && asksSystem;
  }

  bool _isAdminFeatureListQuery(String query) {
    final asksAdmin = _containsKeywordFuzzy(query, ['admin', 'administrator']);
    final asksFeatures = _containsKeywordFuzzy(query, [
      'feature',
      'features',
      'module',
      'modules',
      'list',
    ]);
    return asksAdmin && asksFeatures;
  }

  bool _isStudentFeatureListQuery(String query) {
    final asksStudent = _containsKeywordFuzzy(query, ['student']);
    final asksLocation = _containsKeywordFuzzy(query, [
      'dashboard',
      'side',
      'portal',
      'panel',
    ]);
    final asksFeatures = _containsKeywordFuzzy(query, [
      'feature',
      'features',
      'module',
      'modules',
      'list',
      'include',
      'included',
      'functions',
    ]);
    return asksStudent && asksFeatures && (asksLocation || asksFeatures);
  }

  bool _isFacultyFeatureListQuery(String query) {
    final asksFaculty = _containsKeywordFuzzy(query, [
      'faculty',
      'professor',
      'teacher',
      'instructor',
    ]);
    final asksLocation = _containsKeywordFuzzy(query, [
      'dashboard',
      'side',
      'portal',
      'panel',
    ]);
    final asksFeatures = _containsKeywordFuzzy(query, [
      'feature',
      'features',
      'module',
      'modules',
      'list',
      'include',
      'included',
      'functions',
    ]);
    return asksFaculty && asksFeatures && (asksLocation || asksFeatures);
  }

  bool _isAdminMissingModuleQuery(String query) {
    final asksMissing = _containsKeywordFuzzy(query, [
      'include',
      'included',
      'missing',
      'why',
    ]);
    final asksAdmin = _containsKeywordFuzzy(query, ['admin', 'administrator']);
    final asksNamedModules = _containsKeywordFuzzy(query, [
      'conflict',
      'timetable',
      'report',
      'reports',
    ]);
    return asksMissing && (asksAdmin || asksNamedModules);
  }

  bool _isConflictExplanationQuery(String query) {
    final asksConflict = _containsKeywordFuzzy(query, ['conflict', 'conflicts']);
    final asksHow = _containsKeywordFuzzy(query, [
      'how',
      'manage',
      'handled',
      'handle',
      'resolve',
    ]);
    return asksConflict && asksHow;
  }

  bool _isCapabilityQuery(String query) {
    final asksCan = _containsKeywordFuzzy(query, ['can']);
    final asksAsk = _containsKeywordFuzzy(query, ['ask', 'help']);
    final asksSystem = _containsKeywordFuzzy(query, ['system', 'citesched']);
    return asksCan && (asksAsk || asksSystem);
  }

  bool _isGeneralQuestionPrompt(String query) {
    final normalized = _normalizeQuery(query);
    if (normalized == 'naa koy pangutana' ||
        normalized == 'naa ko pangutana' ||
        normalized == 'i have a question' ||
        normalized == 'i have questions' ||
        normalized == 'can i ask a question' ||
        normalized == 'pwede ko mangutana') {
      return true;
    }

    final asksQuestion = _containsKeywordFuzzy(normalized, [
      'question',
      'questions',
      'pangutana',
      'mangutana',
      'ask',
    ]);
    final asksPermission = _containsKeywordFuzzy(normalized, [
      'can',
      'may',
      'pwede',
      'naa',
      'have',
    ]);
    return asksQuestion && asksPermission;
  }

  bool _isBisayaLanguageRequest(String query) {
    final normalized = _normalizeQuery(query);
    final asksBisaya = _containsKeywordFuzzy(normalized, [
      'bisaya',
      'cebuano',
    ]);
    final asksResponse = _containsKeywordFuzzy(normalized, [
      'tubag',
      'tubaga',
      'answer',
      'respond',
      'reply',
      'istorya',
      'speak',
    ]);
    return asksBisaya && asksResponse;
  }

  bool _isTagalogLanguageRequest(String query) {
    final normalized = _normalizeQuery(query);
    final asksTagalog = _containsKeywordFuzzy(normalized, [
      'tagalog',
      'filipino',
    ]);
    final asksResponse = _containsKeywordFuzzy(normalized, [
      'tubag',
      'tubaga',
      'sagot',
      'sagutin',
      'answer',
      'respond',
      'reply',
      'speak',
    ]);
    return asksTagalog && asksResponse;
  }

  bool _isEnglishLanguageRequest(String query) {
    final normalized = _normalizeQuery(query);
    final asksEnglish = _containsKeywordFuzzy(normalized, [
      'english',
      'ingles',
    ]);
    final asksResponse = _containsKeywordFuzzy(normalized, [
      'tubag',
      'tubaga',
      'sagot',
      'sagutin',
      'answer',
      'respond',
      'reply',
      'speak',
      'talk',
    ]);
    return asksEnglish && asksResponse;
  }

  bool _prefersBulletFormat(String query) {
    return _containsKeywordFuzzy(query, [
      'bullet',
      'bullets',
      'format',
      'formatted',
    ]);
  }

  bool _isFormattingFollowUpQuery(String query) {
    final asksFormat = _containsKeywordFuzzy(query, [
      'bullet',
      'bullets',
      'format',
      'formatted',
    ]);
    final asksOnlyFormatting =
        !_isAdminFeatureListQuery(query) &&
        !_isStudentFeatureListQuery(query) &&
        !_isFacultyFeatureListQuery(query) &&
        !_isSystemAboutQuery(query) &&
        !_isConflictExplanationQuery(query) &&
        !_isAdminManagementQuery(query);
    return asksFormat && asksOnlyFormatting;
  }

  Future<NLPResponse?> _tryFormattingFollowUp(
    Session session, {
    required String query,
    String? sessionId,
    required String preferredLanguage,
  }) async {
    if (!_isFormattingFollowUpQuery(query) || sessionId == null) {
      return null;
    }

    final parsedSessionId = int.tryParse(sessionId.trim());
    if (parsedSessionId == null) return null;

    final messages = await _chatService.getMessages(
      session,
      sessionId: parsedSessionId,
      limit: 20,
    );
    if (messages.isEmpty) return null;

    final normalizedCurrent = _normalizeQuery(query);
    final priorUserMessages = List<AiChatMessage>.from(messages)
      ..removeWhere((message) {
        return message.sender == 'user' &&
            _normalizeQuery(message.message) == normalizedCurrent;
      });

    for (final message in priorUserMessages.reversed) {
      if (message.sender != 'user') continue;
      final priorQuery = _normalizeQuery(message.message);
      if (_isStudentFeatureListQuery(priorQuery)) {
        return NLPResponse(
          text: _studentFeatureListResponse(
            true,
            preferredLanguage: preferredLanguage,
          ),
          intent: NLPIntent.unknown,
        );
      }
      if (_isFacultyFeatureListQuery(priorQuery)) {
        return NLPResponse(
          text: _facultyFeatureListResponse(
            true,
            preferredLanguage: preferredLanguage,
          ),
          intent: NLPIntent.unknown,
        );
      }
      if (_isAdminFeatureListQuery(priorQuery) ||
          _isAdminManagementQuery(priorQuery)) {
        return NLPResponse(
          text: _adminFeatureListResponse(
            true,
            preferredLanguage: preferredLanguage,
          ),
          intent: NLPIntent.unknown,
        );
      }
      if (_isSystemAboutQuery(priorQuery)) {
        return NLPResponse(
          text: _systemAboutResponse(
            true,
            preferredLanguage: preferredLanguage,
          ),
          intent: NLPIntent.unknown,
        );
      }
      if (_isConflictExplanationQuery(priorQuery)) {
        return NLPResponse(
          text: _conflictExplanationResponse(
            true,
            preferredLanguage: preferredLanguage,
          ),
          intent: NLPIntent.conflict,
        );
      }
    }

    return null;
  }

  Future<List<Map<String, String>>> _loadConversationHistory(
    Session session, {
    String? sessionId,
    required String currentQuery,
  }) async {
    final parsedSessionId = int.tryParse(sessionId?.trim() ?? '');
    if (parsedSessionId == null) return const [];

    final messages = await _chatService.getMessages(
      session,
      sessionId: parsedSessionId,
      limit: 12,
    );
    if (messages.isEmpty) return const [];

    final normalizedCurrent = _normalizeQuery(currentQuery.toLowerCase());
    final historyMessages = List<AiChatMessage>.from(messages);
    if (historyMessages.isNotEmpty) {
      final last = historyMessages.last;
      if (last.sender == 'user' &&
          _normalizeQuery(last.message.toLowerCase()) == normalizedCurrent) {
        historyMessages.removeLast();
      }
    }

    return _chatService.toConversationHistory(historyMessages);
  }

  Future<String> _resolvePreferredLanguage(
    Session session, {
    required String query,
    String? sessionId,
  }) async {
    if (_isBisayaLanguageRequest(query)) return 'bisaya';
    if (_isTagalogLanguageRequest(query)) return 'tagalog';
    if (_isEnglishLanguageRequest(query)) return 'english';
    final dominant = _detectDominantLanguage(query);
    if (dominant != null) return dominant;

    final parsedSessionId = int.tryParse(sessionId?.trim() ?? '');
    if (parsedSessionId == null) return 'english';

    final messages = await _chatService.getMessages(
      session,
      sessionId: parsedSessionId,
      limit: 20,
    );
    for (final message in messages.reversed) {
      if (message.sender != 'user') continue;
      final text = message.message;
      if (_isBisayaLanguageRequest(text)) return 'bisaya';
      if (_isTagalogLanguageRequest(text)) return 'tagalog';
      if (_isEnglishLanguageRequest(text)) return 'english';
      final historyDominant = _detectDominantLanguage(text);
      if (historyDominant != null) return historyDominant;
    }

    return 'english';
  }

  String? _detectDominantLanguage(String query) {
    final normalized = _normalizeQuery(query);
    final tokens = normalized
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;

    const tagalogIndicators = {
      'ano',
      'anong',
      'bakit',
      'paano',
      'bukas',
      'ngayon',
      'pwede',
      'sagot',
      'sagutin',
      'filipino',
      'tagalog',
      'aking',
      'iyong',
      'klase',
      'seksyon',
    };
    const bisayaIndicators = {
      'unsa',
      'ngano',
      'giunsa',
      'ugma',
      'karon',
      'pwede',
      'pangutana',
      'mangutana',
      'tubag',
      'tubaga',
      'bisaya',
      'cebuano',
      'imong',
      'nako',
      'akong',
      'klase',
    };
    const englishIndicators = {
      'what',
      'when',
      'where',
      'why',
      'how',
      'schedule',
      'today',
      'tomorrow',
      'answer',
      'english',
      'class',
      'subject',
      'room',
      'conflict',
    };

    var tagalogScore = 0;
    var bisayaScore = 0;
    var englishScore = 0;

    for (final token in tokens) {
      if (tagalogIndicators.contains(token)) tagalogScore++;
      if (bisayaIndicators.contains(token)) bisayaScore++;
      if (englishIndicators.contains(token)) englishScore++;
    }

    final hasTagalog = tagalogScore > 0;
    final hasBisaya = bisayaScore > 0;
    final hasEnglish = englishScore > 0;

    if (!hasTagalog && !hasBisaya && !hasEnglish) return null;

    if (tagalogScore >= bisayaScore && tagalogScore > englishScore) {
      return 'tagalog';
    }
    if (bisayaScore > tagalogScore && bisayaScore >= englishScore) {
      return 'bisaya';
    }
    if (englishScore > 0) {
      return 'english';
    }
    if (hasTagalog) return 'tagalog';
    if (hasBisaya) return 'bisaya';
    return 'english';
  }

  bool _isUnsupportedLanguageRequest(String query) {
    final lowered = query.toLowerCase();
    final asksLanguageSwitch = RegExp(
      r'\b(answer|reply|respond|speak|talk|tubag|tubaga|sagot|sagutin)\b',
    ).hasMatch(lowered);
    if (!asksLanguageSwitch) return false;

    const unsupportedLanguages = [
      'spanish',
      'espanol',
      'french',
      'japanese',
      'korean',
      'mandarin',
      'chinese',
      'german',
      'arabic',
      'russian',
      'ilonggo',
      'hiligaynon',
      'waray',
      'kapampangan',
    ];
    return unsupportedLanguages.any(
      (language) => RegExp(r'\b' + RegExp.escape(language) + r'\b').hasMatch(lowered),
    );
  }

  String _textForLanguage(
    String preferredLanguage, {
    required String english,
    String? tagalog,
    String? bisaya,
  }) {
    switch (preferredLanguage) {
      case 'tagalog':
        return tagalog ?? english;
      case 'bisaya':
        return bisaya ?? english;
      default:
        return english;
    }
  }

  String _languageLabel(String preferredLanguage) {
    switch (preferredLanguage) {
      case 'tagalog':
        return 'Tagalog';
      case 'bisaya':
        return 'Bisaya';
      default:
        return 'English';
    }
  }

  String _llmUnavailableMessage(String preferredLanguage) {
    return _textForLanguage(
      preferredLanguage,
      english:
          'I found matching schedule data, but the AI assistant is temporarily unavailable. Please try again shortly.',
      tagalog:
          'May nakita akong tugmang schedule data, pero pansamantalang hindi available ang AI assistant. Pakisubukang muli maya-maya.',
      bisaya:
          'Nakit-an nako ang nagtugma nga schedule data, pero temporaryong dili available ang AI assistant. Palihug sulayi pag-usab unya.',
    );
  }

  String _loginRequiredMessage(String preferredLanguage, {required String purpose}) {
    switch (purpose) {
      case 'viewSchedule':
        return _textForLanguage(
          preferredLanguage,
          english: 'You must be logged in to view your schedule.',
          tagalog: 'Kailangan mong naka-log in para makita ang iyong schedule.',
          bisaya: 'Kinahanglan naka-log in ka aron makita ang imong schedule.',
        );
      case 'checkConflicts':
        return _textForLanguage(
          preferredLanguage,
          english: 'You must be logged in to check for conflicts.',
          tagalog: 'Kailangan mong naka-log in para makita ang conflicts.',
          bisaya: 'Kinahanglan naka-log in ka aron masusi ang conflicts.',
        );
      case 'checkFacultyLoad':
        return _textForLanguage(
          preferredLanguage,
          english: 'You must be logged in to check faculty load information.',
          tagalog:
              'Kailangan mong naka-log in para masuri ang faculty load information.',
          bisaya:
              'Kinahanglan naka-log in ka aron masusi ang faculty load information.',
        );
      default:
        return _textForLanguage(
          preferredLanguage,
          english: 'You must be logged in to continue.',
          tagalog: 'Kailangan mong naka-log in para magpatuloy.',
          bisaya: 'Kinahanglan naka-log in ka aron mopadayon.',
        );
    }
  }

  String _translateAccessMessage(String message, String preferredLanguage) {
    if (message == _facultyAccessRestrictedMessage) {
      return _textForLanguage(
        preferredLanguage,
        english: _facultyAccessRestrictedMessage,
        tagalog:
            'Access restricted. Ang faculty accounts ay maaari lamang tumingin ng personal schedule, teaching load, at assigned timetable information.',
        bisaya:
            'Access restricted. Ang faculty accounts mahimo lang motan-aw sa personal schedule, teaching load, ug assigned timetable information.',
      );
    }
    if (message == _studentAccessRestrictedMessage) {
      return _textForLanguage(
        preferredLanguage,
        english: _studentAccessRestrictedMessage,
        tagalog:
            'Access restricted. Personal academic schedule at assigned section timetable lamang ang maaari mong ma-access.',
        bisaya:
            'Access restricted. Personal academic schedule ug assigned section timetable ra ang imong ma-access.',
      );
    }
    if (message == _studentSectionRestrictedMessage) {
      return _textForLanguage(
        preferredLanguage,
        english: _studentSectionRestrictedMessage,
        tagalog:
            'Access restricted. Maaari lamang tingnan ng students ang sarili nilang assigned section schedule.',
        bisaya:
            'Access restricted. Ang students mahimo lang motan-aw sa ilang kaugalingong assigned section schedule.',
      );
    }
    return _textForLanguage(
      preferredLanguage,
      english: message,
      tagalog: message,
      bisaya: message,
    );
  }

  String _adminManagementResponse(
    bool bulletFormat, {
    required String preferredLanguage,
  }) {
    if (bulletFormat) {
      return _adminFeatureListResponse(
        true,
        preferredLanguage: preferredLanguage,
      );
    }
    return _textForLanguage(
      preferredLanguage,
      english:
          'Administrators manage CITESched through these main modules: Dashboard, Faculty Management, Faculty Loading, Subject Management, Room Management, Timetable, Conflicts, and Reports. In practice, admins maintain faculty, subjects, rooms, and sections, assign schedules in Faculty Loading and Timetable, review detected conflicts in the Conflicts module, and monitor summaries and analytics in Reports.',
      tagalog:
          'Pinamamahalaan ng administrators ang CITESched sa pamamagitan ng mga pangunahing module na ito: Dashboard, Faculty Management, Faculty Loading, Subject Management, Room Management, Timetable, Conflicts, at Reports. Sa actual na gamit, mina-manage nila ang faculty, subjects, rooms, at sections, nag-a-assign ng schedules sa Faculty Loading at Timetable, nire-review ang detected conflicts sa Conflicts module, at mino-monitor ang summaries at analytics sa Reports.',
      bisaya:
          'Gidumala sa administrators ang CITESched pinaagi niining mga nag-unang modules: Dashboard, Faculty Management, Faculty Loading, Subject Management, Room Management, Timetable, Conflicts, ug Reports. Sa aktwal nga gamit, sila ang nagdumala sa faculty, subjects, rooms, ug sections, naga-assign sa schedules sa Faculty Loading ug Timetable, naga-review sa detected conflicts sa Conflicts module, ug naga-monitor sa summaries ug analytics sa Reports.',
    );
  }

  String _adminFeatureListResponse(
    bool bulletFormat, {
    required String preferredLanguage,
  }) {
    if (!bulletFormat) {
      return _textForLanguage(
        preferredLanguage,
        english:
            'The admin side of CITESched includes these modules: Dashboard, Faculty Management, Faculty Loading, Subject Management, Room Management, Timetable, Conflicts, and Reports.',
        tagalog:
            'Kasama sa admin side ng CITESched ang mga module na ito: Dashboard, Faculty Management, Faculty Loading, Subject Management, Room Management, Timetable, Conflicts, at Reports.',
        bisaya:
            'Lakip sa admin side sa CITESched ang mga module nga kini: Dashboard, Faculty Management, Faculty Loading, Subject Management, Room Management, Timetable, Conflicts, ug Reports.',
      );
    }
    return _textForLanguage(
      preferredLanguage,
      english: '''The admin side of CITESched includes:
* Dashboard
* Faculty Management
* Faculty Loading
* Subject Management
* Room Management
* Timetable
* Conflicts
* Reports''',
      tagalog: '''Kasama sa admin side ng CITESched ang:
* Dashboard
* Faculty Management
* Faculty Loading
* Subject Management
* Room Management
* Timetable
* Conflicts
* Reports''',
      bisaya: '''Lakip sa admin side sa CITESched ang:
* Dashboard
* Faculty Management
* Faculty Loading
* Subject Management
* Room Management
* Timetable
* Conflicts
* Reports''',
    );
  }

  String _studentFeatureListResponse(
    bool bulletFormat, {
    required String preferredLanguage,
  }) {
    if (!bulletFormat) {
      return _textForLanguage(
        preferredLanguage,
        english:
            'The student dashboard includes assistant history, a My Classes Schedule area, PDF and DOCX schedule export, a My Weekly Schedule calendar view, and a read-only subject list that shows subject, section, timeslot, room, and faculty details. It also includes student account actions such as password reset and logout.',
        tagalog:
            'Kasama sa student dashboard ang assistant history, My Classes Schedule area, PDF at DOCX schedule export, My Weekly Schedule calendar view, at read-only subject list na nagpapakita ng subject, section, timeslot, room, at faculty details. Kasama rin dito ang password reset at logout actions.',
        bisaya:
            'Lakip sa student dashboard ang assistant history, My Classes Schedule area, PDF ug DOCX schedule export, My Weekly Schedule calendar view, ug read-only subject list nga nagpakita sa subject, section, timeslot, room, ug faculty details. Lakip usab ang password reset ug logout actions.',
      );
    }
    return _textForLanguage(
      preferredLanguage,
      english: '''The student dashboard includes:
* Assistant History
* My Classes Schedule
* Export PDF for the student schedule
* Export DOCX for the student schedule
* My Weekly Schedule calendar view
* Subjects (read-only) list with subject, section, day/time, room, and faculty details
* Password reset action
* Logout action''',
      tagalog: '''Kasama sa student dashboard ang:
* Assistant History
* My Classes Schedule
* Export PDF para sa student schedule
* Export DOCX para sa student schedule
* My Weekly Schedule calendar view
* Subjects (read-only) list na may subject, section, day/time, room, at faculty details
* Password reset action
* Logout action''',
      bisaya: '''Lakip sa student dashboard ang:
* Assistant History
* My Classes Schedule
* Export PDF para sa student schedule
* Export DOCX para sa student schedule
* My Weekly Schedule calendar view
* Subjects (read-only) list nga adunay subject, section, day/time, room, ug faculty details
* Password reset action
* Logout action''',
    );
  }

  String _facultyFeatureListResponse(
    bool bulletFormat, {
    required String preferredLanguage,
  }) {
    if (!bulletFormat) {
      return _textForLanguage(
        preferredLanguage,
        english:
            'The faculty dashboard includes load and availability metrics such as Assigned Units, Max Load, Outside Preferred, Assigned Hours, and Vacant Hours. It also shows free slot summaries, assistant history, a Weekly Calendar view, a Schedule Table tab, and PDF or DOCX schedule export, along with faculty account actions like password reset and logout.',
        tagalog:
            'Kasama sa faculty dashboard ang load at availability metrics tulad ng Assigned Units, Max Load, Outside Preferred, Assigned Hours, at Vacant Hours. Ipinapakita rin nito ang free slot summaries, assistant history, Weekly Calendar view, Schedule Table tab, at PDF o DOCX schedule export, kasama ang password reset at logout actions.',
        bisaya:
            'Lakip sa faculty dashboard ang load ug availability metrics sama sa Assigned Units, Max Load, Outside Preferred, Assigned Hours, ug Vacant Hours. Gipakita usab niini ang free slot summaries, assistant history, Weekly Calendar view, Schedule Table tab, ug PDF o DOCX schedule export, uban sa password reset ug logout actions.',
      );
    }
    return _textForLanguage(
      preferredLanguage,
      english: '''The faculty dashboard includes:
* Assigned Units metric
* Max Load metric
* Outside Preferred metric
* Assigned Hours metric
* Vacant Hours metric
* Free Slots summary
* Preferred availability monitoring
* Assistant History
* Weekly Calendar view
* Schedule Table view
* Export PDF for the faculty schedule
* Export DOCX for the faculty schedule
* Password reset action
* Logout action''',
      tagalog: '''Kasama sa faculty dashboard ang:
* Assigned Units metric
* Max Load metric
* Outside Preferred metric
* Assigned Hours metric
* Vacant Hours metric
* Free Slots summary
* Preferred availability monitoring
* Assistant History
* Weekly Calendar view
* Schedule Table view
* Export PDF para sa faculty schedule
* Export DOCX para sa faculty schedule
* Password reset action
* Logout action''',
      bisaya: '''Lakip sa faculty dashboard ang:
* Assigned Units metric
* Max Load metric
* Outside Preferred metric
* Assigned Hours metric
* Vacant Hours metric
* Free Slots summary
* Preferred availability monitoring
* Assistant History
* Weekly Calendar view
* Schedule Table view
* Export PDF para sa faculty schedule
* Export DOCX para sa faculty schedule
* Password reset action
* Logout action''',
    );
  }

  String _adminMissingModuleResponse(
    bool bulletFormat, {
    required String preferredLanguage,
  }) {
    if (bulletFormat) {
      return _textForLanguage(
        preferredLanguage,
        english: '''Those admin modules are already included:
* Timetable for schedule viewing and filtering
* Conflicts for detected scheduling issues
* Reports for administrative summaries such as conflict, faculty load, room utilization, and schedule overview reports''',
        tagalog: '''Kasama na ang mga admin modules na ito:
* Timetable para sa schedule viewing at filtering
* Conflicts para sa detected scheduling issues
* Reports para sa administrative summaries tulad ng conflict, faculty load, room utilization, at schedule overview reports''',
        bisaya: '''Apil na ang mga admin modules nga kini:
* Timetable para sa schedule viewing ug filtering
* Conflicts para sa detected scheduling issues
* Reports para sa administrative summaries sama sa conflict, faculty load, room utilization, ug schedule overview reports''',
      );
    }
    return _textForLanguage(
      preferredLanguage,
      english:
          'Those modules are already included on the admin side. CITESched has a Timetable module for schedule viewing and filtering, a Conflicts module for detected scheduling issues, and a Reports module for administrative summaries such as conflict, faculty load, room utilization, and schedule overview reports.',
      tagalog:
          'Kasama na ang mga module na iyon sa admin side. May Timetable module ang CITESched para sa schedule viewing at filtering, Conflicts module para sa detected scheduling issues, at Reports module para sa administrative summaries tulad ng conflict, faculty load, room utilization, at schedule overview reports.',
      bisaya:
          'Apil na daan kana nga mga module sa admin side. Adunay Timetable module ang CITESched para sa schedule viewing ug filtering, Conflicts module para sa detected scheduling issues, ug Reports module para sa administrative summaries sama sa conflict, faculty load, room utilization, ug schedule overview reports.',
    );
  }

  String _systemAboutResponse(
    bool bulletFormat, {
    required String preferredLanguage,
  }) {
    if (bulletFormat) {
      return _textForLanguage(
        preferredLanguage,
        english: '''CITESched is an academic scheduling system for Jose Maria College Foundation Inc. It covers:
* Faculty management
* Student and section management
* Subject and room management
* Timeslot and class schedule management
* Timetable views
* Conflict checking
* Verified schedule-based AI assistance''',
        tagalog: '''Ang CITESched ay academic scheduling system para sa Jose Maria College Foundation Inc. Saklaw nito ang:
* Faculty management
* Student at section management
* Subject at room management
* Timeslot at class schedule management
* Timetable views
* Conflict checking
* Verified schedule-based AI assistance''',
        bisaya: '''Ang CITESched usa ka academic scheduling system para sa Jose Maria College Foundation Inc. Naglangkob kini sa:
* Faculty management
* Student ug section management
* Subject ug room management
* Timeslot ug class schedule management
* Timetable views
* Conflict checking
* Verified schedule-based AI assistance''',
      );
    }
    return _textForLanguage(
      preferredLanguage,
      english:
          'CITESched is an academic scheduling system for Jose Maria College Foundation Inc. It manages faculty, students, sections, subjects, rooms, timeslots, class schedules, timetable views, and conflict checking. I can answer questions using verified CITESched schedule data and help you inspect schedules, room use, faculty loads, and timetable conflicts.',
      tagalog:
          'Ang CITESched ay academic scheduling system para sa Jose Maria College Foundation Inc. Pinamamahalaan nito ang faculty, students, sections, subjects, rooms, timeslots, class schedules, timetable views, at conflict checking. Makakasagot ako gamit ang verified CITESched schedule data at makakatulong sa pagtingin ng schedules, room use, faculty loads, at timetable conflicts.',
      bisaya:
          'Ang CITESched usa ka academic scheduling system para sa Jose Maria College Foundation Inc. Gidumala niini ang faculty, students, sections, subjects, rooms, timeslots, class schedules, timetable views, ug conflict checking. Makatubag ko gamit ang verified CITESched schedule data ug makatabang sa pagtan-aw sa schedules, room use, faculty loads, ug timetable conflicts.',
    );
  }

  String _conflictExplanationResponse(
    bool bulletFormat, {
    required String preferredLanguage,
  }) {
    if (bulletFormat) {
      return _textForLanguage(
        preferredLanguage,
        english: '''When a schedule conflict happens in CITESched:
* The system checks overlapping timeslots for the same room
* It checks overlapping timeslots for the same faculty member
* It checks overlapping timeslots for the same section
* Administrators review conflicts in the Conflict module or Timetable
* Admins resolve them by adjusting room, faculty, section, or timeslot assignments''',
        tagalog: '''Kapag may schedule conflict sa CITESched:
* Tinitingnan ng system ang overlapping timeslots para sa parehong room
* Tinitingnan nito ang overlapping timeslots para sa parehong faculty member
* Tinitingnan nito ang overlapping timeslots para sa parehong section
* Nirereview ng administrators ang conflicts sa Conflict module o Timetable
* Inaayos ng admins ang room, faculty, section, o timeslot assignments para maalis ang overlap''',
        bisaya: '''Kung adunay schedule conflict sa CITESched:
* Gisusi sa system ang overlapping timeslots para sa parehas nga room
* Gisusi niini ang overlapping timeslots para sa parehas nga faculty member
* Gisusi niini ang overlapping timeslots para sa parehas nga section
* Gi-review sa administrators ang conflicts sa Conflict module o Timetable
* Giayo sa admins ang room, faculty, section, o timeslot assignments aron mawagtang ang overlap''',
      );
    }
    return _textForLanguage(
      preferredLanguage,
      english:
          'When a schedule conflict happens in CITESched, it is handled by checking overlapping timeslots for the same room, faculty member, or section. Administrators can review those conflicts in the Conflict Module or Timetable tools, then adjust room assignments, faculty assignments, sections, or timeslots to remove the overlap.',
      tagalog:
          'Kapag may schedule conflict sa CITESched, hina-handle ito sa pamamagitan ng pag-check ng overlapping timeslots para sa parehong room, faculty member, o section. Maaaring i-review ng administrators ang mga conflict na iyon sa Conflict Module o Timetable tools, pagkatapos ay ayusin ang room assignments, faculty assignments, sections, o timeslots para maalis ang overlap.',
      bisaya:
          'Kung adunay schedule conflict sa CITESched, gi-handle kini pinaagi sa pag-check sa overlapping timeslots para sa parehas nga room, faculty member, o section. Mahimo kining i-review sa administrators sa Conflict Module o Timetable tools, unya usbon ang room assignments, faculty assignments, sections, o timeslots aron mawala ang overlap.',
    );
  }

  Future<NLPResponse?> _trySimpleRoomListQuery(
    Session session,
    String query,
    List<String> scopes,
  ) async {
    final asksForRooms = _containsKeywordFuzzy(query, [
      'room',
      'rooms',
      'laboratory',
      'lab',
    ]);
    final asksToShow = _containsKeywordFuzzy(query, [
      'show',
      'list',
      'display',
      'view',
    ]);

    if (!asksForRooms || !asksToShow) return null;
    if (_matchRoomByName(query, await Room.db.find(session)) != null) return null;
    if (_extractTimeRange(query) != null) return null;
    if (_extractDayOfWeek(query) != null) return null;

    final rooms = await Room.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    if (rooms.isEmpty) {
      return NLPResponse(
        text: 'I could not find any active rooms in CITESched.',
        intent: NLPIntent.roomStatus,
      );
    }

    final roomNames = rooms.map((room) => room.name).toList();
    return NLPResponse(
      text:
          'Active rooms: ${roomNames.take(12).join(', ')}${roomNames.length > 12 ? '...' : ''}',
      intent: NLPIntent.roomStatus,
      dataJson: jsonEncode({
        'roomCount': rooms.length,
        'rooms': roomNames,
      }),
    );
  }

  Future<NLPResponse?> _trySimpleTimetableQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
  ) async {
    final asksTimetable = _containsKeywordFuzzy(query, [
      'timetable',
      'schedule',
      'schedules',
    ]);
    final asksToShow = _containsKeywordFuzzy(query, [
      'show',
      'view',
      'display',
      'list',
    ]);

    if (!asksTimetable || !asksToShow) return null;
    if (_extractSectionFromQuery(query) != null) return null;
    if (_hasFacultyReference(query)) return null;
    if (_extractDayOfWeek(query) != null) return null;
    if (_extractTimeRange(query) != null) return null;
    if (_containsKeywordFuzzy(query, ['room', 'rooms'])) return null;

    final isAdmin = scopes.contains('admin');
    if (isAdmin) {
      final schedules = await Schedule.db.find(
        session,
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
          sectionRef: Section.include(),
        ),
      );
      return NLPResponse(
        text:
            'The timetable currently has ${schedules.length} scheduled class entries. I loaded the live timetable so you can view it in table or calendar format.',
        intent: NLPIntent.schedule,
        schedules: schedules,
        dataJson: jsonEncode({
          'contextType': 'timetable',
          'scheduleCount': schedules.length,
        }),
      );
    }

    if (userId == null) return null;
    return _handleMyScheduleQuery(session, userId, scopes, null);
  }

  Future<NLPResponse?> _tryRoomTypeQuestion(
    Session session,
    String query,
  ) async {
    if (!_isRoomTypeQuestion(query)) return null;

    final rooms = await Room.db.find(session);
    final matchedRoom = _matchRoomByName(query, rooms);
    if (matchedRoom == null) {
      return NLPResponse(
        text:
            "Which room are you asking about? Try: 'Is IT Lab a laboratory or lecture room?'",
        intent: NLPIntent.roomStatus,
      );
    }

    final typeLabel = matchedRoom.type == RoomType.laboratory
        ? 'laboratory'
        : 'lecture';
    return NLPResponse(
      text: "Room ${matchedRoom.name} is a $typeLabel room.",
      intent: NLPIntent.roomStatus,
      dataJson: jsonEncode({
        'roomId': matchedRoom.id,
        'roomName': matchedRoom.name,
        'type': typeLabel,
      }),
    );
  }

  bool _isRoomTypeQuestion(String query) {
    final hasLab = _containsKeyword(query, ['lab', 'laboratory']);
    final hasLecture = _containsKeyword(query, ['lecture']);
    return hasLab && hasLecture;
  }

  Room? _matchRoomByName(String query, List<Room> rooms) {
    final cleanedQuery = _normalizeQuery(query.toLowerCase());
    for (var r in rooms) {
      final name = _normalizeQuery(r.name.toLowerCase());
      if (cleanedQuery.contains(name)) return r;

      final tokens = name.split(RegExp(r'\s+')).where((t) => t.length >= 2);
      for (var token in tokens) {
        final tokenRegex = RegExp(r'\b' + RegExp.escape(token) + r'\b');
        if (tokenRegex.hasMatch(cleanedQuery)) {
          return r;
        }
      }
    }
    return null;
  }

  Future<NLPResponse?> _tryRoomTypeScheduleQuery(
    Session session,
    String query,
    DayOfWeek? requestedDay,
    List<String> scopes,
  ) async =>
      _tryRoomTypeScheduleQueryImpl(
        session,
        query,
        requestedDay,
        scopes,
      );

  Future<NLPResponse?> _tryRoomTypeScheduleQueryImpl(
    Session session,
    String query,
    DayOfWeek? requestedDay,
    List<String> scopes,
  ) async {
    final roomType = _extractRoomType(query);
    if (roomType == null) return null;

    final hasScheduleIntent = _hasScheduleIntent(query);

    if (!hasScheduleIntent && requestedDay == null) {
      return null;
    }

    if (requestedDay == null) {
      return NLPResponse(
        text:
            "Which day should I check for ${roomType == RoomType.laboratory ? 'laboratory' : 'lecture'} rooms?",
        intent: NLPIntent.schedule,
      );
    }

    final isAdmin = scopes.contains('admin');
    if (!isAdmin) {
      return NLPResponse(
        text:
            "Please specify whose schedule to check (e.g., 'my schedule on ${_dayLabel(requestedDay)}' or 'schedule for IT 3A on ${_dayLabel(requestedDay)}').",
        intent: NLPIntent.schedule,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );

    final filtered = schedules.where((s) {
      final ts = s.timeslot;
      final room = s.room;
      if (ts == null || room == null) return false;
      if (ts.day != requestedDay) return false;
      return room.type == roomType;
    }).toList();

    if (filtered.isEmpty) {
      return NLPResponse(
        text:
            "I couldn't find any ${roomType == RoomType.laboratory ? 'laboratory' : 'lecture'} classes on ${_dayLabel(requestedDay)}.",
        intent: NLPIntent.schedule,
      );
    }

    return NLPResponse(
      text:
          "Found ${filtered.length} ${roomType == RoomType.laboratory ? 'laboratory' : 'lecture'} class(es) on ${_dayLabel(requestedDay)}.",
      intent: NLPIntent.schedule,
      schedules: filtered,
    );
  }

  RoomType? _extractRoomType(String query) {
    final hasLecture = _containsKeyword(query, ['lecture']);
    final hasLab = _containsKeyword(query, ['lab', 'laboratory']);

    if (hasLecture && hasLab) return null;
    if (hasLecture) return RoomType.lecture;
    if (hasLab) return RoomType.laboratory;
    return null;
  }

  /// Checks if query contains forbidden keywords
  bool _containsForbiddenKeywords(String query) {
    return forbiddenKeywords.any((keyword) => query.contains(keyword));
  }

  /// Returns standard unsupported response
  NLPResponse _unsupportedResponse(String preferredLanguage) {
    return NLPResponse(
      text: _textForLanguage(
        preferredLanguage,
        english: 'This query is not supported by the system.',
        tagalog: 'Hindi sinusuportahan ng system ang query na ito.',
        bisaya: 'Dili suportado sa systema kining querya.',
      ),
      intent: NLPIntent.unknown,
    );
  }

  bool _containsSectionPattern(String query) {
    // Regex for common section patterns (e.g., IT 1A, IT-2B, 3-C, etc.)
    final sectionRegex = RegExp(r'\b([a-zA-Z]{1,4})?\s?\d[a-zA-Z]\b');
    return sectionRegex.hasMatch(query);
  }

  bool _hasScheduleIntent(String query) {
    return _containsKeywordFuzzy(
      query,
      [
        'schedule',
        'scheduled',
        'sched',
        'timetable',
        'class',
        'classes',
        'subject',
        'subjects',
      ],
    );
  }

  bool _hasMyScheduleIntent(String query) {
    return _containsKeywordFuzzy(query, ['my', 'mine']) &&
        _hasScheduleIntent(query);
  }

  bool _hasRoomIntent(String query) {
    return _containsKeywordFuzzy(
      query,
      ['room', 'rooms', 'lab', 'laboratory', 'lecture', 'available', 'free'],
    );
  }

  bool _hasConflictIntent(String query) {
    if (_isConflictExplanationQuery(query)) return false;
    return _containsKeywordFuzzy(query, ['conflict', 'issue', 'overlap']);
  }

  bool _hasOverloadIntent(String query) {
    return _containsKeywordFuzzy(query, ['overload', 'load', 'units']) &&
        _containsKeywordFuzzy(query, ['faculty', 'teacher', 'instructor']);
  }

  bool _hasSystemIntent(String query) {
    return _containsKeywordFuzzy(
      query,
      [
        'generate',
        'regenerate',
        'optimize',
        'timetable',
        'schedule',
        'conflict',
        'resolve',
        'suggest',
      ],
    );
  }

  bool _hasScheduleQuestion(
    String query,
    DayOfWeek? requestedDay,
    List<DayOfWeek> relativeDays,
    _TimeRange? timeRange,
  ) {
    final hasDay = requestedDay != null || relativeDays.isNotEmpty;
    final hasTime = timeRange != null || _containsKeywordFuzzy(query, ['now']);
    if (!hasDay && !hasTime) return false;
    return _containsKeywordFuzzy(query, ['who', 'what', 'which']);
  }

  /// Handles "My Schedule" query for current authenticated user
  Future<NLPResponse> _handleMyScheduleQuery(
    Session session,
    String userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
  ) async {
    try {
      final isFaculty = scopes.contains('faculty');
      final isStudent = scopes.contains('student');

      if (isFaculty) {
        // Get faculty schedules
        final faculty = await _findCurrentFaculty(session, userId);

        if (faculty == null) {
          return NLPResponse(
            text: "Could not find your faculty profile.",
            intent: NLPIntent.schedule,
          );
        }

        final schedules = await Schedule.db.find(
          session,
          where: (t) => t.facultyId.equals(faculty.id!),
          include: Schedule.include(
            subject: Subject.include(),
            room: Room.include(),
            timeslot: Timeslot.include(),
          ),
        );

        final filtered = _filterSchedulesByDay(schedules, requestedDay);
        return NLPResponse(
          text: _buildScheduleCountMessage(
            filtered.length,
            "You have",
            requestedDay,
          ),
          intent: NLPIntent.schedule,
          schedules: filtered,
          dataJson: jsonEncode({
            'contextType': 'my',
            'contextValue': 'faculty',
          }),
        );
      } else if (isStudent) {
        final student = await _findCurrentStudent(session, userId);
        if (student == null) {
          return NLPResponse(
            text: "Could not find your student profile.",
            intent: NLPIntent.schedule,
          );
        }

        List<Schedule> schedules;
        if (student.sectionId != null) {
          schedules = await Schedule.db.find(
            session,
            where: (t) =>
                t.sectionId.equals(student.sectionId) & t.isActive.equals(true),
            include: Schedule.include(
              subject: Subject.include(),
              faculty: Faculty.include(),
              room: Room.include(),
              timeslot: Timeslot.include(),
            ),
          );
        } else if (student.section != null && student.section!.isNotEmpty) {
          schedules = await Schedule.db.find(
            session,
            where: (t) =>
                t.section.equals(student.section!) & t.isActive.equals(true),
            include: Schedule.include(
              subject: Subject.include(),
              faculty: Faculty.include(),
              room: Room.include(),
              timeslot: Timeslot.include(),
            ),
          );
        } else {
          schedules = [];
        }

        final filtered = _filterSchedulesByDay(schedules, requestedDay);
        return NLPResponse(
          text: _buildScheduleCountMessage(
            filtered.length,
            "You have",
            requestedDay,
          ),
          intent: NLPIntent.schedule,
          schedules: filtered,
          dataJson: jsonEncode({
            'contextType': 'my',
            'contextValue': 'student',
          }),
        );
      }

      return NLPResponse(
        text: "Could not determine your user role.",
        intent: NLPIntent.unknown,
      );
    } catch (e) {
      print('Error in _handleMyScheduleQuery: $e');
      return NLPResponse(
        text: "An error occurred while retrieving your schedule.",
        intent: NLPIntent.unknown,
      );
    }
  }

  Future<NLPResponse> _handleConflictQuery(
    Session session,
    String userId,
    List<String> scopes,
  ) async {
    try {
      if (scopes.contains('admin')) {
        return await _handleAdminConflicts(session);
      }
      if (scopes.contains('faculty')) {
        return await _handleFacultyConflicts(session, userId);
      }
      if (scopes.contains('student')) {
        return await _handleStudentConflicts(session, userId);
      }

      return NLPResponse(
        text: "Could not determine your role to check conflicts.",
        intent: NLPIntent.unknown,
      );
    } catch (e) {
      print('Error in _handleConflictQuery: $e');
      return NLPResponse(
        text: "An error occurred while checking conflicts.",
        intent: NLPIntent.conflict,
      );
    }
  }

  Future<NLPResponse> _handleAdminConflicts(Session session) async {
    final conflicts = await _conflictService.getAllConflicts(session);
    if (conflicts.isEmpty) {
      return NLPResponse(
        text:
            "Great news! There are currently no conflicts detected in the system.",
        intent: NLPIntent.conflict,
      );
    }
    final roomConflicts = conflicts
        .where((c) => c.type.toLowerCase().contains('room'))
        .length;
    final facultyConflicts = conflicts
        .where((c) => c.type.toLowerCase().contains('faculty'))
        .length;

    var summary = "I found ${conflicts.length} conflict(s): ";
    if (roomConflicts > 0) summary += "$roomConflicts room conflict(s). ";
    if (facultyConflicts > 0) {
      summary += "$facultyConflicts faculty conflict(s). ";
    }

    return NLPResponse(
      text:
          "$summary You can view details in the Conflict Module or use Timetable to resolve.",
      intent: NLPIntent.conflict,
      dataJson:
          '{"count": ${conflicts.length}, "room": $roomConflicts, "faculty": $facultyConflicts}',
    );
  }

  Future<NLPResponse> _handleFacultyConflicts(
    Session session,
    String userId,
  ) async {
    final faculty = await _findCurrentFaculty(session, userId);

    if (faculty == null) {
      return NLPResponse(
        text: "Could not find your faculty profile.",
        intent: NLPIntent.conflict,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      where: (t) => t.facultyId.equals(faculty.id!),
    );

    int conflictCount = 0;
    for (var schedule in schedules) {
      final timeslotConflict = await _conflictService.checkFacultyAvailability(
        session,
        facultyId: faculty.id!,
        timeslotId: schedule.timeslotId,
        excludeScheduleId: schedule.id,
      );
      if (timeslotConflict != null) conflictCount++;
    }

    if (conflictCount == 0) {
      return NLPResponse(
        text:
            "Good news! You have no conflicts in your schedule. All your classes are scheduled properly.",
        intent: NLPIntent.conflict,
      );
    }

    return NLPResponse(
      text:
          "⚠️ You have $conflictCount conflict(s) in your schedule. Please check the Timetable to resolve them.",
      intent: NLPIntent.conflict,
      dataJson: '{"count": $conflictCount}',
    );
  }

  Future<NLPResponse> _handleStudentConflicts(
    Session session,
    String userId,
  ) async {
    final student = await _findCurrentStudent(session, userId);

    if (student == null || student.section == null) {
      return NLPResponse(
        text: "Could not find your section information.",
        intent: NLPIntent.conflict,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      where: (t) => t.section.equals(student.section!),
    );

    int conflictCount = 0;
    for (var schedule in schedules) {
      final sectionConflict = await _conflictService.checkSectionAvailability(
        session,
        section: student.section!,
        timeslotId: schedule.timeslotId,
        excludeScheduleId: schedule.id,
      );
      if (sectionConflict != null) conflictCount++;
    }

    if (conflictCount == 0) {
      return NLPResponse(
        text:
            "Good news! Your section has no conflicts. All classes are properly scheduled.",
        intent: NLPIntent.conflict,
      );
    }

    return NLPResponse(
      text:
          "⚠️ Your section has $conflictCount conflict(s). Please contact your administrator.",
      intent: NLPIntent.conflict,
      dataJson: '{"count": $conflictCount}',
    );
  }

  /// Handles faculty overload detection
  Future<NLPResponse> _handleOverloadQuery(
    Session session,
    String userId,
    List<String> scopes,
    String query,
  ) async =>
      _handleOverloadQueryImpl(session, userId, scopes, query);

  Future<NLPResponse> _handleOverloadQueryImpl(
    Session session,
    String userId,
    List<String> scopes,
    String query,
  ) async {
    try {
      final isAdmin = scopes.contains('admin');
      final isFaculty = scopes.contains('faculty');
      final facultyList = await Faculty.db.find(session);
      Faculty? foundFaculty;

      // Entity extraction: find faculty by name
      for (var f in facultyList) {
        if (query.contains(f.name.toLowerCase())) {
          foundFaculty = f;
          break;
        }
      }

      if (foundFaculty != null) {
        // If a specific faculty is mentioned and user is not admin, check if it's themselves
        if (!isAdmin && isFaculty) {
          final currentFaculty = await _findCurrentFaculty(session, userId);
          if (currentFaculty == null || currentFaculty.id != foundFaculty.id) {
            return NLPResponse(
              text:
                  "You can only view your own load information. Contact administrators to see other faculty loads.",
              intent: NLPIntent.facultyLoad,
            );
          }
        }

        final schedules = await Schedule.db.find(
          session,
          where: (t) => t.facultyId.equals(foundFaculty!.id!),
          include: Schedule.include(
            subject: Subject.include(),
            timeslot: Timeslot.include(),
          ),
        );

        double totalUnits = 0;
        double totalHours = 0;

        for (var s in schedules) {
          totalUnits += s.units ?? 0;
          if (s.timeslot != null) {
            try {
              var start = DateTime.parse('2000-01-01 ${s.timeslot!.startTime}');
              var end = DateTime.parse('2000-01-01 ${s.timeslot!.endTime}');
              totalHours += end.difference(start).inMinutes / 60.0;
            } catch (_) {
              totalHours += 3.0;
            }
          }
        }

        // Check if overloaded
        final isOverloaded = totalUnits > (foundFaculty.maxLoad ?? 0);
        final intent = isOverloaded
            ? NLPIntent.facultyLoad
            : NLPIntent.schedule;

        return NLPResponse(
          text: isOverloaded
              ? "⚠️ ${foundFaculty.name} is OVERLOADED! Teaching ${schedules.length} classes with ${totalUnits.toStringAsFixed(1)} units (Limit: ${foundFaculty.maxLoad}). Total hours: ${totalHours.toStringAsFixed(1)}/week."
              : "${foundFaculty.name} is teaching ${schedules.length} classes with ${totalUnits.toStringAsFixed(1)} units (Limit: ${foundFaculty.maxLoad}). Total hours: ${totalHours.toStringAsFixed(1)}/week. Load is acceptable.",
          intent: intent,
          schedules: schedules,
          dataJson:
              '{"facultyId": ${foundFaculty.id}, "totalUnits": $totalUnits, "maxLoad": ${foundFaculty.maxLoad}, "isOverloaded": $isOverloaded}',
        );
      }

      // Non-admin users can only see their own load info
      if (!isAdmin && isFaculty) {
        final faculty = await _findCurrentFaculty(session, userId);

        if (faculty == null) {
          return NLPResponse(
            text:
                "General load information is only available to administrators.",
            intent: NLPIntent.facultyLoad,
          );
        }

        final schedules = await Schedule.db.find(
          session,
          where: (t) => t.facultyId.equals(faculty.id!),
          include: Schedule.include(
            subject: Subject.include(),
            timeslot: Timeslot.include(),
          ),
        );

        double totalUnits = 0;
        for (var s in schedules) {
          totalUnits += s.units ?? 0;
        }

        final isOverloaded = totalUnits > (faculty.maxLoad ?? 0);
        return NLPResponse(
          text: isOverloaded
              ? "⚠️ You are currently overloaded with ${totalUnits.toStringAsFixed(1)} units (Limit: ${faculty.maxLoad} units). Consider discussing with administration."
              : "Your current load is ${totalUnits.toStringAsFixed(1)} units (Limit: ${faculty.maxLoad}). Load is within acceptable range.",
          intent: isOverloaded ? NLPIntent.facultyLoad : NLPIntent.schedule,
          dataJson:
              '{"totalUnits": $totalUnits, "maxLoad": ${faculty.maxLoad}, "isOverloaded": $isOverloaded}',
        );
      }

      // If no specific faculty mentioned and user is admin, show all overloaded faculty
      if (!isAdmin) {
        return NLPResponse(
          text:
              "General faculty load information is only available to administrators.",
          intent: NLPIntent.facultyLoad,
        );
      }

      final allSchedules = await Schedule.db.find(
        session,
        include: Schedule.include(
          faculty: Faculty.include(),
          subject: Subject.include(),
          timeslot: Timeslot.include(),
        ),
      );

      final facultyLoad = <int, Map<String, dynamic>>{};
      for (var s in allSchedules) {
        final facultyId = s.facultyId;
        if (!facultyLoad.containsKey(facultyId)) {
          facultyLoad[facultyId] = {
            'units': 0.0,
            'hours': 0.0,
            'faculty': s.faculty,
            'count': 0,
          };
        }
        facultyLoad[facultyId]!['units'] += s.units ?? 0;
        facultyLoad[facultyId]!['count']++;

        if (s.timeslot != null) {
          try {
            var start = DateTime.parse('2000-01-01 ${s.timeslot!.startTime}');
            var end = DateTime.parse('2000-01-01 ${s.timeslot!.endTime}');
            facultyLoad[facultyId]!['hours'] +=
                end.difference(start).inMinutes / 60.0;
          } catch (_) {
            facultyLoad[facultyId]!['hours'] += 3.0;
          }
        }
      }

      final overloadedFaculty = facultyLoad.entries
          .where(
            (e) =>
                ((e.value['units'] as double?) ?? 0) >
                (e.value['faculty'].maxLoad ?? 0),
          )
          .toList();

      if (overloadedFaculty.isEmpty) {
        return NLPResponse(
          text: "Good news! No faculty members are currently overloaded.",
          intent: NLPIntent.schedule,
        );
      }

      var summary =
          "I found ${overloadedFaculty.length} overloaded faculty member(s):\n";
      for (var entry in overloadedFaculty) {
        final faculty = entry.value['faculty'] as Faculty;
        final units = entry.value['units'] as double;
        summary +=
            "\n• ${faculty.name}: ${units.toStringAsFixed(1)} units (Limit: ${faculty.maxLoad})";
      }

      return NLPResponse(
        text: summary,
        intent: NLPIntent.facultyLoad,
        dataJson: '{"overloadedCount": ${overloadedFaculty.length}}',
      );
    } catch (e) {
      print('Error in _handleOverloadQuery: $e');
      return NLPResponse(
        text: "An error occurred while checking faculty load.",
        intent: NLPIntent.facultyLoad,
      );
    }
  }

  Future<NLPResponse> _handleRoomQuery(Session session, String query) async {
    try {
      final rooms = await Room.db.find(session);
      Room? foundRoom;

      for (var r in rooms) {
        if (query.contains(r.name.toLowerCase())) {
          foundRoom = r;
          break;
        }
      }

      if (foundRoom != null) {
        final schedules = await Schedule.db.find(
          session,
          where: (t) => t.roomId.equals(foundRoom!.id!),
          include: Schedule.include(
            subject: Subject.include(),
            timeslot: Timeslot.include(),
          ),
        );

        return NLPResponse(
          text:
              "Room ${foundRoom.name} (${foundRoom.type.name}) currently has ${schedules.length} assigned sessions. Capacity: ${foundRoom.capacity} students.",
          intent: NLPIntent.roomStatus,
          schedules: schedules,
          dataJson: jsonEncode({
            'id': foundRoom.id,
            'capacity': foundRoom.capacity,
            'roomName': foundRoom.name,
            'type': foundRoom.type.name,
          }),
        );
      }

      return NLPResponse(
        text:
            "I can check room status. Try asking 'Is [Room Name] available?' or 'How busy is [Room Name]?'",
        intent: NLPIntent.roomStatus,
      );
    } catch (e) {
      print('Error in _handleRoomQuery: $e');
      return NLPResponse(
        text: "An error occurred while checking room status.",
        intent: NLPIntent.roomStatus,
      );
    }
  }

  Future<NLPResponse> _handleScheduleQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
    List<DayOfWeek> requestedDays,
  ) async =>
      _handleScheduleQueryImpl(
        session,
        query,
        userId,
        scopes,
        requestedDay,
        requestedDays,
      );

  Future<NLPResponse> _handleScheduleQueryImpl(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
    List<DayOfWeek> requestedDays,
  ) async {
    try {
      final isAdmin = scopes.contains('admin');

      // Multi-day schedule queries (e.g., "schedule on Monday, Tuesday")
      final multiDayResponse = await _tryMultiDayScheduleQuery(
        session,
        query,
        userId,
        scopes,
        requestedDays,
      );
      if (multiDayResponse != null) return multiDayResponse;

      // First: check if the query references a faculty name
      final facultySchedules = await _tryFacultyScheduleQuery(
        session,
        query,
        userId,
        scopes,
        requestedDay,
      );
      if (facultySchedules != null) return facultySchedules;

      if (_hasFacultyReference(query)) {
        return NLPResponse(
          text:
              "I couldn't find a faculty member matching that name. Try using the faculty's recorded name in CITESched.",
          intent: NLPIntent.schedule,
        );
      }

      // Extract section (e.g., IT 3A / 3A)
      final extractedSection = _extractSectionFromQuery(query);
      if (extractedSection != null) {
        final sectionCandidates = _buildSectionCandidates(extractedSection);
        final allSchedules = <Schedule>[];
        for (final candidate in sectionCandidates) {
          final chunk = await Schedule.db.find(
            session,
            where: (t) => t.section.equals(candidate),
            include: Schedule.include(
              subject: Subject.include(),
              faculty: Faculty.include(),
              room: Room.include(),
              timeslot: Timeslot.include(),
            ),
          );
          allSchedules.addAll(chunk);
        }

        final schedulesById = <int, Schedule>{};
        for (final sched in allSchedules) {
          final id = sched.id;
          if (id != null) {
            schedulesById[id] = sched;
          }
        }
        final schedules = schedulesById.values.toList();

        final filtered = _filterSchedulesByDay(schedules, requestedDay);
        if (filtered.isEmpty) {
          return NLPResponse(
            text: _buildScheduleCountMessage(
              0,
              "I couldn't find any classes scheduled for section $extractedSection",
              requestedDay,
            ),
            intent: NLPIntent.schedule,
          );
        }

        return NLPResponse(
          text: _buildScheduleCountMessage(
            filtered.length,
            "Found",
            requestedDay,
            suffix: "for section $extractedSection",
          ),
          intent: NLPIntent.schedule,
          schedules: filtered,
          dataJson: jsonEncode({
            'contextType': 'section',
            'contextValue': extractedSection,
          }),
        );
      }

      final isStudent = scopes.contains('student');
      if (isStudent && userId != null) {
        return await _handleMyScheduleQuery(
          session,
          userId,
          scopes,
          requestedDay ??
              (requestedDays.length == 1 ? requestedDays.first : null),
        );
      }

      if (isAdmin && query.contains('timetable')) {
        final schedules = await Schedule.db.find(
          session,
          include: Schedule.include(
            subject: Subject.include(),
            faculty: Faculty.include(),
            room: Room.include(),
            timeslot: Timeslot.include(),
          ),
        );
        final filtered = _filterSchedulesByDay(schedules, requestedDay);
        if (filtered.isEmpty) {
          return NLPResponse(
            text: _buildScheduleCountMessage(
              0,
              "I couldn't find any classes scheduled",
              requestedDay,
              suffix: 'in the timetable',
            ),
            intent: NLPIntent.schedule,
          );
        }

        return NLPResponse(
          text: _buildScheduleCountMessage(
            filtered.length,
            "Found",
            requestedDay,
            suffix: 'in the timetable',
          ),
          intent: NLPIntent.schedule,
          schedules: filtered,
          dataJson: jsonEncode({
            'contextType': 'timetable',
            'contextValue': 'all',
          }),
        );
      }

      if (requestedDay != null) {
        return NLPResponse(
          text:
              "Which schedule on ${_dayLabel(requestedDay)}? Try 'my schedule on ${_dayLabel(requestedDay)}', 'Show schedule for IT 3A on ${_dayLabel(requestedDay)}', or 'Schedule of Prof Juan on ${_dayLabel(requestedDay)}'.",
          intent: NLPIntent.schedule,
        );
      }

      return NLPResponse(
        text:
            "I can find schedules for specific sections. Try asking 'Show schedule for IT 3A'.",
        intent: NLPIntent.schedule,
      );
    } catch (e) {
      print('Error in _handleScheduleQuery: $e');
      return NLPResponse(
        text: "An error occurred while retrieving the schedule.",
        intent: NLPIntent.schedule,
      );
    }
  }

  Future<NLPResponse?> _tryMultiDayScheduleQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    List<DayOfWeek> requestedDays,
  ) async {
    if (requestedDays.length < 2) return null;

    // Require schedule intent words to avoid false positives.
    if (!query.contains('schedule') &&
        !query.contains('timetable') &&
        !query.contains('class') &&
        !query.contains('classes')) {
      return null;
    }

    final isAdmin = scopes.contains('admin');
    final isFaculty = scopes.contains('faculty');
    final isStudent = scopes.contains('student');

    if (!isAdmin) {
      final dayList = requestedDays.map(_dayLabel).join(', ');
      final roleHint = isFaculty || isStudent
          ? 'Try "my schedule on $dayList" or specify a section or faculty.'
          : 'Please log in and specify whose schedule you want.';
      return NLPResponse(
        text: "Which schedule on $dayList? $roleHint",
        intent: NLPIntent.schedule,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      include: Schedule.include(
        timeslot: Timeslot.include(),
      ),
    );

    final counts = <DayOfWeek, int>{};
    for (var day in requestedDays) {
      counts[day] = 0;
    }

    for (var s in schedules) {
      final day = s.timeslot?.day;
      if (day != null && counts.containsKey(day)) {
        counts[day] = (counts[day] ?? 0) + 1;
      }
    }

    final summaryParts = requestedDays
        .map((d) => "${_dayLabel(d)}: ${counts[d] ?? 0}")
        .toList();

    return NLPResponse(
      text: "Schedules by day: ${summaryParts.join(', ')}.",
      intent: NLPIntent.schedule,
      dataJson: _buildDayCountJson(counts),
    );
  }

  Future<NLPResponse?> _tryFacultyScheduleQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
  ) async {
    if (!query.contains('schedule') &&
        !query.contains('timetable') &&
        !query.contains('class') &&
        !query.contains('classes')) {
      return null;
    }

    final facultyList = await Faculty.db.find(session);
    final matchedFaculty = _matchFacultyByName(query, facultyList);
    if (matchedFaculty == null) return null;

    final isAdmin = scopes.contains('admin');
    final isFaculty = scopes.contains('faculty');

    if (!isAdmin && isFaculty) {
      if (userId == null) {
        return NLPResponse(
          text: "You must be logged in to view faculty schedules.",
          intent: NLPIntent.unknown,
        );
      }
    }

    final schedules = await Schedule.db.find(
      session,
      where: (t) => t.facultyId.equals(matchedFaculty.id!),
      include: Schedule.include(
        subject: Subject.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );

    final filtered = _filterSchedulesByDay(schedules, requestedDay);
    if (filtered.isEmpty) {
      return NLPResponse(
        text: _buildScheduleCountMessage(
          0,
          "I couldn't find any classes for ${matchedFaculty.name}",
          requestedDay,
        ),
        intent: NLPIntent.schedule,
      );
    }

    return NLPResponse(
      text: _buildScheduleCountMessage(
        filtered.length,
        "Found",
        requestedDay,
        suffix: "for ${matchedFaculty.name}",
      ),
      intent: NLPIntent.schedule,
      schedules: filtered,
      dataJson: jsonEncode({
        'contextType': 'faculty',
        'contextValue': matchedFaculty.name,
        'facultyId': matchedFaculty.id,
      }),
    );
  }

  Faculty? _matchFacultyByName(String query, List<Faculty> facultyList) {
    final cleanedQuery = _normalizeFacultySearchText(query);
    if (cleanedQuery.isEmpty) return null;
    final queryTokens = _extractFacultySearchTokens(cleanedQuery);
    final extractedCandidate = _extractFacultyNameCandidate(cleanedQuery);
    final candidateTokens = extractedCandidate == null
        ? const <String>{}
        : _extractFacultySearchTokens(extractedCandidate);

    Faculty? bestMatch;
    var bestScore = 0;

    for (var f in facultyList) {
      final normalizedName = _normalizeFacultySearchText(f.name);
      if (normalizedName.isEmpty) continue;
      final nameTokens = _extractFacultySearchTokens(normalizedName);

      if (cleanedQuery.contains(normalizedName)) return f;
      if (extractedCandidate != null &&
          (extractedCandidate == normalizedName ||
              normalizedName.contains(extractedCandidate) ||
              extractedCandidate.contains(normalizedName))) {
        return f;
      }

      if (queryTokens.isEmpty || nameTokens.isEmpty) continue;

      final containsAllNameTokens = nameTokens.every(queryTokens.contains);
      final containsAllQueryTokens = queryTokens.every(nameTokens.contains);
      if (containsAllNameTokens || containsAllQueryTokens) {
        return f;
      }

      if (candidateTokens.isNotEmpty) {
        final candidateContainsAll = candidateTokens.every(nameTokens.contains);
        final nameContainsCandidate = nameTokens.every(candidateTokens.contains);
        if (candidateContainsAll || nameContainsCandidate) {
          return f;
        }
      }

      final overlap = queryTokens.intersection(nameTokens).length;
      final candidateOverlap = candidateTokens.intersection(nameTokens).length;
      final score =
          overlap * 10 +
          candidateOverlap * 14 +
          (_tokenPrefixMatchScore(queryTokens, nameTokens)) +
          (_tokenPrefixMatchScore(nameTokens, queryTokens)) +
          (_tokenPrefixMatchScore(candidateTokens, nameTokens) * 2);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = f;
      }
    }

    return bestScore >= 10 ? bestMatch : null;
  }

  String _normalizeFacultySearchText(String text) {
    final lowered = text.toLowerCase().replaceAll(
      RegExp(r'\b(sir|maam|mam|mr|ms|mrs|prof|professor|dr)\b'),
      ' ',
    );
    return lowered
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Set<String> _extractFacultySearchTokens(String text) {
    const ignoredTokens = {
      'what',
      'is',
      'the',
      'schedule',
      'of',
      'for',
      'show',
      'me',
      'please',
      'timetable',
      'class',
      'classes',
      'teacher',
      'faculty',
      'instructor',
      'professor',
      'prof',
    };
    return text
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.length >= 3 && !ignoredTokens.contains(token))
        .toSet();
  }

  String? _extractFacultyNameCandidate(String text) {
    final patterns = [
      RegExp(r'(?:schedule|timetable|class|classes)\s+of\s+(.+)$'),
      RegExp(r'(?:for|of)\s+(?:sir|maam|mam|mr|ms|mrs|prof|professor|dr)?\s*(.+)$'),
      RegExp(r'(?:sir|maam|mam|mr|ms|mrs|prof|professor|dr)\s+(.+)$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final candidate = match?.group(1)?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        return _normalizeFacultySearchText(candidate);
      }
    }

    return null;
  }

  int _tokenPrefixMatchScore(Set<String> left, Set<String> right) {
    var score = 0;
    for (final a in left) {
      for (final b in right) {
        if (a == b) continue;
        if (a.startsWith(b) || b.startsWith(a)) {
          score += 2;
        }
      }
    }
    return score;
  }

  bool _hasFacultyReference(String query) {
    if (_containsKeywordFuzzy(
      query,
      ['faculty', 'teacher', 'instructor', 'professor', 'prof', 'sir', 'maam'],
    )) {
      return true;
    }

    return RegExp(r'\b(schedule|class|classes|timetable)\s+of\s+[a-z]{3,}')
        .hasMatch(query);
  }

  bool _shouldPreferGroundedResponse(
    String query,
    DayOfWeek? requestedDay,
    List<DayOfWeek> requestedDays,
    List<DayOfWeek> relativeDays,
  ) {
    if (_hasFacultyReference(query)) return true;
    if (_extractSectionFromQuery(query) != null) return true;
    if (_containsKeywordFuzzy(query, ['subject', 'subjects'])) return true;
    if (_containsKeywordFuzzy(query, ['faculty', 'teacher', 'instructor'])) {
      return true;
    }
    if (_containsKeywordFuzzy(query, ['room', 'rooms', 'laboratory', 'lab'])) {
      return true;
    }
    if (_containsKeywordFuzzy(query, ['room']) &&
        (_hasScheduleIntent(query) ||
            requestedDay != null ||
            requestedDays.isNotEmpty ||
            relativeDays.isNotEmpty)) {
      return true;
    }
    if (_containsKeywordFuzzy(query, ['who', 'which', 'what']) &&
        (_hasScheduleIntent(query) ||
            requestedDay != null ||
            relativeDays.isNotEmpty)) {
      return true;
    }
    if (_hasScheduleIntent(query) &&
        !_containsKeywordFuzzy(query, ['my', 'mine']) &&
        !_containsKeywordFuzzy(query, ['generate', 'optimize', 'resolve'])) {
      return true;
    }
    return false;
  }

  List<DayOfWeek> _extractDaysOfWeek(String query) {
    final matches = <DayOfWeek>{};
    final tokens = [
      const {'mon', 'monday'},
      const {'tue', 'tues', 'tuesday'},
      const {'wed', 'wednesday'},
      const {'thu', 'thur', 'thurs', 'thursday'},
      const {'fri', 'friday'},
      const {'sat', 'saturday'},
      const {'sun', 'sunday'},
    ];

    for (var i = 0; i < tokens.length; i++) {
      for (var token in tokens[i]) {
        if (_containsKeywordFuzzy(query, [token])) {
          matches.add(DayOfWeek.values[i]);
        }
      }
    }

    return matches.toList()..sort((a, b) => a.index.compareTo(b.index));
  }

  DayOfWeek? _extractDayOfWeek(String query) {
    final days = _extractDaysOfWeek(query);
    if (days.length == 1) return days.first;
    return null;
  }

  String? _extractSectionFromQuery(String query) {
    final normalized = query.toUpperCase();

    final explicitSectionMatch = RegExp(
      r'\bSECTION\s+([A-Z]{1,4}\s*)?\d[A-Z]\b',
    ).firstMatch(normalized);
    if (explicitSectionMatch != null) {
      return explicitSectionMatch.group(0)?.replaceFirst('SECTION', '').trim();
    }

    final compactMatch = RegExp(
      r'\b([A-Z]{1,4}\s*)?\d[A-Z]\b',
    ).firstMatch(normalized);
    return compactMatch?.group(0)?.trim();
  }

  List<String> _buildSectionCandidates(String sectionInput) {
    final original = sectionInput.trim().toUpperCase();
    final compact = original.replaceAll(RegExp(r'[\s-]+'), '');
    final suffixMatch = RegExp(r'(\d[A-Z])$').firstMatch(compact);
    final suffix = suffixMatch?.group(1);

    final candidates = <String>{};
    if (original.isNotEmpty) candidates.add(original);
    if (compact.isNotEmpty) candidates.add(compact);
    if (suffix != null && suffix.isNotEmpty) candidates.add(suffix);

    return candidates.toList();
  }

  List<DayOfWeek> _extractRelativeDays(String query) {
    final days = <DayOfWeek>[];
    final now = _now();
    if (_containsKeywordFuzzy(query, ['today', 'tonight', 'now'])) {
      days.add(_dayFromDate(now));
    }
    if (_containsKeywordFuzzy(query, ['tomorrow'])) {
      days.add(_dayFromDate(now.add(const Duration(days: 1))));
    }
    if (_containsKeywordFuzzy(query, ['weekend'])) {
      days.add(DayOfWeek.sat);
      days.add(DayOfWeek.sun);
    }
    if (_containsKeywordFuzzy(query, ['week'])) {
      days.addAll([
        DayOfWeek.mon,
        DayOfWeek.tue,
        DayOfWeek.wed,
        DayOfWeek.thu,
        DayOfWeek.fri,
      ]);
    }
    return days;
  }

  DayOfWeek _dayFromDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return DayOfWeek.mon;
      case DateTime.tuesday:
        return DayOfWeek.tue;
      case DateTime.wednesday:
        return DayOfWeek.wed;
      case DateTime.thursday:
        return DayOfWeek.thu;
      case DateTime.friday:
        return DayOfWeek.fri;
      case DateTime.saturday:
        return DayOfWeek.sat;
      case DateTime.sunday:
        return DayOfWeek.sun;
    }
    return DayOfWeek.mon;
  }

  String _dayLabel(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Monday';
      case DayOfWeek.tue:
        return 'Tuesday';
      case DayOfWeek.wed:
        return 'Wednesday';
      case DayOfWeek.thu:
        return 'Thursday';
      case DayOfWeek.fri:
        return 'Friday';
      case DayOfWeek.sat:
        return 'Saturday';
      case DayOfWeek.sun:
        return 'Sunday';
    }
  }

  List<Schedule> _filterSchedulesByDay(
    List<Schedule> schedules,
    DayOfWeek? day,
  ) {
    if (day == null) return schedules;
    return schedules.where((s) => s.timeslot?.day == day).toList();
  }

  String _buildScheduleCountMessage(
    int count,
    String prefix,
    DayOfWeek? day, {
    String? suffix,
  }) {
    final dayPart = day != null ? ' on ${_dayLabel(day)}' : '';
    final suffixPart = suffix != null ? ' $suffix' : '';
    if (prefix.startsWith("I couldn't find")) {
      return '$prefix$dayPart$suffixPart.';
    }
    return '$prefix $count classes$dayPart$suffixPart.';
  }

  String _buildDayCountJson(Map<DayOfWeek, int> counts) {
    final entries = counts.entries
        .map((e) => '"${e.key.name}": ${e.value}')
        .join(', ');
    return '{$entries}';
  }

  String _normalizeQuery(String query) {
    var normalized = query.toLowerCase();
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    normalized = _replaceWholePhrases(
      normalized,
      _multilingualPhraseAliases,
    );
    normalized = _replaceWholePhrases(
      normalized,
      _multilingualWordAliases,
    );

    normalized = _replaceWholePhrases(normalized, const [
      (from: 'lunes', to: 'monday'),
      (from: 'lunis', to: 'monday'),
      (from: 'miyerkules', to: 'wednesday'),
      (from: 'merkules', to: 'wednesday'),
      (from: 'huwebes', to: 'thursday'),
      (from: 'jueves', to: 'thursday'),
      (from: 'biyernes', to: 'friday'),
      (from: 'viernes', to: 'friday'),
      (from: 'sabado', to: 'saturday'),
      (from: 'linggo', to: 'sunday'),
      (from: 'domingo', to: 'sunday'),
    ]);

    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _replaceWholePhrases(
    String input,
    List<({String from, String to})> aliases,
  ) {
    var output = input;
    for (final alias in aliases) {
      output = output.replaceAllMapped(
        RegExp(r'\b' + RegExp.escape(alias.from) + r'\b'),
        (_) => alias.to,
      );
    }
    return output;
  }

  bool _containsKeyword(String query, List<String> keywords) {
    for (final keyword in keywords) {
      final re = RegExp(r'\b' + RegExp.escape(keyword) + r'\b');
      if (re.hasMatch(query)) return true;
    }
    return false;
  }

  bool _containsKeywordFuzzy(String query, List<String> keywords) {
    final tokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    for (final token in tokens) {
      for (final keyword in keywords) {
        if (_levenshtein(token, keyword) <= 1) return true;
      }
    }
    return false;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final dp = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[a.length][b.length];
  }

  DayOfWeek? _singleDayOrNull(
    DayOfWeek? requestedDay,
    List<DayOfWeek> relativeDays,
  ) {
    if (requestedDay != null) return requestedDay;
    if (relativeDays.length == 1) return relativeDays.first;
    return null;
  }

  Future<List<Schedule>?> _resolveSchedulesByScope(
    Session session,
    String? userId,
    List<String> scopes,
  ) async {
    final isAdmin = scopes.contains('admin');
    final isFaculty = scopes.contains('faculty');
    final isStudent = scopes.contains('student');

    if (isAdmin) {
      return Schedule.db.find(
        session,
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    }

    if (isFaculty) {
      if (userId == null) return null;
      final faculty = await _findCurrentFaculty(session, userId);
      if (faculty == null) return null;
      return Schedule.db.find(
        session,
        where: (t) => t.facultyId.equals(faculty.id!),
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    }

    if (isStudent) {
      if (userId == null) return null;
      final student = await _findCurrentStudent(session, userId);
      if (student?.section == null) return null;
      return Schedule.db.find(
        session,
        where: (t) => t.section.equals(student!.section!),
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    }

    return null;
  }

  List<Schedule> _sortSchedulesByStart(List<Schedule> schedules) {
    final sorted = List<Schedule>.from(schedules);
    sorted.sort((a, b) {
      final sa = _parseTimeToMinutes(a.timeslot?.startTime ?? '00:00');
      final sb = _parseTimeToMinutes(b.timeslot?.startTime ?? '00:00');
      return sa.compareTo(sb);
    });
    return sorted;
  }

  bool _isNextClassQuery(String query) {
    return _containsKeywordFuzzy(query, ['next']) &&
        _containsKeywordFuzzy(query, ['class']);
  }

  bool _isFirstOrLastClassQuery(String query) {
    return _containsKeywordFuzzy(query, ['first', 'last']) &&
        _containsKeywordFuzzy(query, ['class']);
  }

  NLPResponse? _buildNextClassResponse(
    List<Schedule> schedules,
    DayOfWeek? day,
    DayOfWeek nowDay,
    int nowMinutes,
  ) {
    final effectiveDay = day ?? nowDay;
    final daySchedules = _filterSchedulesByDay(schedules, effectiveDay);
    final upcoming = daySchedules.where((s) {
      final ts = s.timeslot;
      if (ts == null) return false;
      final start = _parseTimeToMinutes(ts.startTime);
      return start > nowMinutes;
    }).toList();
    final sortedUpcoming = _sortSchedulesByStart(upcoming);

    if (sortedUpcoming.isEmpty) {
      return NLPResponse(
        text: "No upcoming classes found.",
        intent: NLPIntent.schedule,
      );
    }

    final next = sortedUpcoming.first;
    return NLPResponse(
      text: "Your next class is ${next.subject?.name ?? 'a class'}.",
      intent: NLPIntent.schedule,
      schedules: [next],
    );
  }

  NLPResponse? _buildFirstOrLastClassResponse(
    String query,
    List<Schedule> schedules,
  ) {
    final sorted = _sortSchedulesByStart(schedules);
    if (sorted.isEmpty) {
      return NLPResponse(
        text: "No classes found for that day.",
        intent: NLPIntent.schedule,
      );
    }

    final wantsLast = _containsKeywordFuzzy(query, ['last']);
    final picked = wantsLast ? sorted.last : sorted.first;
    return NLPResponse(
      text:
          "Your ${wantsLast ? 'last' : 'first'} class is ${picked.subject?.name ?? 'a class'}.",
      intent: NLPIntent.schedule,
      schedules: [picked],
    );
  }

  List<Schedule> _applyExactStartOrEndFilter(
    String query,
    List<Schedule> schedules,
  ) =>
      _applyExactStartOrEndFilterImpl(query, schedules);

  List<Schedule> _applyExactStartOrEndFilterImpl(
    String query,
    List<Schedule> schedules,
  ) {
    var filtered = schedules;
    final asksStartAt =
        _containsKeywordFuzzy(query, ['start', 'starts']) &&
        _containsKeywordFuzzy(query, ['at']);
    final asksEndAt =
        _containsKeywordFuzzy(query, ['end', 'ends']) &&
        _containsKeywordFuzzy(query, ['at']);

    if (asksStartAt) {
      final startAt = _parseTimeToken(query);
      if (startAt != null) {
        filtered = filtered.where((s) {
          final ts = s.timeslot;
          if (ts == null) return false;
          return _parseTimeToMinutes(ts.startTime) == startAt;
        }).toList();
      }
      return filtered;
    }

    if (asksEndAt) {
      final endAt = _parseTimeToken(query);
      if (endAt != null) {
        filtered = filtered.where((s) {
          final ts = s.timeslot;
          if (ts == null) return false;
          return _parseTimeToMinutes(ts.endTime) == endAt;
        }).toList();
      }
    }
    return filtered;
  }

  NLPResponse _buildTimeFilteredResponse(
    List<Schedule> filtered,
    DayOfWeek? day,
    _TimeRange? timeRange,
  ) {
    if (filtered.isEmpty) {
      if (day != null) {
        final atThatTime = timeRange != null ? ' at that time' : '';
        return NLPResponse(
          text: "I couldn't find any classes$atThatTime on ${_dayLabel(day)}.",
          intent: NLPIntent.schedule,
        );
      }
      return NLPResponse(
        text: "I couldn't find any classes for that time range.",
        intent: NLPIntent.schedule,
      );
    }

    final daySuffix = day != null ? ' on ${_dayLabel(day)}' : '';
    return NLPResponse(
      text: 'Found ${filtered.length} class(es)$daySuffix.',
      intent: NLPIntent.schedule,
      schedules: filtered,
    );
  }

  Future<NLPResponse?> _tryTimeBasedScheduleQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
    List<DayOfWeek> relativeDays,
  ) async {
    var timeRange = _extractTimeRange(query);
    final hasNow = _containsKeywordFuzzy(query, [
      'now',
      'ongoing',
      'happening',
    ]);
    final hasTime = timeRange != null || hasNow;
    var day = _singleDayOrNull(requestedDay, relativeDays);

    if (!hasTime && day == null) return null;

    final schedules = await _resolveSchedulesByScope(session, userId, scopes);
    if (schedules == null) return null;

    final now = _now();
    final nowDay = _dayFromDate(now);
    final nowMinutes = now.hour * 60 + now.minute;

    if (hasNow) {
      day ??= nowDay;
      timeRange = _TimeRange(nowMinutes, nowMinutes + 1);
    }

    var dayScopedSchedules = _filterSchedulesByDay(schedules, day);

    // Next class
    if (_isNextClassQuery(query)) {
      return _buildNextClassResponse(
        dayScopedSchedules,
        day,
        nowDay,
        nowMinutes,
      );
    }

    // First/last class (for day)
    if (_isFirstOrLastClassQuery(query)) {
      return _buildFirstOrLastClassResponse(query, dayScopedSchedules);
    }

    dayScopedSchedules = _applyExactStartOrEndFilter(query, dayScopedSchedules);

    final filtered = _filterSchedulesByTimeRange(dayScopedSchedules, timeRange);
    return _buildTimeFilteredResponse(filtered, day, timeRange);
  }

  Future<NLPResponse?> _tryFilteredScheduleQuery(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
    List<DayOfWeek> relativeDays,
    _TimeRange? timeRange,
  ) async =>
      _tryFilteredScheduleQueryImpl(
        session,
        query,
        userId,
        scopes,
        requestedDay,
        relativeDays,
        timeRange,
      );

  Future<NLPResponse?> _tryFilteredScheduleQueryImpl(
    Session session,
    String query,
    String? userId,
    List<String> scopes,
    DayOfWeek? requestedDay,
    List<DayOfWeek> relativeDays,
    _TimeRange? timeRange,
  ) async {
    final isAdmin = scopes.contains('admin');
    final isFaculty = scopes.contains('faculty');
    final isStudent = scopes.contains('student');

    final day =
        requestedDay ?? (relativeDays.length == 1 ? relativeDays.first : null);
    final roomType = _extractRoomType(query);
    final rooms = await Room.db.find(session);
    final room = _matchRoomByName(query, rooms);

    final facultyList = await Faculty.db.find(session);
    final matchedFaculty = _matchFacultyByName(query, facultyList);

    final section = _extractSectionFromQuery(query);

    final hasAnyFilter =
        day != null ||
        timeRange != null ||
        roomType != null ||
        room != null ||
        matchedFaculty != null ||
        section != null;
    if (!hasAnyFilter) return null;

    List<Schedule> schedules;
    if (isAdmin) {
      schedules = await Schedule.db.find(
        session,
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    } else if (isFaculty) {
      if (userId == null) return null;
      final faculty = await _findCurrentFaculty(session, userId);
      if (faculty == null) return null;
      if (matchedFaculty != null && matchedFaculty.id != faculty.id) {
        return NLPResponse(
          text:
              "You can only view your own schedule. Contact administrators to see other faculty schedules.",
          intent: NLPIntent.schedule,
        );
      }
      schedules = await Schedule.db.find(
        session,
        where: (t) => t.facultyId.equals(faculty.id!),
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    } else if (isStudent) {
      if (userId == null) return null;
      final student = await _findCurrentStudent(session, userId);
      if (student?.section == null) return null;
      if (section != null) {
        final requestedCandidates = _buildSectionCandidates(section);
        final currentCandidates = _buildSectionCandidates(student!.section!);
        final intersects = requestedCandidates
            .toSet()
            .intersection(currentCandidates.toSet())
            .isNotEmpty;
        if (!intersects) {
          return NLPResponse(
            text: "You can only view your own section schedule.",
            intent: NLPIntent.schedule,
          );
        }
      }
      schedules = await Schedule.db.find(
        session,
        where: (t) => t.section.equals(student!.section!),
        include: Schedule.include(
          subject: Subject.include(),
          faculty: Faculty.include(),
          room: Room.include(),
          timeslot: Timeslot.include(),
        ),
      );
    } else {
      return null;
    }

    if (matchedFaculty != null) {
      schedules = schedules
          .where((s) => s.facultyId == matchedFaculty.id)
          .toList();
      if (schedules.isEmpty) {
        return NLPResponse(
          text: _buildScheduleCountMessage(
            0,
            "I couldn't find any classes for ${matchedFaculty.name}",
            day,
          ),
          intent: NLPIntent.schedule,
        );
      }
    }
    if (section != null) {
      final requestedCandidates = _buildSectionCandidates(section);
      schedules = schedules
          .where((s) => requestedCandidates.contains(s.section.toUpperCase()))
          .toList();
    }
    if (room != null) {
      schedules = schedules.where((s) => s.roomId == room.id).toList();
    }
    if (roomType != null) {
      schedules = schedules.where((s) => s.room?.type == roomType).toList();
    }
    schedules = _filterSchedulesByDay(schedules, day);
    schedules = _filterSchedulesByTimeRange(schedules, timeRange);

    if (schedules.isEmpty) {
      return NLPResponse(
        text: "I couldn't find any matching classes.",
        intent: NLPIntent.schedule,
      );
    }

    if (_containsKeywordFuzzy(query, ['which', 'room']) &&
        section != null &&
        day != null) {
      final roomNames = schedules
          .map((s) => s.room?.name)
          .whereType<String>()
          .toSet()
          .toList();
      return NLPResponse(
        text: "Rooms used: ${roomNames.join(', ')}.",
        intent: NLPIntent.schedule,
        schedules: schedules,
      );
    }

    if (_containsKeywordFuzzy(query, ['who']) &&
        _containsKeywordFuzzy(query, ['teach', 'teaching', 'instructor'])) {
      final names = schedules
          .map((s) => s.faculty?.name)
          .whereType<String>()
          .toSet()
          .toList();
      return NLPResponse(
        text: "Teaching: ${names.join(', ')}.",
        intent: NLPIntent.schedule,
        schedules: schedules,
      );
    }

    return NLPResponse(
      text: "Found ${schedules.length} class(es).",
      intent: NLPIntent.schedule,
      schedules: schedules,
    );
  }

  Future<NLPResponse?> _tryRoomTimeQuery(
    Session session,
    String query,
    List<DayOfWeek> relativeDays,
    List<String> scopes,
  ) async {
    var timeRange = _extractTimeRange(query);
    final hasNow = _containsKeywordFuzzy(query, ['now']);
    if (timeRange == null && !hasNow) return null;

    if (!scopes.contains('admin')) {
      return NLPResponse(
        text: "Please specify a room name to check availability.",
        intent: NLPIntent.roomStatus,
      );
    }

    final schedules = await Schedule.db.find(
      session,
      include: Schedule.include(
        room: Room.include(),
        timeslot: Timeslot.include(),
      ),
    );
    var day = relativeDays.length == 1 ? relativeDays.first : null;
    if (hasNow) {
      final now = _now();
      day ??= _dayFromDate(now);
      final nowMinutes = now.hour * 60 + now.minute;
      timeRange ??= _TimeRange(nowMinutes, nowMinutes + 1);
    }
    final filtered = schedules.where((s) {
      final ts = s.timeslot;
      if (ts == null || s.room == null) return false;
      if (day != null && ts.day != day) return false;
      return _timeRangeOverlaps(
        _parseTimeToMinutes(ts.startTime),
        _parseTimeToMinutes(ts.endTime),
        timeRange,
      );
    }).toList();

    final rooms = await Room.db.find(session);
    final occupiedRoomIds = filtered.map((s) => s.roomId).toSet();
    final availableRooms = rooms
        .where((r) => !occupiedRoomIds.contains(r.id))
        .toList();

    return NLPResponse(
      text:
          "Available rooms: ${availableRooms.take(8).map((r) => r.name).join(', ')}${availableRooms.length > 8 ? '...' : ''}",
      intent: NLPIntent.roomStatus,
      dataJson: jsonEncode({
        'availableCount': availableRooms.length,
      }),
    );
  }

  List<Schedule> _filterSchedulesByTimeRange(
    List<Schedule> schedules,
    _TimeRange? range,
  ) {
    if (range == null) return schedules;
    return schedules.where((s) {
      final ts = s.timeslot;
      if (ts == null) return false;
      final start = _parseTimeToMinutes(ts.startTime);
      final end = _parseTimeToMinutes(ts.endTime);
      return _timeRangeOverlaps(start, end, range);
    }).toList();
  }

  bool _timeRangeOverlaps(int start, int end, _TimeRange? range) {
    if (range == null) return true;
    return !(end <= range.start || start >= range.end);
  }

  _TimeRange? _extractTimeRange(String query) {
    final bounds = _extractTimeRangeBounds(
      query,
      keywordMatcher: _containsKeywordFuzzy,
    );
    if (bounds == null) return null;
    return _TimeRange(bounds.start, bounds.end);
  }

  int? _parseTimeToken(String? token) {
    return _parseTimeTokenValue(token);
  }

  int _parseTimeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }
}

class _TimeRange {
  final int start;
  final int end;
  const _TimeRange(this.start, this.end);
}
