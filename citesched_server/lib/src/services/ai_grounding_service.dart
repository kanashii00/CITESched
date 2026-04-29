import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_server/serverpod_auth_server.dart';

import '../generated/protocol.dart';

class GroundedContextPayload {
  const GroundedContextPayload({
    required this.jsonText,
    required this.hasData,
    required this.intent,
  });

  final String jsonText;
  final bool hasData;
  final NLPIntent intent;
}

class AiGroundingService {
  static const String fallbackNoDataMessage =
      "I don't have enough schedule data to answer that accurately.";

  Future<GroundedContextPayload> buildContext(
    Session session, {
    required String query,
    required String roleType,
    required String userIdentifier,
  }) async {
    final normalized = query.toLowerCase();
    final scheduleInclude = Schedule.include(
      subject: Subject.include(),
      faculty: Faculty.include(),
      room: Room.include(),
      timeslot: Timeslot.include(),
      sectionRef: Section.include(),
    );

    final currentStudent = await _findCurrentStudent(session, userIdentifier);
    final currentFaculty = await _findCurrentFaculty(session, userIdentifier);
    final activeRooms = await Room.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    final activeFaculty = await Faculty.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    final activeSections = await Section.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    final activeSubjects = await Subject.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );

    final data = <String, dynamic>{
      'role': roleType,
      'query': query,
      'databaseSnapshot': {
        'roomCount': activeRooms.length,
        'facultyCount': activeFaculty.length,
        'sectionCount': activeSections.length,
        'subjectCount': activeSubjects.length,
      },
      'rooms': activeRooms.map(_roomJson).toList(),
      'facultyDirectory': activeFaculty.map(_facultyJson).toList(),
      'sections': activeSections.map(_sectionJson).toList(),
      'subjects': activeSubjects.map(_subjectJson).toList(),
    };

    if (currentStudent != null) {
      data['currentStudent'] = _studentJson(currentStudent);
    }

    if (currentFaculty != null) {
      data['currentFaculty'] = _facultyJson(currentFaculty);
    }

    NLPIntent inferredIntent = NLPIntent.schedule;
    var hasData = false;

    if (_looksLikeRoomQuery(normalized)) {
      inferredIntent = NLPIntent.roomStatus;
      final day = _extractDayOfWeek(normalized);
      final room = await _findReferencedRoom(session, normalized);
      if (room != null) {
        final roomSchedules = await Schedule.db.find(
          session,
          where: (t) => t.roomId.equals(room.id!),
          include: scheduleInclude,
        );
        final filtered = day == null
            ? roomSchedules
            : roomSchedules.where((item) => item.timeslot?.day == day).toList();
        data['room'] = _roomJson(room);
        data['roomSchedules'] = filtered.map(_scheduleJson).toList();
        hasData = filtered.isNotEmpty || room.id != null;
      }
    } else if (_looksLikeConflictQuery(normalized)) {
      inferredIntent = NLPIntent.conflict;
      final schedules = await _loadSchedulesForRole(
        session,
        roleType: roleType,
        userIdentifier: userIdentifier,
        include: scheduleInclude,
      );
      if (schedules.isNotEmpty) {
        final conflicts = _collectConflicts(schedules);
        data['scheduleConflicts'] = conflicts
            .map(
              (pair) => {
                'first': _scheduleJson(pair.$1),
                'second': _scheduleJson(pair.$2),
              },
            )
            .toList();
        hasData = true;
      }
    } else if (_looksLikeFacultyLoadQuery(normalized)) {
      inferredIntent = NLPIntent.facultyLoad;
      final faculty = await _findReferencedFaculty(
            session,
            normalized,
          ) ??
          currentFaculty;
      if (faculty != null) {
        final schedules = await Schedule.db.find(
          session,
          where: (t) => t.facultyId.equals(faculty.id!),
          include: scheduleInclude,
        );
        data['faculty'] = _facultyJson(faculty);
        data['facultySchedules'] = schedules.map(_scheduleJson).toList();
        data['loadSummary'] = {
          'classCount': schedules.length,
          'totalUnits': schedules.fold<double>(
            0,
            (sum, item) => sum + (item.units ?? item.subject?.units.toDouble() ?? 0),
          ),
        };
        hasData = schedules.isNotEmpty;
      }
    } else {
      inferredIntent = NLPIntent.schedule;
      final schedules = await _loadSchedulesForRole(
        session,
        roleType: roleType,
        userIdentifier: userIdentifier,
        include: scheduleInclude,
      );
      if (schedules.isNotEmpty) {
        data['schedules'] = schedules.map(_scheduleJson).toList();
        hasData = true;
      }

      final day = _extractDayOfWeek(normalized);

      final referencedFaculty = _matchReferencedFaculty(normalized, activeFaculty);
      if (referencedFaculty != null) {
        final facultySchedules = await Schedule.db.find(
          session,
          where: (t) => t.facultyId.equals(referencedFaculty.id!),
          include: scheduleInclude,
        );
        final filteredFacultySchedules = day == null
            ? facultySchedules
            : facultySchedules
                  .where((item) => item.timeslot?.day == day)
                  .toList();
        data['faculty'] = _facultyJson(referencedFaculty);
        data['facultySchedules'] = filteredFacultySchedules
            .map(_scheduleJson)
            .toList();
        hasData = hasData || filteredFacultySchedules.isNotEmpty;
      }

      final section = _matchReferencedSection(normalized, activeSections);
      if (section != null) {
        final sectionSchedules = await Schedule.db.find(
          session,
          where: (t) => t.sectionId.equals(section.id!),
          include: scheduleInclude,
        );
        final filteredSectionSchedules = day == null
            ? sectionSchedules
            : sectionSchedules
                  .where((item) => item.timeslot?.day == day)
                  .toList();
        data['section'] = _sectionJson(section);
        data['sectionSchedules'] = filteredSectionSchedules
            .map(_scheduleJson)
            .toList();
        hasData = hasData || filteredSectionSchedules.isNotEmpty;
      }

      final referencedRoom = _matchReferencedRoom(normalized, activeRooms);
      if (referencedRoom != null) {
        final roomSchedules = await Schedule.db.find(
          session,
          where: (t) => t.roomId.equals(referencedRoom.id!),
          include: scheduleInclude,
        );
        final filteredRoomSchedules = day == null
            ? roomSchedules
            : roomSchedules
                  .where((item) => item.timeslot?.day == day)
                  .toList();
        data['room'] = _roomJson(referencedRoom);
        data['roomSchedules'] = filteredRoomSchedules.map(_scheduleJson).toList();
        hasData = hasData || filteredRoomSchedules.isNotEmpty;
      }

      final referencedSubject = _matchReferencedSubject(normalized, activeSubjects);
      if (referencedSubject != null) {
        final subjectSchedules = await Schedule.db.find(
          session,
          where: (t) => t.subjectId.equals(referencedSubject.id!),
          include: scheduleInclude,
        );
        final filteredSubjectSchedules = day == null
            ? subjectSchedules
            : subjectSchedules
                  .where((item) => item.timeslot?.day == day)
                  .toList();
        data['subject'] = _subjectJson(referencedSubject);
        data['subjectSchedules'] = filteredSubjectSchedules
            .map(_scheduleJson)
            .toList();
        hasData = hasData || filteredSubjectSchedules.isNotEmpty;
      }
    }

    if (_looksLikeSubjectCatalogQuery(normalized)) {
      final resolvedProgram = _extractProgram(normalized);
      final resolvedYear = _extractYearLevel(normalized);
      if (resolvedProgram != null) {
        final subjects = await Subject.db.find(
          session,
          where: (t) => t.program.equals(resolvedProgram),
        );
        final filtered = resolvedYear == null
            ? subjects
            : subjects.where((subject) => subject.yearLevel == resolvedYear).toList();
        data['subjectCatalog'] = filtered
            .map(
              (subject) => {
                'id': subject.id,
                'code': subject.code,
                'name': subject.name,
                'units': subject.units,
                'yearLevel': subject.yearLevel,
                'term': subject.term,
              },
            )
            .toList();
        hasData = hasData || filtered.isNotEmpty;
      }
    }

    return GroundedContextPayload(
      jsonText: const JsonEncoder.withIndent('  ').convert(data),
      hasData: hasData,
      intent: inferredIntent,
    );
  }

  Future<List<Schedule>> _loadSchedulesForRole(
    Session session, {
    required String roleType,
    required String userIdentifier,
    required ScheduleInclude include,
  }) async {
    switch (roleType) {
      case 'admin':
        return Schedule.db.find(session, include: include);
      case 'faculty':
        final faculty = await _findCurrentFaculty(session, userIdentifier);
        if (faculty?.id == null) return const [];
        return Schedule.db.find(
          session,
          where: (t) => t.facultyId.equals(faculty!.id),
          include: include,
        );
      case 'student':
        final student = await _findCurrentStudent(session, userIdentifier);
        if (student?.sectionId != null) {
          return Schedule.db.find(
            session,
            where: (t) => t.sectionId.equals(student!.sectionId),
            include: include,
          );
        }
        if (student?.section != null) {
          return Schedule.db.find(
            session,
            where: (t) => t.section.equals(student!.section!),
            include: include,
          );
        }
        return const [];
      default:
        return const [];
    }
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
        include: Student.include(sectionRef: Section.include()),
      );
      if (byUserInfoId != null) return byUserInfoId;
    }

    final linkedUserInfo = await UserInfo.db.findFirstRow(
      session,
      where: (t) => t.userIdentifier.equals(userIdentifier),
    );
    if (linkedUserInfo?.id != null) {
      final byLinked = await Student.db.findFirstRow(
        session,
        where: (t) =>
            t.userInfoId.equals(linkedUserInfo!.id) & t.isActive.equals(true),
        include: Student.include(sectionRef: Section.include()),
      );
      if (byLinked != null) return byLinked;
    }

    return Student.db.findFirstRow(
      session,
      where: (t) => t.email.equals(userIdentifier) & t.isActive.equals(true),
      include: Student.include(sectionRef: Section.include()),
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
      final byLinked = await Faculty.db.findFirstRow(
        session,
        where: (t) =>
            t.userInfoId.equals(linkedUserInfo!.id) & t.isActive.equals(true),
      );
      if (byLinked != null) return byLinked;
    }

    return Faculty.db.findFirstRow(
      session,
      where: (t) => t.email.equals(userIdentifier) & t.isActive.equals(true),
    );
  }

  Future<Room?> _findReferencedRoom(Session session, String query) async {
    final rooms = await Room.db.find(session, where: (t) => t.isActive.equals(true));
    return _matchReferencedRoom(query, rooms);
  }

  Room? _matchReferencedRoom(String query, List<Room> rooms) {
    final normalized = _normalizeSearchText(query);
    for (final room in rooms) {
      final roomName = _normalizeSearchText(room.name);
      if (normalized.contains(roomName)) return room;

      final queryTokens = normalized
          .split(RegExp(r'\s+'))
          .where((token) => token.length >= 2)
          .toSet();
      final roomTokens = roomName
          .split(RegExp(r'\s+'))
          .where((token) => token.length >= 2)
          .toSet();
      if (queryTokens.intersection(roomTokens).isNotEmpty) {
        return room;
      }
    }
    return null;
  }

  Future<Faculty?> _findReferencedFaculty(Session session, String query) async {
    final faculty = await Faculty.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    return _matchReferencedFaculty(query, faculty);
  }

  Faculty? _matchReferencedFaculty(String query, List<Faculty> faculty) {
    final normalized = _normalizeFacultySearchText(query);
    Faculty? bestMatch;
    var bestScore = 0;
    for (final item in faculty) {
      final facultyName = _normalizeFacultySearchText(item.name);
      if (facultyName.isEmpty) continue;
      if (normalized.contains(facultyName)) return item;

      final queryTokens = normalized
          .split(RegExp(r'\s+'))
          .where((token) => token.length >= 3)
          .toSet();
      final facultyTokens = facultyName
          .split(RegExp(r'\s+'))
          .where((token) => token.length >= 3)
          .toSet();
      final overlap = queryTokens.intersection(facultyTokens).length;
      if (overlap > bestScore) {
        bestScore = overlap;
        bestMatch = item;
      }
    }
    return bestScore > 0 ? bestMatch : null;
  }

  Future<Section?> _findReferencedSection(Session session, String query) async {
    final sections = await Section.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );
    return _matchReferencedSection(query, sections);
  }

  Section? _matchReferencedSection(String query, List<Section> sections) {
    final normalized = _normalizeSearchText(query);
    for (final section in sections) {
      final composite =
          '${section.program.name.toUpperCase()} ${section.yearLevel}${section.sectionCode}'
              .toLowerCase();
      final normalizedComposite = _normalizeSearchText(composite);
      final normalizedCode = _normalizeSearchText(section.sectionCode);
      if (normalized.contains(composite) ||
          normalized.contains(normalizedComposite) ||
          normalized.contains(normalizedCode)) {
        return section;
      }
    }
    return null;
  }

  Subject? _matchReferencedSubject(String query, List<Subject> subjects) {
    final normalized = _normalizeSearchText(query);
    Subject? bestMatch;
    var bestScore = 0;

    for (final subject in subjects) {
      final code = _normalizeSearchText(subject.code);
      final name = _normalizeSearchText(subject.name);

      if (code.isNotEmpty && normalized.contains(code)) return subject;
      if (name.isNotEmpty && normalized.contains(name)) return subject;

      final queryTokens = normalized
          .split(RegExp(r'\s+'))
          .where((token) => token.length >= 3)
          .toSet();
      final subjectTokens = {
        ...code.split(RegExp(r'\s+')).where((token) => token.length >= 2),
        ...name.split(RegExp(r'\s+')).where((token) => token.length >= 3),
      };
      final overlap = queryTokens.intersection(subjectTokens.toSet()).length;
      if (overlap > bestScore) {
        bestScore = overlap;
        bestMatch = subject;
      }
    }

    return bestScore > 0 ? bestMatch : null;
  }

  bool _looksLikeRoomQuery(String query) {
    return query.contains('room') ||
        query.contains('lab') ||
        query.contains('available room');
  }

  bool _looksLikeConflictQuery(String query) {
    return query.contains('conflict') || query.contains('overlap');
  }

  bool _looksLikeFacultyLoadQuery(String query) {
    return query.contains('faculty load') ||
        query.contains('teaching load') ||
        (query.contains('load') && query.contains('faculty'));
  }

  bool _looksLikeSubjectCatalogQuery(String query) {
    return query.contains('subject catalog') ||
        query.contains('curriculum') ||
        query.contains('subjects for');
  }

  DayOfWeek? _extractDayOfWeek(String query) {
    if (query.contains('monday')) return DayOfWeek.mon;
    if (query.contains('tuesday')) return DayOfWeek.tue;
    if (query.contains('wednesday')) return DayOfWeek.wed;
    if (query.contains('thursday')) return DayOfWeek.thu;
    if (query.contains('friday')) return DayOfWeek.fri;
    if (query.contains('saturday')) return DayOfWeek.sat;
    if (query.contains('sunday')) return DayOfWeek.sun;
    return null;
  }

  String _normalizeSearchText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeFacultySearchText(String text) {
    final lowered = text.toLowerCase().replaceAll(
      RegExp(r'\b(sir|maam|mam|mr|ms|mrs|prof|professor|dr)\b'),
      ' ',
    );
    return _normalizeSearchText(lowered);
  }

  Program? _extractProgram(String query) {
    if (query.contains('bsit') || RegExp(r'\bit\b').hasMatch(query)) {
      return Program.it;
    }
    if (query.contains('emc')) {
      return Program.emc;
    }
    return null;
  }

  int? _extractYearLevel(String query) {
    final match = RegExp(r'\b([1-4])(st|nd|rd|th)? year\b').firstMatch(query);
    if (match == null) return null;
    return int.tryParse(match.group(1) ?? '');
  }

  List<(Schedule, Schedule)> _collectConflicts(List<Schedule> schedules) {
    final conflicts = <(Schedule, Schedule)>[];
    for (var i = 0; i < schedules.length; i++) {
      final left = schedules[i];
      final leftSlot = left.timeslot;
      if (leftSlot == null) continue;

      for (var j = i + 1; j < schedules.length; j++) {
        final right = schedules[j];
        final rightSlot = right.timeslot;
        if (rightSlot == null || leftSlot.day != rightSlot.day) continue;

        final leftStart = _timeToMinutes(leftSlot.startTime);
        final leftEnd = _timeToMinutes(leftSlot.endTime);
        final rightStart = _timeToMinutes(rightSlot.startTime);
        final rightEnd = _timeToMinutes(rightSlot.endTime);

        final overlaps = leftStart < rightEnd && rightStart < leftEnd;
        if (!overlaps) continue;

        final sameFaculty = left.facultyId == right.facultyId;
        final sameRoom = left.roomId != null && left.roomId == right.roomId;
        final sameSection =
            left.sectionId != null && left.sectionId == right.sectionId;

        if (sameFaculty || sameRoom || sameSection) {
          conflicts.add((left, right));
        }
      }
    }
    return conflicts;
  }

  int _timeToMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }

  Map<String, dynamic> _scheduleJson(Schedule schedule) {
    return {
      'id': schedule.id,
      'section': schedule.section,
      'subject': schedule.subject == null
          ? null
          : {
              'id': schedule.subject!.id,
              'code': schedule.subject!.code,
              'name': schedule.subject!.name,
              'units': schedule.subject!.units,
            },
      'faculty': schedule.faculty == null
          ? null
          : {
              'id': schedule.faculty!.id,
              'name': schedule.faculty!.name,
              'facultyId': schedule.faculty!.facultyId,
            },
      'room': schedule.room == null
          ? null
          : {
              'id': schedule.room!.id,
              'name': schedule.room!.name,
              'type': schedule.room!.type.name,
            },
      'timeslot': schedule.timeslot == null
          ? null
          : {
              'id': schedule.timeslot!.id,
              'day': schedule.timeslot!.day.name,
              'startTime': schedule.timeslot!.startTime,
              'endTime': schedule.timeslot!.endTime,
            },
    };
  }

  Map<String, dynamic> _roomJson(Room room) => {
        'id': room.id,
        'name': room.name,
        'type': room.type.name,
        'capacity': room.capacity,
        'program': room.program.name,
      };

  Map<String, dynamic> _facultyJson(Faculty faculty) => {
        'id': faculty.id,
        'name': faculty.name,
        'facultyId': faculty.facultyId,
        'email': faculty.email,
        'program': faculty.program?.name,
        'maxLoad': faculty.maxLoad,
      };

  Map<String, dynamic> _studentJson(Student student) => {
        'id': student.id,
        'name': student.name,
        'studentNumber': student.studentNumber,
        'course': student.course,
        'yearLevel': student.yearLevel,
        'section': student.section,
      };

  Map<String, dynamic> _sectionJson(Section section) => {
        'id': section.id,
        'program': section.program.name,
        'yearLevel': section.yearLevel,
        'sectionCode': section.sectionCode,
        'academicYear': section.academicYear,
        'semester': section.semester,
      };

  Map<String, dynamic> _subjectJson(Subject subject) => {
        'id': subject.id,
        'code': subject.code,
        'name': subject.name,
        'units': subject.units,
        'hours': subject.hours,
        'yearLevel': subject.yearLevel,
        'term': subject.term,
        'program': subject.program.name,
        'types': subject.types.map((type) => type.name).toList(),
        'studentsCount': subject.studentsCount,
      };
}
