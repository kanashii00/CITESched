import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../services/ai_chat_service.dart';
import '../services/ai_guard_service.dart';
import '../services/nlp_service.dart';

class NLPEndpoint extends Endpoint {
  final NLPService _nlpService = NLPService();
  final AiChatService _chatService = AiChatService();
  final AiGuardService _guardService = AiGuardService();

  @override
  bool get requireLogin => true;

  Future<NLPResponse> query(
    Session session,
    String text, {
    String? sessionId,
    String? sessionTitle,
  }) async {
    try {
      final authInfo = _requireAuth(session);
      final userId = authInfo.userIdentifier.toString();
      final resolvedRole = _guardService.resolveRole(authInfo.scopes);
      final sanitizedText = _guardService.sanitizeUserPrompt(text);

      if (sanitizedText.isEmpty || sanitizedText.length > AiGuardService.maxPromptLength) {
        return NLPResponse(
          text:
              'Invalid query. Please enter a query between 1-${AiGuardService.maxPromptLength} characters.',
          intent: NLPIntent.unknown,
        );
      }

      if (_guardService.containsPromptInjection(sanitizedText)) {
        return NLPResponse(
          text:
              'That request cannot be processed because it attempts to override system safety rules.',
          intent: NLPIntent.unknown,
        );
      }

      if (!_guardService.allowRequest('$userId:$resolvedRole')) {
        return NLPResponse(
          text: 'Too many AI requests right now. Please wait a moment and try again.',
          intent: NLPIntent.unknown,
        );
      }

      final activeSession = await _resolveSession(
        session,
        userId: userId,
        role: resolvedRole,
        sessionId: sessionId,
        sessionTitle: sessionTitle,
      );

      await _saveMessage(
        session,
        authInfo: authInfo,
        chatSession: activeSession,
        sender: 'user',
        message: sanitizedText,
      );

      final response = await _nlpService.processQuery(
        session,
        sanitizedText,
        userId,
        authInfo.scopes.map((item) => item.name).whereType<String>().toList(),
        activeSession.id?.toString(),
      );

      await _saveMessage(
        session,
        authInfo: authInfo,
        chatSession: activeSession,
        sender: 'assistant',
        message: response.text,
        intent: response.intent.name,
        metadataJson: response.dataJson,
      );

      return response;
    } catch (e) {
      session.log('NLP Query Error: $e');
      return NLPResponse(
        text: 'An error occurred processing your request. Please try again.',
        intent: NLPIntent.unknown,
      );
    }
  }

  Future<List<Schedule>> getFacultyLoad(
    Session session, {
    required int facultyId,
  }) async {
    _requireRole(session, const {'admin', 'faculty'});
    return _findSchedules(
      session,
      where: (t) => t.facultyId.equals(facultyId),
    );
  }

  Future<List<Schedule>> getStudentSchedule(
    Session session, {
    required int studentId,
  }) async {
    final authInfo = _requireAuth(session);
    final role = _guardService.resolveRole(authInfo.scopes);
    final student = await Student.db.findById(
      session,
      studentId,
      include: Student.include(sectionRef: Section.include()),
    );
    if (student == null) return const [];

    if (role == 'student') {
      final userInfoId = int.tryParse(authInfo.userIdentifier.toString());
      if (student.userInfoId != userInfoId) {
        throw Exception('Students can only view their own schedule.');
      }
    }

    if (student.sectionId != null) {
      return _findSchedules(
        session,
        where: (t) => t.sectionId.equals(student.sectionId!),
      );
    }

    if (student.section == null) return const [];
    return _findSchedules(
      session,
      where: (t) => t.section.equals(student.section!),
    );
  }

  Future<List<Schedule>> getSectionSchedule(
    Session session, {
    required int sectionId,
  }) async {
    _requireRole(session, const {'admin', 'faculty', 'student'});
    return _findSchedules(
      session,
      where: (t) => t.sectionId.equals(sectionId),
    );
  }

  Future<List<Schedule>> getRoomAvailability(
    Session session, {
    required int roomId,
    required DayOfWeek day,
  }) async {
    _requireRole(session, const {'admin', 'faculty', 'student'});
    final schedules = await _findSchedules(
      session,
      where: (t) => t.roomId.equals(roomId),
    );
    return schedules.where((item) => item.timeslot?.day == day).toList();
  }

  Future<List<Subject>> getSubjectCatalog(
    Session session, {
    required Program program,
    int? yearLevel,
  }) async {
    _requireRole(session, const {'admin', 'faculty', 'student'});
    return Subject.db.find(
      session,
      where: yearLevel == null
          ? (t) => t.program.equals(program) & t.isActive.equals(true)
          : (t) =>
                t.program.equals(program) &
                t.yearLevel.equals(yearLevel) &
                t.isActive.equals(true),
      orderBy: (t) => t.code,
      orderDescending: false,
    );
  }

  Future<List<ScheduleConflict>> getScheduleConflicts(Session session) async {
    _requireRole(session, const {'admin', 'faculty'});
    final schedules = await _findSchedules(session);
    final conflicts = <ScheduleConflict>[];

    for (var i = 0; i < schedules.length; i++) {
      for (var j = i + 1; j < schedules.length; j++) {
        final left = schedules[i];
        final right = schedules[j];
        final leftSlot = left.timeslot;
        final rightSlot = right.timeslot;
        if (leftSlot == null || rightSlot == null) continue;
        if (leftSlot.day != rightSlot.day) continue;

        final overlaps = _timeToMinutes(leftSlot.startTime) <
                _timeToMinutes(rightSlot.endTime) &&
            _timeToMinutes(rightSlot.startTime) <
                _timeToMinutes(leftSlot.endTime);
        if (!overlaps) continue;

        final isFacultyConflict = left.facultyId == right.facultyId;
        final isRoomConflict = left.roomId != null && left.roomId == right.roomId;
        final isSectionConflict =
            left.sectionId != null && left.sectionId == right.sectionId;
        if (!isFacultyConflict && !isRoomConflict && !isSectionConflict) continue;

        conflicts.add(
          ScheduleConflict(
            type: isRoomConflict
                ? 'room_conflict'
                : isFacultyConflict
                ? 'faculty_conflict'
                : 'section_conflict',
            message:
                'Conflict between ${left.subject?.code ?? left.id} and ${right.subject?.code ?? right.id}.',
            scheduleId: left.id!,
            conflictingScheduleId: right.id!,
            facultyId: isFacultyConflict ? left.facultyId : null,
            roomId: isRoomConflict ? left.roomId : null,
            subjectId: left.subjectId,
            details: isSectionConflict
                ? 'Section ${left.section} overlaps on ${leftSlot.day.name}.'
                : null,
          ),
        );
      }
    }

    return conflicts;
  }

  Future<List<String>> generateScheduleSuggestions(Session session) async {
    _requireRole(session, const {'admin', 'faculty', 'student'});
    final authInfo = _requireAuth(session);
    final role = _guardService.resolveRole(authInfo.scopes);

    switch (role) {
      case 'admin':
        final conflicts = await getScheduleConflicts(session);
        final suggestions = <String>[
          'Generate timetable',
          'Check room conflicts',
          'Find available faculty',
          'Show available rooms',
        ];
        if (conflicts.isNotEmpty) {
          suggestions.insert(0, 'Review ${conflicts.length} schedule conflicts');
        }
        return suggestions;
      case 'faculty':
        return const [
          'Show my schedule today',
          'Show my weekly timetable',
          'Check teaching load',
          'Detect my schedule conflicts',
          'Show my assigned sections',
          'Find my available hours',
        ];
      case 'student':
        return const [
          'Show my schedule today',
          'View my subjects',
          'Check timetable conflicts',
          'Show my section timetable',
          'Find next class',
        ];
      default:
        return const ['Show my schedule today'];
    }
  }

  Future<List<Schedule>> searchSchedules(
    Session session, {
    required String query,
  }) async {
    _requireRole(session, const {'admin', 'faculty', 'student'});
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];

    final schedules = await _findSchedules(session);
    return schedules.where((schedule) {
      final haystack = [
        schedule.subject?.code,
        schedule.subject?.name,
        schedule.faculty?.name,
        schedule.room?.name,
        schedule.section,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(normalized);
    }).toList();
  }

  Future<AiChatSession> createChatSession(
    Session session, {
    String? userId,
    String? role,
    String? title,
  }) async {
    final authInfo = _requireAuth(session);
    final resolvedRole = _guardService.resolveRole(
      authInfo.scopes,
      requestedRole: role,
    );
    final resolvedUserId = authInfo.userIdentifier.toString();
    final resolvedTitle =
        title?.trim().isNotEmpty == true ? title!.trim() : _defaultSessionTitle(resolvedRole);

    if (userId != null &&
        userId.trim().isNotEmpty &&
        userId.trim() != resolvedUserId) {
      throw Exception('You can only create chat sessions for your own account.');
    }

    return _chatService.createSession(
      session,
      userId: resolvedUserId,
      roleType: resolvedRole,
      title: resolvedTitle,
    );
  }

  Future<List<ChatSessionSummary>> getChatHistory(
    Session session, {
    String? userId,
    String? role,
    int limit = 30,
  }) async {
    final authInfo = _requireAuth(session);
    final resolvedRole = _guardService.resolveRole(
      authInfo.scopes,
      requestedRole: role,
    );
    final resolvedUserId = authInfo.userIdentifier.toString();
    if (userId != null &&
        userId.trim().isNotEmpty &&
        userId.trim() != resolvedUserId) {
      throw Exception('You can only read your own chat history.');
    }

    final sessions = await _chatService.getSessions(
      session,
      userId: resolvedUserId,
      roleType: resolvedRole,
      limit: limit,
    );

    final summaries = <ChatSessionSummary>[];
    for (final sessionRecord in sessions) {
      final messages = await _chatService.getMessages(
        session,
        sessionId: sessionRecord.id!,
        limit: 1,
      );
      summaries.add(
        ChatSessionSummary(
          sessionId: sessionRecord.id!.toString(),
          title: sessionRecord.title,
          lastMessageAt: messages.isEmpty
              ? sessionRecord.updatedAt
              : messages.last.timestamp,
          lastMessageText: messages.isEmpty ? '' : messages.last.message,
        ),
      );
    }

    return summaries;
  }

  Future<List<AiChatMessage>> getChatMessages(
    Session session, {
    required String sessionId,
    String? role,
    int limit = 200,
  }) async {
    final authInfo = _requireAuth(session);
    final resolvedRole = _guardService.resolveRole(
      authInfo.scopes,
      requestedRole: role,
    );
    final owned = await _getOwnedSession(
      session,
      authInfo: authInfo,
      role: resolvedRole,
      sessionId: sessionId,
    );
    if (owned == null) return const [];

    return _chatService.getMessages(
      session,
      sessionId: owned.id!,
      limit: limit,
    );
  }

  Future<AiChatMessage> saveChatMessage(
    Session session, {
    required String sessionId,
    required String sender,
    required String message,
    String? role,
  }) async {
    final authInfo = _requireAuth(session);
    final resolvedRole = _guardService.resolveRole(
      authInfo.scopes,
      requestedRole: role,
    );
    final owned = await _getOwnedSession(
      session,
      authInfo: authInfo,
      role: resolvedRole,
      sessionId: sessionId,
    );
    if (owned == null) {
      throw Exception('Chat session not found.');
    }

    final sanitized = _guardService.sanitizeUserPrompt(message);
    final saved = await _chatService.saveMessage(
      session,
      sessionId: owned.id!,
      sender: sender,
      message: sanitized,
    );
    await _logLegacyMessage(
      session,
      userId: authInfo.userIdentifier.toString(),
      role: resolvedRole,
      legacySessionId: owned.id!.toString(),
      sessionTitle: owned.title,
      sender: sender,
      text: sanitized,
    );
    return saved;
  }

  Future<bool> deleteChatSession(
    Session session, {
    required String sessionId,
    String? role,
  }) async {
    final authInfo = _requireAuth(session);
    final resolvedRole = _guardService.resolveRole(
      authInfo.scopes,
      requestedRole: role,
    );
    final parsedId = int.tryParse(sessionId);
    if (parsedId == null) return false;

    final deleted = await _chatService.deleteSession(
      session,
      sessionId: parsedId,
      userId: authInfo.userIdentifier.toString(),
      roleType: resolvedRole,
    );
    if (!deleted) return false;

    await ChatHistory.db.deleteWhere(
      session,
      where: (t) =>
          t.userId.equals(authInfo.userIdentifier.toString()) &
          t.role.equals(resolvedRole) &
          t.sessionId.equals(sessionId),
    );
    return true;
  }

  AuthenticationInfo _requireAuth(Session session) {
    final authInfo = session.authenticated;
    if (authInfo == null) {
      throw Exception('Authentication required.');
    }
    return authInfo;
  }

  String _requireRole(Session session, Set<String> allowedRoles) {
    final authInfo = _requireAuth(session);
    final resolved = _guardService.resolveRole(authInfo.scopes);
    if (!allowedRoles.contains(resolved)) {
      throw Exception('You are not allowed to access this resource.');
    }
    return resolved;
  }

  Future<AiChatSession> _resolveSession(
    Session session, {
    required String userId,
    required String role,
    String? sessionId,
    String? sessionTitle,
  }) async {
    final parsedId = int.tryParse(sessionId?.trim() ?? '');
    if (parsedId != null) {
      final existing = await _chatService.getOwnedSession(
        session,
        sessionId: parsedId,
        userId: userId,
        roleType: role,
      );
      if (existing != null) {
        if (sessionTitle != null && sessionTitle.trim().isNotEmpty) {
          await _chatService.touchSession(
            session,
            existing,
            title: sessionTitle.trim(),
          );
          return existing.copyWith(title: sessionTitle.trim());
        }
        return existing;
      }
    }

    return _chatService.createSession(
      session,
      userId: userId,
      roleType: role,
      title: sessionTitle?.trim().isNotEmpty == true
          ? sessionTitle!.trim()
          : _defaultSessionTitle(role),
    );
  }

  Future<AiChatSession?> _getOwnedSession(
    Session session, {
    required AuthenticationInfo authInfo,
    required String role,
    required String sessionId,
  }) async {
    final parsedId = int.tryParse(sessionId.trim());
    if (parsedId == null) return null;
    return _chatService.getOwnedSession(
      session,
      sessionId: parsedId,
      userId: authInfo.userIdentifier.toString(),
      roleType: role,
    );
  }

  Future<void> _saveMessage(
    Session session, {
    required AuthenticationInfo authInfo,
    required AiChatSession chatSession,
    required String sender,
    required String message,
    String? intent,
    String? metadataJson,
  }) async {
    await _chatService.saveMessage(
      session,
      sessionId: chatSession.id!,
      sender: sender,
      message: message,
    );
    await _logLegacyMessage(
      session,
      userId: authInfo.userIdentifier.toString(),
      role: chatSession.roleType,
      legacySessionId: chatSession.id!.toString(),
      sessionTitle: chatSession.title,
      sender: sender,
      text: message,
      intent: intent,
      metadataJson: metadataJson,
    );
  }

  Future<void> _logLegacyMessage(
    Session session, {
    required String userId,
    required String role,
    required String legacySessionId,
    required String sessionTitle,
    required String sender,
    required String text,
    String? intent,
    String? metadataJson,
  }) async {
    await ChatHistory.db.insertRow(
      session,
      ChatHistory(
        userId: userId,
        role: role,
        sessionId: legacySessionId,
        sessionTitle: sessionTitle,
        sender: sender,
        text: text,
        intent: intent,
        metadataJson: metadataJson,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<List<Schedule>> _findSchedules(
    Session session, {
    WhereExpressionBuilder<ScheduleTable>? where,
  }) {
    return Schedule.db.find(
      session,
      where: where,
      include: Schedule.include(
        subject: Subject.include(),
        faculty: Faculty.include(),
        room: Room.include(),
        timeslot: Timeslot.include(),
        sectionRef: Section.include(),
      ),
    );
  }

  String _defaultSessionTitle(String role) {
    final now = DateTime.now();
    final dateLabel =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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

  int _timeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }
}
