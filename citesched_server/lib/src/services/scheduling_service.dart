import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'conflict_service.dart';

/// Service class for handling scheduling logic.
/// Uses [ConflictService] to validate schedule entries and generates schedules.
/// Respects faculty availability preferences from the FacultyAvailability table.
class SchedulingService {
  final ConflictService _conflictService = ConflictService();
  static const double _lectureHours = 2.0;
  static const double _labHours = 3.0;
  static const int _labEarliestStartMinutes = 9 * 60;
  static const int _lunchStartMinutes = 12 * 60;
  static const int _lunchEndMinutes = 13 * 60;
  static const List<(int start, int end)> _preferredLectureWindows = [
    (8 * 60, 10 * 60),
    (10 * 60, 12 * 60),
    (13 * 60, 15 * 60),
    (15 * 60, 17 * 60),
    (17 * 60, 19 * 60),
  ];
  static const List<(int start, int end)> _preferredLabWindows = [
    (9 * 60, 12 * 60),
    (13 * 60, 16 * 60),
    (16 * 60, 19 * 60),
  ];

  bool _roomSupportsProgram(Room room, Program subjectProgram) {
    return room.program == Program.both || room.program == subjectProgram;
  }

  /// Generate schedules using a greedy algorithm.
  /// Attempts to assign each subject to available timeslots while respecting
  /// all constraints including faculty day/time availability.
  Future<GenerateScheduleResponse> generateSchedule(
    Session session,
    GenerateScheduleRequest request,
  ) async {
    final validationResponse = _validateGenerateScheduleRequest(request);
    if (validationResponse != null) return validationResponse;

    final data = await _loadGenerateData(session, request);
    final tracking = _initFacultyTracking(
      data.validFaculties,
      data.existingSchedules,
    );
    final assignedKeys = _buildAssignedSubjectSectionKeys(
      data.existingSchedules,
    );

    final outcome = await _generateSchedulesForSubjects(
      session: session,
      data: data,
      tracking: tracking,
      assignedSubjectSectionKeys: assignedKeys,
    );

    _logConflicts(session, outcome.conflicts);
    return _buildGenerateResponse(outcome);
  }

  GenerateScheduleResponse? _validateGenerateScheduleRequest(
    GenerateScheduleRequest request,
  ) {
    if (request.subjectIds.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'No subjects provided for schedule generation',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: 0,
      );
    }
    if (request.facultyIds.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'No faculty provided for schedule generation',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: request.subjectIds.length,
      );
    }
    if (request.sections.isEmpty) {
      return GenerateScheduleResponse(
        success: false,
        message: 'No sections provided for schedule generation',
        totalAssigned: 0,
        conflictsDetected: 0,
        unassignedSubjects: 0,
      );
    }
    return null;
  }

  Future<_GenerateData> _loadGenerateData(
    Session session,
    GenerateScheduleRequest request,
  ) async {
    final subjects = await Future.wait(
      request.subjectIds.map((id) => Subject.db.findById(session, id)),
    );
    final faculties = await Future.wait(
      request.facultyIds.map((id) => Faculty.db.findById(session, id)),
    );
    final rooms = await Future.wait(
      request.roomIds.map((id) => Room.db.findById(session, id)),
    );
    final timeslots = await Future.wait(
      request.timeslotIds.map((id) => Timeslot.db.findById(session, id)),
    );
    final existingSchedules = await Schedule.db.find(
      session,
      where: (t) => t.isActive.equals(true),
    );

    final validSubjects = subjects
        .whereType<Subject>()
        .where((s) => s.isActive)
        .toList();
    final validFaculties = faculties
        .whereType<Faculty>()
        .where((f) => f.isActive)
        .toList();
    final validRooms = rooms
        .whereType<Room>()
        .where((r) => r.isActive)
        .toList();
    final validTimeslots = timeslots.whereType<Timeslot>().toList();
    final timeslotCache = <String, Timeslot>{
      for (final t in validTimeslots)
        _timeslotKey(t.day, t.startTime, t.endTime): t,
    };

    final requestedSections = request.sections
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final candidateSections = await _buildSectionCandidates(
      session: session,
      requestedSections: requestedSections,
    );

    final facultyAvailMap = <int, List<FacultyAvailability>>{};
    for (final faculty in validFaculties) {
      final avails = await FacultyAvailability.db.find(
        session,
        where: (t) => t.facultyId.equals(faculty.id!),
      );
      facultyAvailMap[faculty.id!] = avails;
    }

    return _GenerateData(
      request: request,
      validSubjects: validSubjects,
      validFaculties: validFaculties,
      validRooms: validRooms,
      validTimeslots: validTimeslots,
      timeslotCache: timeslotCache,
      candidateSections: candidateSections,
      facultyAvailMap: facultyAvailMap,
      existingSchedules: existingSchedules,
    );
  }

  _FacultyTracking _initFacultyTracking(
    List<Faculty> validFaculties,
    List<Schedule> existingSchedules,
  ) {
    final facultyAssignments = <int, double>{};
    final facultyTimeslotUsage = <int, Map<int, int>>{};
    final facultyYearLevelAssignments = <int, Map<String, int>>{};
    for (final faculty in validFaculties) {
      facultyAssignments[faculty.id!] = 0;
      facultyTimeslotUsage[faculty.id!] = {};
      facultyYearLevelAssignments[faculty.id!] = {};
    }

    for (final existing in existingSchedules) {
      final current = facultyAssignments[existing.facultyId];
      if (current == null) continue;
      facultyAssignments[existing.facultyId] = current + (existing.units ?? 0);
      if (existing.timeslotId != null) {
        final usage = facultyTimeslotUsage[existing.facultyId]!;
        usage[existing.timeslotId!] = (usage[existing.timeslotId!] ?? 0) + 1;
      }
      final yearLevelKey = _facultyYearLevelKeyFromSchedule(existing);
      if (yearLevelKey != null) {
        final usage = facultyYearLevelAssignments[existing.facultyId]!;
        usage[yearLevelKey] = (usage[yearLevelKey] ?? 0) + 1;
      }
    }

    return _FacultyTracking(
      assignments: facultyAssignments,
      timeslotUsage: facultyTimeslotUsage,
      yearLevelAssignments: facultyYearLevelAssignments,
    );
  }

  Set<String> _buildAssignedSubjectSectionKeys(
    List<Schedule> existingSchedules,
  ) {
    return <String>{
      for (final s in existingSchedules)
        _componentKey(
          s.subjectId,
          s.sectionId,
          s.section,
          _componentTagFromLoadTypes(s.loadTypes),
        ),
    };
  }

  Future<_GenerationOutcome> _generateSchedulesForSubjects({
    required Session session,
    required _GenerateData data,
    required _FacultyTracking tracking,
    required Set<String> assignedSubjectSectionKeys,
  }) async {
    final generatedSchedules = <Schedule>[];
    final conflicts = <ScheduleConflict>[];

    for (final subject in data.validSubjects) {
      await _generateForSubject(
        session: session,
        data: data,
        subject: subject,
        tracking: tracking,
        assignedSubjectSectionKeys: assignedSubjectSectionKeys,
        generatedSchedules: generatedSchedules,
        conflicts: conflicts,
      );
    }

    return _GenerationOutcome(
      generatedSchedules: generatedSchedules,
      conflicts: conflicts,
    );
  }

  Future<void> _generateForSubject({
    required Session session,
    required _GenerateData data,
    required Subject subject,
    required _FacultyTracking tracking,
    required Set<String> assignedSubjectSectionKeys,
    required List<Schedule> generatedSchedules,
    required List<ScheduleConflict> conflicts,
  }) async {
    final matchingSections = _matchingSectionsForSubject(
      subject,
      data.candidateSections,
    );

    if (matchingSections.isEmpty) {
      conflicts.add(
        ScheduleConflict(
          type: 'generation_failed',
          message:
              'No matching section found for ${subject.name} (${subject.code})',
          details:
              'Subject program/year does not match any available active section.',
        ),
      );
      return;
    }

    for (final section in matchingSections) {
      final result = await _generateForSection(
        session: session,
        data: data,
        subject: subject,
        section: section,
        tracking: tracking,
        assignedSubjectSectionKeys: assignedSubjectSectionKeys,
        generatedSchedules: generatedSchedules,
        conflicts: conflicts,
      );

      if (!result.allAssigned) {
        final details = await _buildGenerationFailureDetails(
          session: session,
          data: data,
          subject: subject,
          section: section,
          tracking: tracking,
          maxComponentHours: result.maxComponentHours,
        );
        conflicts.add(
          ScheduleConflict(
            type: 'generation_failed',
            message:
                'Could not assign ${subject.name} (${subject.code}) - Section ${section.sectionCode}',
            details: details,
          ),
        );
      }
    }
  }

  List<_SectionCandidate> _matchingSectionsForSubject(
    Subject subject,
    List<_SectionCandidate> candidateSections,
  ) {
    return candidateSections.where((section) {
      if (section.program != subject.program) return false;
      if (subject.yearLevel != null && section.yearLevel != subject.yearLevel) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<_SectionGenerationResult> _generateForSection({
    required Session session,
    required _GenerateData data,
    required Subject subject,
    required _SectionCandidate section,
    required _FacultyTracking tracking,
    required Set<String> assignedSubjectSectionKeys,
    required List<Schedule> generatedSchedules,
    required List<ScheduleConflict> conflicts,
  }) async {
    final components = _componentsForSubject(subject);
    double maxComponentHours = 0;
    for (final component in components) {
      if (component.hours > maxComponentHours) {
        maxComponentHours = component.hours;
      }
    }

    final insertedForPair = <Schedule>[];
    var allAssigned = true;

    for (final component in components) {
      final pairKey = _componentKey(
        subject.id!,
        section.id,
        section.sectionCode,
        component.tag,
      );
      if (assignedSubjectSectionKeys.contains(pairKey)) {
        continue;
      }

      final eligibleRooms = _eligibleRoomsForComponent(
        rooms: data.validRooms,
        subject: subject,
        componentTypes: component.types,
      );
      if (eligibleRooms.isEmpty) {
        conflicts.add(
          ScheduleConflict(
            type: 'generation_failed',
            message: 'No eligible room for ${subject.name} (${subject.code})',
            details: 'No room matches subject type/program constraints.',
          ),
        );
        allAssigned = false;
        break;
      }

      final assigned = await _assignComponentToSection(
        session: session,
        data: data,
        subject: subject,
        section: section,
        component: component,
        eligibleRooms: eligibleRooms,
        tracking: tracking,
        assignedSubjectSectionKeys: assignedSubjectSectionKeys,
        generatedSchedules: generatedSchedules,
        insertedForPair: insertedForPair,
      );

      if (!assigned) {
        allAssigned = false;
        break;
      }
    }

    if (!allAssigned && insertedForPair.isNotEmpty) {
      for (final inserted in insertedForPair) {
        await Schedule.db.deleteRow(session, inserted);
      }
    }

    return _SectionGenerationResult(
      allAssigned: allAssigned,
      maxComponentHours: maxComponentHours,
    );
  }

  Future<bool> _assignComponentToSection({
    required Session session,
    required _GenerateData data,
    required Subject subject,
    required _SectionCandidate section,
    required _LoadComponent component,
    required List<Room> eligibleRooms,
    required _FacultyTracking tracking,
    required Set<String> assignedSubjectSectionKeys,
    required List<Schedule> generatedSchedules,
    required List<Schedule> insertedForPair,
  }) async {
    final rankedFaculties = _rankFacultiesForSection(
      validFaculties: data.validFaculties,
      facultyAssignments: tracking.assignments,
      yearLevelAssignments: tracking.yearLevelAssignments,
      section: section,
    );

    for (final faculty in rankedFaculties) {
      if (!_isFacultyEligibleForSubject(faculty, subject)) {
        continue;
      }

      final currentLoad = tracking.assignments[faculty.id!] ?? 0;
      if ((currentLoad + component.units) > (faculty.maxLoad ?? 0)) continue;

      final candidateTimeslots = await _candidateTimeslotsForFaculty(
        session: session,
        allTimeslots: data.validTimeslots,
        availability: data.facultyAvailMap[faculty.id!] ?? const [],
        requiredHours: component.hours,
        cache: data.timeslotCache,
        requireLabStartAfterNine: component.types.contains(
          SubjectType.laboratory,
        ),
      );
      final rankedTimeslots = _rankTimeslotsForFaculty(
        timeslots: candidateTimeslots,
        timeslotUsage: tracking.timeslotUsage[faculty.id!] ?? const {},
      );
      if (rankedTimeslots.isEmpty) {
        continue;
      }

      final assigned = await _assignWithFaculty(
        session: session,
        subject: subject,
        section: section,
        component: component,
        faculty: faculty,
        rankedTimeslots: rankedTimeslots,
        eligibleRooms: eligibleRooms,
        tracking: tracking,
        assignedSubjectSectionKeys: assignedSubjectSectionKeys,
        generatedSchedules: generatedSchedules,
        insertedForPair: insertedForPair,
      );
      if (assigned) {
        return true;
      }
    }

    return false;
  }

  List<Faculty> _rankFacultiesForSection({
    required List<Faculty> validFaculties,
    required Map<int, double> facultyAssignments,
    required Map<int, Map<String, int>> yearLevelAssignments,
    required _SectionCandidate section,
  }) {
    final ranked = [...validFaculties];
    final targetYearLevelKey = _facultyYearLevelKey(
      section.program,
      section.yearLevel,
    );
    ranked.sort((a, b) {
      final aSectionCount =
          yearLevelAssignments[a.id!]?[targetYearLevelKey] ?? 0;
      final bSectionCount =
          yearLevelAssignments[b.id!]?[targetYearLevelKey] ?? 0;
      final sectionCompare = aSectionCount.compareTo(bSectionCount);
      if (sectionCompare != 0) return sectionCompare;

      final aLoad = facultyAssignments[a.id!] ?? 0;
      final bLoad = facultyAssignments[b.id!] ?? 0;
      final aMax = (a.maxLoad ?? 1).toDouble();
      final bMax = (b.maxLoad ?? 1).toDouble();
      final aRatio = aMax <= 0 ? 1.0 : aLoad / aMax;
      final bRatio = bMax <= 0 ? 1.0 : bLoad / bMax;
      return aRatio.compareTo(bRatio);
    });
    return ranked;
  }

  bool _isFacultyEligibleForSubject(Faculty faculty, Subject subject) {
    if (subject.facultyId != null && faculty.id != subject.facultyId) {
      return false;
    }
    return _canTeachProgram(faculty, subject);
  }

  Future<bool> _assignWithFaculty({
    required Session session,
    required Subject subject,
    required _SectionCandidate section,
    required _LoadComponent component,
    required Faculty faculty,
    required List<Timeslot> rankedTimeslots,
    required List<Room> eligibleRooms,
    required _FacultyTracking tracking,
    required Set<String> assignedSubjectSectionKeys,
    required List<Schedule> generatedSchedules,
    required List<Schedule> insertedForPair,
  }) async {
    for (final timeslot in rankedTimeslots) {
      if (_violatesComponentDaySeparation(
        timeslot: timeslot,
        insertedForPair: insertedForPair,
      )) {
        continue;
      }

      for (final room in eligibleRooms) {
        final candidate = Schedule(
          subjectId: subject.id!,
          facultyId: faculty.id!,
          roomId: room.id!,
          timeslotId: timeslot.id!,
          section: section.sectionCode,
          sectionId: section.id,
          loadTypes: component.types,
          units: component.units,
          hours: component.hours,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final validationConflicts = await _conflictService.validateSchedule(
          session,
          candidate,
        );
        if (validationConflicts.isNotEmpty) {
          continue;
        }

        final inserted = await _tryInsertSchedule(session, candidate);
        if (inserted == null) {
          continue;
        }

        generatedSchedules.add(inserted);
        insertedForPair.add(inserted);
        tracking.assignments[faculty.id!] =
            (tracking.assignments[faculty.id!] ?? 0) + component.units;
        final usage = tracking.timeslotUsage[faculty.id!]!;
        usage[timeslot.id!] = (usage[timeslot.id!] ?? 0) + 1;
        final yearLevelKey = _facultyYearLevelKey(
          section.program,
          section.yearLevel,
        );
        final yearLevelUsage =
            tracking.yearLevelAssignments[faculty.id!] ??= {};
        yearLevelUsage[yearLevelKey] =
            (yearLevelUsage[yearLevelKey] ?? 0) + 1;
        assignedSubjectSectionKeys.add(
          _componentKey(
            subject.id!,
            section.id,
            section.sectionCode,
            component.tag,
          ),
        );
        return true;
      }
    }
    return false;
  }

  bool _violatesComponentDaySeparation({
    required Timeslot timeslot,
    required List<Schedule> insertedForPair,
  }) {
    if (insertedForPair.isEmpty) return false;

    for (final existing in insertedForPair) {
      if (existing.timeslotId == null) continue;
      final existingTimeslot = existing.timeslot;
      if (existingTimeslot != null && existingTimeslot.day == timeslot.day) {
        return true;
      }
    }

    return false;
  }

  Future<String> _buildGenerationFailureDetails({
    required Session session,
    required _GenerateData data,
    required Subject subject,
    required _SectionCandidate section,
    required _FacultyTracking tracking,
    required double maxComponentHours,
  }) async {
    var details =
        'No valid faculty/room/timeslot combination satisfies all constraints.';

    if (subject.facultyId == null) return details;

    final lockedFaculty = await Faculty.db.findById(
      session,
      subject.facultyId!,
    );
    final lockedName = lockedFaculty?.name ?? 'Faculty ID ${subject.facultyId}';

    if (lockedFaculty == null || !lockedFaculty.isActive) {
      return 'Subject ${subject.code} is locked to $lockedName, but that faculty member is missing or inactive.';
    }
    if (!data.request.facultyIds.contains(lockedFaculty.id)) {
      return 'Subject ${subject.code} is locked to $lockedName, but that faculty member is not included in the selected faculty filter.';
    }
    if (lockedFaculty.program != null &&
        lockedFaculty.program != subject.program) {
      return 'Subject ${subject.code} is locked to $lockedName, but program does not match (${lockedFaculty.program} vs ${subject.program}).';
    }

    final lockedId = lockedFaculty.id!;
    final lockedCurrentLoad =
        tracking.assignments[lockedId] ??
        data.existingSchedules
            .where((s) => s.facultyId == lockedId)
            .fold<double>(0, (sum, s) => sum + (s.units ?? 0));
    final subjectUnits = subject.units.toDouble();

    if ((lockedCurrentLoad + subjectUnits) >
        (lockedFaculty.maxLoad ?? 0).toDouble()) {
      return 'Subject ${subject.code} is locked to $lockedName, but assigning it would exceed max load (${lockedCurrentLoad.toStringAsFixed(1)} + ${subjectUnits.toStringAsFixed(1)} > ${(lockedFaculty.maxLoad ?? 0).toDouble().toStringAsFixed(1)}).';
    }

    final lockedAvailability =
        data.facultyAvailMap[lockedId] ??
        await FacultyAvailability.db.find(
          session,
          where: (t) => t.facultyId.equals(lockedId),
        );
    final lockedUsage =
        tracking.timeslotUsage[lockedId] ??
        <int, int>{
          for (final s in data.existingSchedules.where(
            (s) => s.facultyId == lockedId && s.timeslotId != null,
          ))
            s.timeslotId!: 1,
        };
    final lockedCandidates = await _candidateTimeslotsForFaculty(
      session: session,
      allTimeslots: data.validTimeslots,
      availability: lockedAvailability,
      requiredHours: maxComponentHours > 0
          ? maxComponentHours
          : _requiredHours(subject),
      cache: data.timeslotCache,
    );
    final lockedTimeslots = _rankTimeslotsForFaculty(
      timeslots: lockedCandidates,
      timeslotUsage: lockedUsage,
    );

    if (lockedTimeslots.isEmpty) {
      return 'Subject ${subject.code} is locked to $lockedName, but no timeslot fits preferred availability and required hours.';
    }

    return 'Subject ${subject.code} is locked to $lockedName, but no room/timeslot combination is conflict-free for section ${section.sectionCode}.';
  }

  void _logConflicts(Session session, List<ScheduleConflict> conflicts) {
    if (conflicts.isEmpty) return;
    final limit = conflicts.length < 10 ? conflicts.length : 10;
    for (var i = 0; i < limit; i++) {
      final c = conflicts[i];
      session.log(
        '[SCHEDULE_CONFLICT] ${c.type}: ${c.message} :: ${c.details ?? ''}',
        level: LogLevel.warning,
      );
    }
  }

  GenerateScheduleResponse _buildGenerateResponse(
    _GenerationOutcome outcome,
  ) {
    return GenerateScheduleResponse(
      success: outcome.conflicts.isEmpty,
      schedules: outcome.generatedSchedules,
      conflicts: outcome.conflicts.isEmpty ? null : outcome.conflicts,
      totalAssigned: outcome.generatedSchedules.length,
      conflictsDetected: outcome.conflicts.length,
      unassignedSubjects: outcome.conflicts.length,
      message: outcome.conflicts.isEmpty
          ? 'Successfully generated ${outcome.generatedSchedules.length} schedule entries'
          : '${outcome.generatedSchedules.length} assigned, ${outcome.conflicts.length} unassigned',
    );
  }

  int _parseTimeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours * 60 + minutes;
  }

  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).clamp(0, 23).toString().padLeft(2, '0');
    final m = (minutes % 60).clamp(0, 59).toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _overlapsLunchWindow(int startMinutes, int endMinutes) {
    return startMinutes < _lunchEndMinutes && endMinutes > _lunchStartMinutes;
  }

  List<(int start, int end)> _preferredWindowsForDuration(int requiredMinutes) {
    if (requiredMinutes == (_lectureHours * 60).round()) {
      return _preferredLectureWindows;
    }
    if (requiredMinutes == (_labHours * 60).round()) {
      return _preferredLabWindows;
    }
    return const [];
  }

  Iterable<(int start, int end)> _windowsWithinRange({
    required int rangeStart,
    required int rangeEnd,
    required int requiredMinutes,
    required bool requireLabStartAfterNine,
  }) sync* {
    final fixedWindows = _preferredWindowsForDuration(requiredMinutes);
    if (fixedWindows.isNotEmpty) {
      for (final window in fixedWindows) {
        final start = window.$1;
        final end = window.$2;
        if (requireLabStartAfterNine && start < _labEarliestStartMinutes) {
          continue;
        }
        if (_overlapsLunchWindow(start, end)) {
          continue;
        }
        if (start >= rangeStart && end <= rangeEnd) {
          yield (start, end);
        }
      }
      return;
    }

    final stepMinutes = requiredMinutes % 60 == 0 ? 60 : 30;
    for (
      var start = rangeStart;
      start + requiredMinutes <= rangeEnd;
      start += stepMinutes
    ) {
      if (requireLabStartAfterNine && start < _labEarliestStartMinutes) {
        continue;
      }
      final end = start + requiredMinutes;
      if (_overlapsLunchWindow(start, end)) {
        continue;
      }
      yield (start, end);
    }
  }

  String _timeslotKey(DayOfWeek day, String startTime, String endTime) {
    return '${day.name}|${startTime.trim()}|${endTime.trim()}';
  }

  Future<Timeslot> _getOrCreateTimeslot({
    required Session session,
    required DayOfWeek day,
    required String startTime,
    required String endTime,
    required Map<String, Timeslot> cache,
  }) async {
    final key = _timeslotKey(day, startTime, endTime);
    final existing = cache[key];
    if (existing != null) return existing;

    final label = '${day.name.toUpperCase()} $startTime-$endTime';
    final created = await Timeslot.db.insertRow(
      session,
      Timeslot(
        day: day,
        startTime: startTime,
        endTime: endTime,
        label: label,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    cache[key] = created;
    return created;
  }

  bool _timeslotFitsAvailability(
    Timeslot timeslot,
    FacultyAvailability availability,
  ) {
    if (timeslot.day != availability.dayOfWeek) return false;
    final tsStart = _parseTimeToMinutes(timeslot.startTime);
    final tsEnd = _parseTimeToMinutes(timeslot.endTime);
    final avStart = _parseTimeToMinutes(availability.startTime);
    final avEnd = _parseTimeToMinutes(availability.endTime);
    return tsStart >= avStart && tsEnd <= avEnd;
  }

  bool _timeslotExactAvailabilityMatch(
    Timeslot timeslot,
    FacultyAvailability availability,
  ) {
    if (timeslot.day != availability.dayOfWeek) return false;
    final tsStart = _parseTimeToMinutes(timeslot.startTime);
    final tsEnd = _parseTimeToMinutes(timeslot.endTime);
    final avStart = _parseTimeToMinutes(availability.startTime);
    final avEnd = _parseTimeToMinutes(availability.endTime);
    return tsStart == avStart && tsEnd == avEnd;
  }

  double _requiredHours(Subject subject) {
    final value = subject.hours ?? subject.units.toDouble();
    return value <= 0 ? subject.units.toDouble() : value;
  }

  List<_LoadComponent> _componentsForSubject(Subject subject) {
    final types = subject.types;
    final hasLecture = types.contains(SubjectType.lecture);
    final hasLab = types.contains(SubjectType.laboratory);
    final hasBlended = types.contains(SubjectType.blended);

    if (hasBlended || (hasLecture && hasLab)) {
      const totalHours = _lectureHours + _labHours;
      final totalUnits = subject.units.toDouble();
      final lectureUnits = totalUnits * (_lectureHours / totalHours);
      final labUnits = (totalUnits - lectureUnits);
      return [
        _LoadComponent(
          tag: 'lecture',
          types: const [SubjectType.lecture],
          hours: _lectureHours,
          units: lectureUnits,
        ),
        _LoadComponent(
          tag: 'laboratory',
          types: const [SubjectType.laboratory],
          hours: _labHours,
          units: labUnits,
        ),
      ];
    }

    if (hasLab && !hasLecture) {
      return [
        _LoadComponent(
          tag: 'laboratory',
          types: const [SubjectType.laboratory],
          hours: subject.hours ?? _labHours,
          units: subject.units.toDouble(),
        ),
      ];
    }

    return [
      _LoadComponent(
        tag: 'lecture',
        types: const [SubjectType.lecture],
        hours: subject.hours ?? _lectureHours,
        units: subject.units.toDouble(),
      ),
    ];
  }

  double _timeslotHours(Timeslot timeslot) {
    final durationMinutes =
        _parseTimeToMinutes(timeslot.endTime) -
        _parseTimeToMinutes(timeslot.startTime);
    return durationMinutes / 60.0;
  }

  String _componentKey(
    int subjectId,
    int? sectionId,
    String sectionCode,
    String tag,
  ) {
    final base = sectionId != null
        ? '$subjectId|$sectionId'
        : '$subjectId|${sectionCode.trim().toLowerCase()}';
    return '$base|$tag';
  }

  String _facultyYearLevelKey(Program program, int yearLevel) {
    return '${program.name}|$yearLevel';
  }

  String? _facultyYearLevelKeyFromSchedule(Schedule schedule) {
    final sectionCode = schedule.section.trim();
    if (sectionCode.isEmpty) return null;
    final yearLevel = _yearLevelFromSectionCode(sectionCode, fallback: 0);
    if (yearLevel <= 0) return null;
    final program = _programFromSectionCode(sectionCode);
    return _facultyYearLevelKey(program, yearLevel);
  }

  Program _programFromSectionCode(String sectionCode) {
    final normalized = sectionCode.trim().toUpperCase();
    if (normalized.contains('EMC')) return Program.emc;
    return Program.it;
  }

  int _dayRank(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 1;
      case DayOfWeek.tue:
        return 2;
      case DayOfWeek.wed:
        return 3;
      case DayOfWeek.thu:
        return 4;
      case DayOfWeek.fri:
        return 5;
      case DayOfWeek.sat:
        return 6;
      case DayOfWeek.sun:
        return 7;
    }
  }

  List<Timeslot> _rankTimeslotsForFaculty({
    required List<Timeslot> timeslots,
    required Map<int, int> timeslotUsage,
  }) {
    if (timeslots.isEmpty) return const [];

    final candidates = [...timeslots];
    candidates.sort((a, b) {
      final dayCompare = _dayRank(a.day).compareTo(_dayRank(b.day));
      if (dayCompare != 0) return dayCompare;
      final timeCompare = _parseTimeToMinutes(
        a.startTime,
      ).compareTo(_parseTimeToMinutes(b.startTime));
      if (timeCompare != 0) return timeCompare;
      final aUse = timeslotUsage[a.id!] ?? 0;
      final bUse = timeslotUsage[b.id!] ?? 0;
      return aUse.compareTo(bUse);
    });

    return candidates;
  }

  Future<List<Timeslot>> _candidateTimeslotsForFaculty({
    required Session session,
    required List<Timeslot> allTimeslots,
    required List<FacultyAvailability> availability,
    required double requiredHours,
    required Map<String, Timeslot> cache,
    bool requireLabStartAfterNine = false,
  }) async {
    final requiredMinutes = (requiredHours * 60).round();
    if (requiredMinutes <= 0) return const [];

    if (availability.isEmpty) {
      return await _candidateTimeslotsFromExisting(
        session: session,
        allTimeslots: allTimeslots,
        requiredMinutes: requiredMinutes,
        cache: cache,
        requireLabStartAfterNine: requireLabStartAfterNine,
      );
    }

    return await _candidateTimeslotsFromAvailability(
      session: session,
      availability: availability,
      requiredMinutes: requiredMinutes,
      cache: cache,
      requireLabStartAfterNine: requireLabStartAfterNine,
    );
  }

  Future<List<Timeslot>> _candidateTimeslotsFromExisting({
    required Session session,
    required List<Timeslot> allTimeslots,
    required int requiredMinutes,
    required Map<String, Timeslot> cache,
    required bool requireLabStartAfterNine,
  }) async => _candidateTimeslotsFromExistingImpl(
    session: session,
    allTimeslots: allTimeslots,
    requiredMinutes: requiredMinutes,
    cache: cache,
    requireLabStartAfterNine: requireLabStartAfterNine,
  );

  Future<List<Timeslot>> _candidateTimeslotsFromExistingImpl({
    required Session session,
    required List<Timeslot> allTimeslots,
    required int requiredMinutes,
    required Map<String, Timeslot> cache,
    required bool requireLabStartAfterNine,
  }) async {
    final candidates = <Timeslot>[];
    final seen = <String>{};

    for (final slot in allTimeslots) {
      final start = _parseTimeToMinutes(slot.startTime);
      final end = _parseTimeToMinutes(slot.endTime);
      if (end - start < requiredMinutes) continue;

      for (final window in _windowsWithinRange(
        rangeStart: start,
        rangeEnd: end,
        requiredMinutes: requiredMinutes,
        requireLabStartAfterNine: requireLabStartAfterNine,
      )) {
        final startTime = _formatMinutes(window.$1);
        final endTime = _formatMinutes(window.$2);
        final key = _timeslotKey(slot.day, startTime, endTime);
        if (!seen.add(key)) continue;
        final created = await _getOrCreateTimeslot(
          session: session,
          day: slot.day,
          startTime: startTime,
          endTime: endTime,
          cache: cache,
        );
        candidates.add(created);
      }
    }

    return candidates;
  }

  Future<List<Timeslot>> _candidateTimeslotsFromAvailability({
    required Session session,
    required List<FacultyAvailability> availability,
    required int requiredMinutes,
    required Map<String, Timeslot> cache,
    required bool requireLabStartAfterNine,
  }) async => _candidateTimeslotsFromAvailabilityImpl(
    session: session,
    availability: availability,
    requiredMinutes: requiredMinutes,
    cache: cache,
    requireLabStartAfterNine: requireLabStartAfterNine,
  );

  Future<List<Timeslot>> _candidateTimeslotsFromAvailabilityImpl({
    required Session session,
    required List<FacultyAvailability> availability,
    required int requiredMinutes,
    required Map<String, Timeslot> cache,
    required bool requireLabStartAfterNine,
  }) async {
    final candidates = <Timeslot>[];
    final seen = <String>{};

    for (final avail in availability) {
      final start = _parseTimeToMinutes(avail.startTime);
      final end = _parseTimeToMinutes(avail.endTime);
      if (end - start < requiredMinutes) continue;

      for (final window in _windowsWithinRange(
        rangeStart: start,
        rangeEnd: end,
        requiredMinutes: requiredMinutes,
        requireLabStartAfterNine: requireLabStartAfterNine,
      )) {
        final startTime = _formatMinutes(window.$1);
        final endTime = _formatMinutes(window.$2);
        final key = _timeslotKey(avail.dayOfWeek, startTime, endTime);
        if (!seen.add(key)) {
          continue;
        }
        final slot = await _getOrCreateTimeslot(
          session: session,
          day: avail.dayOfWeek,
          startTime: startTime,
          endTime: endTime,
          cache: cache,
        );
        candidates.add(slot);
      }
    }

    return candidates;
  }

  bool _isExclusionViolation(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('exclusion') ||
        message.contains('schedule_instructor_no_overlap') ||
        message.contains('schedule_room_no_overlap') ||
        message.contains('schedule_section_no_overlap');
  }

  Future<Schedule?> _tryInsertSchedule(
    Session session,
    Schedule schedule,
  ) async {
    try {
      final inserted = await Schedule.db.insertRow(session, schedule);
      return inserted;
    } catch (e) {
      if (_isExclusionViolation(e)) {
        return null;
      }
      rethrow;
    }
  }

  List<Room> _eligibleRoomsForSubject({
    required List<Room> rooms,
    required Subject subject,
  }) {
    final requiresLabRoom =
        subject.types.contains(SubjectType.laboratory) ||
        subject.types.contains(SubjectType.blended);

    return rooms.where((room) {
      if (requiresLabRoom) {
        return room.type == RoomType.laboratory &&
            _roomSupportsProgram(room, subject.program);
      }
      return room.type == RoomType.lecture;
    }).toList();
  }

  List<Room> _eligibleRoomsForComponent({
    required List<Room> rooms,
    required Subject subject,
    required List<SubjectType> componentTypes,
  }) {
    final requiresLab = componentTypes.contains(SubjectType.laboratory);
    return rooms.where((room) {
      if (requiresLab) {
        return room.type == RoomType.laboratory &&
            _roomSupportsProgram(room, subject.program);
      }
      return room.type == RoomType.lecture;
    }).toList();
  }

  bool _canTeachProgram(Faculty faculty, Subject subject) {
    if (faculty.program == null) return true;
    if (faculty.program == subject.program) return true;
    // EMC faculty can teach BSIT subjects, but IT faculty cannot teach EMC.
    if (faculty.program == Program.emc && subject.program == Program.it) {
      return true;
    }
    return false;
  }

  Program _programFromStudentCourse(String? course) {
    final normalized = course?.trim().toUpperCase() ?? '';
    if (normalized == 'BSEMC' || normalized == 'EMC') {
      return Program.emc;
    }
    return Program.it;
  }

  int _yearLevelFromSectionCode(String? sectionCode, {int fallback = 1}) {
    final match = RegExp(r'\\d+').firstMatch(sectionCode ?? '');
    if (match == null) return fallback;
    return int.tryParse(match.group(0)!) ?? fallback;
  }

  Future<List<_SectionCandidate>> _buildSectionCandidates({
    required Session session,
    required Set<String> requestedSections,
  }) async {
    String normalize(String value) =>
        value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final requestedNormalized = requestedSections
        .map((s) => normalize(s))
        .where((s) => s.isNotEmpty)
        .toSet();

    final sectionRows = await Section.db.find(session);
    final candidateByKey = <String, _SectionCandidate>{};

    bool shouldInclude(String code) {
      if (requestedNormalized.isEmpty) return true;
      return requestedNormalized.contains(normalize(code));
    }

    for (final section in sectionRows) {
      if (!section.isActive) continue;
      if (!shouldInclude(section.sectionCode)) continue;
      final key =
          '${section.program.name}|${section.yearLevel}|${normalize(section.sectionCode)}';
      candidateByKey[key] = _SectionCandidate(
        id: section.id,
        sectionCode: section.sectionCode.trim(),
        program: section.program,
        yearLevel: section.yearLevel,
      );
    }

    final students = await Student.db.find(
      session,
      where: (t) => t.isActive.equals(true) & t.section.notEquals(null),
    );
    for (final student in students) {
      final code = student.section?.trim();
      if (code == null || code.isEmpty) continue;
      if (!shouldInclude(code)) continue;
      final program = _programFromStudentCourse(student.course);
      final yearLevel = student.yearLevel > 0
          ? student.yearLevel
          : _yearLevelFromSectionCode(code, fallback: 1);
      final key = '${program.name}|$yearLevel|${normalize(code)}';
      candidateByKey.putIfAbsent(
        key,
        () => _SectionCandidate(
          id: student.sectionId,
          sectionCode: code,
          program: program,
          yearLevel: yearLevel,
        ),
      );
    }

    return candidateByKey.values.toList();
  }

  String _componentTagFromLoadTypes(List<SubjectType>? types) {
    if (types == null || types.isEmpty) return 'lecture';
    final hasLecture = types.contains(SubjectType.lecture);
    final hasLab = types.contains(SubjectType.laboratory);
    if (hasLab && !hasLecture) return 'laboratory';
    if (hasLecture && !hasLab) return 'lecture';
    return 'blended';
  }
}

class _LoadComponent {
  final String tag;
  final List<SubjectType> types;
  final double hours;
  final double units;

  const _LoadComponent({
    required this.tag,
    required this.types,
    required this.hours,
    required this.units,
  });
}

class _SectionCandidate {
  final int? id;
  final String sectionCode;
  final Program program;
  final int yearLevel;

  const _SectionCandidate({
    required this.id,
    required this.sectionCode,
    required this.program,
    required this.yearLevel,
  });
}

class _GenerateData {
  final GenerateScheduleRequest request;
  final List<Subject> validSubjects;
  final List<Faculty> validFaculties;
  final List<Room> validRooms;
  final List<Timeslot> validTimeslots;
  final Map<String, Timeslot> timeslotCache;
  final List<_SectionCandidate> candidateSections;
  final Map<int, List<FacultyAvailability>> facultyAvailMap;
  final List<Schedule> existingSchedules;

  const _GenerateData({
    required this.request,
    required this.validSubjects,
    required this.validFaculties,
    required this.validRooms,
    required this.validTimeslots,
    required this.timeslotCache,
    required this.candidateSections,
    required this.facultyAvailMap,
    required this.existingSchedules,
  });
}

class _FacultyTracking {
  final Map<int, double> assignments;
  final Map<int, Map<int, int>> timeslotUsage;
  final Map<int, Map<String, int>> yearLevelAssignments;

  const _FacultyTracking({
    required this.assignments,
    required this.timeslotUsage,
    required this.yearLevelAssignments,
  });
}

class _GenerationOutcome {
  final List<Schedule> generatedSchedules;
  final List<ScheduleConflict> conflicts;

  const _GenerationOutcome({
    required this.generatedSchedules,
    required this.conflicts,
  });
}

class _SectionGenerationResult {
  final bool allAssigned;
  final double maxComponentHours;

  const _SectionGenerationResult({
    required this.allAssigned,
    required this.maxComponentHours,
  });
}
