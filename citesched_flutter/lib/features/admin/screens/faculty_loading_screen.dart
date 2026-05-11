import 'package:citesched_client/citesched_client.dart';
import 'dart:async';
import 'dart:convert';

import 'package:citesched_flutter/core/utils/date_utils.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/features/admin/screens/faculty_load_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:citesched_flutter/core/providers/conflict_provider.dart';
import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';
import 'package:citesched_flutter/core/utils/error_handler.dart';

String _programDisplayLabel(Program program) {
  switch (program) {
    case Program.it:
      return 'BSIT';
    case Program.emc:
      return 'BSEMC';
    case Program.both:
      return 'Both IT and EMC';
  }
}

String _sectionDisplayLabel(Section section) {
  final code = section.sectionCode.trim();
  final program = _programDisplayLabel(section.program);
  if (code.toUpperCase().startsWith('$program -')) return code;
  return '$program - $code';
}

String _getDayAbbr(DayOfWeek day) {
  switch (day) {
    case DayOfWeek.mon:
      return 'Mon';
    case DayOfWeek.tue:
      return 'Tue';
    case DayOfWeek.wed:
      return 'Wed';
    case DayOfWeek.thu:
      return 'Thu';
    case DayOfWeek.fri:
      return 'Fri';
    case DayOfWeek.sat:
      return 'Sat';
    case DayOfWeek.sun:
      return 'Sun';
  }
}

const String _noPreferredTimeslotsMessage =
    'No preferred timeslots for this faculty';
const String _selectSubjectTypeTimeslotMessage =
    'Select subject types first before showing schedule timeslot dropdown below.';
const String _waitingForAiLabel = 'Waiting for AI...';
const double _generalEducationLectureHours = 1.5;

bool _requiresLaboratoryRoom(List<SubjectType> types) {
  return types.contains(SubjectType.laboratory) ||
      types.contains(SubjectType.blended);
}

bool _isBlendedSubject(List<SubjectType> types) {
  return types.contains(SubjectType.blended) ||
      (types.contains(SubjectType.lecture) &&
          types.contains(SubjectType.laboratory));
}

String _normalizeSubjectCode(String code) {
  return code.trim().replaceAll(RegExp(r'\s+'), '').toUpperCase();
}

bool _isGeneralEducationSubject(Subject subject) {
  return _normalizeSubjectCode(subject.code).startsWith('GE');
}

bool _isStudentAvailabilityExemptSubject(Subject subject) {
  final normalized = _normalizeSubjectCode(subject.code);
  return normalized.startsWith('GE') || normalized.startsWith('SF');
}

double _hoursForSubjectTypes(List<SubjectType> types) {
  final hasLecture = types.contains(SubjectType.lecture);
  final hasLaboratory = types.contains(SubjectType.laboratory);
  final hasBlended = types.contains(SubjectType.blended);

  if (hasBlended || (hasLecture && hasLaboratory)) return 5.0;
  if (hasLaboratory) return 3.0;
  if (hasLecture) return 2.0;
  return 0.0;
}

double _requiredHoursForSubject(
  Subject subject,
  List<SubjectType> effectiveTypes,
) {
  if (_isGeneralEducationSubject(subject) &&
      effectiveTypes.contains(SubjectType.lecture) &&
      !effectiveTypes.contains(SubjectType.laboratory)) {
    return _generalEducationLectureHours;
  }
  return _hoursForSubjectTypes(effectiveTypes);
}

double _unitsForSubjectTypes(List<SubjectType> types) {
  final hasLecture = types.contains(SubjectType.lecture);
  final hasLaboratory = types.contains(SubjectType.laboratory);
  final hasBlended = types.contains(SubjectType.blended);

  if (hasBlended || (hasLecture && hasLaboratory)) return 3.0;
  if (hasLaboratory) return 1.0;
  if (hasLecture) return 2.0;
  return 0.0;
}

double _requiredUnitsForSubject(
  Subject subject,
  List<SubjectType> effectiveTypes,
) {
  if (effectiveTypes.length == 1) {
    if (effectiveTypes.contains(SubjectType.lecture)) {
      return 2.0;
    }
    if (effectiveTypes.contains(SubjectType.laboratory)) {
      return 1.0;
    }
  }
  return _unitsForSubjectTypes(effectiveTypes);
}

const List<(int start, int end)> _preferredLectureWindows = [
  (8 * 60, 10 * 60),
  (10 * 60, 12 * 60),
  (13 * 60, 15 * 60),
  (15 * 60, 17 * 60),
  (17 * 60, 19 * 60),
];

const List<(int start, int end)> _preferredLabWindows = [
  (9 * 60, 12 * 60),
  (13 * 60, 16 * 60),
  (16 * 60, 19 * 60),
];

const List<(int start, int end)> _preferredGeLectureWindows = [
  (8 * 60, 9 * 60 + 30),
  (9 * 60 + 30, 11 * 60),
  (13 * 60, 14 * 60 + 30),
  (14 * 60 + 30, 16 * 60),
  (16 * 60, 17 * 60 + 30),
  (17 * 60 + 30, 19 * 60),
];

List<SubjectType> _expandedSubjectTypes(List<SubjectType> types) {
  final expanded = <SubjectType>{};
  if (types.contains(SubjectType.blended)) {
    expanded.add(SubjectType.lecture);
    expanded.add(SubjectType.laboratory);
  }
  for (final t in types) {
    if (t == SubjectType.blended) continue;
    expanded.add(t);
  }
  return expanded.toList();
}

List<String> _displaySubjectTypeLabels(List<SubjectType> types) {
  final expanded = _expandedSubjectTypes(types);
  if (expanded.isEmpty) return const [];
  return expanded.map((t) {
    switch (t) {
      case SubjectType.lecture:
        return 'LECTURE';
      case SubjectType.laboratory:
        return 'LAB';
      case SubjectType.blended:
        return 'BLENDED';
    }
  }).toList();
}

List<SubjectType> _effectiveAssignmentTypes(
  List<SubjectType> subjectTypes,
  SubjectType? overrideType,
) {
  if (_isBlendedSubject(subjectTypes)) {
    if (overrideType == SubjectType.lecture) {
      return const [SubjectType.lecture];
    }
    if (overrideType == SubjectType.laboratory) {
      return const [SubjectType.laboratory];
    }
  }
  return subjectTypes;
}

List<String> _componentTagsForTypes(List<SubjectType>? types) {
  if (types == null || types.isEmpty) return const ['lecture'];

  final hasLecture = types.contains(SubjectType.lecture);
  final hasLab = types.contains(SubjectType.laboratory);
  final hasBlended = types.contains(SubjectType.blended);

  if (hasBlended || (hasLecture && hasLab)) {
    return const ['lecture', 'laboratory'];
  }
  if (hasLab) return const ['laboratory'];
  return const ['lecture'];
}

bool _hasOverlappingAssignmentComponent(
  List<SubjectType>? existingTypes,
  List<SubjectType> newTypes,
) {
  final existingTags = _componentTagsForTypes(existingTypes).toSet();
  final newTags = _componentTagsForTypes(newTypes).toSet();
  return existingTags.intersection(newTags).isNotEmpty;
}

Widget _buildSubjectTypeDisplay({
  required List<SubjectType> types,
  required Color accentColor,
  required bool isDark,
}) {
  final labels = _displaySubjectTypeLabels(types);
  if (labels.isEmpty) return const SizedBox.shrink();

  final textColor = isDark ? Colors.grey[300] : Colors.grey[700];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Subject Type',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: labels
            .map(
              (label) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );
}

Widget _buildLoadTypeSelector({
  required bool show,
  required SubjectType? selected,
  required ValueChanged<SubjectType?> onChanged,
  required Color accentColor,
  required bool isDark,
  String? errorText,
}) {
  if (!show) return const SizedBox.shrink();
  final textColor = isDark ? Colors.grey[300] : Colors.grey[700];
  final hasError = errorText != null && errorText.isNotEmpty;
  final errorColor = Colors.red[700]!;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Assign As',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ChoiceChip(
            label: Text('LECTURE', style: GoogleFonts.poppins(fontSize: 12)),
            selected: selected == SubjectType.lecture,
            onSelected: (value) =>
                onChanged(value ? SubjectType.lecture : null),
            selectedColor: accentColor.withValues(alpha: 0.2),
            backgroundColor: hasError
                ? errorColor.withValues(alpha: 0.08)
                : null,
            side: BorderSide(
              color: hasError
                  ? errorColor
                  : (selected == SubjectType.lecture
                        ? accentColor.withValues(alpha: 0.4)
                        : (isDark ? Colors.white24 : Colors.black26)),
              width: hasError ? 1.5 : 1,
            ),
            labelStyle: GoogleFonts.poppins(
              color: hasError
                  ? errorColor
                  : selected == SubjectType.lecture
                  ? accentColor
                  : (isDark ? Colors.white : Colors.black87),
              fontWeight: selected == SubjectType.lecture
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
          ChoiceChip(
            label: Text('LAB', style: GoogleFonts.poppins(fontSize: 12)),
            selected: selected == SubjectType.laboratory,
            onSelected: (value) =>
                onChanged(value ? SubjectType.laboratory : null),
            selectedColor: accentColor.withValues(alpha: 0.2),
            backgroundColor: hasError
                ? errorColor.withValues(alpha: 0.08)
                : null,
            side: BorderSide(
              color: hasError
                  ? errorColor
                  : (selected == SubjectType.laboratory
                        ? accentColor.withValues(alpha: 0.4)
                        : (isDark ? Colors.white24 : Colors.black26)),
              width: hasError ? 1.5 : 1,
            ),
            labelStyle: GoogleFonts.poppins(
              color: hasError
                  ? errorColor
                  : selected == SubjectType.laboratory
                  ? accentColor
                  : (isDark ? Colors.white : Colors.black87),
              fontWeight: selected == SubjectType.laboratory
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
      if (errorText != null) ...[
        const SizedBox(height: 8),
        Text(
          errorText,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.red[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ],
  );
}

Widget _buildHighlightedTimeslotHint({
  required String message,
  required Color accentColor,
  required bool isDark,
}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: accentColor.withValues(alpha: isDark ? 0.45 : 0.30),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 18,
          color: accentColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accentColor,
            ),
          ),
        ),
      ],
    ),
  );
}

String _formatLoadValue(double value) {
  if (value == value.roundToDouble()) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(1);
}

int _timeOfDayToMinutes(TimeOfDay value) => value.hour * 60 + value.minute;

TimeOfDay _timeOfDayFromMinutes(int totalMinutes) {
  final normalized = totalMinutes.clamp(0, (24 * 60) - 1);
  return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
}

const List<double> _manualUnitOptions = [1.0, 2.0, 3.0];
const List<double> _manualHourOptions = [1.0, 2.0, 3.0];
const String _facultyLoadUnitOptionsPrefsKey =
    'faculty_loading_unit_options_v1';
const String _facultyLoadHourOptionsPrefsKey =
    'faculty_loading_hour_options_v1';
const String _deleteSelectedLoadOptionAction =
    '__delete_selected_load_option__';

double _normalizeLoadOption(double value) {
  if (value == value.roundToDouble()) {
    return value.roundToDouble();
  }
  return double.parse(value.toStringAsFixed(1));
}

List<double> _mergeLoadOptions(List<double> currentOptions, double value) {
  final normalizedValue = _normalizeLoadOption(value);
  final merged = <double>{
    ...currentOptions.map(_normalizeLoadOption),
    normalizedValue,
  }.toList()..sort();
  return merged;
}

Future<List<double>> _loadPersistedLoadOptions(
  String key,
  List<double> fallback,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return List<double>.from(fallback);
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return List<double>.from(fallback);
    }
    final parsed = decoded
        .map((value) => (value as num?)?.toDouble())
        .whereType<double>()
        .map(_normalizeLoadOption)
        .toSet()
        .toList()
      ..sort();
    if (parsed.isEmpty) {
      return List<double>.from(fallback);
    }
    return parsed;
  } catch (_) {
    return List<double>.from(fallback);
  }
}

Future<void> _persistLoadOptions(String key, List<double> options) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final normalized = options.map(_normalizeLoadOption).toSet().toList()
      ..sort();
    await prefs.setString(key, jsonEncode(normalized));
  } catch (_) {
    // Local persistence is best-effort only.
  }
}

double _nearestLoadOption(double value, List<double> options) {
  if (options.isEmpty) return value;
  return options.reduce(
    (best, candidate) =>
        (candidate - value).abs() < (best - value).abs() ? candidate : best,
  );
}

double _resolveSelectedLoadValue(
  double? currentValue,
  double suggestedValue,
  List<double> options,
) {
  if (currentValue != null && options.contains(currentValue)) {
    return currentValue;
  }
  if (options.contains(suggestedValue)) {
    return suggestedValue;
  }
  return _nearestLoadOption(suggestedValue, options);
}

class _FacultySummaryStats {
  final Faculty faculty;
  final int assignedSubjects;
  final double totalUnits;
  final double totalHours;
  final bool hasConflicts;
  final double remainingLoad;

  const _FacultySummaryStats({
    required this.faculty,
    required this.assignedSubjects,
    required this.totalUnits,
    required this.totalHours,
    required this.hasConflicts,
    required this.remainingLoad,
  });
}

bool _isRoomAllowedForTypes({
  required Room room,
  required List<SubjectType> loadTypes,
}) {
  if (_requiresLaboratoryRoom(loadTypes)) {
    return room.type == RoomType.laboratory;
  }
  return room.type == RoomType.lecture;
}

bool _isSupportedSchedulingRoom(Room room) {
  return room.type == RoomType.lecture || room.type == RoomType.laboratory;
}

String _facultyNameById(List<Faculty> list, int? id) {
  if (id == null) return 'Unknown faculty';
  for (final f in list) {
    if (f.id == id) return f.name;
  }
  return 'Faculty #$id';
}

String _subjectNameById(List<Subject> list, int? id) {
  if (id == null) return 'Unknown subject';
  for (final s in list) {
    if (s.id == id) return s.name;
  }
  return 'Subject #$id';
}

Program? _programForFacultyId(List<Faculty> faculties, int? facultyId) {
  if (facultyId == null) return null;
  for (final faculty in faculties) {
    if (faculty.id == facultyId) return faculty.program;
  }
  return null;
}

Program? _programForSubjectId(List<Subject> subjects, int? subjectId) {
  if (subjectId == null) return null;
  for (final subject in subjects) {
    if (subject.id == subjectId) return subject.program;
  }
  return null;
}

Program? _programFromStudentCourse(String? course) {
  if (course == null) return null;
  final normalized = course.trim().toUpperCase();
  if (normalized == 'BSIT' || normalized == 'IT') return Program.it;
  if (normalized == 'BSEMC' || normalized == 'EMC') return Program.emc;
  return null;
}

List<Subject> _subjectsAssignedToFaculty(
  List<Subject> subjects,
  int? facultyId,
) {
  if (facultyId == null) return const [];
  return subjects.where((s) => s.isActive && s.facultyId == facultyId).toList();
}

String _roomNameById(List<Room> list, int? id) {
  if (id == null) return 'Unknown room';
  for (final r in list) {
    if (r.id == id) return r.name;
  }
  return 'Room #$id';
}

String _sectionLabelById(
  List<Section> list,
  int? id,
  String? fallbackCode,
) {
  if (id != null) {
    for (final s in list) {
      if (s.id == id) return _sectionDisplayLabel(s);
    }
  }
  if (fallbackCode != null && fallbackCode.trim().isNotEmpty) {
    return fallbackCode.trim();
  }
  return 'Unknown section';
}

String _timeslotLabelById(List<Timeslot> list, int? id) {
  if (id == null) return 'TBA';
  for (final t in list) {
    if (t.id == id) {
      return CITESchedDateUtils.formatTimeslot(
        t.day,
        t.startTime,
        t.endTime,
      );
    }
  }
  return 'Timeslot #$id';
}

String _formatMinutes(int minutes) {
  final h = (minutes ~/ 60).clamp(0, 23).toString().padLeft(2, '0');
  final m = (minutes % 60).clamp(0, 59).toString().padLeft(2, '0');
  return '$h:$m';
}

int _timeToMinutes(String time) {
  var value = time.trim();
  if (value.isEmpty) return 0;

  final upper = value.toUpperCase();
  final hasAm = upper.contains('AM');
  final hasPm = upper.contains('PM');

  if (hasAm || hasPm) {
    final pieces = upper.split(' ');
    final clock = pieces.first;
    final clockParts = clock.split(':');
    if (clockParts.length < 2) return 0;
    var hour = int.tryParse(clockParts[0]) ?? 0;
    final minute =
        int.tryParse(clockParts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    if (hasPm && hour < 12) hour += 12;
    if (hasAm && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  final parts = value.split(':');
  if (parts.length < 2) return 0;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  return hour * 60 + minute;
}

class _TimeslotWindow {
  final DayOfWeek day;
  final String startTime;
  final String endTime;

  const _TimeslotWindow({
    required this.day,
    required this.startTime,
    required this.endTime,
  });
}

class _SectionAvailabilityWindow {
  final DayOfWeek day;
  final String startTime;
  final String endTime;

  const _SectionAvailabilityWindow({
    required this.day,
    required this.startTime,
    required this.endTime,
  });
}

class _TimeslotOption {
  final Timeslot slot;
  final String label;
  final bool isEnabled;
  final String? disabledReason;

  const _TimeslotOption({
    required this.slot,
    required this.label,
    this.isEnabled = true,
    this.disabledReason,
  });
}

class _TimeslotOptionsResult {
  final List<_TimeslotOption> options;
  final List<_TimeslotWindow> missing;

  const _TimeslotOptionsResult({
    required this.options,
    required this.missing,
  });
}

String _sectionAvailabilityRequiredMessage(String sectionCode) {
  final trimmedCode = sectionCode.trim();
  final label = trimmedCode.isEmpty ? 'this section' : 'section $trimmedCode';
  return 'Set the student section availability for $label first before assigning subjects.';
}

List<_SectionAvailabilityWindow> _sectionAvailabilityFromJson(String? rawJson) {
  if (rawJson == null || rawJson.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) return const [];

    final entries = <_SectionAvailabilityWindow>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final dayValue = item['day']?.toString();
      final startTime = item['startTime']?.toString();
      final endTime = item['endTime']?.toString();
      if (dayValue == null || startTime == null || endTime == null) continue;

      DayOfWeek? day;
      for (final value in DayOfWeek.values) {
        if (value.name == dayValue) {
          day = value;
          break;
        }
      }
      if (day == null) continue;

      entries.add(
        _SectionAvailabilityWindow(
          day: day,
          startTime: startTime,
          endTime: endTime,
        ),
      );
    }
    return entries;
  } catch (_) {
    return const [];
  }
}

bool _windowFitsSectionAvailability(
  _TimeslotWindow window,
  List<_SectionAvailabilityWindow> availability,
) {
  if (availability.isEmpty) return true;
  final start = _timeToMinutes(window.startTime);
  final end = _timeToMinutes(window.endTime);

  for (final entry in availability) {
    if (entry.day != window.day) continue;
    final entryStart = _timeToMinutes(entry.startTime);
    final entryEnd = _timeToMinutes(entry.endTime);
    if (start >= entryStart && end <= entryEnd) {
      return true;
    }
  }
  return false;
}

bool _windowFitsFacultyAvailability(
  _TimeslotWindow window,
  List<FacultyAvailability> availability,
) {
  if (availability.isEmpty) return true;
  final start = _timeToMinutes(window.startTime);
  final end = _timeToMinutes(window.endTime);

  for (final entry in availability) {
    if (entry.dayOfWeek != window.day) continue;
    final entryStart = _timeToMinutes(entry.startTime);
    final entryEnd = _timeToMinutes(entry.endTime);
    if (start >= entryStart && end <= entryEnd) {
      return true;
    }
  }
  return false;
}

bool _hasConfiguredSectionAvailability(Section? section) {
  return _sectionAvailabilityFromJson(section?.availabilityJson).isNotEmpty;
}

List<_TimeslotWindow> _windowsFromAvailability({
  required List<FacultyAvailability> availability,
  required int requiredMinutes,
}) {
  if (requiredMinutes <= 0) return const [];
  final windows = <_TimeslotWindow>[];
  final seen = <String>{};
  final preferredWindows = switch (requiredMinutes) {
    90 => _preferredGeLectureWindows,
    120 => _preferredLectureWindows,
    180 => _preferredLabWindows,
    _ => const <(int start, int end)>[],
  };

  for (final avail in availability) {
    final start = _timeToMinutes(avail.startTime);
    final end = _timeToMinutes(avail.endTime);
    if (end - start < requiredMinutes) continue;

    if (preferredWindows.isNotEmpty) {
      final eligibleWindows = <(int start, int end)>[];
      for (final window in preferredWindows) {
        if (window.$1 < start || window.$2 > end) continue;
        eligibleWindows.add(window);
      }
      final trailingStart = end - requiredMinutes;
      final trailingFits =
          trailingStart >= start &&
          !(trailingStart < 13 * 60 && end > 12 * 60);
      final replacesLastPreferred =
          trailingFits &&
          eligibleWindows.isNotEmpty &&
          (eligibleWindows.last.$1 != trailingStart ||
              eligibleWindows.last.$2 != end);

      if (replacesLastPreferred) {
        eligibleWindows.removeLast();
      }

      for (final window in eligibleWindows) {
        final key =
            '${avail.dayOfWeek.name}|${_formatMinutes(window.$1)}|${_formatMinutes(window.$2)}';
        if (!seen.add(key)) continue;
        windows.add(
          _TimeslotWindow(
            day: avail.dayOfWeek,
            startTime: _formatMinutes(window.$1),
            endTime: _formatMinutes(window.$2),
          ),
        );
      }

      if (trailingFits) {
        final key =
            '${avail.dayOfWeek.name}|${_formatMinutes(trailingStart)}|${_formatMinutes(end)}';
        if (seen.add(key)) {
          windows.add(
            _TimeslotWindow(
              day: avail.dayOfWeek,
              startTime: _formatMinutes(trailingStart),
              endTime: _formatMinutes(end),
            ),
          );
        }
      }
      continue;
    }

    for (var s = start; s + requiredMinutes <= end; s += requiredMinutes) {
      final e = s + requiredMinutes;
      if (s < 13 * 60 && e > 12 * 60) continue;
      final key =
          '${avail.dayOfWeek.name}|${_formatMinutes(s)}|${_formatMinutes(e)}';
      if (!seen.add(key)) continue;
      windows.add(
        _TimeslotWindow(
          day: avail.dayOfWeek,
          startTime: _formatMinutes(s),
          endTime: _formatMinutes(e),
        ),
      );
    }
  }
  return windows;
}

_TimeslotOptionsResult _buildTimeslotOptionsFromAvailability({
  required List<FacultyAvailability> availability,
  required List<_SectionAvailabilityWindow> sectionAvailability,
  required List<Timeslot> timeslots,
  required double requiredHours,
  required String typeLabel,
  required List<Schedule> schedules,
  required int? currentScheduleId,
  required int? facultyId,
  required int? roomId,
  required int? selectedTimeslotId,
  required List<Faculty> facultyList,
  required List<SubjectType> effectiveTypes,
}) {
  final requiredMinutes = (requiredHours * 60).round();
  final windows =
      _windowsFromAvailability(
        availability: availability,
        requiredMinutes: requiredMinutes,
      ).where((window) {
        return _windowFitsSectionAvailability(window, sectionAvailability);
      }).toList();

  final options = <_TimeslotOption>[];
  final missing = <_TimeslotWindow>[];

  for (final window in windows) {
    final match = timeslots.firstWhere(
      (t) =>
          t.day == window.day &&
          t.startTime == window.startTime &&
          t.endTime == window.endTime,
      orElse: () => Timeslot(
        day: window.day,
        startTime: window.startTime,
        endTime: window.endTime,
        label: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final isExisting = match.id != null;
    if (!isExisting) {
      missing.add(window);
      continue;
    }

    final baseLabel = CITESchedDateUtils.formatTimeslot(
      window.day,
      window.startTime,
      window.endTime,
    );
    final conflictMessage = _timeslotOccupancyMessage(
      schedules: schedules,
      facultyList: facultyList,
      currentScheduleId: currentScheduleId,
      selectedFacultyId: facultyId,
      selectedRoomId: roomId,
      timeslotId: match.id,
      candidateTimeslot: match,
      timeslots: timeslots,
      effectiveTypes: effectiveTypes,
    );
    options.add(
      _TimeslotOption(
        slot: match,
        label: '$baseLabel - $typeLabel',
        isEnabled: conflictMessage == null,
        disabledReason: conflictMessage,
      ),
    );
  }

  if (selectedTimeslotId != null &&
      !options.any((option) => option.slot.id == selectedTimeslotId)) {
    Timeslot? selectedTimeslot;
    for (final timeslot in timeslots) {
      if (timeslot.id == selectedTimeslotId) {
        selectedTimeslot = timeslot;
        break;
      }
    }

    if (selectedTimeslot != null) {
      final selectedWindow = _TimeslotWindow(
        day: selectedTimeslot.day,
        startTime: selectedTimeslot.startTime,
        endTime: selectedTimeslot.endTime,
      );
      final slotMinutes =
          _timeToMinutes(selectedTimeslot.endTime) -
          _timeToMinutes(selectedTimeslot.startTime);
      final fitsAvailability = _windowFitsFacultyAvailability(
        selectedWindow,
        availability,
      );
      final fitsSection = _windowFitsSectionAvailability(
        selectedWindow,
        sectionAvailability,
      );

      if (slotMinutes == requiredMinutes && fitsAvailability && fitsSection) {
        final baseLabel = CITESchedDateUtils.formatTimeslot(
          selectedTimeslot.day,
          selectedTimeslot.startTime,
          selectedTimeslot.endTime,
        );
        final conflictMessage = _timeslotOccupancyMessage(
          schedules: schedules,
          facultyList: facultyList,
          currentScheduleId: currentScheduleId,
          selectedFacultyId: facultyId,
          selectedRoomId: roomId,
          timeslotId: selectedTimeslot.id,
          candidateTimeslot: selectedTimeslot,
          timeslots: timeslots,
          effectiveTypes: effectiveTypes,
        );
        options.add(
          _TimeslotOption(
            slot: selectedTimeslot,
            label: '$baseLabel - $typeLabel',
            isEnabled: conflictMessage == null,
            disabledReason: conflictMessage,
          ),
        );
      }
    }
  }

  return _TimeslotOptionsResult(options: options, missing: missing);
}

Future<void> _createTimeslotsFromWindows({
  required WidgetRef ref,
  required BuildContext context,
  required List<_TimeslotWindow> windows,
}) async {
  if (windows.isEmpty) {
    AppErrorDialog.show(context, 'No timeslot windows to create.');
    return;
  }

  try {
    final existing = await client.admin.getAllTimeslots();
    final existingKeys = existing
        .map((t) => '${t.day.name}|${t.startTime}|${t.endTime}')
        .toSet();

    var createdCount = 0;
    for (final window in windows) {
      final key = '${window.day.name}|${window.startTime}|${window.endTime}';
      if (existingKeys.contains(key)) continue;
      final label =
          '${_getDayAbbr(window.day)} ${window.startTime}-${window.endTime}';
      await client.admin.createTimeslot(
        Timeslot(
          day: window.day,
          startTime: window.startTime,
          endTime: window.endTime,
          label: label,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      createdCount += 1;
    }

    ref.invalidate(timeslotsProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            createdCount > 0
                ? 'Created $createdCount timeslot(s).'
                : 'All matching timeslots already exist.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      AppErrorDialog.show(context, e);
    }
  }
}

Future<Timeslot> _findOrCreateMatchingTimeslot(Timeslot draft) async {
  final existing = await client.admin.getAllTimeslots();
  for (final timeslot in existing) {
    if (timeslot.day == draft.day &&
        timeslot.startTime == draft.startTime &&
        timeslot.endTime == draft.endTime) {
      return timeslot;
    }
  }

  try {
    return await client.admin.createTimeslot(
      Timeslot(
        day: draft.day,
        startTime: draft.startTime,
        endTime: draft.endTime,
        label: draft.label,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  } catch (_) {
    final refreshed = await client.admin.getAllTimeslots();
    for (final timeslot in refreshed) {
      if (timeslot.day == draft.day &&
          timeslot.startTime == draft.startTime &&
          timeslot.endTime == draft.endTime) {
        return timeslot;
      }
    }
    rethrow;
  }
}

Future<List<FacultyAvailability>> _loadFacultyAvailability(
  WidgetRef ref,
  int? facultyId,
) async {
  if (facultyId == null) return const <FacultyAvailability>[];
  final cached = ref.read(facultyAvailabilityProvider(facultyId));
  final cachedList = cached.maybeWhen(
    data: (list) => list,
    orElse: () => null,
  );
  if (cachedList != null) return cachedList;
  return client.admin.getFacultyAvailability(facultyId);
}

String _timeslotWindowsKey(List<_TimeslotWindow> windows) {
  return windows
      .map(
        (window) => '${window.day.name}|${window.startTime}|${window.endTime}',
      )
      .join('||');
}

bool _matchesSection(
  Schedule schedule,
  int? sectionId,
  String? sectionCodeFallback,
) {
  if (sectionId != null && schedule.sectionId != null) {
    return schedule.sectionId == sectionId;
  }
  if (sectionCodeFallback != null && sectionCodeFallback.trim().isNotEmpty) {
    return schedule.section.trim() == sectionCodeFallback.trim();
  }
  return false;
}

bool _isCurrentSchedule(
  Schedule schedule,
  int? currentScheduleId,
) {
  return currentScheduleId != null && schedule.id == currentScheduleId;
}

bool _isSameSubjectDifferentFaculty({
  required bool sameSection,
  required Schedule schedule,
  required int subjectId,
  required int facultyId,
  required List<SubjectType> effectiveTypes,
}) {
  return sameSection &&
      schedule.subjectId == subjectId &&
      schedule.facultyId != facultyId &&
      _hasOverlappingAssignmentComponent(schedule.loadTypes, effectiveTypes);
}

bool _isSameAssignment({
  required bool sameSection,
  required Schedule schedule,
  required int subjectId,
  required int facultyId,
  required List<SubjectType> effectiveTypes,
}) {
  return sameSection &&
      schedule.subjectId == subjectId &&
      schedule.facultyId == facultyId &&
      _hasOverlappingAssignmentComponent(schedule.loadTypes, effectiveTypes);
}

bool _isFacultyTimeConflict({
  required bool isAutoAssign,
  required Schedule schedule,
  required int facultyId,
  required int? timeslotId,
}) {
  return !isAutoAssign &&
      timeslotId != null &&
      schedule.facultyId == facultyId &&
      schedule.timeslotId == timeslotId;
}

bool _isRoomTimeConflict({
  required bool isAutoAssign,
  required Schedule schedule,
  required int? roomId,
  required int? timeslotId,
}) {
  return !isAutoAssign &&
      roomId != null &&
      timeslotId != null &&
      schedule.roomId == roomId &&
      schedule.timeslotId == timeslotId;
}

bool _isSectionTimeConflict({
  required bool isAutoAssign,
  required Schedule schedule,
  required int? sectionId,
  required String? sectionCodeFallback,
  required int? timeslotId,
}) {
  return !isAutoAssign &&
      timeslotId != null &&
      schedule.timeslotId == timeslotId &&
      _matchesSection(schedule, sectionId, sectionCodeFallback);
}

String? _detectAssignmentConflict({
  required List<Schedule> schedules,
  required int? currentScheduleId,
  required int facultyId,
  required int subjectId,
  required int? sectionId,
  required String? sectionCodeFallback,
  required int? roomId,
  required int? timeslotId,
  required bool isAutoAssign,
  required List<Faculty> facultyList,
  required List<Subject> subjectList,
  required List<Room> roomList,
  required List<Timeslot> timeslotList,
  required List<Section> sectionList,
  required List<SubjectType> effectiveTypes,
}) {
  final facultyName = _facultyNameById(facultyList, facultyId);
  final subjectName = _subjectNameById(subjectList, subjectId);
  final sectionLabel = _sectionLabelById(
    sectionList,
    sectionId,
    sectionCodeFallback,
  );
  final timeslotLabel = _timeslotLabelById(timeslotList, timeslotId);
  final roomLabel = _roomNameById(roomList, roomId);

  for (final schedule in schedules) {
    if (_isCurrentSchedule(schedule, currentScheduleId)) {
      continue;
    }

    final sameSection = _matchesSection(
      schedule,
      sectionId,
      sectionCodeFallback,
    );

    if (_isSameSubjectDifferentFaculty(
      sameSection: sameSection,
      schedule: schedule,
      subjectId: subjectId,
      facultyId: facultyId,
      effectiveTypes: effectiveTypes,
    )) {
      final otherFaculty = _facultyNameById(facultyList, schedule.facultyId);
      return 'Subject $subjectName is already assigned to $otherFaculty for $sectionLabel.';
    }

    if (_isSameAssignment(
      sameSection: sameSection,
      schedule: schedule,
      subjectId: subjectId,
      facultyId: facultyId,
      effectiveTypes: effectiveTypes,
    )) {
      return 'This assignment already exists for $facultyName in $sectionLabel.';
    }

    if (_isFacultyTimeConflict(
      isAutoAssign: isAutoAssign,
      schedule: schedule,
      facultyId: facultyId,
      timeslotId: timeslotId,
    )) {
      return '$facultyName already has a class at $timeslotLabel.';
    }

    if (_isRoomTimeConflict(
      isAutoAssign: isAutoAssign,
      schedule: schedule,
      roomId: roomId,
      timeslotId: timeslotId,
    )) {
      return 'Room $roomLabel is already booked at $timeslotLabel.';
    }

    if (_isSectionTimeConflict(
      isAutoAssign: isAutoAssign,
      schedule: schedule,
      sectionId: sectionId,
      sectionCodeFallback: sectionCodeFallback,
      timeslotId: timeslotId,
    )) {
      return 'Section $sectionLabel already has a class at $timeslotLabel. '
          'A section cannot be scheduled in two places at the same time.';
    }
  }

  return null;
}

String? _timeslotOccupancyMessage({
  required List<Schedule> schedules,
  required List<Faculty> facultyList,
  required int? currentScheduleId,
  required int? selectedFacultyId,
  required int? selectedRoomId,
  required int? timeslotId,
  required Timeslot candidateTimeslot,
  required List<Timeslot> timeslots,
  required List<SubjectType> effectiveTypes,
}) {
  if (timeslotId == null) {
    return null;
  }

  final isLaboratory = effectiveTypes.contains(SubjectType.laboratory);
  final sameInstructorOccupants = <Schedule>[];
  final sameRoomOccupants = <Schedule>[];
  final timeslotById = {for (final timeslot in timeslots) timeslot.id!: timeslot};

  for (final schedule in schedules) {
    if (_isCurrentSchedule(schedule, currentScheduleId)) {
      continue;
    }
    final scheduleTimeslot =
        schedule.timeslot ??
        (schedule.timeslotId != null ? timeslotById[schedule.timeslotId!] : null);
    if (scheduleTimeslot == null ||
        !_timeslotsOverlap(scheduleTimeslot, candidateTimeslot)) {
      continue;
    }
    if (!schedule.isActive) {
      continue;
    }
    if (selectedFacultyId != null && schedule.facultyId == selectedFacultyId) {
      sameInstructorOccupants.add(schedule);
    }
    if (isLaboratory &&
        selectedRoomId != null &&
        schedule.roomId == selectedRoomId) {
      sameRoomOccupants.add(schedule);
    }
  }

  if (sameInstructorOccupants.isNotEmpty && selectedFacultyId != null) {
    final facultyName = _facultyNameById(facultyList, selectedFacultyId);
    return '$facultyName already has a class at this time.';
  }

  if (!isLaboratory || sameRoomOccupants.isEmpty) {
    return null;
  }

  final facultyNames =
      sameRoomOccupants
          .map((schedule) => _facultyNameById(facultyList, schedule.facultyId))
          .toSet()
          .toList()
        ..sort();

  if (facultyNames.isEmpty) {
    return 'This availability window is already taken.';
  }

  return 'Taken by ${facultyNames.join(', ')}.';
}

bool _timeslotsOverlap(Timeslot a, Timeslot b) {
  if (a.day != b.day) return false;
  final aStart = _timeToMinutes(a.startTime);
  final aEnd = _timeToMinutes(a.endTime);
  final bStart = _timeToMinutes(b.startTime);
  final bEnd = _timeToMinutes(b.endTime);
  return aStart < bEnd && bStart < aEnd;
}

bool _facultyMatchesSearch(Faculty faculty, String searchQuery) {
  if (searchQuery.isEmpty) {
    return true;
  }
  return faculty.name.toLowerCase().contains(searchQuery.toLowerCase());
}

double _scheduleHours(Schedule schedule, Map<int, Timeslot> timeslotMap) {
  if (schedule.hours != null) {
    return schedule.hours!;
  }
  final timeslotId = schedule.timeslotId;
  if (timeslotId == null) {
    return 0;
  }
  final t = timeslotMap[timeslotId];
  if (t == null) {
    return 0;
  }
  try {
    final startParts = t.startTime.split(':');
    final endParts = t.endTime.split(':');
    final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    return (endMin - startMin) / 60.0;
  } catch (_) {
    return 0;
  }
}

bool _hasFacultySummaryConflict({
  required Faculty faculty,
  required Schedule schedule,
  required AsyncValue<List<ScheduleConflict>> allConflicts,
}) {
  return allConflicts.maybeWhen(
    data: (conflicts) => conflicts.any(
      (c) =>
          c.facultyId == faculty.id ||
          c.conflictingScheduleId == schedule.id ||
          c.scheduleId == schedule.id,
    ),
    orElse: () => false,
  );
}

List<_FacultySummaryStats> _buildFacultySummaryStats({
  required List<Faculty> facultyList,
  required List<Schedule> schedules,
  required Map<int, Subject> subjectMap,
  required Map<int, Timeslot> timeslotMap,
  required AsyncValue<List<ScheduleConflict>> allConflicts,
  required String searchQuery,
}) {
  return facultyList
      .where((faculty) => _facultyMatchesSearch(faculty, searchQuery))
      .map((faculty) {
        final assignments = schedules
            .where((s) => s.facultyId == faculty.id)
            .toList();

        var totalUnits = 0.0;
        var totalHours = 0.0;
        var hasConflicts = false;

        for (final schedule in assignments) {
          totalUnits +=
              schedule.units ??
              (subjectMap[schedule.subjectId]?.units.toDouble() ?? 0.0);
          totalHours += _scheduleHours(schedule, timeslotMap);
          hasConflicts =
              hasConflicts ||
              _hasFacultySummaryConflict(
                faculty: faculty,
                schedule: schedule,
                allConflicts: allConflicts,
              );
        }

        return _FacultySummaryStats(
          faculty: faculty,
          assignedSubjects: assignments.length,
          totalUnits: totalUnits,
          totalHours: totalHours,
          hasConflicts: hasConflicts,
          remainingLoad: (faculty.maxLoad ?? 0) - totalUnits,
        );
      })
      .toList();
}

Widget _buildFacultySummaryTable({
  required BuildContext context,
  required List<_FacultySummaryStats> facultyStats,
  required List<Schedule> schedules,
  required bool isDark,
  required Color headerBg,
  required Color rowBgA,
  required Color rowBgB,
  required Color dividerColor,
}) {
  return Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 28,
                    horizontalMargin: 16,
                    headingRowHeight: 44,
                    dataRowMinHeight: 52,
                    dataRowMaxHeight: 60,
                    showCheckboxColumn: false,
                    showBottomBorder: true,
                    dividerThickness: 0.6,
                    headingRowColor: WidgetStateProperty.all(headerBg),
                    headingTextStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.85)
                          : Colors.grey[700],
                      letterSpacing: 0.8,
                    ),
                    dataTextStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black87,
                    ),
                    border: TableBorder(
                      horizontalInside: BorderSide(color: dividerColor),
                      bottom: BorderSide(color: dividerColor),
                      top: BorderSide(color: dividerColor),
                    ),
                    columns: [
                      DataColumn(
                        label: Text(
                          'FACULTY NAME',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'SUBJECTS',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'UNITS',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'HOURS',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'REMAINING',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'STATUS',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    rows: facultyStats.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stats = entry.value;
                      final faculty = stats.faculty;
                      final hasConflict = stats.hasConflicts;
                      final remainingLoad = stats.remainingLoad;
                      return DataRow(
                        color: WidgetStateProperty.all(
                          index.isEven ? rowBgA : rowBgB,
                        ),
                        onSelectChanged: (_) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FacultyLoadDetailsScreen(
                                faculty: faculty,
                                initialSchedules: schedules
                                    .where((s) => s.facultyId == faculty.id)
                                    .toList(),
                              ),
                            ),
                          );
                        },
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                if (hasConflict)
                                  const Icon(
                                    Icons.warning_rounded,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                if (hasConflict) const SizedBox(width: 4),
                                Text(
                                  faculty.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(Text(stats.assignedSubjects.toString())),
                          DataCell(Text(stats.totalUnits.toString())),
                          DataCell(
                            Text('${stats.totalHours.toStringAsFixed(1)}h'),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: remainingLoad < 0
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                remainingLoad.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  color: remainingLoad < 0
                                      ? Colors.red
                                      : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            hasConflict
                                ? const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  )
                                : const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                  ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildConflictList(List<String> conflicts) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Conflict Details:',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 12),
      ...conflicts.take(5).map((conflict) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      if (conflicts.length > 5)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '... and ${conflicts.length - 5} more conflicts',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ),
    ],
  );
}

Widget _buildConflictBannerCard({
  required bool hasConflicts,
  required bool showConflictDetails,
  required VoidCallback? onTap,
  required List<String> conflicts,
}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    decoration: BoxDecoration(
      color: hasConflicts ? Colors.red[50] : Colors.green[50],
      borderRadius: BorderRadius.circular(12),
      border: Border(
        left: BorderSide(
          color: hasConflicts ? Colors.red : Colors.green,
          width: 4,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: (hasConflicts ? Colors.red : Colors.green).withValues(
            alpha: 0.1,
          ),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hasConflicts
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasConflicts
                        ? Icons.warning_rounded
                        : Icons.check_circle_rounded,
                    color: hasConflicts ? Colors.red : Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasConflicts
                            ? 'Schedule Conflicts Detected'
                            : 'No Conflicts Detected',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasConflicts
                              ? Colors.red[900]
                              : Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasConflicts
                            ? '${conflicts.length} conflict(s) found. Click to view details.'
                            : 'All faculty schedules are properly assigned without conflicts.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: hasConflicts
                              ? Colors.red[700]
                              : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasConflicts)
                  Icon(
                    showConflictDetails
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.red[700],
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
        if (hasConflicts && showConflictDetails)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: _buildConflictList(conflicts),
          ),
      ],
    ),
  );
}

// ─── Error Helper Functions ────────────────────────────────────────────

/// Strips boilerplate prefixes from server-side exception messages.
/// e.g. "Exception: Schedule validation failed: Faculty is already assigned..."
///  -> "Faculty is already assigned..."
String _parseServerError(Object error) {
  if (error is ServerpodClientException) {
    final message = error.message.trim();
    if (message.isNotEmpty &&
        message.toLowerCase() != 'internal server error') {
      return message;
    }

    switch (error.statusCode) {
      case 400:
        return 'The request is invalid. Please review the assignment details and try again.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to update faculty loading.';
      case 404:
        return 'The schedule record could not be found.';
      case 500:
        return 'The server could not save this assignment. Please review the validation details and try again.';
    }
  }

  var msg = error.toString();
  if (msg.startsWith('ServerpodClientException: ')) {
    msg = msg.substring('ServerpodClientException: '.length);
  }
  msg = msg.replaceFirst(RegExp(r',?\s*statusCode\s*=\s*\d+\s*$'), '');
  if (msg.startsWith('Exception: ')) msg = msg.substring('Exception: '.length);
  if (msg.startsWith('Schedule validation failed: ')) {
    msg = msg.substring('Schedule validation failed: '.length);
  }
  return msg.trim().isNotEmpty ? msg.trim() : 'An unexpected error occurred.';
}

String _formatScheduleConflict(ScheduleConflict conflict) {
  final details = conflict.details?.trim();
  if (details != null && details.isNotEmpty && details != conflict.message) {
    return '${conflict.message}: $details';
  }
  return conflict.message;
}

Future<String?> _validateScheduleWithServer(Schedule schedule) async {
  final conflicts = await client.admin.validateSchedule(schedule);
  if (conflicts.isEmpty) return null;
  return conflicts.map(_formatScheduleConflict).join('; ');
}

/// Shows a styled conflict / validation error dialog.
/// Splits on '; ' so each conflict is shown as a separate bullet.
void _showConflictErrorDialog(BuildContext context, String message) {
  final parts = message.split('; ').where((p) => p.trim().isNotEmpty).toList();

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Color(0xFF8B0000),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Scheduling Conflict',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The assignment could not be saved due to the following conflict(s):',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ...parts.map(
            (part) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 16,
                      color: Color(0xFF8B0000),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      part.trim(),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'OK, Got It',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B0000),
            ),
          ),
        ),
      ],
    ),
  );
}

class FacultyLoadingScreen extends ConsumerStatefulWidget {
  final Schedule? initialEditSchedule;

  const FacultyLoadingScreen({super.key, this.initialEditSchedule});

  @override
  ConsumerState<FacultyLoadingScreen> createState() =>
      _FacultyLoadingScreenState();
}

class _FacultyLoadingScreenState extends ConsumerState<FacultyLoadingScreen> {
  bool _openedInitialEdit = false;
  String _searchQuery = '';
  String? _selectedFaculty;
  bool _isShowingArchived = false;
  bool _showConflictDetails = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedScheduleIds = {};
  Set<int>? _expandedFacultySummaryIds;
  Set<int>? _expandedCompactScheduleIds;

  Set<int> get _safeExpandedFacultySummaryIds =>
      _expandedFacultySummaryIds ??= <int>{};
  Set<int> get _safeExpandedCompactScheduleIds =>
      _expandedCompactScheduleIds ??= <int>{};

  // Color scheme matching admin sidebar
  final Color maroonColor = const Color(0xFF720045);

  bool get isMobile => ResponsiveHelper.isMobile(context);
  final Color innerMenuBg = const Color(0xFF7b004f);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncSelectedSchedules(List<Schedule> schedules) {
    final visibleIds = schedules
        .map((schedule) => schedule.id)
        .whereType<int>()
        .toSet();
    final intersection = _selectedScheduleIds.intersection(visibleIds);
    if (intersection.length != _selectedScheduleIds.length) {
      _selectedScheduleIds
        ..clear()
        ..addAll(intersection);
    }
  }

  void _toggleSelectAllSchedules(
    List<Schedule> schedules,
    bool? isSelected,
  ) {
    final shouldSelect = isSelected ?? false;
    setState(() {
      _selectedScheduleIds.clear();
      if (shouldSelect) {
        _selectedScheduleIds.addAll(
          schedules.map((schedule) => schedule.id).whereType<int>(),
        );
      }
    });
  }

  void _toggleScheduleSelection(int scheduleId, bool? isSelected) {
    setState(() {
      if (isSelected ?? false) {
        _selectedScheduleIds.add(scheduleId);
      } else {
        _selectedScheduleIds.remove(scheduleId);
      }
    });
  }

  void _toggleCompactScheduleExpanded(int? scheduleId) {
    if (scheduleId == null) return;
    setState(() {
      if (_safeExpandedCompactScheduleIds.contains(scheduleId)) {
        _safeExpandedCompactScheduleIds.remove(scheduleId);
      } else {
        _safeExpandedCompactScheduleIds.add(scheduleId);
      }
    });
  }

  void _toggleFacultySummaryExpanded(int? facultyId) {
    if (facultyId == null) return;
    setState(() {
      if (_safeExpandedFacultySummaryIds.contains(facultyId)) {
        _safeExpandedFacultySummaryIds.remove(facultyId);
      } else {
        _safeExpandedFacultySummaryIds.add(facultyId);
      }
    });
  }

  Future<void> _archiveSelectedSchedules(List<Schedule> schedules) async {
    final selected = schedules
        .where((schedule) => _selectedScheduleIds.contains(schedule.id))
        .toList();
    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Selected Assignments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Archive ${selected.length} selected schedule assignments?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Archive', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        for (final schedule in selected) {
          await client.admin.updateSchedule(schedule.copyWith(isActive: false));
        }
        _selectedScheduleIds.clear();
        notifyScheduleDataChanged(ref);
        ref.invalidate(schedulesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected assignments archived successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          AppErrorDialog.show(context, e);
        }
      }
    }
  }

  Future<void> _deleteSelectedSchedules(List<Schedule> schedules) async {
    final selected = schedules
        .where((schedule) => _selectedScheduleIds.contains(schedule.id))
        .toList();
    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Selected Assignments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'PERMANENTLY delete ${selected.length} selected assignments? This cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete Permanently', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        for (final schedule in selected) {
          await client.admin.deleteSchedule(schedule.id!);
        }
        _selectedScheduleIds.clear();
        notifyScheduleDataChanged(ref);
        ref.invalidate(schedulesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected assignments deleted permanently'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          AppErrorDialog.show(context, e);
        }
      }
    }
  }

  void _restoreSchedule(Schedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restore Assignment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Restore this schedule assignment to active lists?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Restore', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final restored = schedule.copyWith(isActive: true);
        await client.admin.updateSchedule(restored);
        notifyScheduleDataChanged(ref);
        ref.invalidate(schedulesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment restored successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          AppErrorDialog.show(context, e);
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_openedInitialEdit) return;
    final initialSchedule = widget.initialEditSchedule;
    if (initialSchedule == null) return;
    _openedInitialEdit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showEditAssignmentModal(initialSchedule);
    });
  }

  void _showNewAssignmentModal() {
    showDialog(
      context: context,
      builder: (context) => _NewAssignmentModal(
        maroonColor: maroonColor,
        onSuccess: () {
          notifyScheduleDataChanged(ref);
          ref.invalidate(schedulesProvider);
        },
      ),
    );
  }

  void _showEditAssignmentModal(Schedule schedule) {
    showDialog(
      context: context,
      builder: (context) => _EditAssignmentModal(
        schedule: schedule,
        maroonColor: maroonColor,
        onSuccess: () {
          notifyScheduleDataChanged(ref);
          ref.invalidate(schedulesProvider);
        },
      ),
    );
  }

  void _showAssignmentDetailsDialog({
    required Schedule schedule,
    Faculty? faculty,
    Subject? subject,
    Room? room,
    Timeslot? timeslot,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Assignment Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Faculty', faculty?.name ?? 'Unknown'),
              _detailRow('Faculty ID', faculty?.facultyId ?? '-'),
              const SizedBox(height: 8),
              _detailRow('Subject', subject?.name ?? 'Unknown'),
              _detailRow('Code', subject?.code ?? '-'),
              _detailRow(
                'Year Level',
                subject?.yearLevel?.toString() ?? '-',
              ),
              const SizedBox(height: 8),
              _detailRow('Section', schedule.section),
              _detailRow('Load Type', _getLoadTypeText(schedule.loadTypes)),
              _detailRow(
                'Units',
                schedule.units?.toString() ?? subject?.units.toString() ?? '-',
              ),
              _detailRow('Hours', schedule.hours?.toString() ?? '-'),
              const SizedBox(height: 8),
              _detailRow('Room', room?.name ?? _waitingForAiLabel),
              _detailRow(
                'Timeslot',
                timeslot != null
                    ? '${_getDayAbbr(timeslot.day)} ${timeslot.startTime}-${timeslot.endTime}'
                    : _waitingForAiLabel,
              ),
              const SizedBox(height: 8),
              _detailRow(
                'Status',
                (schedule.roomId == -1 || schedule.timeslotId == -1)
                    ? 'Pending AI'
                    : 'Scheduled',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _archiveSchedule(Schedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Assignment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to archive this schedule assignment?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Archive', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final archived = schedule.copyWith(isActive: false);
        await client.admin.updateSchedule(archived);
        notifyScheduleDataChanged(ref);
        ref.invalidate(schedulesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment archived successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          AppErrorDialog.show(context, e);
        }
      }
    }
  }

  void _deleteSchedule(Schedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Assignment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this schedule assignment?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await client.admin.deleteSchedule(schedule.id!);
        notifyScheduleDataChanged(ref);
        ref.invalidate(schedulesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assignment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          AppErrorDialog.show(context, e);
        }
      }
    }
  }

  Widget _buildViewToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleOption('Active', false, isDark),
          _buildToggleOption('Archived', true, isDark),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, bool isArchived, bool isDark) {
    final isSelected = _isShowingArchived == isArchived;
    return GestureDetector(
      onTap: () {
        setState(() {
          _isShowingArchived = isArchived;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? maroonColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: maroonColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(schedulesProvider);
    final facultyAsync = ref.watch(facultyListProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);
    final allConflicts = ref.watch(allConflictsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    return DefaultTabController(
      length: 2,
      child: Builder(
        builder: (context) {
          final tabController = DefaultTabController.of(context);

          return AnimatedBuilder(
            animation: tabController,
            builder: (context, _) {
              final selectedTabIndex = tabController.index;

              return Scaffold(
                backgroundColor: bgColor,
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    final useStackedHeader = constraints.maxWidth < 1100;

                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: useStackedHeader ? 12 : 24,
                        vertical: useStackedHeader ? 16 : 32,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderSection(useStackedHeader),
                            const SizedBox(height: 24),
                            _buildConflictBanner(
                              schedulesAsync,
                              facultyAsync,
                              allConflicts,
                            ),
                            const SizedBox(height: 20),
                            _buildSearchAndFilterRow(
                              isDark: isDark,
                              isMobile: useStackedHeader,
                              facultyAsync: facultyAsync,
                            ),
                            const SizedBox(height: 24),
                            _buildTabBar(isDark, useStackedHeader),
                            const SizedBox(height: 24),
                            selectedTabIndex == 0
                                ? _buildFacultySummaryView(
                                    schedulesAsync,
                                    facultyAsync,
                                    subjectsAsync,
                                    roomsAsync,
                                    timeslotsAsync,
                                    isDark,
                                  )
                                : _buildSubjectAssignmentsView(
                                    schedulesAsync,
                                    facultyAsync,
                                    subjectsAsync,
                                    roomsAsync,
                                    timeslotsAsync,
                                    isDark,
                                    maroonColor,
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(bool useStackedHeader) {
    return Container(
      padding: EdgeInsets.all(useStackedHeader ? 20 : 32),
      decoration: BoxDecoration(
        color: maroonColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: maroonColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: useStackedHeader
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Icon(
                        Icons.assignment_ind_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Faculty Loading',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage faculty schedule assignments and workload',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _showNewAssignmentModal,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Assign Subject',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: maroonColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment_ind_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Faculty Loading',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage faculty schedule assignments and workload',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _showNewAssignmentModal,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Assign Subject',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: maroonColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilterRow({
    required bool isDark,
    required bool isMobile,
    required AsyncValue<List<Faculty>> facultyAsync,
  }) {
    final searchBar = Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.transparent : Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: maroonColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                cursorColor: maroonColor,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search by faculty, subject, or section...',
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
          ],
        ),
      ),
    );

    final facultyFilter = Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: facultyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Text('Error'),
          data: (faculty) => DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFaculty,
              hint: Text(
                'Filter by Faculty',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              isExpanded: true,
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'All Faculty',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
                ...faculty.map(
                  (f) => DropdownMenuItem<String>(
                    value: f.id.toString(),
                    child: Text(
                      f.name,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedFaculty = value;
                });
              },
            ),
          ),
        ),
      ),
    );

    return Column(
      children: [
        if (isMobile) ...[
          _buildViewToggle(isDark),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            searchBar,
            const SizedBox(width: 16),
            facultyFilter,
            if (!isMobile) ...[
              const SizedBox(width: 16),
              _buildViewToggle(isDark),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar(bool isDark, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        isScrollable: isMobile,
        indicator: BoxDecoration(
          color: maroonColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: maroonColor.withValues(alpha: 0.2)),
        ),
        indicatorColor: maroonColor,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: maroonColor,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Faculty Loading Summary'),
          Tab(text: 'Subject Assignments'),
        ],
      ),
    );
  }

  Widget _buildSubjectAssignmentsView(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Faculty>> facultyAsync,
    AsyncValue<List<Subject>> subjectsAsync,
    AsyncValue<List<Room>> roomsAsync,
    AsyncValue<List<Timeslot>> timeslotsAsync,
    bool isDark,
    Color maroonColor,
  ) => _buildSubjectAssignmentsViewContent(
    schedulesAsync,
    facultyAsync,
    subjectsAsync,
    roomsAsync,
    timeslotsAsync,
    isDark,
    maroonColor,
  );

  Widget _buildSubjectAssignmentsViewContent(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Faculty>> facultyAsync,
    AsyncValue<List<Subject>> subjectsAsync,
    AsyncValue<List<Room>> roomsAsync,
    AsyncValue<List<Timeslot>> timeslotsAsync,
    bool isDark,
    Color maroonColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactList = constraints.maxWidth < 1400;
        return schedulesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading schedules',
                  style: GoogleFonts.poppins(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(schedulesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (schedules) {
            return facultyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Center(child: Text('Error')),
              data: (facultyList) {
                return subjectsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => const Center(child: Text('Error')),
                  data: (subjectList) {
                    return roomsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) =>
                          const Center(child: Text('Error')),
                      data: (roomList) {
                        return timeslotsAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (error, stack) =>
                              const Center(child: Text('Error')),
                          data: (timeslotList) {
                            // Create maps for lookup
                            final facultyMap = {
                              for (var f in facultyList) f.id!: f,
                            };
                            final subjectMap = {
                              for (var s in subjectList) s.id!: s,
                            };
                            final roomMap = {
                              for (var r in roomList) r.id!: r,
                            };
                            final timeslotMap = {
                              for (var t in timeslotList) t.id!: t,
                            };

                            final filteredSchedules = schedules.where((
                              schedule,
                            ) {
                              final matchesSearch =
                                  _searchQuery.isEmpty ||
                                  () {
                                    final faculty =
                                        facultyMap[schedule.facultyId];
                                    final subject =
                                        subjectMap[schedule.subjectId];
                                    return (faculty?.name
                                                .toLowerCase()
                                                .contains(
                                                  _searchQuery,
                                                ) ??
                                            false) ||
                                        (subject?.name.toLowerCase().contains(
                                              _searchQuery,
                                            ) ??
                                            false) ||
                                        schedule.section.toLowerCase().contains(
                                          _searchQuery,
                                        );
                                  }();

                              final matchesFaculty =
                                  _selectedFaculty == null ||
                                  schedule.facultyId.toString() ==
                                      _selectedFaculty;

                              final matchesArchived =
                                  schedule.isActive != _isShowingArchived;

                              return matchesSearch &&
                                  matchesFaculty &&
                                  matchesArchived;
                            }).toList();
                            final allSelected =
                                filteredSchedules.isNotEmpty &&
                                _selectedScheduleIds.length ==
                                    filteredSchedules.length;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              _syncSelectedSchedules(filteredSchedules);
                            });

                            if (filteredSchedules.isEmpty) {
                              return Center(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.assignment_outlined,
                                        size: 56,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? (_isShowingArchived
                                                  ? 'No archived assignments'
                                                  : 'No assignments yet')
                                            : 'No assignments found',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      if (_searchQuery.isEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Click "New Assignment" to get started',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (useCompactList) {
                              return _buildCompactScheduleAssignmentsList(
                                filteredSchedules: filteredSchedules,
                                facultyMap: facultyMap,
                                subjectMap: subjectMap,
                                roomMap: roomMap,
                                timeslotMap: timeslotMap,
                                isDark: isDark,
                                maroonColor: maroonColor,
                              );
                            }

                            return Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 16 : 24,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: maroonColor.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: isMobile
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.assignment_rounded,
                                                    color: maroonColor,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Schedule Assignments',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: maroonColor,
                                                          ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: maroonColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '${filteredSchedules.length} Total',
                                                      style:
                                                          GoogleFonts.poppins(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (_selectedScheduleIds
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: maroonColor
                                                        .withValues(
                                                          alpha: 0.1,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${_selectedScheduleIds.length} selected',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: maroonColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              if (_selectedScheduleIds
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    if (!_isShowingArchived)
                                                      TextButton.icon(
                                                        onPressed: () =>
                                                            _archiveSelectedSchedules(
                                                              filteredSchedules,
                                                            ),
                                                        icon: const Icon(
                                                          Icons
                                                              .archive_outlined,
                                                        ),
                                                        label: Text(
                                                          'Archive Selected',
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        style:
                                                            TextButton.styleFrom(
                                                              foregroundColor:
                                                                  maroonColor,
                                                            ),
                                                      ),
                                                    if (_isShowingArchived)
                                                      TextButton.icon(
                                                        onPressed: () =>
                                                            _deleteSelectedSchedules(
                                                              filteredSchedules,
                                                            ),
                                                        icon: const Icon(
                                                          Icons
                                                              .delete_forever_outlined,
                                                        ),
                                                        label: Text(
                                                          'Delete Selected',
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        style:
                                                            TextButton.styleFrom(
                                                              foregroundColor:
                                                                  Colors.red,
                                                            ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Icon(
                                                Icons.assignment_rounded,
                                                color: maroonColor,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Schedule Assignments',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: maroonColor,
                                                ),
                                              ),
                                              if (_selectedScheduleIds
                                                  .isNotEmpty) ...[
                                                const SizedBox(width: 16),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: maroonColor
                                                        .withValues(
                                                          alpha: 0.1,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${_selectedScheduleIds.length} selected',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: maroonColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(width: 12),
                                              TextButton.icon(
                                                onPressed:
                                                    filteredSchedules.isEmpty
                                                    ? null
                                                    : () =>
                                                          _toggleSelectAllSchedules(
                                                            filteredSchedules,
                                                            !allSelected,
                                                          ),
                                                icon: Icon(
                                                  allSelected
                                                      ? Icons.check_box_rounded
                                                      : Icons
                                                            .check_box_outline_blank_rounded,
                                                ),
                                                label: Text(
                                                  allSelected
                                                      ? 'Clear Selection'
                                                      : 'Select All',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor: maroonColor,
                                                ),
                                              ),
                                              const Spacer(),
                                              if (!_isShowingArchived &&
                                                  _selectedScheduleIds
                                                      .isNotEmpty) ...[
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _archiveSelectedSchedules(
                                                        filteredSchedules,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.archive_outlined,
                                                  ),
                                                  label: Text(
                                                    'Archive Selected',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        maroonColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                              ],
                                              if (_isShowingArchived &&
                                                  _selectedScheduleIds
                                                      .isNotEmpty) ...[
                                                TextButton.icon(
                                                  onPressed: () =>
                                                      _deleteSelectedSchedules(
                                                        filteredSchedules,
                                                      ),
                                                  icon: const Icon(
                                                    Icons
                                                        .delete_forever_outlined,
                                                  ),
                                                  label: Text(
                                                    'Delete Selected',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Colors.red,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                              ],
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: maroonColor,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        20,
                                                      ),
                                                ),
                                                child: Text(
                                                  '${filteredSchedules.length} Total',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final compactDesktop =
                                          constraints.maxWidth < 1800;
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minWidth:
                                                constraints.maxWidth > 1560
                                                ? constraints.maxWidth
                                                : 1560,
                                          ),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.vertical,
                                            padding: const EdgeInsets.all(
                                              16,
                                            ),
                                            child: DataTable(
                                              showCheckboxColumn: false,
                                              headingRowColor:
                                                  WidgetStateProperty.all(
                                                    maroonColor,
                                                  ),
                                              headingTextStyle:
                                                  GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                    letterSpacing: 0.5,
                                                  ),
                                              dataRowMinHeight: 70,
                                              dataRowMaxHeight: 90,
                                              columnSpacing: compactDesktop
                                                  ? 18
                                                  : 28,
                                              horizontalMargin: compactDesktop
                                                  ? 14
                                                  : 24,
                                              decoration: const BoxDecoration(
                                                color: Colors.transparent,
                                              ),
                                              columns: [
                                                DataColumn(
                                                  label: Checkbox(
                                                    value: allSelected,
                                                    onChanged: (value) =>
                                                        _toggleSelectAllSchedules(
                                                          filteredSchedules,
                                                          value,
                                                        ),
                                                    activeColor: Colors.white,
                                                    checkColor: maroonColor,
                                                  ),
                                                ),
                                                const DataColumn(
                                                  label: Text('FACULTY'),
                                                ),
                                                const DataColumn(
                                                  label: Text('SUBJECT'),
                                                ),
                                                const DataColumn(
                                                  label: Text('SECTION'),
                                                ),
                                                const DataColumn(
                                                  label: Text('YEAR'),
                                                ),
                                                const DataColumn(
                                                  label: Text('LOAD'),
                                                ),
                                                const DataColumn(
                                                  label: Text('UNITS'),
                                                ),
                                                const DataColumn(
                                                  label: Text('HOURS'),
                                                ),
                                                const DataColumn(
                                                  label: Text(
                                                    'ROOM & SCHEDULE',
                                                  ),
                                                ),
                                                const DataColumn(
                                                  label: Text('STATUS'),
                                                ),
                                                const DataColumn(
                                                  label: Text('ACTIONS'),
                                                ),
                                              ],
                                              rows: filteredSchedules.asMap().entries.map((
                                                entry,
                                              ) {
                                                final schedule = entry.value;
                                                final index = entry.key;
                                                final faculty =
                                                    facultyMap[schedule
                                                        .facultyId];
                                                final subject =
                                                    subjectMap[schedule
                                                        .subjectId];
                                                final room =
                                                    roomMap[schedule.roomId];
                                                final timeslot =
                                                    timeslotMap[schedule
                                                        .timeslotId];

                                                final isAutoAssign =
                                                    schedule.roomId == -1 ||
                                                    schedule.timeslotId == -1;

                                                return DataRow(
                                                  color: WidgetStateProperty.resolveWith<Color?>(
                                                    (states) {
                                                      if (states.contains(
                                                        WidgetState.hovered,
                                                      )) {
                                                        return maroonColor
                                                            .withValues(
                                                              alpha: 0.05,
                                                            );
                                                      }
                                                      return index.isEven
                                                          ? (isDark
                                                                ? Colors.white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.02,
                                                                      )
                                                                : Colors.grey
                                                                      .withValues(
                                                                        alpha:
                                                                            0.02,
                                                                      ))
                                                          : null;
                                                    },
                                                  ),
                                                  cells: [
                                                    DataCell(
                                                      Checkbox(
                                                        value:
                                                            schedule.id !=
                                                                null &&
                                                            _selectedScheduleIds
                                                                .contains(
                                                                  schedule.id,
                                                                ),
                                                        onChanged:
                                                            schedule.id == null
                                                            ? null
                                                            : (value) =>
                                                                  _toggleScheduleSelection(
                                                                    schedule
                                                                        .id!,
                                                                    value,
                                                                  ),
                                                        activeColor:
                                                            maroonColor,
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 40,
                                                            height: 40,
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors: [
                                                                  maroonColor,
                                                                  maroonColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.7,
                                                                      ),
                                                                ],
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    10,
                                                                  ),
                                                            ),
                                                            child: Center(
                                                              child: Text(
                                                                (faculty?.name.isNotEmpty ??
                                                                        false)
                                                                    ? faculty!
                                                                          .name[0]
                                                                          .toUpperCase()
                                                                    : '?',
                                                                style: GoogleFonts.poppins(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                faculty?.name ??
                                                                    'Unknown',
                                                                style: GoogleFonts.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                              if (faculty
                                                                      ?.facultyId !=
                                                                  null)
                                                                Text(
                                                                  'ID: ${faculty!.facultyId}',
                                                                  style: GoogleFonts.poppins(
                                                                    fontSize:
                                                                        11,
                                                                    color: Colors
                                                                        .grey[600],
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Text(
                                                            subject?.name ??
                                                                'Unknown',
                                                            style:
                                                                GoogleFonts.poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize: 13,
                                                                ),
                                                          ),
                                                          if (subject?.code !=
                                                              null)
                                                            Text(
                                                              subject!.code,
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: maroonColor
                                                              .withValues(
                                                                alpha: 0.08,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          schedule.section,
                                                          style:
                                                              GoogleFonts.poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 13,
                                                                color:
                                                                    maroonColor,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        subject?.yearLevel
                                                                ?.toString() ??
                                                            '-',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              _getLoadTypeColor(
                                                                schedule
                                                                    .loadTypes,
                                                              ).withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                          border: Border.all(
                                                            color:
                                                                _getLoadTypeColor(
                                                                  schedule
                                                                      .loadTypes,
                                                                ).withValues(
                                                                  alpha: 0.3,
                                                                ),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              _getLoadTypeIcon(
                                                                (schedule.loadTypes !=
                                                                            null &&
                                                                        schedule
                                                                            .loadTypes!
                                                                            .isNotEmpty)
                                                                    ? schedule
                                                                          .loadTypes!
                                                                          .first
                                                                    : null,
                                                              ),
                                                              size: 14,
                                                              color: _getLoadTypeColor(
                                                                schedule
                                                                    .loadTypes,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              _getLoadTypeText(
                                                                schedule
                                                                    .loadTypes,
                                                              ),
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: _getLoadTypeColor(
                                                                  schedule
                                                                      .loadTypes,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        schedule.units != null
                                                            ? schedule.units!
                                                                  .round()
                                                                  .toString()
                                                            : (subjectMap[schedule
                                                                          .subjectId]
                                                                      ?.units
                                                                      .toString() ??
                                                                  'N/A'),
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Text(
                                                        schedule.hours
                                                                ?.toString() ??
                                                            'N/A',
                                                        style:
                                                            GoogleFonts.poppins(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .meeting_room_rounded,
                                                                size: 16,
                                                                color:
                                                                    isAutoAssign
                                                                    ? Colors
                                                                          .orange
                                                                    : maroonColor,
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                room?.name ??
                                                                    _waitingForAiLabel,
                                                                style: GoogleFonts.poppins(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      isAutoAssign
                                                                      ? Colors
                                                                            .orange
                                                                      : Colors
                                                                            .black87,
                                                                  fontStyle:
                                                                      isAutoAssign
                                                                      ? FontStyle
                                                                            .italic
                                                                      : null,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .access_time_rounded,
                                                                size: 16,
                                                                color:
                                                                    isAutoAssign
                                                                    ? Colors
                                                                          .orange
                                                                    : Colors
                                                                          .grey[600],
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                timeslot != null
                                                                    ? '${_getDayAbbr(timeslot.day)} ${timeslot.startTime}-${timeslot.endTime}'
                                                                    : _waitingForAiLabel,
                                                                style: GoogleFonts.poppins(
                                                                  fontSize: 11,
                                                                  color:
                                                                      isAutoAssign
                                                                      ? Colors
                                                                            .orange
                                                                      : Colors
                                                                            .grey[700],
                                                                  fontStyle:
                                                                      isAutoAssign
                                                                      ? FontStyle
                                                                            .italic
                                                                      : null,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                _getLoadTypeIcon(
                                                                  (schedule.loadTypes !=
                                                                              null &&
                                                                          schedule
                                                                              .loadTypes!
                                                                              .isNotEmpty)
                                                                      ? schedule
                                                                            .loadTypes!
                                                                            .first
                                                                      : null,
                                                                ),
                                                                size: 14,
                                                                color: _getLoadTypeColor(
                                                                  schedule
                                                                      .loadTypes,
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 6,
                                                              ),
                                                              Text(
                                                                _getLoadTypeText(
                                                                  schedule
                                                                      .loadTypes,
                                                                ),
                                                                style: GoogleFonts.poppins(
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: _getLoadTypeColor(
                                                                    schedule
                                                                        .loadTypes,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    DataCell(
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 14,
                                                              vertical: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: isAutoAssign
                                                                ? [
                                                                    Colors
                                                                        .orange,
                                                                    Colors
                                                                        .orange
                                                                        .withValues(
                                                                          alpha:
                                                                              0.7,
                                                                        ),
                                                                  ]
                                                                : [
                                                                    Colors
                                                                        .green,
                                                                    Colors.green
                                                                        .withValues(
                                                                          alpha:
                                                                              0.7,
                                                                        ),
                                                                  ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color:
                                                                  (isAutoAssign
                                                                          ? Colors.orange
                                                                          : Colors.green)
                                                                      .withValues(
                                                                        alpha:
                                                                            0.3,
                                                                      ),
                                                              blurRadius: 8,
                                                              offset:
                                                                  const Offset(
                                                                    0,
                                                                    2,
                                                                  ),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              isAutoAssign
                                                                  ? Icons
                                                                        .pending_actions
                                                                  : Icons
                                                                        .check_circle,
                                                              size: 14,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Text(
                                                              isAutoAssign
                                                                  ? 'Pending AI'
                                                                  : 'Scheduled',
                                                              style: GoogleFonts.poppins(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    DataCell(
                                                      SizedBox(
                                                        width:
                                                            _isShowingArchived
                                                            ? 108
                                                            : 156,
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            if (!_isShowingArchived) ...[
                                                              Tooltip(
                                                                message:
                                                                    'Open details',
                                                                child: Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    onTap: () => _showAssignmentDetailsDialog(
                                                                      schedule:
                                                                          schedule,
                                                                      faculty:
                                                                          faculty,
                                                                      subject:
                                                                          subject,
                                                                      room:
                                                                          room,
                                                                      timeslot:
                                                                          timeslot,
                                                                    ),
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: maroonColor.withValues(
                                                                          alpha:
                                                                              0.1,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .open_in_new,
                                                                        color:
                                                                            maroonColor,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Tooltip(
                                                                message:
                                                                    'Edit assignment',
                                                                child: Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    onTap: () =>
                                                                        _showEditAssignmentModal(
                                                                          schedule,
                                                                        ),
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: maroonColor.withValues(
                                                                          alpha:
                                                                              0.1,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .edit_outlined,
                                                                        color:
                                                                            maroonColor,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Tooltip(
                                                                message:
                                                                    'Archive assignment',
                                                                child: Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    onTap: () =>
                                                                        _archiveSchedule(
                                                                          schedule,
                                                                        ),
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: maroonColor.withValues(
                                                                          alpha:
                                                                              0.1,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .archive_outlined,
                                                                        color: Colors
                                                                            .orange,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ] else ...[
                                                              Tooltip(
                                                                message:
                                                                    'Open details',
                                                                child: Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    onTap: () => _showAssignmentDetailsDialog(
                                                                      schedule:
                                                                          schedule,
                                                                      faculty:
                                                                          faculty,
                                                                      subject:
                                                                          subject,
                                                                      room:
                                                                          room,
                                                                      timeslot:
                                                                          timeslot,
                                                                    ),
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .green
                                                                            .withValues(
                                                                              alpha: 0.1,
                                                                            ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .open_in_new,
                                                                        color:
                                                                            maroonColor,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Tooltip(
                                                                message:
                                                                    'Restore assignment',
                                                                child: Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    onTap: () =>
                                                                        _restoreSchedule(
                                                                          schedule,
                                                                        ),
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: maroonColor.withValues(
                                                                          alpha:
                                                                              0.1,
                                                                        ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: Icon(
                                                                        Icons
                                                                            .restore_rounded,
                                                                        color: Colors
                                                                            .green,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Tooltip(
                                                                message:
                                                                    'Delete permanently',
                                                                child: Material(
                                                                  color: Colors
                                                                      .transparent,
                                                                  child: InkWell(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          8,
                                                                        ),
                                                                    onTap: () =>
                                                                        _deleteSchedule(
                                                                          schedule,
                                                                        ),
                                                                    child: Container(
                                                                      padding:
                                                                          const EdgeInsets.all(
                                                                            8,
                                                                          ),
                                                                      decoration: BoxDecoration(
                                                                        color: Colors
                                                                            .red
                                                                            .withValues(
                                                                              alpha: 0.1,
                                                                            ),
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              8,
                                                                            ),
                                                                      ),
                                                                      child: const Icon(
                                                                        Icons
                                                                            .delete_forever_rounded,
                                                                        color: Colors
                                                                            .red,
                                                                        size:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFacultySummaryView(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Faculty>> facultyAsync,
    AsyncValue<List<Subject>> subjectsAsync,
    AsyncValue<List<Room>> roomsAsync,
    AsyncValue<List<Timeslot>> timeslotsAsync,
    bool isDark,
  ) => _buildFacultySummaryViewContent(
    schedulesAsync,
    facultyAsync,
    subjectsAsync,
    roomsAsync,
    timeslotsAsync,
    isDark,
  );

  Widget _buildFacultySummaryViewContent(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Faculty>> facultyAsync,
    AsyncValue<List<Subject>> subjectsAsync,
    AsyncValue<List<Room>> roomsAsync,
    AsyncValue<List<Timeslot>> timeslotsAsync,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactList = constraints.maxWidth < 1400;
        const maroonColor = Color(0xFF4f003b);
        final headerBg = isDark
            ? maroonColor.withValues(alpha: 0.22)
            : maroonColor.withValues(alpha: 0.08);
        final rowBgA = isDark ? const Color(0xFF0F172A) : Colors.white;
        final rowBgB = isDark
            ? const Color(0xFF111827)
            : const Color(0xFFF9FAFB);
        final dividerColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06);

        return schedulesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
          data: (schedules) => facultyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (facultyList) {
              final subjectList = subjectsAsync.maybeWhen(
                data: (d) => d,
                orElse: () => <Subject>[],
              );
              final timeslotList = timeslotsAsync.maybeWhen(
                data: (d) => d,
                orElse: () => <Timeslot>[],
              );
              final allConflicts = ref.watch(allConflictsProvider);
              final facultyStats = _buildFacultySummaryStats(
                facultyList: facultyList,
                schedules: schedules,
                subjectMap: {for (var s in subjectList) s.id ?? -1: s},
                timeslotMap: {for (var t in timeslotList) t.id ?? -1: t},
                allConflicts: allConflicts,
                searchQuery: _searchQuery,
              );

              if (useCompactList) {
                return _buildCompactFacultySummaryList(
                  facultyStats: facultyStats,
                  schedules: schedules,
                  isDark: isDark,
                );
              }

              return _buildFacultySummaryTable(
                context: context,
                facultyStats: facultyStats,
                schedules: schedules,
                isDark: isDark,
                headerBg: headerBg,
                rowBgA: rowBgA,
                rowBgB: rowBgB,
                dividerColor: dividerColor,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCompactFacultySummaryList({
    required List<_FacultySummaryStats> facultyStats,
    required List<Schedule> schedules,
    required bool isDark,
  }) {
    final subjects = ref
        .read(subjectsProvider)
        .maybeWhen(
          data: (list) => list,
          orElse: () => <Subject>[],
        );
    final rooms = ref
        .read(roomsProvider)
        .maybeWhen(
          data: (list) => list,
          orElse: () => <Room>[],
        );
    final timeslots = ref
        .read(timeslotsProvider)
        .maybeWhen(
          data: (list) => list,
          orElse: () => <Timeslot>[],
        );
    final subjectMap = {for (final subject in subjects) subject.id!: subject};
    final roomMap = {for (final room in rooms) room.id!: room};
    final timeslotMap = {
      for (final timeslot in timeslots) timeslot.id!: timeslot,
    };

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: facultyStats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final stats = facultyStats[index];
        final faculty = stats.faculty;
        final remainingLoad = stats.remainingLoad;
        final hasConflict = stats.hasConflicts;
        final facultySchedules = schedules
            .where((s) => s.facultyId == faculty.id)
            .toList();
        final isExpanded =
            faculty.id != null &&
            _safeExpandedFacultySummaryIds.contains(faculty.id);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => _toggleFacultySummaryExpanded(faculty.id),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              faculty.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            hasConflict
                                ? Icons.warning_rounded
                                : Icons.check_circle_rounded,
                            color: hasConflict ? Colors.orange : Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: maroonColor,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            Icons.menu_book_rounded,
                            '${stats.assignedSubjects} Subjects',
                            Colors.blue,
                          ),
                          _buildInfoChip(
                            Icons.straighten_rounded,
                            '${stats.totalUnits.toStringAsFixed(1)} Units',
                            Colors.purple,
                          ),
                          _buildInfoChip(
                            Icons.schedule_rounded,
                            '${stats.totalHours.toStringAsFixed(1)} Hours',
                            Colors.teal,
                          ),
                          _buildInfoChip(
                            Icons.speed_rounded,
                            '${remainingLoad.toStringAsFixed(1)} Remaining',
                            remainingLoad < 0 ? Colors.red : Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 220),
                crossFadeState: isExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        height: 1,
                        color: isDark
                            ? Colors.white12
                            : Colors.black.withValues(alpha: 0.08),
                      ),
                      const SizedBox(height: 12),
                      if (facultySchedules.isEmpty)
                        Text(
                          'No subject assignments for this faculty.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        )
                      else
                        ...facultySchedules.asMap().entries.map((entry) {
                          final schedule = entry.value;
                          final subject = subjectMap[schedule.subjectId];
                          final room = roomMap[schedule.roomId];
                          final timeslot = timeslotMap[schedule.timeslotId];
                          final isPending =
                              schedule.roomId == -1 ||
                              schedule.timeslotId == -1;
                          final scheduleLabel = timeslot != null
                              ? '${_getDayAbbr(timeslot.day)} ${timeslot.startTime}-${timeslot.endTime}'
                              : _waitingForAiLabel;

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key == facultySchedules.length - 1
                                  ? 0
                                  : 10,
                            ),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.grey.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.05),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject?.name ?? 'Unknown Subject',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildInfoChip(
                                        Icons.book_outlined,
                                        subject?.code ?? '-',
                                        Colors.blue,
                                      ),
                                      _buildInfoChip(
                                        Icons.groups_outlined,
                                        schedule.section,
                                        Colors.purple,
                                      ),
                                      _buildInfoChip(
                                        Icons.layers_outlined,
                                        _getLoadTypeText(schedule.loadTypes),
                                        _getLoadTypeColor(schedule.loadTypes),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _detailRow(
                                    'Room',
                                    room?.name ?? _waitingForAiLabel,
                                  ),
                                  _detailRow('Schedule', scheduleLabel),
                                  _detailRow(
                                    'Status',
                                    isPending ? 'Pending AI' : 'Scheduled',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FacultyLoadDetailsScreen(
                                  faculty: faculty,
                                  initialSchedules: facultySchedules,
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.open_in_new, color: maroonColor),
                          label: Text(
                            'Open Full Details',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: maroonColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactScheduleAssignmentsList({
    required List<Schedule> filteredSchedules,
    required Map<int, Faculty> facultyMap,
    required Map<int, Subject> subjectMap,
    required Map<int, Room> roomMap,
    required Map<int, Timeslot> timeslotMap,
    required bool isDark,
    required Color maroonColor,
  }) {
    final allSelected =
        filteredSchedules.isNotEmpty &&
        _selectedScheduleIds.length == filteredSchedules.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_rounded,
                            color: maroonColor,
                            size: 20,
                          ),
                          Text(
                            'Schedule Assignments',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: maroonColor,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: maroonColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${filteredSchedules.length} Total',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (_selectedScheduleIds.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: maroonColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_selectedScheduleIds.length} selected',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: maroonColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: filteredSchedules.isEmpty
                        ? null
                        : () => _toggleSelectAllSchedules(
                            filteredSchedules,
                            !allSelected,
                          ),
                    icon: Icon(
                      allSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 18,
                    ),
                    label: Text(
                      allSelected ? 'Clear Selection' : 'Select All',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: maroonColor,
                      side: BorderSide(
                        color: maroonColor.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (_selectedScheduleIds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!_isShowingArchived)
                        TextButton.icon(
                          onPressed: () =>
                              _archiveSelectedSchedules(filteredSchedules),
                          icon: const Icon(Icons.archive_outlined),
                          label: Text(
                            'Archive Selected',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: maroonColor,
                          ),
                        ),
                      if (_isShowingArchived)
                        TextButton.icon(
                          onPressed: () =>
                              _deleteSelectedSchedules(filteredSchedules),
                          icon: const Icon(Icons.delete_forever_outlined),
                          label: Text(
                            'Delete Selected',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 12),
              ...filteredSchedules.asMap().entries.map((entry) {
                final index = entry.key;
                final schedule = entry.value;
                final faculty = facultyMap[schedule.facultyId];
                final subject = subjectMap[schedule.subjectId];
                final room = roomMap[schedule.roomId];
                final timeslot = timeslotMap[schedule.timeslotId];
                final isSelected =
                    schedule.id != null &&
                    _selectedScheduleIds.contains(schedule.id);
                final isExpanded =
                    schedule.id != null &&
                    _safeExpandedCompactScheduleIds.contains(schedule.id);
                final roomAndSchedule = timeslot != null
                    ? '${room?.name ?? _waitingForAiLabel} • ${_getDayAbbr(timeslot.day)} ${timeslot.startTime}-${timeslot.endTime}'
                    : _waitingForAiLabel;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == filteredSchedules.length - 1 ? 0 : 12,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? maroonColor.withValues(alpha: 0.45)
                            : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.06)),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _toggleCompactScheduleExpanded(schedule.id),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: schedule.id == null
                                    ? null
                                    : (value) => _toggleScheduleSelection(
                                        schedule.id!,
                                        value,
                                      ),
                                activeColor: maroonColor,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      faculty?.name ?? 'Unknown Faculty',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subject?.name ?? 'Unknown Subject',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: maroonColor,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 220),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip(
                                    Icons.book_outlined,
                                    subject?.code ?? '-',
                                    Colors.blue,
                                  ),
                                  _buildInfoChip(
                                    Icons.groups_outlined,
                                    schedule.section,
                                    Colors.purple,
                                  ),
                                  _buildInfoChip(
                                    Icons.school_outlined,
                                    'Year ${subject?.yearLevel ?? '-'}',
                                    Colors.orange,
                                  ),
                                  _buildInfoChip(
                                    Icons.layers_outlined,
                                    _getLoadTypeText(schedule.loadTypes),
                                    _getLoadTypeColor(schedule.loadTypes),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _detailRow(
                                'Units',
                                schedule.units?.toString() ??
                                    subject?.units.toString() ??
                                    '-',
                              ),
                              _detailRow(
                                'Hours',
                                schedule.hours?.toString() ?? '-',
                              ),
                              _detailRow('Room & Schedule', roomAndSchedule),
                              _detailRow(
                                'Status',
                                (schedule.roomId == -1 ||
                                        schedule.timeslotId == -1)
                                    ? 'Pending AI'
                                    : 'Scheduled',
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildCompactAssignmentAction(
                                    icon: Icons.open_in_new,
                                    color: maroonColor,
                                    tooltip: 'Open details',
                                    onTap: () => _showAssignmentDetailsDialog(
                                      schedule: schedule,
                                      faculty: faculty,
                                      subject: subject,
                                      room: room,
                                      timeslot: timeslot,
                                    ),
                                  ),
                                  if (!_isShowingArchived) ...[
                                    _buildCompactAssignmentAction(
                                      icon: Icons.edit_outlined,
                                      color: maroonColor,
                                      tooltip: 'Edit assignment',
                                      onTap: () =>
                                          _showEditAssignmentModal(schedule),
                                    ),
                                    _buildCompactAssignmentAction(
                                      icon: Icons.archive_outlined,
                                      color: Colors.orange,
                                      tooltip: 'Archive assignment',
                                      onTap: () => _archiveSchedule(schedule),
                                    ),
                                  ] else ...[
                                    _buildCompactAssignmentAction(
                                      icon: Icons.restore_rounded,
                                      color: Colors.green,
                                      tooltip: 'Restore assignment',
                                      onTap: () => _restoreSchedule(schedule),
                                    ),
                                    _buildCompactAssignmentAction(
                                      icon: Icons.delete_forever_rounded,
                                      color: Colors.red,
                                      tooltip: 'Delete permanently',
                                      onTap: () => _deleteSchedule(schedule),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          secondChild: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAssignmentAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getLoadTypeColor(List<SubjectType>? types) {
    if (types == null || types.isEmpty) return Colors.grey;
    final expanded = _expandedSubjectTypes(types);
    if (expanded.contains(SubjectType.lecture) &&
        expanded.contains(SubjectType.laboratory)) {
      return Colors.orange;
    }
    if (expanded.contains(SubjectType.lecture)) return Colors.purple;
    if (expanded.contains(SubjectType.laboratory)) return Colors.teal;
    return Colors.blue;
  }

  String _getLoadTypeText(List<SubjectType>? types) {
    if (types == null || types.isEmpty) return 'N/A';
    return _displaySubjectTypeLabels(types).join(' / ');
  }

  IconData _getLoadTypeIcon(SubjectType? type) {
    if (type == null) return Icons.help_outline;
    switch (type) {
      case SubjectType.lecture:
        return Icons.menu_book;
      case SubjectType.laboratory:
        return Icons.science;
      case SubjectType.blended:
        return Icons.layers_outlined;
    }
  }

  String _getDayAbbr(DayOfWeek day) {
    switch (day) {
      case DayOfWeek.mon:
        return 'Mon';
      case DayOfWeek.tue:
        return 'Tue';
      case DayOfWeek.wed:
        return 'Wed';
      case DayOfWeek.thu:
        return 'Thu';
      case DayOfWeek.fri:
        return 'Fri';
      case DayOfWeek.sat:
        return 'Sat';
      case DayOfWeek.sun:
        return 'Sun';
    }
  }

  Widget _buildConflictBanner(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Faculty>> facultyAsync,
    AsyncValue<List<ScheduleConflict>> allConflicts,
  ) => _buildConflictBannerContent(
    schedulesAsync,
    facultyAsync,
    allConflicts,
  );

  Widget _buildConflictBannerContent(
    AsyncValue<List<Schedule>> schedulesAsync,
    AsyncValue<List<Faculty>> facultyAsync,
    AsyncValue<List<ScheduleConflict>> allConflicts,
  ) {
    return schedulesAsync.when(
      loading: () => const SizedBox(),
      error: (error, stack) => const SizedBox(),
      data: (_) {
        final conflicts = allConflicts.maybeWhen(
          data: (list) => list
              .map(
                (c) => c.details != null && c.details!.isNotEmpty
                    ? '${c.message}” ${c.details}'
                    : c.message,
              )
              .toList(),
          orElse: () => <String>[],
        );
        final hasConflicts = conflicts.isNotEmpty;
        final onTap = hasConflicts
            ? () {
                setState(() {
                  _showConflictDetails = !_showConflictDetails;
                });
              }
            : null;

        return _buildConflictBannerCard(
          hasConflicts: hasConflicts,
          showConflictDetails: _showConflictDetails,
          onTap: onTap,
          conflicts: conflicts,
        );
      },
    );
  }
}

// New Assignment Modal
class _NewAssignmentModal extends ConsumerStatefulWidget {
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _NewAssignmentModal({
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  ConsumerState<_NewAssignmentModal> createState() =>
      _NewAssignmentModalState();
}

class _NewAssignmentModalState extends ConsumerState<_NewAssignmentModal> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedFacultyId;
  int? _selectedSubjectId;
  int? _selectedSectionId;
  int? _selectedRoomId;
  int? _selectedTimeslotId;
  Timeslot? _selectedTimeslotOverride;
  double? _selectedUnits;
  double? _selectedHours;
  late List<double> _unitOptions;
  late List<double> _hourOptions;
  bool _isAutoAssign = false;
  bool _isLoading = false;
  SubjectType? _selectedLoadType;
  bool _showLoadTypeRequired = false;
  final Set<String> _syncingTimeslotKeys = <String>{};

  bool get _canSubmit =>
      !_isLoading &&
      _selectedRoomId != null &&
      (_isAutoAssign || _selectedTimeslotId != null);

  @override
  void initState() {
    super.initState();
    _unitOptions = List<double>.from(_manualUnitOptions);
    _hourOptions = List<double>.from(_manualHourOptions);
    unawaited(_loadSavedLoadOptions());
  }

  Future<void> _loadSavedLoadOptions() async {
    final savedUnits = await _loadPersistedLoadOptions(
      _facultyLoadUnitOptionsPrefsKey,
      _manualUnitOptions,
    );
    final savedHours = await _loadPersistedLoadOptions(
      _facultyLoadHourOptionsPrefsKey,
      _manualHourOptions,
    );
    if (!mounted) return;
    setState(() {
      _unitOptions = savedUnits;
      _hourOptions = savedHours;
      final subject = _findSubject(
        ref.read(subjectsProvider).maybeWhen(
          data: (subjects) => subjects,
          orElse: () => <Subject>[],
        ),
      );
      if (subject != null) {
        _applySubjectDefaults(subject, preserveSelection: true);
      } else {
        if (_selectedUnits != null) {
          _unitOptions = _mergeLoadOptions(_unitOptions, _selectedUnits!);
        }
        if (_selectedHours != null) {
          _hourOptions = _mergeLoadOptions(_hourOptions, _selectedHours!);
        }
      }
    });
  }

  void _applySubjectDefaults(
    Subject? subject, {
    bool preserveSelection = false,
  }) {
    if (subject == null) {
      _selectedUnits = null;
      _selectedHours = null;
      _selectedLoadType = null;
      _showLoadTypeRequired = false;
      return;
    }
    _selectedLoadType = _isBlendedSubject(subject.types)
        ? _selectedLoadType
        : null;
    if (!_isBlendedSubject(subject.types)) {
      _showLoadTypeRequired = false;
    }
    final effectiveTypes = _effectiveAssignmentTypes(
      subject.types,
      _selectedLoadType,
    );
    final suggestedUnits = subject.units.toDouble();
    final suggestedHours =
        subject.hours ?? _requiredHoursForSubject(subject, effectiveTypes);
    _unitOptions = _mergeLoadOptions(_unitOptions, suggestedUnits);
    _hourOptions = _mergeLoadOptions(_hourOptions, suggestedHours);
    _selectedUnits = _resolveSelectedLoadValue(
      preserveSelection ? _selectedUnits : null,
      suggestedUnits,
      _unitOptions,
    );
    _selectedHours = _resolveSelectedLoadValue(
      preserveSelection ? _selectedHours : null,
      suggestedHours,
      _hourOptions,
    );
  }

  Future<void> _showAddLoadOptionDialog({
    required String label,
    required String helperText,
    required ValueChanged<double> onValueAdded,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add $label Option',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                helperText,
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '$label value',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: widget.maroonColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid $label value.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                double.parse(controller.text.trim()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.maroonColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Add', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;
    onValueAdded(_normalizeLoadOption(result));
  }

  Future<void> _removeSelectedLoadOption({
    required String label,
    required double? selectedValue,
    required List<double> currentItems,
    required List<double> protectedItems,
    required ValueChanged<List<double>> onItemsUpdated,
    required ValueChanged<double?> onSelectionUpdated,
  }) async {
    if (selectedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select a $label option to remove.')),
      );
      return;
    }
    if (currentItems.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least one $label option must remain available.'),
        ),
      );
      return;
    }
    if (protectedItems.contains(_normalizeLoadOption(selectedValue))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Default ${label.toLowerCase()} options cannot be deleted.',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove $label Option',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove ${_formatLoadValue(selectedValue)} $label${selectedValue == 1 ? '' : 's'} from this dropdown?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Remove', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final updatedItems = List<double>.from(currentItems)
      ..remove(_normalizeLoadOption(selectedValue));
    updatedItems.sort();
    onItemsUpdated(updatedItems);
    onSelectionUpdated(updatedItems.isEmpty ? null : updatedItems.first);
  }

  Widget _buildLoadDropdownField({
    required String label,
    required IconData icon,
    required double? value,
    required List<double> items,
    required List<double> protectedItems,
    required ValueChanged<double?> onChanged,
    required VoidCallback onAddPressed,
    required VoidCallback onRemoveSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dropdownBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final uniqueItems = items.toSet().toList()..sort();
    final safeValue = uniqueItems.contains(value) ? value : null;
    final canDeleteSelected =
        value != null && !protectedItems.contains(_normalizeLoadOption(value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Object>(
          initialValue: safeValue,
          dropdownColor: dropdownBg,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(color: textColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.maroonColor, width: 2),
            ),
          ),
          items: [
            ...uniqueItems.map(
              (item) => DropdownMenuItem<Object>(
                value: item,
                child: Text(
                  '${_formatLoadValue(item)} $label${item == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(color: textColor),
                ),
              ),
            ),
            if (canDeleteSelected)
              DropdownMenuItem<Object>(
                value: _deleteSelectedLoadOptionAction,
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete ${_formatLoadValue(value!)} $label${value == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (selected) {
            if (selected == _deleteSelectedLoadOptionAction) {
              onRemoveSelected();
              return;
            }
            onChanged(selected as double?);
          },
          validator: (selected) => selected == null ? 'Required' : null,
          style: GoogleFonts.poppins(color: textColor),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAddPressed,
            icon: Icon(icon, size: 18, color: widget.maroonColor),
            label: Text(
              'Add $label option',
              style: GoogleFonts.poppins(
                color: widget.maroonColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Section _resolveSection(List<Section> sections) {
    return sections.firstWhere(
      (s) => s.id == _selectedSectionId,
      orElse: () => sections.isNotEmpty
          ? sections.first
          : Section(
              sectionCode: '',
              program: Program.it,
              yearLevel: 1,
              semester: 1,
              academicYear: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
    );
  }

  Faculty? _findFaculty(List<Faculty> facultyList) {
    for (final faculty in facultyList) {
      if (faculty.id == _selectedFacultyId) {
        return faculty;
      }
    }
    return null;
  }

  Subject? _findSubject(List<Subject> subjectList) {
    for (final subject in subjectList) {
      if (subject.id == _selectedSubjectId) {
        return subject;
      }
    }
    return null;
  }

  Room? _findRoom(List<Room> roomList) {
    for (final room in roomList) {
      if (room.id == _selectedRoomId) {
        return room;
      }
    }
    return null;
  }

  TimeOfDay _timeOfDayFromHHmm(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  String _timeOfDayToHHmm(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int? _requiredAssignmentMinutes() {
    final selectedHours = _selectedHours;
    if (selectedHours == null || selectedHours <= 0) return null;
    return (selectedHours * 60).round();
  }

  void _syncMissingTimeslots(List<_TimeslotWindow> windows) {
    if (windows.isEmpty) return;
    final key = _timeslotWindowsKey(windows);
    if (_syncingTimeslotKeys.contains(key)) return;
    _syncingTimeslotKeys.add(key);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _createTimeslotsFromWindows(
          ref: ref,
          context: context,
          windows: windows,
        );
      } finally {
        if (mounted) {
          setState(() {
            _syncingTimeslotKeys.remove(key);
          });
        } else {
          _syncingTimeslotKeys.remove(key);
        }
      }
    });
  }

  void _syncAutoAssignedTimeslotPreview(List<_TimeslotOption> options) {
    if (!_isAutoAssign) return;
    final enabledOptions = options.where((option) => option.isEnabled).toList();
    final previewId = enabledOptions.isEmpty
        ? null
        : enabledOptions.first.slot.id;
    if (_selectedTimeslotId == previewId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedTimeslotId = previewId;
      });
    });
  }

  Future<void> _editTimeslotRange(_TimeslotOption option) async {
    final slot = option.slot;
    final result = await showDialog<Timeslot>(
      context: context,
      builder: (dialogContext) {
        var startTime = _timeOfDayFromHHmm(slot.startTime);
        var endTime = _timeOfDayFromHHmm(slot.endTime);
        final requiredMinutes = _requiredAssignmentMinutes();
        final requiredHoursLabel = _selectedHours == null
            ? null
            : _formatLoadValue(_selectedHours!);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> onPickStart() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: startTime,
              );
              if (picked != null) {
                if (requiredMinutes != null) {
                  final computedEndMinutes =
                      _timeOfDayToMinutes(picked) + requiredMinutes;
                  if (computedEndMinutes >= 24 * 60) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Selected $requiredHoursLabel-hour duration does not fit in the day.',
                        ),
                      ),
                    );
                    return;
                  }
                  setDialogState(() {
                    startTime = picked;
                    endTime = _timeOfDayFromMinutes(computedEndMinutes);
                  });
                  return;
                }
                setDialogState(() => startTime = picked);
              }
            }

            Future<void> onPickEnd() async {
              final picked = await showTimePicker(
                context: context,
                initialTime: endTime,
              );
              if (picked != null) {
                if (requiredMinutes != null) {
                  final computedStartMinutes =
                      _timeOfDayToMinutes(picked) - requiredMinutes;
                  if (computedStartMinutes < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Selected $requiredHoursLabel-hour duration does not fit in the day.',
                        ),
                      ),
                    );
                    return;
                  }
                  setDialogState(() {
                    endTime = picked;
                    startTime = _timeOfDayFromMinutes(computedStartMinutes);
                  });
                  return;
                }
                setDialogState(() => endTime = picked);
              }
            }

            return AlertDialog(
              title: Text(
                'Edit Timeslot Range',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDayAbbr(slot.day),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  if (requiredHoursLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Duration is linked to the selected subject load: $requiredHoursLabel hour${_selectedHours == 1 ? '' : 's'}.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Start', style: GoogleFonts.poppins()),
                    subtitle: Text(
                      startTime.format(context),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.schedule),
                    onTap: onPickStart,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('End', style: GoogleFonts.poppins()),
                    subtitle: Text(
                      endTime.format(context),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.schedule),
                    onTap: onPickEnd,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
              ElevatedButton(
                onPressed: () async {
                  final startMinutes = _timeOfDayToMinutes(startTime);
                  final endMinutes = _timeOfDayToMinutes(endTime);
                  if (endMinutes <= startMinutes) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('End time must be after start time.'),
                        ),
                      );
                      return;
                    }
                    if (requiredMinutes != null &&
                        (endMinutes - startMinutes) != requiredMinutes) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Timeslot must match the selected $requiredHoursLabel-hour load.',
                          ),
                        ),
                      );
                    return;
                  }

                  final availabilityList = await _loadFacultyAvailability(
                    ref,
                    _selectedFacultyId,
                  );
                  final editedWindow = _TimeslotWindow(
                    day: slot.day,
                    startTime: _timeOfDayToHHmm(startTime),
                    endTime: _timeOfDayToHHmm(endTime),
                  );
                  if (!_windowFitsFacultyAvailability(
                    editedWindow,
                    availabilityList,
                  )) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Timeslot must stay within the selected faculty availability.',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  Navigator.pop(
                    context,
                    Timeslot(
                        id: slot.id,
                        day: slot.day,
                        startTime: _timeOfDayToHHmm(startTime),
                        endTime: _timeOfDayToHHmm(endTime),
                        label:
                            '${_getDayAbbr(slot.day)} ${_timeOfDayToHHmm(startTime)}-${_timeOfDayToHHmm(endTime)}',
                        createdAt: slot.createdAt,
                        updatedAt: DateTime.now(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.maroonColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Save', style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    try {
      final resolvedTimeslot = await _findOrCreateMatchingTimeslot(result);
      ref.invalidate(timeslotsProvider);
      if (mounted) {
        setState(() {
          _selectedTimeslotId = resolvedTimeslot.id;
          _selectedTimeslotOverride = resolvedTimeslot;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timeslot selected successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showConflictErrorDialog(context, _parseServerError(e));
      }
    }
  }

  void _validateSelectedAssignment({
    required Faculty faculty,
    required Subject subject,
    required Section section,
    required List<Room> roomList,
  }) {
    if (!_isStudentAvailabilityExemptSubject(subject) &&
        !_hasConfiguredSectionAvailability(section)) {
      throw Exception(_sectionAvailabilityRequiredMessage(section.sectionCode));
    }

    if (faculty.program != null && faculty.program != section.program) {
      final isEmcTeachingIt =
          faculty.program == Program.emc && section.program == Program.it;
      if (!isEmcTeachingIt) {
        throw Exception(
          'Faculty program must match the selected section program.',
        );
      }
    }

    if (subject.program != section.program) {
      throw Exception(
        'Subject program must match the selected section program.',
      );
    }

    if (_isBlendedSubject(subject.types) && _selectedLoadType == null) {
      throw Exception(
        'Please select whether this blended subject is Lecture or Lab.',
      );
    }

    if (_selectedRoomId == null) {
      return;
    }

    final effectiveTypes = _effectiveAssignmentTypes(
      subject.types,
      _selectedLoadType,
    );
    final selectedRoom = _findRoom(roomList);
    if (selectedRoom == null) {
      return;
    }

    if (!_isSupportedSchedulingRoom(selectedRoom)) {
      throw Exception(
        'Only lecture and laboratory rooms are allowed for scheduling.',
      );
    }

    if (effectiveTypes.isNotEmpty &&
        !_isRoomAllowedForTypes(
          room: selectedRoom,
          loadTypes: effectiveTypes,
        )) {
      throw Exception(
        _requiresLaboratoryRoom(effectiveTypes)
            ? 'Laboratory or blended subjects can only be assigned to laboratory rooms.'
            : 'Lecture-only subjects can only be assigned to lecture rooms.',
      );
    }
  }

  Widget _buildTimeslotSearchField({
    required String label,
    required List<_TimeslotOption> options,
  }) {
    final selectedOption = _selectedTimeslotId == null
        ? null
        : options
              .where((o) => o.slot.id == _selectedTimeslotId)
              .cast<_TimeslotOption?>()
              .firstWhere((o) => o != null, orElse: () => null);
    final selectedLabel =
        selectedOption?.label ??
        (_selectedTimeslotOverride != null &&
                _selectedTimeslotOverride!.id == _selectedTimeslotId
            ? CITESchedDateUtils.formatTimeslot(
                _selectedTimeslotOverride!.day,
                _selectedTimeslotOverride!.startTime,
                _selectedTimeslotOverride!.endTime,
              )
            : null);

    return Autocomplete<_TimeslotOption>(
      key: ValueKey(
        'new-timeslot-${_selectedFacultyId ?? 'none'}-${_selectedSubjectId ?? 'none'}-${_selectedSectionId ?? 'none'}-${_selectedRoomId ?? 'none'}-${_selectedLoadType?.name ?? 'default'}-${_isAutoAssign ? 'auto' : 'manual'}-${_selectedTimeslotId ?? 'none'}-${options.length}',
      ),
      displayStringForOption: (option) => option.label,
      initialValue: selectedLabel == null
          ? const TextEditingValue()
          : TextEditingValue(text: selectedLabel),
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return options;
        }
        return options.where(
          (option) => option.label.toLowerCase().contains(query),
        );
      },
      onSelected: (option) {
        if (!option.isEnabled) return;
        setState(() {
          _selectedTimeslotId = option.slot.id;
          _selectedTimeslotOverride = option.slot;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (selectedLabel != null &&
            selectedLabel.isNotEmpty &&
            controller.text != selectedLabel) {
          controller.value = TextEditingValue(
            text: selectedLabel,
            selection: TextSelection.collapsed(offset: selectedLabel.length),
          );
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.maroonColor, width: 2),
            ),
            helperText: _isAutoAssign
                ? 'Auto-assign is enabled. This dropdown stays visible for reference, but the system will choose the timeslot.'
                : _selectedTimeslotId == null
                ? 'Select from dropdown. Typed text alone will not be accepted.'
                : null,
          ),
          onChanged: (value) {
            final normalizedValue = value.toLowerCase().trim();
            final matchesSelectedLabel =
                selectedLabel != null &&
                selectedLabel.toLowerCase().trim() == normalizedValue;
            final match = matchesSelectedLabel || options.any(
              (option) =>
                  option.label.toLowerCase().trim() ==
                  normalizedValue,
            );
            if (!match && _selectedTimeslotId != null) {
              setState(() {
                _selectedTimeslotId = null;
                _selectedTimeslotOverride = null;
              });
            }
          },
          validator: (_) =>
              !_isAutoAssign && _selectedTimeslotId == null ? 'Required' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 520,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final isEnabled = option.isEnabled;
                  return ListTile(
                    dense: true,
                    enabled: isEnabled,
                    title: Text(
                      option.label,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    subtitle: option.disabledReason == null
                        ? null
                        : Text(
                            option.disabledReason!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                    trailing: IconButton(
                      tooltip: 'Edit timeslot range',
                      icon: Icon(
                        Icons.edit_outlined,
                        color: widget.maroonColor,
                        size: 20,
                      ),
                      onPressed: () => _editTimeslotRange(option),
                    ),
                    onTap: isEnabled ? () => onSelected(option) : null,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async => _submitAssignment();

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sections = ref
          .read(sectionListProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Section>[],
          );
      final schedules = ref
          .read(schedulesProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Schedule>[],
          );
      final facultyList = ref
          .read(facultyListProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Faculty>[],
          );
      final subjectList = ref
          .read(subjectsProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Subject>[],
          );
      final roomList = ref
          .read(roomsProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Room>[],
          );
      final timeslotList = ref
          .read(timeslotsProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Timeslot>[],
          );
      final section = _resolveSection(sections);
      final selectedFaculty = _findFaculty(facultyList);
      final selectedSubject = _findSubject(subjectList);

      if (selectedSubject == null) {
        throw Exception(
          'Please select a valid subject assigned to this faculty.',
        );
      }
      if (selectedFaculty == null) {
        throw Exception('Please select a valid faculty member.');
      }
      if (_selectedUnits == null || _selectedHours == null) {
        throw Exception('Please select both units and hours.');
      }
      if (_isBlendedSubject(selectedSubject.types) &&
          _selectedLoadType == null) {
        setState(() => _showLoadTypeRequired = true);
        return;
      }

      _validateSelectedAssignment(
        faculty: selectedFaculty,
        subject: selectedSubject,
        section: section,
        roomList: roomList,
      );

      final effectiveTypes = _effectiveAssignmentTypes(
        selectedSubject.types,
        _selectedLoadType,
      );

      final conflictMessage = _detectAssignmentConflict(
        schedules: schedules,
        currentScheduleId: null,
        facultyId: _selectedFacultyId!,
        subjectId: _selectedSubjectId!,
        sectionId: _selectedSectionId,
        sectionCodeFallback: section.sectionCode,
        roomId: _selectedRoomId,
        timeslotId: _selectedTimeslotId,
        isAutoAssign: _isAutoAssign,
        facultyList: facultyList,
        subjectList: subjectList,
        roomList: roomList,
        timeslotList: timeslotList,
        sectionList: sections,
        effectiveTypes: effectiveTypes,
      );

      if (conflictMessage != null) {
        if (mounted) {
          _showConflictErrorDialog(context, conflictMessage);
        }
        return;
      }

      final schedule = Schedule(
        facultyId: _selectedFacultyId!,
        subjectId: _selectedSubjectId!,
        roomId: _selectedRoomId,
        timeslotId: _isAutoAssign ? null : _selectedTimeslotId,
        section: section.sectionCode,
        sectionId: _selectedSectionId,
        loadTypes: effectiveTypes,
        units: _selectedUnits,
        hours: _selectedHours,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final serverConflictMessage = await _validateScheduleWithServer(schedule);
      if (serverConflictMessage != null) {
        if (mounted) {
          _showConflictErrorDialog(context, serverConflictMessage);
        }
        return;
      }

      await client.admin.createSchedule(schedule);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        widget.onSuccess();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Assignment created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showConflictErrorDialog(context, _parseServerError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => _buildAssignmentDialog(context);

  Widget _buildAssignmentDialog(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final facultyAsync = ref.watch(facultyListProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);
    final sectionsAsync = ref.watch(sectionListProvider);
    final studentsAsync = ref.watch(studentsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 20 : 24,
      ),
      child: Container(
        width: isMobile ? double.infinity : 700,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.9 : 750,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: widget.maroonColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_add,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'New Schedule Assignment',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Faculty Dropdown
                      facultyAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading faculty'),
                        data: (facultyList) {
                          final filteredFaculty = facultyList
                              .where((f) => f.isActive && f.program != null)
                              .toList();

                          if (filteredFaculty.isEmpty) {
                            return const Text(
                              'No active faculty instructors available.',
                            );
                          }

                          return _buildDropdown<int>(
                            label: 'Faculty',
                            value: _selectedFacultyId,
                            items: filteredFaculty.map((f) => f.id!).toList(),
                            itemLabel: (id) => filteredFaculty
                                .firstWhere((f) => f.id == id)
                                .name,
                            onChanged: (value) => setState(() {
                              _selectedFacultyId = value;
                              _selectedRoomId = null;
                              _selectedTimeslotId = null;
                              final allSubjects = ref
                                  .read(subjectsProvider)
                                  .maybeWhen(
                                    data: (s) => s,
                                    orElse: () => <Subject>[],
                                  );
                              final allowed = _subjectsAssignedToFaculty(
                                allSubjects,
                                _selectedFacultyId,
                              );
                              if (_selectedSubjectId != null &&
                                  !allowed.any(
                                    (s) => s.id == _selectedSubjectId,
                                  )) {
                                _selectedSubjectId = null;
                                _applySubjectDefaults(null);
                              }
                            }),
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Subject Dropdown
                      subjectsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading subjects'),
                        data: (subjectList) {
                          if (_selectedFacultyId == null) {
                            return const Text(
                              'Select a faculty member first to see assigned subjects.',
                            );
                          }
                          final filtered = _subjectsAssignedToFaculty(
                            subjectList,
                            _selectedFacultyId,
                          );
                          if (filtered.isEmpty) {
                            return const Text(
                              'No subject is assigned to this faculty in Subject Management.',
                            );
                          }
                          return _buildDropdown<int>(
                            label: 'Subject',
                            value: _selectedSubjectId,
                            items: filtered.map((s) => s.id!).toList(),
                            itemLabel: (id) =>
                                filtered.firstWhere((s) => s.id == id).name,
                            onChanged: (value) => setState(() {
                              _selectedSubjectId = value;
                              _selectedRoomId = null;
                              _selectedTimeslotId = null;
                              final selected = filtered.where(
                                (s) => s.id == value,
                              );
                              _applySubjectDefaults(
                                selected.isNotEmpty ? selected.first : null,
                              );
                            }),
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final subjectList = ref
                              .watch(subjectsProvider)
                              .maybeWhen(
                                data: (s) => s,
                                orElse: () => <Subject>[],
                              );
                          Subject? selectedSubject;
                          for (final subject in subjectList) {
                            if (subject.id == _selectedSubjectId) {
                              selectedSubject = subject;
                              break;
                            }
                          }
                          return _buildSubjectTypeDisplay(
                            types:
                                selectedSubject?.types ?? const <SubjectType>[],
                            accentColor: widget.maroonColor,
                            isDark: isDark,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final subjectList = ref
                              .watch(subjectsProvider)
                              .maybeWhen(
                                data: (s) => s,
                                orElse: () => <Subject>[],
                              );
                          Subject? selectedSubject;
                          for (final subject in subjectList) {
                            if (subject.id == _selectedSubjectId) {
                              selectedSubject = subject;
                              break;
                            }
                          }
                          final canChooseLoadType =
                              selectedSubject != null &&
                              _isBlendedSubject(selectedSubject.types);
                          return _buildLoadTypeSelector(
                            show: canChooseLoadType,
                            selected: _selectedLoadType,
                            errorText:
                                _showLoadTypeRequired &&
                                    _selectedLoadType == null
                                ? 'Required'
                                : null,
                            onChanged: (value) {
                              setState(() {
                                _selectedLoadType = value;
                                _showLoadTypeRequired = false;
                                _selectedTimeslotId = null;
                                if (selectedSubject != null) {
                                  _applySubjectDefaults(
                                    selectedSubject,
                                    preserveSelection: true,
                                  );
                                }
                              });
                            },
                            accentColor: widget.maroonColor,
                            isDark: isDark,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Section (only sections that still have active students)
                      studentsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading students'),
                        data: (students) => sectionsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) =>
                              const Text('Error loading sections'),
                          data: (sections) {
                            final selectedFacultyProgram = _programForFacultyId(
                              ref
                                  .read(facultyListProvider)
                                  .maybeWhen(
                                    data: (s) => s,
                                    orElse: () => <Faculty>[],
                                  ),
                              _selectedFacultyId,
                            );
                            final selectedSubjectProgram = _programForSubjectId(
                              ref
                                  .read(subjectsProvider)
                                  .maybeWhen(
                                    data: (s) => s,
                                    orElse: () => <Subject>[],
                                  ),
                              _selectedSubjectId,
                            );
                            final subjectList = ref
                                .read(subjectsProvider)
                                .maybeWhen(
                                  data: (s) => s,
                                  orElse: () => <Subject>[],
                                );
                            Subject? selectedSubject;
                            for (final subject in subjectList) {
                              if (subject.id == _selectedSubjectId) {
                                selectedSubject = subject;
                                break;
                              }
                            }
                            final subjectYearLevel = selectedSubject?.yearLevel;
                            Program? targetProgram = selectedSubjectProgram;
                            if (selectedFacultyProgram != null &&
                                selectedFacultyProgram != Program.emc) {
                              targetProgram = selectedFacultyProgram;
                            }

                            final eligibleStudents = students.where((student) {
                              final matchesProgram =
                                  targetProgram == null ||
                                  _programFromStudentCourse(
                                        student.course,
                                      ) ==
                                      targetProgram;
                              final matchesYear =
                                  subjectYearLevel == null ||
                                  student.yearLevel == subjectYearLevel;
                              return matchesProgram && matchesYear;
                            });

                            final enrolledSectionIds = eligibleStudents
                                .where((s) => s.sectionId != null)
                                .map((s) => s.sectionId!)
                                .toSet();
                            final enrolledSectionCodes = eligibleStudents
                                .map((s) => s.section?.trim())
                                .whereType<String>()
                                .where((code) => code.isNotEmpty)
                                .toSet();
                            final filteredById = <int, Section>{};
                            for (final s in sections) {
                              if (s.id != null &&
                                  (enrolledSectionIds.contains(s.id) ||
                                      enrolledSectionCodes.contains(
                                        s.sectionCode.trim(),
                                      )) &&
                                  (targetProgram == null ||
                                      s.program == targetProgram)) {
                                filteredById[s.id!] = s;
                              }
                            }
                            final filtered = filteredById.values.toList()
                              ..sort(
                                (a, b) => _sectionDisplayLabel(
                                  a,
                                ).compareTo(_sectionDisplayLabel(b)),
                              );

                            if (filtered.isEmpty) {
                              return const Text('No sections available');
                            }

                            final items = filtered.map((s) => s.id!).toList();
                            if ((_selectedSectionId == null ||
                                    !items.contains(_selectedSectionId)) &&
                                items.isNotEmpty) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                setState(() {
                                  _selectedSectionId = items.first;
                                });
                              });
                            }
                            final initialId =
                                (_selectedSectionId != null &&
                                    items.contains(_selectedSectionId))
                                ? _selectedSectionId
                                : items.first;

                            return _buildDropdown<int>(
                              label: 'Section',
                              value: initialId,
                              items: items,
                              itemLabel: (id) => _sectionDisplayLabel(
                                filtered.firstWhere((s) => s.id == id),
                              ),
                              onChanged: (value) => setState(() {
                                _selectedSectionId = value;
                                _selectedTimeslotId = null;
                              }),
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildLoadDropdownField(
                        label: 'Unit',
                        icon: Icons.numbers,
                        value: _selectedUnits,
                        items: _unitOptions,
                        protectedItems: _manualUnitOptions,
                        onChanged: (value) => setState(() {
                          _selectedUnits = value;
                        }),
                        onAddPressed: () => _showAddLoadOptionDialog(
                          label: 'Unit',
                          helperText:
                              'Add another unit choice for this assignment dropdown.',
                          onValueAdded: (value) {
                            setState(() {
                              _unitOptions = _mergeLoadOptions(
                                _unitOptions,
                                value,
                              );
                              _selectedUnits = value;
                            });
                            unawaited(
                              _persistLoadOptions(
                                _facultyLoadUnitOptionsPrefsKey,
                                _unitOptions,
                              ),
                            );
                          },
                        ),
                        onRemoveSelected: () => _removeSelectedLoadOption(
                          label: 'Unit',
                          selectedValue: _selectedUnits,
                          currentItems: _unitOptions,
                          protectedItems: _manualUnitOptions,
                          onItemsUpdated: (items) {
                            setState(() {
                              _unitOptions = items;
                            });
                            unawaited(
                              _persistLoadOptions(
                                _facultyLoadUnitOptionsPrefsKey,
                                items,
                              ),
                            );
                          },
                          onSelectionUpdated: (value) {
                            setState(() {
                              _selectedUnits = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildLoadDropdownField(
                        label: 'Hour',
                        icon: Icons.access_time,
                        value: _selectedHours,
                        items: _hourOptions,
                        protectedItems: _manualHourOptions,
                        onChanged: (value) => setState(() {
                          _selectedHours = value;
                          _selectedTimeslotId = null;
                        }),
                        onAddPressed: () => _showAddLoadOptionDialog(
                          label: 'Hour',
                          helperText:
                              'Add another hour choice for this assignment dropdown.',
                          onValueAdded: (value) {
                            setState(() {
                              _hourOptions = _mergeLoadOptions(
                                _hourOptions,
                                value,
                              );
                              _selectedHours = value;
                              _selectedTimeslotId = null;
                            });
                            unawaited(
                              _persistLoadOptions(
                                _facultyLoadHourOptionsPrefsKey,
                                _hourOptions,
                              ),
                            );
                          },
                        ),
                        onRemoveSelected: () => _removeSelectedLoadOption(
                          label: 'Hour',
                          selectedValue: _selectedHours,
                          currentItems: _hourOptions,
                          protectedItems: _manualHourOptions,
                          onItemsUpdated: (items) {
                            setState(() {
                              _hourOptions = items;
                            });
                            unawaited(
                              _persistLoadOptions(
                                _facultyLoadHourOptionsPrefsKey,
                                items,
                              ),
                            );
                          },
                          onSelectionUpdated: (value) {
                            setState(() {
                              _selectedHours = value;
                              _selectedTimeslotId = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Auto-Assign Checkbox
                      CheckboxListTile(
                        value: _isAutoAssign,
                        onChanged: (value) {
                          setState(() {
                            final nextValue = value ?? false;
                            if (_isAutoAssign && !nextValue) {
                              _selectedTimeslotId = null;
                            }
                            _isAutoAssign = nextValue;
                          });
                        },
                        title: Text(
                          'Auto-Assign Timeslot',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Keep the selected room and let the system assign the time',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        activeColor: widget.maroonColor,
                      ),
                      const SizedBox(height: 16),

                      roomsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading rooms'),
                        data: (roomList) {
                          final subjects = ref
                              .read(subjectsProvider)
                              .maybeWhen(
                                data: (list) => list,
                                orElse: () => <Subject>[],
                              );
                          Subject? selectedSubject;
                          for (final subject in subjects) {
                            if (subject.id == _selectedSubjectId) {
                              selectedSubject = subject;
                              break;
                            }
                          }
                          final effectiveTypes = selectedSubject == null
                              ? const <SubjectType>[]
                              : _effectiveAssignmentTypes(
                                  selectedSubject.types,
                                  _selectedLoadType,
                                );
                          final filteredRooms = effectiveTypes.isEmpty
                              ? roomList
                                    .where(_isSupportedSchedulingRoom)
                                    .toList()
                              : roomList
                                    .where(
                                      (room) => _isRoomAllowedForTypes(
                                        room: room,
                                        loadTypes: effectiveTypes,
                                      ),
                                    )
                                    .toList();

                          if (filteredRooms.isEmpty) {
                            return Text(
                              _requiresLaboratoryRoom(effectiveTypes)
                                  ? 'No laboratory rooms available for this subject.'
                                  : 'No lecture rooms available for this subject.',
                              style: GoogleFonts.poppins(fontSize: 12),
                            );
                          }

                          return _buildDropdown<int>(
                            label: 'Room',
                            value: _selectedRoomId,
                            items: filteredRooms.map((r) => r.id!).toList(),
                            itemLabel: (id) => filteredRooms
                                .firstWhere((r) => r.id == id)
                                .name,
                            onChanged: (value) => setState(() {
                              _selectedRoomId = value;
                              _selectedTimeslotId = null;
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      timeslotsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading timeslots'),
                        data: (timeslotList) {
                          if (_selectedFacultyId == null) {
                            return Text(
                              'Select a faculty member to load available timeslots',
                              style: GoogleFonts.poppins(fontSize: 12),
                            );
                          }

                          final availabilityAsync = ref.watch(
                            facultyAvailabilityProvider(_selectedFacultyId!),
                          );

                          return availabilityAsync.when(
                            loading: () => const CircularProgressIndicator(),
                            error: (error, stack) => Text(
                              'Error loading availability',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            data: (availabilityList) {
                              if (availabilityList.isEmpty) {
                                return Text(
                                  _noPreferredTimeslotsMessage,
                                  style: GoogleFonts.poppins(fontSize: 12),
                                );
                              }

                              final subjects = ref
                                  .read(subjectsProvider)
                                  .maybeWhen(
                                    data: (list) => list,
                                    orElse: () => <Subject>[],
                                  );
                              Subject? selectedSubject;
                              for (final subject in subjects) {
                                if (subject.id == _selectedSubjectId) {
                                  selectedSubject = subject;
                                  break;
                                }
                              }

                              if (selectedSubject == null) {
                                return _buildHighlightedTimeslotHint(
                                  message: _selectSubjectTypeTimeslotMessage,
                                  accentColor: widget.maroonColor,
                                  isDark: isDark,
                                );
                              }

                              if (_isBlendedSubject(selectedSubject.types) &&
                                  _selectedLoadType == null) {
                                return _buildHighlightedTimeslotHint(
                                  message: _selectSubjectTypeTimeslotMessage,
                                  accentColor: widget.maroonColor,
                                  isDark: isDark,
                                );
                              }

                              final effectiveTypes = _effectiveAssignmentTypes(
                                selectedSubject.types,
                                _selectedLoadType,
                              );
                              final schedules = ref
                                  .read(schedulesProvider)
                                  .maybeWhen(
                                    data: (list) => list,
                                    orElse: () => <Schedule>[],
                                  );
                              final facultyList = ref
                                  .read(facultyListProvider)
                                  .maybeWhen(
                                    data: (list) => list,
                                    orElse: () => <Faculty>[],
                                  );
                              final sectionList = ref
                                  .read(sectionListProvider)
                                  .maybeWhen(
                                    data: (list) => list,
                                    orElse: () => <Section>[],
                                  );
                              Section? selectedSection;
                              for (final section in sectionList) {
                                if (section.id == _selectedSectionId) {
                                  selectedSection = section;
                                  break;
                                }
                              }
                              final hasSectionAvailability =
                                  _isStudentAvailabilityExemptSubject(
                                    selectedSubject,
                                  ) ||
                                  _hasConfiguredSectionAvailability(
                                    selectedSection,
                                  );
                              final sectionAvailabilityMessage =
                                  _sectionAvailabilityRequiredMessage(
                                    selectedSection?.sectionCode ?? '',
                                  );
                              final requiredHours =
                                  _selectedHours ??
                                  _requiredHoursForSubject(
                                    selectedSubject,
                                    effectiveTypes,
                                  );
                              final typeLabel =
                                  effectiveTypes.contains(
                                    SubjectType.laboratory,
                                  )
                                  ? 'Laboratory'
                                  : 'Lecture';
                              final result =
                                  _buildTimeslotOptionsFromAvailability(
                                    availability: availabilityList,
                                    sectionAvailability:
                                        _isStudentAvailabilityExemptSubject(
                                          selectedSubject,
                                        )
                                        ? const <_SectionAvailabilityWindow>[]
                                        : _sectionAvailabilityFromJson(
                                            selectedSection?.availabilityJson,
                                          ),
                                    timeslots: timeslotList,
                                    requiredHours: requiredHours,
                                    typeLabel: typeLabel,
                                    schedules: schedules,
                                    currentScheduleId: null,
                                    facultyId: _selectedFacultyId,
                                    roomId: _selectedRoomId,
                                    selectedTimeslotId: _selectedTimeslotId,
                                    facultyList: facultyList,
                                    effectiveTypes: effectiveTypes,
                                  );

                              final options = result.options;
                              final missingWindows = result.missing;
                              _syncAutoAssignedTimeslotPreview(options);
                              final syncKey = _timeslotWindowsKey(
                                missingWindows,
                              );
                              final isSyncingMissingTimeslots =
                                  missingWindows.isNotEmpty &&
                                  _syncingTimeslotKeys.contains(syncKey);
                              if (missingWindows.isNotEmpty &&
                                  !isSyncingMissingTimeslots) {
                                _syncMissingTimeslots(missingWindows);
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isAutoAssign) ...[
                                    _buildHighlightedTimeslotHint(
                                      message:
                                          'Auto-assign is turned on. The dropdown is still visible, but the system will assign the final timeslot.',
                                      accentColor: widget.maroonColor,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (missingWindows.isNotEmpty) ...[
                                    _buildHighlightedTimeslotHint(
                                      message:
                                          'Syncing updated faculty availability to the timeslot dropdown...',
                                      accentColor: widget.maroonColor,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (!hasSectionAvailability) ...[
                                    _buildHighlightedTimeslotHint(
                                      message: sectionAvailabilityMessage,
                                      accentColor: widget.maroonColor,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (!hasSectionAvailability)
                                    const SizedBox.shrink()
                                  else if (options.isEmpty &&
                                      !isSyncingMissingTimeslots)
                                    Text(
                                      'No timeslots available for this faculty',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                      ),
                                    )
                                  else if (options.isEmpty &&
                                      isSyncingMissingTimeslots)
                                    const SizedBox.shrink()
                                  else
                                    _buildTimeslotSearchField(
                                      label: 'Timeslot',
                                      options: options,
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.maroonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Create Assignment',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.maroonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Create Assignment',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon, color: widget.maroonColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.maroonColor, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dropdownBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final uniqueItems = items.toSet().toList();
    final hasSingleMatch = value == null
        ? true
        : uniqueItems.where((item) => item == value).length == 1;
    final safeValue = hasSingleMatch ? value : null;

    return DropdownButtonFormField<T>(
      initialValue: safeValue,
      dropdownColor: dropdownBg,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: textColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.maroonColor, width: 2),
        ),
      ),
      items: uniqueItems.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel(item),
            style: GoogleFonts.poppins(color: textColor),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.poppins(color: textColor),
    );
  }
}

// Edit Assignment Modal (similar structure to New Assignment)
class _EditAssignmentModal extends ConsumerStatefulWidget {
  final Schedule schedule;
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _EditAssignmentModal({
    required this.schedule,
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  ConsumerState<_EditAssignmentModal> createState() =>
      _EditAssignmentModalState();
}

class _EditAssignmentModalState extends ConsumerState<_EditAssignmentModal> {
  final _formKey = GlobalKey<FormState>();

  late int _selectedFacultyId;
  late int _selectedSubjectId;
  int? _selectedSectionId;
  int? _selectedRoomId;
  int? _selectedTimeslotId;
  Timeslot? _selectedTimeslotOverride;
  double? _selectedUnits;
  double? _selectedHours;
  late List<double> _unitOptions;
  late List<double> _hourOptions;
  bool _isAutoAssign = false;
  bool _isLoading = false;
  SubjectType? _selectedLoadType;
  bool _showLoadTypeRequired = false;
  final Set<String> _syncingTimeslotKeys = <String>{};

  bool get _canSubmit =>
      !_isLoading &&
      _selectedRoomId != null &&
      (_isAutoAssign || _selectedTimeslotId != null);

  void _applySubjectDefaults(
    Subject? subject, {
    bool preserveSelection = false,
  }) {
    if (subject == null) return;
    _selectedLoadType = _isBlendedSubject(subject.types)
        ? _selectedLoadType
        : null;
    if (!_isBlendedSubject(subject.types)) {
      _showLoadTypeRequired = false;
    }
    final effectiveTypes = _effectiveAssignmentTypes(
      subject.types,
      _selectedLoadType,
    );
    final suggestedUnits = subject.units.toDouble();
    final suggestedHours =
        subject.hours ?? _requiredHoursForSubject(subject, effectiveTypes);
    _unitOptions = _mergeLoadOptions(_unitOptions, suggestedUnits);
    _hourOptions = _mergeLoadOptions(_hourOptions, suggestedHours);
    _selectedUnits = _resolveSelectedLoadValue(
      preserveSelection ? _selectedUnits : null,
      suggestedUnits,
      _unitOptions,
    );
    _selectedHours = _resolveSelectedLoadValue(
      preserveSelection ? _selectedHours : null,
      suggestedHours,
      _hourOptions,
    );
  }

  Future<void> _showAddLoadOptionDialog({
    required String label,
    required String helperText,
    required ValueChanged<double> onValueAdded,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Add $label Option',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                helperText,
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: '$label value',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: widget.maroonColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  final parsed = double.tryParse((value ?? '').trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid $label value.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(
                dialogContext,
                double.parse(controller.text.trim()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.maroonColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Add', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;
    onValueAdded(_normalizeLoadOption(result));
  }

  Future<void> _removeSelectedLoadOption({
    required String label,
    required double? selectedValue,
    required List<double> currentItems,
    required List<double> protectedItems,
    required ValueChanged<List<double>> onItemsUpdated,
    required ValueChanged<double?> onSelectionUpdated,
  }) async {
    if (selectedValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Select a $label option to remove.')),
      );
      return;
    }
    if (currentItems.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least one $label option must remain available.'),
        ),
      );
      return;
    }
    if (protectedItems.contains(_normalizeLoadOption(selectedValue))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Default ${label.toLowerCase()} options cannot be deleted.',
          ),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove $label Option',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove ${_formatLoadValue(selectedValue)} $label${selectedValue == 1 ? '' : 's'} from this dropdown?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Remove', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final updatedItems = List<double>.from(currentItems)
      ..remove(_normalizeLoadOption(selectedValue));
    updatedItems.sort();
    onItemsUpdated(updatedItems);
    onSelectionUpdated(updatedItems.isEmpty ? null : updatedItems.first);
  }

  Widget _buildLoadDropdownField({
    required String label,
    required IconData icon,
    required double? value,
    required List<double> items,
    required List<double> protectedItems,
    required ValueChanged<double?> onChanged,
    required VoidCallback onAddPressed,
    required VoidCallback onRemoveSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final dropdownBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final uniqueItems = items.toSet().toList()..sort();
    final safeValue = uniqueItems.contains(value) ? value : null;
    final canDeleteSelected =
        value != null && !protectedItems.contains(_normalizeLoadOption(value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<Object>(
          initialValue: safeValue,
          isExpanded: true,
          dropdownColor: dropdownBg,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(color: textColor),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.maroonColor, width: 2),
            ),
          ),
          items: [
            ...uniqueItems.map(
              (item) => DropdownMenuItem<Object>(
                value: item,
                child: Text(
                  '${_formatLoadValue(item)} $label${item == 1 ? '' : 's'}',
                  style: GoogleFonts.poppins(color: textColor),
                ),
              ),
            ),
            if (canDeleteSelected)
              DropdownMenuItem<Object>(
                value: _deleteSelectedLoadOptionAction,
                child: Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Delete ${_formatLoadValue(value!)} $label${value == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: (selected) {
            if (selected == _deleteSelectedLoadOptionAction) {
              onRemoveSelected();
              return;
            }
            onChanged(selected as double?);
          },
          validator: (selected) => selected == null ? 'Required' : null,
          style: GoogleFonts.poppins(color: textColor),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onAddPressed,
            icon: Icon(icon, size: 18, color: widget.maroonColor),
            label: Text(
              'Add $label option',
              style: GoogleFonts.poppins(
                color: widget.maroonColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Section _resolveSection(List<Section> sections) {
    return sections.firstWhere(
      (s) => s.id == _selectedSectionId,
      orElse: () => sections.firstWhere(
        (s) => s.sectionCode == widget.schedule.section,
        orElse: () => sections.isNotEmpty
            ? sections.first
            : Section(
                sectionCode: widget.schedule.section,
                program: Program.it,
                yearLevel: 1,
                semester: 1,
                academicYear: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
      ),
    );
  }

  Faculty? _findFaculty(List<Faculty> facultyList) {
    for (final faculty in facultyList) {
      if (faculty.id == _selectedFacultyId) {
        return faculty;
      }
    }
    return null;
  }

  Subject? _findSubject(List<Subject> subjectList) {
    for (final subject in subjectList) {
      if (subject.id == _selectedSubjectId) {
        return subject;
      }
    }
    return null;
  }

  Room? _findRoom(List<Room> roomList) {
    for (final room in roomList) {
      if (room.id == _selectedRoomId) {
        return room;
      }
    }
    return null;
  }

  TimeOfDay _timeOfDayFromHHmm(String value) {
    final parts = value.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  String _timeOfDayToHHmm(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int? _requiredAssignmentMinutes() {
    final selectedHours = _selectedHours;
    if (selectedHours == null || selectedHours <= 0) return null;
    return (selectedHours * 60).round();
  }

  void _syncMissingTimeslots(List<_TimeslotWindow> windows) {
    if (windows.isEmpty) return;
    final key = _timeslotWindowsKey(windows);
    if (_syncingTimeslotKeys.contains(key)) return;
    _syncingTimeslotKeys.add(key);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _createTimeslotsFromWindows(
          ref: ref,
          context: context,
          windows: windows,
        );
      } finally {
        if (mounted) {
          setState(() {
            _syncingTimeslotKeys.remove(key);
          });
        } else {
          _syncingTimeslotKeys.remove(key);
        }
      }
    });
  }

  void _syncAutoAssignedTimeslotPreview(List<_TimeslotOption> options) {
    if (!_isAutoAssign) return;
    final enabledOptions = options.where((option) => option.isEnabled).toList();
    final previewId = enabledOptions.isEmpty
        ? null
        : enabledOptions.first.slot.id;
    if (_selectedTimeslotId == previewId) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedTimeslotId = previewId;
      });
    });
  }

  Future<void> _editTimeslotRange(_TimeslotOption option) async {
    final slot = option.slot;
    var startTime = _timeOfDayFromHHmm(slot.startTime);
    var endTime = _timeOfDayFromHHmm(slot.endTime);
    final requiredMinutes = _requiredAssignmentMinutes();
    final requiredHoursLabel = _selectedHours == null
        ? null
        : _formatLoadValue(_selectedHours!);
    final result = await showDialog<Timeslot>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> onPickStart() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: startTime,
            );
            if (picked != null) {
              if (requiredMinutes != null) {
                final int computedEndMinutes =
                    _timeOfDayToMinutes(picked) + requiredMinutes;
                if (computedEndMinutes >= 24 * 60) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Selected $requiredHoursLabel-hour duration does not fit in the day.',
                      ),
                    ),
                  );
                  return;
                }
                setDialogState(() {
                  startTime = picked;
                  endTime = _timeOfDayFromMinutes(computedEndMinutes);
                });
                return;
              }
              setDialogState(() => startTime = picked);
            }
          }

          Future<void> onPickEnd() async {
            final picked = await showTimePicker(
              context: context,
              initialTime: endTime,
            );
            if (picked != null) {
              if (requiredMinutes != null) {
                final int computedStartMinutes =
                    _timeOfDayToMinutes(picked) - requiredMinutes;
                if (computedStartMinutes < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Selected $requiredHoursLabel-hour duration does not fit in the day.',
                      ),
                    ),
                  );
                  return;
                }
                setDialogState(() {
                  endTime = picked;
                  startTime = _timeOfDayFromMinutes(computedStartMinutes);
                });
                return;
              }
              setDialogState(() => endTime = picked);
            }
          }

          return AlertDialog(
            title: Text(
              'Edit Timeslot Range',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDayAbbr(slot.day),
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                if (requiredHoursLabel != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Duration is linked to the selected subject load: $requiredHoursLabel hour${_selectedHours == 1 ? '' : 's'}.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Start', style: GoogleFonts.poppins()),
                  subtitle: Text(
                    startTime.format(context),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.schedule),
                  onTap: onPickStart,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('End', style: GoogleFonts.poppins()),
                  subtitle: Text(
                    endTime.format(context),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.schedule),
                  onTap: onPickEnd,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () async {
                  final startMinutes = _timeOfDayToMinutes(startTime);
                  final endMinutes = _timeOfDayToMinutes(endTime);
                  if (endMinutes <= startMinutes) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('End time must be after start time.'),
                      ),
                    );
                    return;
                  }
                  if (requiredMinutes != null &&
                      (endMinutes - startMinutes) != requiredMinutes) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Timeslot must match the selected $requiredHoursLabel-hour load.',
                        ),
                      ),
                      );
                    return;
                  }

                  final availabilityList = await _loadFacultyAvailability(
                    ref,
                    _selectedFacultyId,
                  );
                  final editedWindow = _TimeslotWindow(
                    day: slot.day,
                    startTime: _timeOfDayToHHmm(startTime),
                    endTime: _timeOfDayToHHmm(endTime),
                  );
                  if (!_windowFitsFacultyAvailability(
                    editedWindow,
                    availabilityList,
                  )) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Timeslot must stay within the selected faculty availability.',
                          ),
                        ),
                      );
                    }
                    return;
                  }

                  Navigator.pop(
                    context,
                    Timeslot(
                      id: slot.id,
                      day: slot.day,
                      startTime: _timeOfDayToHHmm(startTime),
                      endTime: _timeOfDayToHHmm(endTime),
                      label:
                          '${_getDayAbbr(slot.day)} ${_timeOfDayToHHmm(startTime)}-${_timeOfDayToHHmm(endTime)}',
                      createdAt: slot.createdAt,
                      updatedAt: DateTime.now(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.maroonColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Save', style: GoogleFonts.poppins()),
              ),
            ],
          );
        },
      ),
    );

    if (result == null) return;

    try {
      final resolvedTimeslot = await _findOrCreateMatchingTimeslot(result);
      ref.invalidate(timeslotsProvider);
      if (mounted) {
        setState(() {
          _selectedTimeslotId = resolvedTimeslot.id;
          _selectedTimeslotOverride = resolvedTimeslot;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timeslot selected successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showConflictErrorDialog(context, _parseServerError(e));
      }
    }
  }

  void _validateSelectedAssignment({
    required Faculty faculty,
    required Subject subject,
    required Section section,
    required List<Room> roomList,
  }) {
    if (!_hasConfiguredSectionAvailability(section)) {
      throw Exception(_sectionAvailabilityRequiredMessage(section.sectionCode));
    }

    if (faculty.program != null && faculty.program != section.program) {
      final isEmcTeachingIt =
          faculty.program == Program.emc && section.program == Program.it;
      if (!isEmcTeachingIt) {
        throw Exception(
          'Faculty program must match the selected section program.',
        );
      }
    }

    if (subject.program != section.program) {
      throw Exception(
        'Subject program must match the selected section program.',
      );
    }

    if (_isBlendedSubject(subject.types) && _selectedLoadType == null) {
      throw Exception(
        'Please select whether this blended subject is Lecture or Lab.',
      );
    }

    if (_selectedRoomId == null) {
      return;
    }

    final effectiveTypes = _effectiveAssignmentTypes(
      subject.types,
      _selectedLoadType,
    );
    final selectedRoom = _findRoom(roomList);
    if (selectedRoom == null) {
      return;
    }

    if (!_isSupportedSchedulingRoom(selectedRoom)) {
      throw Exception(
        'Only lecture and laboratory rooms are allowed for scheduling.',
      );
    }

    if (effectiveTypes.isNotEmpty &&
        !_isRoomAllowedForTypes(
          room: selectedRoom,
          loadTypes: effectiveTypes,
        )) {
      throw Exception(
        _requiresLaboratoryRoom(effectiveTypes)
            ? 'Laboratory or blended subjects can only be assigned to laboratory rooms.'
            : 'Lecture-only subjects can only be assigned to lecture rooms.',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _unitOptions = List<double>.from(_manualUnitOptions);
    _hourOptions = List<double>.from(_manualHourOptions);
    if (widget.schedule.units != null) {
      _unitOptions = _mergeLoadOptions(_unitOptions, widget.schedule.units!);
    }
    if (widget.schedule.hours != null) {
      _hourOptions = _mergeLoadOptions(_hourOptions, widget.schedule.hours!);
    }
    _selectedUnits = _resolveSelectedLoadValue(
      widget.schedule.units,
      widget.schedule.units ?? 2.0,
      _unitOptions,
    );
    _selectedHours = _resolveSelectedLoadValue(
      widget.schedule.hours,
      widget.schedule.hours ?? 2.0,
      _hourOptions,
    );
    _selectedSectionId = widget.schedule.sectionId;
    _selectedFacultyId = widget.schedule.facultyId;
    _selectedSubjectId = widget.schedule.subjectId;
    _selectedRoomId = widget.schedule.roomId == -1
        ? null
        : widget.schedule.roomId;
    _selectedTimeslotId = widget.schedule.timeslotId == -1
        ? null
        : widget.schedule.timeslotId;
    _selectedTimeslotOverride = widget.schedule.timeslot;
    _isAutoAssign =
        widget.schedule.timeslotId == null || widget.schedule.timeslotId == -1;

    final subjects = ref
        .read(subjectsProvider)
        .maybeWhen(
          data: (s) => s,
          orElse: () => <Subject>[],
        );
    for (final subject in subjects) {
      if (subject.id == _selectedSubjectId) {
        _applySubjectDefaults(subject, preserveSelection: true);
        break;
      }
    }
    unawaited(_loadSavedLoadOptions());
  }

  Future<void> _loadSavedLoadOptions() async {
    final savedUnits = await _loadPersistedLoadOptions(
      _facultyLoadUnitOptionsPrefsKey,
      _manualUnitOptions,
    );
    final savedHours = await _loadPersistedLoadOptions(
      _facultyLoadHourOptionsPrefsKey,
      _manualHourOptions,
    );
    if (!mounted) return;
    setState(() {
      _unitOptions = savedUnits;
      _hourOptions = savedHours;
      if (widget.schedule.units != null) {
        _unitOptions = _mergeLoadOptions(_unitOptions, widget.schedule.units!);
      }
      if (widget.schedule.hours != null) {
        _hourOptions = _mergeLoadOptions(_hourOptions, widget.schedule.hours!);
      }
      final subject = _findSubject(
        ref.read(subjectsProvider).maybeWhen(
          data: (subjects) => subjects,
          orElse: () => <Subject>[],
        ),
      );
      if (subject != null) {
        _applySubjectDefaults(subject, preserveSelection: true);
      }
    });
  }

  Widget _buildTimeslotSearchField({
    required String label,
    required List<_TimeslotOption> options,
  }) {
    final selectedOption = _selectedTimeslotId == null
        ? null
        : options
              .where((o) => o.slot.id == _selectedTimeslotId)
              .cast<_TimeslotOption?>()
              .firstWhere((o) => o != null, orElse: () => null);
    final selectedLabel =
        selectedOption?.label ??
        (_selectedTimeslotOverride != null &&
                _selectedTimeslotOverride!.id == _selectedTimeslotId
            ? CITESchedDateUtils.formatTimeslot(
                _selectedTimeslotOverride!.day,
                _selectedTimeslotOverride!.startTime,
                _selectedTimeslotOverride!.endTime,
              )
            : null);

    return Autocomplete<_TimeslotOption>(
      key: ValueKey(
        'edit-timeslot-${_selectedFacultyId}-${_selectedSubjectId}-${_selectedSectionId ?? 'none'}-${_selectedRoomId ?? 'none'}-${_selectedLoadType?.name ?? 'default'}-${_isAutoAssign ? 'auto' : 'manual'}-${_selectedTimeslotId ?? 'none'}-${options.length}',
      ),
      displayStringForOption: (option) => option.label,
      initialValue: selectedLabel == null
          ? const TextEditingValue()
          : TextEditingValue(text: selectedLabel),
      optionsBuilder: (TextEditingValue value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) {
          return options;
        }
        return options.where(
          (option) => option.label.toLowerCase().contains(query),
        );
      },
      onSelected: (option) {
        if (!option.isEnabled) return;
        setState(() {
          _selectedTimeslotId = option.slot.id;
          _selectedTimeslotOverride = option.slot;
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (selectedLabel != null &&
            selectedLabel.isNotEmpty &&
            controller.text != selectedLabel) {
          controller.value = TextEditingValue(
            text: selectedLabel,
            selection: TextSelection.collapsed(offset: selectedLabel.length),
          );
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: widget.maroonColor, width: 2),
            ),
            helperText: _selectedTimeslotId == null
                ? 'Select from dropdown. Typed text alone will not be accepted.'
                : null,
          ),
          onChanged: (value) {
            final normalizedValue = value.toLowerCase().trim();
            final matchesSelectedLabel =
                selectedLabel != null &&
                selectedLabel.toLowerCase().trim() == normalizedValue;
            final match = matchesSelectedLabel || options.any(
              (option) =>
                  option.label.toLowerCase().trim() ==
                  normalizedValue,
            );
            if (!match && _selectedTimeslotId != null) {
              setState(() {
                _selectedTimeslotId = null;
                _selectedTimeslotOverride = null;
              });
            }
          },
          validator: (_) => _selectedTimeslotId == null ? 'Required' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 520,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  final isEnabled = option.isEnabled;
                  return ListTile(
                    dense: true,
                    enabled: isEnabled,
                    title: Text(
                      option.label,
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                    subtitle: option.disabledReason == null
                        ? null
                        : Text(
                            option.disabledReason!,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                    trailing: IconButton(
                      tooltip: 'Edit timeslot range',
                      icon: Icon(
                        Icons.edit_outlined,
                        color: widget.maroonColor,
                        size: 20,
                      ),
                      onPressed: () => _editTimeslotRange(option),
                    ),
                    onTap: isEnabled ? () => onSelected(option) : null,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async => _submitAssignment();

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sections = ref
          .read(sectionListProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Section>[],
          );
      final schedules = ref
          .read(schedulesProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Schedule>[],
          );
      final facultyList = ref
          .read(facultyListProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Faculty>[],
          );
      final subjectList = ref
          .read(subjectsProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Subject>[],
          );
      final roomList = ref
          .read(roomsProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Room>[],
          );
      final timeslotList = ref
          .read(timeslotsProvider)
          .maybeWhen(
            data: (s) => s,
            orElse: () => <Timeslot>[],
          );

      final section = _resolveSection(sections);
      final selectedFaculty = _findFaculty(facultyList);
      final selectedSubject = _findSubject(subjectList);
      if (selectedFaculty == null) {
        throw Exception('Please select a valid faculty member.');
      }
      if (selectedSubject == null) {
        throw Exception(
          'Please select a valid subject assigned to this faculty.',
        );
      }
      if (_selectedUnits == null || _selectedHours == null) {
        throw Exception('Please select both units and hours.');
      }
      if (_isBlendedSubject(selectedSubject.types) &&
          _selectedLoadType == null) {
        setState(() => _showLoadTypeRequired = true);
        return;
      }
      _validateSelectedAssignment(
        faculty: selectedFaculty,
        subject: selectedSubject,
        section: section,
        roomList: roomList,
      );
      final effectiveTypes = _effectiveAssignmentTypes(
        selectedSubject.types,
        _selectedLoadType,
      );

      final conflictMessage = _detectAssignmentConflict(
        schedules: schedules,
        currentScheduleId: widget.schedule.id,
        facultyId: selectedFaculty.id!,
        subjectId: selectedSubject.id!,
        sectionId: _selectedSectionId ?? widget.schedule.sectionId,
        sectionCodeFallback: section.sectionCode,
        roomId: _selectedRoomId,
        timeslotId: _selectedTimeslotId,
        isAutoAssign: _isAutoAssign,
        facultyList: facultyList,
        subjectList: subjectList,
        roomList: roomList,
        timeslotList: timeslotList,
        sectionList: sections,
        effectiveTypes: effectiveTypes,
      );

      if (conflictMessage != null) {
        if (mounted) {
          _showConflictErrorDialog(context, conflictMessage);
        }
        return;
      }

      final updatedSchedule = Schedule(
        id: widget.schedule.id,
        facultyId: selectedFaculty.id!,
        subjectId: selectedSubject.id!,
        roomId: _selectedRoomId,
        timeslotId: _isAutoAssign ? null : _selectedTimeslotId,
        section: section.sectionCode,
        sectionId: _selectedSectionId ?? widget.schedule.sectionId,
        loadTypes: effectiveTypes,
        units: _selectedUnits,
        hours: _selectedHours,
        createdAt: widget.schedule.createdAt,
        updatedAt: DateTime.now(),
      );

      await client.admin.updateSchedule(updatedSchedule);

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        widget.onSuccess();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Edit saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showConflictErrorDialog(context, _parseServerError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final facultyAsync = ref.watch(facultyListProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final roomsAsync = ref.watch(roomsProvider);
    final timeslotsAsync = ref.watch(timeslotsProvider);
    final sectionsAsync = ref.watch(sectionListProvider);
    final studentsAsync = ref.watch(studentsProvider);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: isMobile ? 24 : 32,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? double.infinity : 700,
        constraints: BoxConstraints(
          maxWidth: isMobile ? 420 : 700,
          maxHeight:
              MediaQuery.of(context).size.height * (isMobile ? 0.88 : 0.82),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: widget.maroonColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: isMobile ? 24 : 28,
                  ),
                  SizedBox(width: isMobile ? 8 : 12),
                  Expanded(
                    child: Text(
                      'Edit Schedule Assignment',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form (same structure as New Assignment)
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Faculty Dropdown
                      facultyAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading faculty'),
                        data: (facultyList) {
                          final filteredFaculty = facultyList
                              .where((f) => f.isActive && f.program != null)
                              .toList();
                          if (!filteredFaculty.any(
                            (f) => f.id == _selectedFacultyId,
                          )) {
                            final current = facultyList.where(
                              (f) => f.id == _selectedFacultyId,
                            );
                            if (current.isNotEmpty) {
                              filteredFaculty.add(current.first);
                            }
                          }
                          return _buildDropdown<int>(
                            label: 'Faculty',
                            value: _selectedFacultyId,
                            items: filteredFaculty.map((f) => f.id!).toList(),
                            itemLabel: (id) => filteredFaculty
                                .firstWhere((f) => f.id == id)
                                .name,
                            onChanged: (value) => setState(() {
                              _selectedFacultyId = value!;
                              _selectedRoomId = null;
                              _selectedTimeslotId = null;
                              final allSubjects = ref
                                  .read(subjectsProvider)
                                  .maybeWhen(
                                    data: (s) => s,
                                    orElse: () => <Subject>[],
                                  );
                              final allowed = _subjectsAssignedToFaculty(
                                allSubjects,
                                _selectedFacultyId,
                              );
                              if (!allowed.any(
                                (s) => s.id == _selectedSubjectId,
                              )) {
                                _selectedSubjectId = allowed.isNotEmpty
                                    ? allowed.first.id!
                                    : _selectedSubjectId;
                                final selected = allowed.where(
                                  (s) => s.id == _selectedSubjectId,
                                );
                                _applySubjectDefaults(
                                  selected.isNotEmpty ? selected.first : null,
                                );
                              }
                            }),
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Subject Dropdown
                      subjectsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading subjects'),
                        data: (subjectList) {
                          final filtered = _subjectsAssignedToFaculty(
                            subjectList,
                            _selectedFacultyId,
                          );
                          if (!filtered.any(
                            (s) => s.id == _selectedSubjectId,
                          )) {
                            final current = subjectList.where(
                              (s) => s.id == _selectedSubjectId,
                            );
                            if (current.isNotEmpty) {
                              filtered.add(current.first);
                            }
                          }
                          if (filtered.isEmpty) {
                            return const Text(
                              'No subject is assigned to this faculty in Subject Management.',
                            );
                          }
                          return _buildDropdown<int>(
                            label: 'Subject',
                            value: _selectedSubjectId,
                            items: filtered.map((s) => s.id!).toList(),
                            itemLabel: (id) =>
                                filtered.firstWhere((s) => s.id == id).name,
                            onChanged: (value) => setState(() {
                              _selectedSubjectId = value!;
                              _selectedRoomId = null;
                              _selectedTimeslotId = null;
                              final selected = filtered.where(
                                (s) => s.id == value,
                              );
                              _applySubjectDefaults(
                                selected.isNotEmpty ? selected.first : null,
                              );
                            }),
                            validator: (value) =>
                                value == null ? 'Required' : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final subjectList = ref
                              .watch(subjectsProvider)
                              .maybeWhen(
                                data: (s) => s,
                                orElse: () => <Subject>[],
                              );
                          Subject? selectedSubject;
                          for (final subject in subjectList) {
                            if (subject.id == _selectedSubjectId) {
                              selectedSubject = subject;
                              break;
                            }
                          }
                          return _buildSubjectTypeDisplay(
                            types:
                                selectedSubject?.types ?? const <SubjectType>[],
                            accentColor: widget.maroonColor,
                            isDark: isDark,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final subjectList = ref
                              .watch(subjectsProvider)
                              .maybeWhen(
                                data: (s) => s,
                                orElse: () => <Subject>[],
                              );
                          Subject? selectedSubject;
                          for (final subject in subjectList) {
                            if (subject.id == _selectedSubjectId) {
                              selectedSubject = subject;
                              break;
                            }
                          }
                          final canChooseLoadType =
                              selectedSubject != null &&
                              _isBlendedSubject(selectedSubject.types);
                          return _buildLoadTypeSelector(
                            show: canChooseLoadType,
                            selected: _selectedLoadType,
                            errorText:
                                _showLoadTypeRequired &&
                                    _selectedLoadType == null
                                ? 'Required'
                                : null,
                            onChanged: (value) {
                              setState(() {
                                _selectedLoadType = value;
                                _showLoadTypeRequired = false;
                                _selectedTimeslotId = null;
                                if (selectedSubject != null) {
                                  _applySubjectDefaults(
                                    selectedSubject,
                                    preserveSelection: true,
                                  );
                                }
                              });
                            },
                            accentColor: widget.maroonColor,
                            isDark: isDark,
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Section (only sections that still have active students)
                      studentsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading students'),
                        data: (students) => sectionsAsync.when(
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) =>
                              const Text('Error loading sections'),
                          data: (sections) {
                            final selectedFacultyProgram = _programForFacultyId(
                              ref
                                  .read(facultyListProvider)
                                  .maybeWhen(
                                    data: (s) => s,
                                    orElse: () => <Faculty>[],
                                  ),
                              _selectedFacultyId,
                            );
                            final selectedSubjectProgram = _programForSubjectId(
                              ref
                                  .read(subjectsProvider)
                                  .maybeWhen(
                                    data: (s) => s,
                                    orElse: () => <Subject>[],
                                  ),
                              _selectedSubjectId,
                            );
                            final subjectList = ref
                                .read(subjectsProvider)
                                .maybeWhen(
                                  data: (s) => s,
                                  orElse: () => <Subject>[],
                                );
                            Subject? selectedSubject;
                            for (final subject in subjectList) {
                              if (subject.id == _selectedSubjectId) {
                                selectedSubject = subject;
                                break;
                              }
                            }
                            final subjectYearLevel = selectedSubject?.yearLevel;
                            Program? targetProgram = selectedSubjectProgram;
                            if (selectedFacultyProgram != null &&
                                selectedFacultyProgram != Program.emc) {
                              targetProgram = selectedFacultyProgram;
                            }

                            final eligibleStudents = students.where((student) {
                              final matchesProgram =
                                  targetProgram == null ||
                                  _programFromStudentCourse(
                                        student.course,
                                      ) ==
                                      targetProgram;
                              final matchesYear =
                                  subjectYearLevel == null ||
                                  student.yearLevel == subjectYearLevel;
                              return matchesProgram && matchesYear;
                            });

                            final enrolledSectionIds = eligibleStudents
                                .where((s) => s.sectionId != null)
                                .map((s) => s.sectionId!)
                                .toSet();
                            final enrolledSectionCodes = eligibleStudents
                                .map((s) => s.section?.trim())
                                .whereType<String>()
                                .where((code) => code.isNotEmpty)
                                .toSet();
                            final filteredById = <int, Section>{};
                            for (final s in sections) {
                              if (s.id != null &&
                                  (enrolledSectionIds.contains(s.id) ||
                                      enrolledSectionCodes.contains(
                                        s.sectionCode.trim(),
                                      ))) {
                                filteredById[s.id!] = s;
                              }
                            }
                            // Always include the schedule's current section so
                            // the edit dropdown cannot visually drift from
                            // what will actually be saved.
                            for (final s in sections) {
                              if (s.id == null) continue;
                              if (s.id == widget.schedule.sectionId ||
                                  s.sectionCode == widget.schedule.section) {
                                filteredById[s.id!] = s;
                              }
                            }
                            final filtered = filteredById.values.toList()
                              ..sort(
                                (a, b) => _sectionDisplayLabel(
                                  a,
                                ).compareTo(_sectionDisplayLabel(b)),
                              );

                            if (filtered.isEmpty) {
                              return const Text('No sections available');
                            }

                            final items = filtered.map((s) => s.id!).toList();
                            final fallbackId = filtered
                                .firstWhere(
                                  (s) =>
                                      s.id == widget.schedule.sectionId ||
                                      s.sectionCode == widget.schedule.section,
                                  orElse: () => filtered.first,
                                )
                                .id!;
                            final initialId =
                                (_selectedSectionId != null &&
                                    items.contains(_selectedSectionId))
                                ? _selectedSectionId
                                : fallbackId;

                            return _buildDropdown<int>(
                              label: 'Section',
                              value: initialId,
                              items: items,
                              itemLabel: (id) => _sectionDisplayLabel(
                                filtered.firstWhere((s) => s.id == id),
                              ),
                              onChanged: (value) => setState(() {
                                _selectedSectionId = value;
                                _selectedTimeslotId = null;
                              }),
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildLoadDropdownField(
                        label: 'Unit',
                        icon: Icons.numbers,
                        value: _selectedUnits,
                        items: _unitOptions,
                        protectedItems: _manualUnitOptions,
                        onChanged: (value) => setState(() {
                          _selectedUnits = value;
                        }),
                        onAddPressed: () => _showAddLoadOptionDialog(
                          label: 'Unit',
                          helperText:
                              'Add another unit choice for this assignment dropdown.',
                          onValueAdded: (value) {
                            setState(() {
                              _unitOptions = _mergeLoadOptions(
                                _unitOptions,
                                value,
                              );
                              _selectedUnits = value;
                            });
                            unawaited(
                              _persistLoadOptions(
                                _facultyLoadUnitOptionsPrefsKey,
                                _unitOptions,
                              ),
                            );
                          },
                        ),
                        onRemoveSelected: () => _removeSelectedLoadOption(
                          label: 'Unit',
                          selectedValue: _selectedUnits,
                          currentItems: _unitOptions,
                          protectedItems: _manualUnitOptions,
                          onItemsUpdated: (items) {
                            setState(() {
                              _unitOptions = items;
                            });
                            unawaited(
                              _persistLoadOptions(
                                _facultyLoadUnitOptionsPrefsKey,
                                items,
                              ),
                            );
                          },
                          onSelectionUpdated: (value) {
                            setState(() {
                              _selectedUnits = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildLoadDropdownField(
                        label: 'Hour',
                        icon: Icons.access_time,
                        value: _selectedHours,
                        items: _hourOptions,
                        protectedItems: _manualHourOptions,
                        onChanged: (value) => setState(() {
                          _selectedHours = value;
                          _selectedTimeslotId = null;
                        }),
                        onAddPressed: () => _showAddLoadOptionDialog(
                          label: 'Hour',
                          helperText:
                              'Add another hour choice for this assignment dropdown.',
                          onValueAdded: (value) {
                            setState(() {
                              _hourOptions = _mergeLoadOptions(
                                _hourOptions,
                                value,
                              );
                              _selectedHours = value;
                              _selectedTimeslotId = null;
                            });
                            unawaited(
                              _persistLoadOptions(
                                _facultyLoadHourOptionsPrefsKey,
                                _hourOptions,
                              ),
                            );
                          },
                        ),
                        onRemoveSelected: () => _removeSelectedLoadOption(
                          label: 'Hour',
                          selectedValue: _selectedHours,
                          currentItems: _hourOptions,
                          protectedItems: _manualHourOptions,
                          onItemsUpdated: (items) {
                            setState(() {
                              _hourOptions = items;
                            });
                            unawaited(
                              _persistLoadOptions(
                                _facultyLoadHourOptionsPrefsKey,
                                items,
                              ),
                            );
                          },
                          onSelectionUpdated: (value) {
                            setState(() {
                              _selectedHours = value;
                              _selectedTimeslotId = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Auto-Assign Checkbox
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _isAutoAssign,
                        onChanged: (value) {
                          setState(() {
                            final nextValue = value ?? false;
                            if (_isAutoAssign && !nextValue) {
                              _selectedTimeslotId = null;
                            }
                            _isAutoAssign = nextValue;
                          });
                        },
                        title: Text(
                          'Auto-Assign Timeslot',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Keep the selected room and let the system assign the time',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                        activeColor: widget.maroonColor,
                      ),
                      const SizedBox(height: 16),

                      roomsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading rooms'),
                        data: (roomList) {
                          final subjects = ref
                              .read(subjectsProvider)
                              .maybeWhen(
                                data: (list) => list,
                                orElse: () => <Subject>[],
                              );
                          Subject? selectedSubject;
                          for (final subject in subjects) {
                            if (subject.id == _selectedSubjectId) {
                              selectedSubject = subject;
                              break;
                            }
                          }
                          final effectiveTypes = selectedSubject == null
                              ? const <SubjectType>[]
                              : _effectiveAssignmentTypes(
                                  selectedSubject.types,
                                  _selectedLoadType,
                                );
                          final filteredRooms = effectiveTypes.isEmpty
                              ? roomList
                                    .where(_isSupportedSchedulingRoom)
                                    .toList()
                              : roomList
                                    .where(
                                      (room) => _isRoomAllowedForTypes(
                                        room: room,
                                        loadTypes: effectiveTypes,
                                      ),
                                    )
                                    .toList();

                          if (filteredRooms.isEmpty) {
                            return Text(
                              _requiresLaboratoryRoom(effectiveTypes)
                                  ? 'No laboratory rooms available for this subject.'
                                  : 'No lecture rooms available for this subject.',
                              style: GoogleFonts.poppins(fontSize: 12),
                            );
                          }

                          return _buildDropdown<int>(
                            label: 'Room',
                            value: _selectedRoomId,
                            items: filteredRooms.map((r) => r.id!).toList(),
                            itemLabel: (id) => filteredRooms
                                .firstWhere((r) => r.id == id)
                                .name,
                            onChanged: (value) => setState(() {
                              _selectedRoomId = value;
                              _selectedTimeslotId = null;
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      timeslotsAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) =>
                            const Text('Error loading timeslots'),
                        data: (timeslotList) {
                          final availabilityAsync = ref.watch(
                            facultyAvailabilityProvider(_selectedFacultyId),
                          );

                          return availabilityAsync.when(
                            loading: () => const CircularProgressIndicator(),
                            error: (error, stack) => Text(
                              'Error loading availability',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            data: (availabilityList) {
                              if (availabilityList.isEmpty) {
                                return Text(
                                  _noPreferredTimeslotsMessage,
                                  style: GoogleFonts.poppins(fontSize: 12),
                                );
                              }

                              final subjects = ref
                                  .read(subjectsProvider)
                                  .maybeWhen(
                                    data: (list) => list,
                                    orElse: () => <Subject>[],
                                  );
                              Subject? selectedSubject;
                              for (final subject in subjects) {
                                if (subject.id == _selectedSubjectId) {
                                  selectedSubject = subject;
                                  break;
                                }
                              }

                              if (selectedSubject == null) {
                                return _buildHighlightedTimeslotHint(
                                  message: _selectSubjectTypeTimeslotMessage,
                                  accentColor: widget.maroonColor,
                                  isDark: isDark,
                                );
                              }

                              if (_isBlendedSubject(selectedSubject.types) &&
                                  _selectedLoadType == null) {
                                return _buildHighlightedTimeslotHint(
                                  message: _selectSubjectTypeTimeslotMessage,
                                  accentColor: widget.maroonColor,
                                  isDark: isDark,
                                );
                              }

                              final effectiveTypes = _effectiveAssignmentTypes(
                                selectedSubject.types,
                                _selectedLoadType,
                              );
                              final schedules = ref
                                  .read(schedulesProvider)
                                  .maybeWhen(
                                    data: (list) => list,
                                    orElse: () => <Schedule>[],
                                  );
                              final facultyList = ref
                                  .read(facultyListProvider)
                                  .maybeWhen(
                                    data: (list) => list,
                                    orElse: () => <Faculty>[],
                                  );
                              final sectionList = ref
                                  .read(sectionListProvider)
                                  .maybeWhen(
                                    data: (list) => list,
                                    orElse: () => <Section>[],
                                  );
                              Section? selectedSection;
                              for (final section in sectionList) {
                                if (section.id ==
                                    (_selectedSectionId ??
                                        widget.schedule.sectionId)) {
                                  selectedSection = section;
                                  break;
                                }
                              }
                              final hasSectionAvailability =
                                  _isStudentAvailabilityExemptSubject(
                                    selectedSubject,
                                  ) ||
                                  _hasConfiguredSectionAvailability(
                                    selectedSection,
                                  );
                              final sectionAvailabilityMessage =
                                  _sectionAvailabilityRequiredMessage(
                                    selectedSection?.sectionCode ?? '',
                                  );
                              final requiredHours =
                                  _selectedHours ??
                                  _requiredHoursForSubject(
                                    selectedSubject,
                                    effectiveTypes,
                                  );
                              final typeLabel =
                                  effectiveTypes.contains(
                                    SubjectType.laboratory,
                                  )
                                  ? 'Laboratory'
                                  : 'Lecture';
                              final result =
                                  _buildTimeslotOptionsFromAvailability(
                                    availability: availabilityList,
                                    sectionAvailability:
                                        _isStudentAvailabilityExemptSubject(
                                          selectedSubject,
                                        )
                                        ? const <_SectionAvailabilityWindow>[]
                                        : _sectionAvailabilityFromJson(
                                            selectedSection?.availabilityJson,
                                          ),
                                    timeslots: timeslotList,
                                    requiredHours: requiredHours,
                                    typeLabel: typeLabel,
                                    schedules: schedules,
                                    currentScheduleId: widget.schedule.id,
                                    facultyId: _selectedFacultyId,
                                    roomId: _selectedRoomId,
                                    selectedTimeslotId: _selectedTimeslotId,
                                    facultyList: facultyList,
                                    effectiveTypes: effectiveTypes,
                                  );

                              final options = result.options;
                              final missingWindows = result.missing;
                              _syncAutoAssignedTimeslotPreview(options);
                              final syncKey = _timeslotWindowsKey(
                                missingWindows,
                              );
                              final isSyncingMissingTimeslots =
                                  missingWindows.isNotEmpty &&
                                  _syncingTimeslotKeys.contains(syncKey);
                              if (missingWindows.isNotEmpty &&
                                  !isSyncingMissingTimeslots) {
                                _syncMissingTimeslots(missingWindows);
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_isAutoAssign) ...[
                                    _buildHighlightedTimeslotHint(
                                      message:
                                          'Auto-assign is turned on. The dropdown is still visible, but the system will assign the final timeslot.',
                                      accentColor: widget.maroonColor,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (missingWindows.isNotEmpty) ...[
                                    _buildHighlightedTimeslotHint(
                                      message:
                                          'Syncing updated faculty availability to the timeslot dropdown...',
                                      accentColor: widget.maroonColor,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (!hasSectionAvailability) ...[
                                    _buildHighlightedTimeslotHint(
                                      message: sectionAvailabilityMessage,
                                      accentColor: widget.maroonColor,
                                      isDark: isDark,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  if (!hasSectionAvailability)
                                    const SizedBox.shrink()
                                  else if (options.isEmpty &&
                                      !isSyncingMissingTimeslots)
                                    Text(
                                      'No timeslots available for this faculty',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                      ),
                                    )
                                  else if (options.isEmpty &&
                                      isSyncingMissingTimeslots)
                                    const SizedBox.shrink()
                                  else
                                    _buildTimeslotSearchField(
                                      label: 'Timeslot',
                                      options: options,
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.maroonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(color: Colors.grey[700]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.maroonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(icon, color: widget.maroonColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.maroonColor, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    final uniqueItems = items.toSet().toList();
    final hasSingleMatch = value == null
        ? true
        : uniqueItems.where((item) => item == value).length == 1;
    final safeValue = hasSingleMatch ? value : null;

    return DropdownButtonFormField<T>(
      initialValue: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.maroonColor, width: 2),
        ),
      ),
      items: uniqueItems.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
      style: GoogleFonts.poppins(color: Colors.black87),
    );
  }
}
