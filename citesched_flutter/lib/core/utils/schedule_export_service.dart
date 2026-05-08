import 'dart:convert';
import 'dart:typed_data';

import 'package:citesched_client/citesched_client.dart';
import 'package:docx_creator/docx_creator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum ScheduleExportLayout { calendar, table, combined }

class ScheduleExportService {
  static final PdfPageFormat _largeLandscapePageFormat = PdfPageFormat(
    2000,
    1500,
  );

  static Future<void> exportAllFacultyCalendarPdf({
    required String title,
    required List<Schedule> schedules,
    String? subtitle,
  }) async {
    final sorted = _sortedSchedules(schedules);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: _largeLandscapePageFormat,
        margin: const pw.EdgeInsets.all(18),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (subtitle != null && subtitle.trim().isNotEmpty) ...[
              pw.SizedBox(height: 6),
              pw.Text(subtitle, style: const pw.TextStyle(fontSize: 10)),
            ],
            pw.SizedBox(height: 10),
            if (sorted.isEmpty)
              pw.Text('No schedules assigned.')
            else
              _buildPdfWeeklyCalendar(
                sorted,
                summaryMode: true,
              ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      name: '${_safeFileName(title)}.pdf',
      onLayout: (format) => pdf.save(),
    );
  }

  static Future<void> exportSchedulesPdf({
    required String title,
    required List<Schedule> schedules,
    String? subtitle,
    ScheduleExportLayout layout = ScheduleExportLayout.combined,
  }) async {
    final sorted = _sortedSchedules(schedules);
    final pdf = pw.Document();
    final pageFormat = layout == ScheduleExportLayout.table
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a3.landscape;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          if (subtitle != null) ...[
            pw.SizedBox(height: 8),
            pw.Text(subtitle),
          ],
          pw.SizedBox(height: 12),
          if (sorted.isEmpty)
            pw.Text('No schedules assigned.')
          else
            ..._buildPdfLayoutContent(sorted, layout),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: '${_safeFileName(title)}.pdf',
      onLayout: (format) => pdf.save(),
    );
  }

  static Future<String?> exportSchedulesDocx({
    required String title,
    required List<Schedule> schedules,
    String? subtitle,
    ScheduleExportLayout layout = ScheduleExportLayout.table,
  }) async {
    final sorted = _sortedSchedules(schedules);
    var builder = docx().h1(title);
    if (subtitle != null && subtitle.trim().isNotEmpty) {
      builder = builder.p(subtitle.trim());
    }
    builder = builder.p('Export Layout: ${_layoutLabel(layout)}').p('');
    if (sorted.isEmpty) {
      builder = builder.p('No schedules assigned.');
    } else {
      builder = _appendDocxLayoutContent(
        builder,
        sorted,
        layout,
      );
    }
    final doc = builder.build();

    final bytes = await DocxExporter().exportToBytes(doc);
    final fileName = '${_safeFileName(title)}.docx';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save DOCX',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['docx'],
      bytes: bytes,
    );
    if (path != null) return path;
    return kIsWeb ? 'Downloaded in browser' : null;
  }

  static Future<String?> exportSchedulesCsv({
    required String title,
    required List<Schedule> schedules,
    ScheduleExportLayout layout = ScheduleExportLayout.table,
  }) async {
    final sorted = _sortedSchedules(schedules);
    final lines = [
      _csvLine([title]),
      _csvLine(['Export Layout', _layoutLabel(layout)]),
      '',
      ..._buildCsvLayoutContent(
        sorted,
        layout,
        includeGroupColumn: false,
      ),
    ];

    final bytes = Uint8List.fromList(utf8.encode(lines.join('\n')));
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CSV',
      fileName: '${_safeFileName(title)}.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: bytes,
    );
    if (path != null) return path;
    return kIsWeb ? 'Downloaded in browser' : null;
  }

  static Future<void> exportGroupedSchedulesPdf({
    required String title,
    required List<Schedule> schedules,
    required String grouping,
    ScheduleExportLayout layout = ScheduleExportLayout.combined,
  }) async {
    final groups = _orderedGroupEntries(
      _groupSchedules(schedules, grouping),
      grouping,
    );

    if (layout == ScheduleExportLayout.calendar) {
      await _exportGroupedCalendarSchedulesPdf(
        title: title,
        groups: groups,
        grouping: grouping,
      );
      return;
    }

    final pdf = pw.Document();
    final pageFormat = layout == ScheduleExportLayout.table
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a3.landscape;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Grouped by ${grouping.toUpperCase()}'),
            pw.SizedBox(height: 16),
          ];

          for (var i = 0; i < groups.length; i++) {
            final entry = groups[i];
            final sortedSchedules = _sortedSchedules(entry.value);
            if (i > 0) {
              widgets.add(pw.SizedBox(height: 10));
            }
            widgets.add(
              pw.Text(
                entry.key,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));
            widgets.addAll(_buildPdfLayoutContent(sortedSchedules, layout));
            widgets.add(pw.SizedBox(height: 16));
          }

          if (groups.isEmpty) {
            widgets.add(pw.Text('No schedules available.'));
          }
          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      name: '${_safeFileName(title)}.pdf',
      onLayout: (format) => pdf.save(),
    );
  }

  static Future<void> _exportGroupedCalendarSchedulesPdf({
    required String title,
    required List<MapEntry<String, List<Schedule>>> groups,
    required String grouping,
  }) async {
    final pdf = pw.Document();

    if (groups.isEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a3.landscape,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Grouped by ${grouping.toUpperCase()}'),
              pw.SizedBox(height: 16),
              pw.Text('No schedules available.'),
            ],
          ),
        ),
      );
    } else {
      for (final entry in groups) {
        final sortedSchedules = _sortedSchedules(entry.value);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a3.landscape,
            margin: const pw.EdgeInsets.all(24),
            build: (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text('Grouped by ${grouping.toUpperCase()}'),
                pw.SizedBox(height: 16),
                pw.Text(
                  entry.key,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                _buildPdfWeeklyCalendar(sortedSchedules),
              ],
            ),
          ),
        );
      }
    }

    await Printing.layoutPdf(
      name: '${_safeFileName(title)}.pdf',
      onLayout: (format) => pdf.save(),
    );
  }

  static Future<String?> exportGroupedSchedulesDocx({
    required String title,
    required List<Schedule> schedules,
    required String grouping,
    ScheduleExportLayout layout = ScheduleExportLayout.table,
  }) async {
    final groups = _orderedGroupEntries(
      _groupSchedules(schedules, grouping),
      grouping,
    );
    var builder = docx()
        .h1(title)
        .p('Grouped by ${grouping.toUpperCase()}')
        .p('Export Layout: ${_layoutLabel(layout)}')
        .p('');

    if (groups.isEmpty) {
      builder = builder.p('No schedules available.');
    } else {
      for (final entry in groups) {
        builder = _appendDocxLayoutContent(
          builder.h2(entry.key),
          _sortedSchedules(entry.value),
          layout,
        );
      }
    }

    final bytes = await DocxExporter().exportToBytes(builder.build());
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save DOCX',
      fileName: '${_safeFileName(title)}.docx',
      type: FileType.custom,
      allowedExtensions: const ['docx'],
      bytes: bytes,
    );
    if (path != null) return path;
    return kIsWeb ? 'Downloaded in browser' : null;
  }

  static Future<String?> exportGroupedSchedulesCsv({
    required String title,
    required List<Schedule> schedules,
    required String grouping,
    ScheduleExportLayout layout = ScheduleExportLayout.table,
  }) async {
    final groups = _orderedGroupEntries(
      _groupSchedules(schedules, grouping),
      grouping,
    );
    final lines = <String>[
      _csvLine([title]),
      _csvLine(['Grouping', grouping.toUpperCase()]),
      _csvLine(['Export Layout', _layoutLabel(layout)]),
      '',
    ];
    for (var i = 0; i < groups.length; i++) {
      final entry = groups[i];
      if (i > 0) {
        lines.add('');
      }
      lines.add(_csvLine([entry.key]));
      lines.addAll(
        _buildCsvLayoutContent(
          _sortedSchedules(entry.value),
          layout,
          includeGroupColumn: false,
        ),
      );
    }

    final bytes = Uint8List.fromList(utf8.encode(lines.join('\n')));
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save CSV',
      fileName: '${_safeFileName(title)}.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: bytes,
    );
    if (path != null) return path;
    return kIsWeb ? 'Downloaded in browser' : null;
  }

  static Future<void> exportStudentSchedulePdf({
    required Student? student,
    required List<ScheduleInfo> schedules,
  }) async {
    final sorted = _sortedScheduleInfo(schedules);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Student Class Schedule',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Student ID: ${student?.studentNumber ?? "-"}'),
          pw.Text('Name: ${student?.name ?? "-"}'),
          pw.Text('Program: ${student?.course ?? "-"}'),
          pw.Text('Section: ${student?.section ?? "-"}'),
          pw.Text('Year Level: ${student?.yearLevel ?? "-"}'),
          pw.SizedBox(height: 12),
          if (sorted.isEmpty)
            pw.Text('No schedules assigned.')
          else
            _buildPdfScheduleTable(
              sorted.map((info) => info.schedule).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Student_Schedule_${student?.studentNumber ?? "student"}.pdf',
      onLayout: (format) => pdf.save(),
    );
  }

  static Future<String?> exportStudentScheduleDocx({
    required Student? student,
    required List<ScheduleInfo> schedules,
  }) async {
    final sorted = _sortedScheduleInfo(schedules);
    var builder = docx()
        .h1('Student Class Schedule')
        .p('Student ID: ${student?.studentNumber ?? "-"}')
        .p('Name: ${student?.name ?? "-"}')
        .p('Program: ${student?.course ?? "-"}')
        .p('Section: ${student?.section ?? "-"}')
        .p('Year Level: ${student?.yearLevel ?? "-"}')
        .h2('Schedule');

    if (sorted.isEmpty) {
      builder = builder.p('No schedules assigned.');
    } else {
      for (final info in sorted) {
        builder = _appendDocxScheduleEntry(
          builder,
          _scheduleRowData(info.schedule),
        );
      }
    }

    final doc = builder.build();

    final bytes = await DocxExporter().exportToBytes(doc);
    final fileName =
        'Student_Schedule_${student?.studentNumber ?? "student"}.docx';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Student Schedule DOCX',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['docx'],
      bytes: bytes,
    );
    if (path != null) return path;
    return kIsWeb ? 'Downloaded in browser' : null;
  }

  static Future<void> exportFacultySchedulePdf({
    required String facultyName,
    required List<ScheduleInfo> schedules,
  }) async {
    final sorted = _sortedScheduleInfo(schedules);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(
            'Faculty Teaching Schedule',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Faculty: $facultyName'),
          pw.SizedBox(height: 12),
          if (sorted.isEmpty)
            pw.Text('No schedules assigned.')
          else
            _buildPdfScheduleTable(
              sorted.map((info) => info.schedule).toList(),
            ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Faculty_Schedule_${facultyName.replaceAll(" ", "_")}.pdf',
      onLayout: (format) => pdf.save(),
    );
  }

  static Future<String?> exportFacultyScheduleDocx({
    required String facultyName,
    required List<ScheduleInfo> schedules,
  }) async {
    final sorted = _sortedScheduleInfo(schedules);
    var builder = docx()
        .h1('Faculty Teaching Schedule')
        .p('Faculty: $facultyName')
        .h2('Schedule');

    if (sorted.isEmpty) {
      builder = builder.p('No schedules assigned.');
    } else {
      for (final info in sorted) {
        builder = _appendDocxScheduleEntry(
          builder,
          _scheduleRowData(info.schedule),
        );
      }
    }

    final doc = builder.build();

    final bytes = await DocxExporter().exportToBytes(doc);
    final fileName =
        'Faculty_Schedule_${facultyName.replaceAll(" ", "_")}.docx';
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Faculty Schedule DOCX',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['docx'],
      bytes: bytes,
    );
    if (path != null) return path;
    return kIsWeb ? 'Downloaded in browser' : null;
  }

  static List<ScheduleInfo> _sortedScheduleInfo(List<ScheduleInfo> schedules) {
    final dayOrder = <DayOfWeek, int>{
      DayOfWeek.mon: 1,
      DayOfWeek.tue: 2,
      DayOfWeek.wed: 3,
      DayOfWeek.thu: 4,
      DayOfWeek.fri: 5,
      DayOfWeek.sat: 6,
      DayOfWeek.sun: 7,
    };
    final sorted = List<ScheduleInfo>.from(schedules);
    sorted.sort((a, b) {
      final ta = a.schedule.timeslot;
      final tb = b.schedule.timeslot;
      final da = ta == null ? 99 : (dayOrder[ta.day] ?? 99);
      final db = tb == null ? 99 : (dayOrder[tb.day] ?? 99);
      if (da != db) return da.compareTo(db);
      final sa = ta?.startTime ?? '';
      final sb = tb?.startTime ?? '';
      return sa.compareTo(sb);
    });
    return sorted;
  }

  static List<Schedule> _sortedSchedules(List<Schedule> schedules) {
    final dayOrder = <DayOfWeek, int>{
      DayOfWeek.mon: 1,
      DayOfWeek.tue: 2,
      DayOfWeek.wed: 3,
      DayOfWeek.thu: 4,
      DayOfWeek.fri: 5,
      DayOfWeek.sat: 6,
      DayOfWeek.sun: 7,
    };
    final sorted = List<Schedule>.from(schedules);
    sorted.sort((a, b) {
      final ta = a.timeslot;
      final tb = b.timeslot;
      final da = ta == null ? 99 : (dayOrder[ta.day] ?? 99);
      final db = tb == null ? 99 : (dayOrder[tb.day] ?? 99);
      if (da != db) return da.compareTo(db);
      return (ta?.startTime ?? '').compareTo(tb?.startTime ?? '');
    });
    return sorted;
  }

  static _ScheduleRowData _scheduleRowData(Schedule schedule) {
    final ts = schedule.timeslot;
    final subjectCode = _firstNonEmpty([
      schedule.subject?.code,
      schedule.subjectId > 0 ? 'SUBJ-${schedule.subjectId}' : null,
    ]);
    final subjectName = _firstNonEmpty([
      schedule.subject?.name,
      schedule.subject?.code,
      schedule.subjectId > 0 ? 'Subject #${schedule.subjectId}' : null,
    ]);
    final facultyName = _firstNonEmpty([
      schedule.faculty?.name,
      schedule.facultyId > 0 ? 'Faculty #${schedule.facultyId}' : null,
    ]);
    final roomName = _firstNonEmpty([
      schedule.room?.name,
      schedule.roomId != null ? 'Room #${schedule.roomId}' : null,
      'Unassigned',
    ]);
    final day = ts?.day != null ? _dayName(ts!.day) : '-';
    final time = _firstNonEmpty([
      ts != null ? _formatTimeRange(ts.startTime, ts.endTime) : null,
      ts?.label,
      schedule.timeslotId != null ? 'Timeslot #${schedule.timeslotId}' : null,
    ]);
    final section = _firstNonEmpty([
      schedule.section,
      schedule.sectionRef?.sectionCode,
      'Unassigned',
    ]);

    return _ScheduleRowData(
      code: subjectCode,
      subject: subjectName,
      faculty: facultyName,
      room: roomName,
      day: day,
      time: time,
      section: section,
    );
  }

  static List<String> _scheduleRow(Schedule schedule) {
    final row = _scheduleRowData(schedule);
    return [
      row.code,
      row.subject,
      row.faculty,
      row.room,
      row.day,
      row.time,
      row.section,
    ];
  }

  static Map<String, List<Schedule>> _groupSchedules(
    List<Schedule> schedules,
    String grouping,
  ) {
    final groups = <String, List<Schedule>>{};
    for (final schedule in schedules) {
      final key = switch (grouping) {
        'section' =>
          schedule.section.isEmpty ? 'Unassigned Section' : schedule.section,
        'year' => _yearGroupLabel(schedule),
        'room' => schedule.room?.name ?? 'Room Unassigned',
        'faculty' => schedule.faculty?.name ?? 'Faculty Unassigned',
        _ => 'All Schedules',
      };
      groups.putIfAbsent(key, () => <Schedule>[]).add(schedule);
    }
    return groups;
  }

  static List<MapEntry<String, List<Schedule>>> _orderedGroupEntries(
    Map<String, List<Schedule>> groups,
    String grouping,
  ) {
    final entries = groups.entries.toList();
    entries.sort((a, b) => _compareGroupLabels(a.key, b.key, grouping));
    return entries;
  }

  static int _compareGroupLabels(String a, String b, String grouping) {
    switch (grouping) {
      case 'year':
        return _yearGroupSortValue(a).compareTo(_yearGroupSortValue(b));
      case 'section':
        return _sectionSortKey(a).compareTo(_sectionSortKey(b));
      case 'room':
        return a.toLowerCase().compareTo(b.toLowerCase());
      case 'faculty':
        return a.toLowerCase().compareTo(b.toLowerCase());
      default:
        return a.toLowerCase().compareTo(b.toLowerCase());
    }
  }

  static String _yearGroupLabel(Schedule schedule) {
    final yearLevel =
        schedule.sectionRef?.yearLevel ?? schedule.subject?.yearLevel;
    if (yearLevel == null || yearLevel <= 0) return 'Year Unassigned';
    return '${_ordinalYear(yearLevel)} Year';
  }

  static String _csvLine(List<String> values) {
    return values.map((value) => '"${value.replaceAll('"', '""')}"').join(',');
  }

  static String _safeFileName(String text) {
    return text
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  static String _dayName(DayOfWeek? day) {
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
      default:
        return '-';
    }
  }

  static String _ordinalYear(int yearLevel) {
    switch (yearLevel) {
      case 1:
        return '1st';
      case 2:
        return '2nd';
      case 3:
        return '3rd';
      default:
        return '${yearLevel}th';
    }
  }

  static int _yearGroupSortValue(String label) {
    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 999;
    }
    return 999;
  }

  static String _sectionSortKey(String label) {
    final normalized = label.trim().toUpperCase();
    final match = RegExp(r'^(\d+)\s*([A-Z]*)').firstMatch(normalized);
    if (match == null) return '999_$normalized';
    final year = int.tryParse(match.group(1)!) ?? 999;
    final suffix = match.group(2) ?? '';
    return '${year.toString().padLeft(3, '0')}_$suffix';
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    final raw = time.trim().toUpperCase();
    if (raw.isEmpty) return const TimeOfDay(hour: 0, minute: 0);

    final ampmMatch = RegExp(r'([AP]M)$').firstMatch(raw);
    var value = raw;
    String? suffix;
    if (ampmMatch != null) {
      suffix = ampmMatch.group(1);
      value = raw.substring(0, ampmMatch.start).trim();
    }

    final parts = value.split(':');
    var hour = int.tryParse(parts.first) ?? 0;
    var minute = 0;
    if (parts.length > 1) {
      minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    if (suffix == 'PM' && hour < 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(
      hour: hour.clamp(0, 23),
      minute: minute.clamp(0, 59),
    );
  }

  static String _formatTimeRange(String startTime, String endTime) {
    final start = _parseTimeOfDay(startTime);
    final end = _parseTimeOfDay(endTime);
    return '${_formatTimeOfDay(start)} - ${_formatTimeOfDay(end)}';
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute$suffix';
  }

  static String _formatHourLabel(int hour) {
    final normalized = ((hour % 24) + 24) % 24;
    final suffix = normalized >= 12 ? 'PM' : 'AM';
    final displayHour = normalized % 12 == 0 ? 12 : normalized % 12;
    return '$displayHour:00$suffix';
  }

  static pw.Widget _buildPdfWeeklyCalendar(
    List<Schedule> schedules, {
    bool summaryMode = false,
  }) {
    if (schedules.isEmpty) {
      return pw.Text('No schedules available.');
    }
    final compact = summaryMode || schedules.length > 40;

    const days = <DayOfWeek>[
      DayOfWeek.mon,
      DayOfWeek.tue,
      DayOfWeek.wed,
      DayOfWeek.thu,
      DayOfWeek.fri,
      DayOfWeek.sat,
    ];

    final schedulesWithTimes = schedules
        .where((schedule) => schedule.timeslot != null)
        .toList();
    if (schedulesWithTimes.isEmpty) {
      return pw.Text('No timeslot data available for calendar view.');
    }

    final earliestHour = schedulesWithTimes
        .map((schedule) => _parseTimeOfDay(schedule.timeslot!.startTime).hour)
        .reduce((a, b) => a < b ? a : b);
    final latestHour = schedulesWithTimes
        .map((schedule) {
          final end = _parseTimeOfDay(schedule.timeslot!.endTime);
          return end.minute > 0 ? end.hour + 1 : end.hour;
        })
        .reduce((a, b) => a > b ? a : b);

    final startHour = earliestHour < 7 ? earliestHour : 7;
    final endHour = latestHour > 21 ? latestHour : 21;
    final timeColumnWidth = summaryMode ? 60.0 : (compact ? 48.0 : 52.0);
    final dayWidth = summaryMode ? 188.0 : (compact ? 96.0 : 104.0);
    final headerHeight = compact ? 26.0 : 30.0;
    final hourHeight = summaryMode ? 48.0 : (compact ? 24.0 : 28.0);
    final gridHeight = (endHour - startHour) * hourHeight;
    final totalWidth = timeColumnWidth + (dayWidth * days.length);
    final totalHeight = headerHeight + gridHeight;
    final canvasBackground = PdfColor.fromHex('FCF7FB');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildPdfCalendarLegend(),
        pw.SizedBox(height: 8),
        pw.Text(
          'Weekly Calendar View',
          style: pw.TextStyle(
            fontSize: compact ? 10 : 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.SizedBox(
          width: totalWidth,
          height: totalHeight,
          child: pw.Stack(
            children: [
              pw.Container(
                width: totalWidth,
                height: totalHeight,
                decoration: pw.BoxDecoration(
                  color: canvasBackground,
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                ),
              ),
              pw.Positioned(
                left: timeColumnWidth,
                top: 0,
                child: pw.Row(
                  children: days
                      .map(
                        (day) => pw.Container(
                          width: dayWidth,
                          height: headerHeight,
                          alignment: pw.Alignment.center,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('F1E2EC'),
                            border: pw.Border(
                              right: pw.BorderSide(
                                color: PdfColors.grey400,
                                width: 0.5,
                              ),
                              bottom: pw.BorderSide(
                                color: PdfColors.grey400,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: pw.Text(
                            _dayShortName(day),
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('8A1455'),
                              fontSize: compact ? 9 : 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              ...List.generate(endHour - startHour, (index) {
                final hour = startHour + index;
                final top = headerHeight + (index * hourHeight);
                return pw.Positioned(
                  left: 0,
                  top: top,
                  child: pw.Row(
                    children: [
                      pw.Container(
                        width: timeColumnWidth,
                        height: hourHeight,
                        alignment: pw.Alignment.topCenter,
                        padding: const pw.EdgeInsets.only(top: 3),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(
                              color: PdfColors.grey400,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: pw.Text(
                          _formatHourLabel(hour),
                          style: pw.TextStyle(
                            color: PdfColors.grey700,
                            fontSize: compact ? 7 : 8,
                          ),
                        ),
                      ),
                      ...days.map(
                        (_) => pw.Container(
                          width: dayWidth,
                          height: hourHeight,
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(
                                color: PdfColors.grey300,
                                width: 0.5,
                              ),
                              bottom: pw.BorderSide(
                                color: PdfColors.grey300,
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (startHour <= 12 && endHour > 12)
                _buildPdfLunchBlock(
                  startHour: startHour,
                  hourHeight: hourHeight,
                  timeColumnWidth: timeColumnWidth,
                  dayWidth: dayWidth,
                  dayCount: days.length,
                  headerHeight: headerHeight,
                ),
              if (summaryMode)
                ..._buildPdfSummaryScheduleBlocks(
                  schedulesWithTimes,
                  days: days,
                  startHour: startHour,
                  headerHeight: headerHeight,
                  hourHeight: hourHeight,
                  timeColumnWidth: timeColumnWidth,
                  dayWidth: dayWidth,
                )
              else
                ...schedulesWithTimes.map(
                  (schedule) => _buildPdfDetailedScheduleBlock(
                    schedule,
                    days: days,
                    startHour: startHour,
                    headerHeight: headerHeight,
                    hourHeight: hourHeight,
                    timeColumnWidth: timeColumnWidth,
                    dayWidth: dayWidth,
                    compact: compact,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfCalendarLegend() {
    return pw.Row(
      children: [
        _buildPdfLegendChip(
          label: 'LECTURE',
          fillColor: PdfColor.fromHex('0B5D2A'),
        ),
        pw.SizedBox(width: 8),
        _buildPdfLegendChip(
          label: 'LABORATORY',
          fillColor: PdfColor.fromHex('1E4D99'),
        ),
        pw.SizedBox(width: 8),
        _buildPdfLegendChip(
          label: 'MIXED',
          fillColor: PdfColor.fromHex('7C3AED'),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfLegendChip({
    required String label,
    required PdfColor fillColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: fillColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static String _dayShortName(DayOfWeek day) {
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

  static pw.Widget _buildPdfLunchBlock({
    required int startHour,
    required double hourHeight,
    required double timeColumnWidth,
    required double dayWidth,
    required int dayCount,
    required double headerHeight,
  }) {
    final top = headerHeight + ((12 - startHour) * hourHeight) + 2;
    final height = hourHeight - 4;

    return pw.Positioned(
      left: timeColumnWidth + 4,
      top: top,
      child: pw.Container(
        width: (dayWidth * dayCount) - 8,
        height: height,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('D9D9D9'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          border: pw.Border.all(color: PdfColors.grey500, width: 1),
        ),
        child: pw.Text(
          'LUNCH TIME',
          style: pw.TextStyle(
            color: PdfColors.grey700,
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  static List<pw.Widget> _buildPdfSummaryScheduleBlocks(
    List<Schedule> schedules, {
    required List<DayOfWeek> days,
    required int startHour,
    required double headerHeight,
    required double hourHeight,
    required double timeColumnWidth,
    required double dayWidth,
  }) {
    final grouped = <String, List<Schedule>>{};

    for (final schedule in schedules) {
      final timeslot = schedule.timeslot;
      if (timeslot == null) continue;
      final key =
          '${timeslot.day.name}|${timeslot.startTime}|${timeslot.endTime}';
      grouped.putIfAbsent(key, () => <Schedule>[]).add(schedule);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final at = a.value.first.timeslot!;
        final bt = b.value.first.timeslot!;
        final dayCompare = (days.indexOf(
          at.day,
        )).compareTo(days.indexOf(bt.day));
        if (dayCompare != 0) return dayCompare;
        return at.startTime.compareTo(bt.startTime);
      });

    return entries.map((entry) {
      final slotSchedules = entry.value;
      final first = slotSchedules.first;
      final timeslot = first.timeslot!;
      final dayIndex = days.indexOf(timeslot.day);
      final start = _parseTimeOfDay(timeslot.startTime);
      final end = _parseTimeOfDay(timeslot.endTime);
      final top =
          headerHeight +
          (((start.hour - startHour) + (start.minute / 60.0)) * hourHeight) +
          2;
      final height =
          (((end.hour - start.hour) * 60) + (end.minute - start.minute)) /
          60.0 *
          hourHeight;
      final left = timeColumnWidth + (dayIndex * dayWidth) + 4;
      final width = dayWidth - 8;
      final cardHeight = (height - 4) < 68.0 ? 68.0 : (height - 4);
      final lectureCount = slotSchedules
          .where((schedule) => !_isLaboratorySchedule(schedule))
          .length;
      final laboratoryCount = slotSchedules.where(_isLaboratorySchedule).length;
      final fillColor = _summaryBlockFillColor(
        lectureCount: lectureCount,
        laboratoryCount: laboratoryCount,
      );
      final borderColor = _summaryBlockBorderColor(
        lectureCount: lectureCount,
        laboratoryCount: laboratoryCount,
      );
      final detailLines = slotSchedules
          .map((schedule) => _summaryScheduleLine(schedule))
          .toList();

      return pw.Positioned(
        left: left,
        top: top,
        child: pw.Container(
          width: width,
          height: cardHeight,
          padding: const pw.EdgeInsets.all(5),
          decoration: pw.BoxDecoration(
            color: fillColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            border: pw.Border.all(color: borderColor, width: 1.4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  _formatTimeRange(timeslot.startTime, timeslot.endTime),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  _summaryTypeLabel(
                    lectureCount: lectureCount,
                    laboratoryCount: laboratoryCount,
                  ),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 6.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              ...detailLines.map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Text(
                    line,
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 5.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  static pw.Widget _buildPdfDetailedScheduleBlock(
    Schedule schedule, {
    required List<DayOfWeek> days,
    required int startHour,
    required double headerHeight,
    required double hourHeight,
    required double timeColumnWidth,
    required double dayWidth,
    required bool compact,
  }) {
    final timeslot = schedule.timeslot;
    if (timeslot == null) return pw.SizedBox();

    final dayIndex = days.indexOf(timeslot.day);
    if (dayIndex < 0) return pw.SizedBox();

    final start = _parseTimeOfDay(timeslot.startTime);
    final end = _parseTimeOfDay(timeslot.endTime);
    final top =
        headerHeight +
        (((start.hour - startHour) + (start.minute / 60.0)) * hourHeight) +
        2;
    final height =
        (((end.hour - start.hour) * 60) + (end.minute - start.minute)) /
        60.0 *
        hourHeight;
    final left = timeColumnWidth + (dayIndex * dayWidth) + 4;
    final width = dayWidth - 8;
    final cardHeight = (height - 4) < 44.0 ? 44.0 : (height - 4);
    final isDenseCard = compact || cardHeight < 78.0;
    final cardPadding = isDenseCard ? 3.0 : 5.0;
    final titleFont = isDenseCard ? 6.4 : 8.2;
    final typeFont = isDenseCard ? 4.9 : 6.0;
    final labelFont = isDenseCard ? 4.6 : 5.6;
    final bodyFont = isDenseCard ? 4.3 : 5.2;
    final sectionFont = isDenseCard ? 4.1 : 5.0;
    final row = _scheduleRowData(schedule);
    final isLab = _isLaboratorySchedule(schedule);
    final fillColor = isLab
        ? PdfColor.fromHex('0B3A82')
        : PdfColor.fromHex('0B5D2A');
    final borderColor = isLab
        ? PdfColor.fromHex('2563EB')
        : PdfColor.fromHex('16A34A');
    final classType = isLab ? 'LAB' : 'LECTURE';

    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Container(
        width: width,
        height: cardHeight,
        padding: pw.EdgeInsets.all(cardPadding),
        decoration: pw.BoxDecoration(
          color: fillColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          border: pw.Border.all(color: borderColor, width: 1.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                _formatTimeRange(timeslot.startTime, timeslot.endTime),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: titleFont,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: isDenseCard ? 0.5 : 1.5),
            pw.Center(
              child: pw.Text(
                classType,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: typeFont,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: isDenseCard ? 1 : 2),
            pw.Text(
              'Faculty: ${_truncateForPdf(row.faculty, compact ? 22 : 24)}',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: labelFont,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Code: ${_truncateForPdf(row.code, compact ? 18 : 20)}',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: labelFont,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              'Subject: ${_truncateForPdf(row.subject, compact ? 22 : 28)}',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: bodyFont,
              ),
            ),
            pw.Text(
              'Room: ${_truncateForPdf(row.room, compact ? 18 : 20)}',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: bodyFont,
              ),
            ),
            pw.Text(
              'Section: ${_truncateForPdf(row.section, compact ? 18 : 20)}',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: sectionFont,
              ),
            ),
            pw.Text(
              'Type: $classType',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: sectionFont,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static PdfColor _summaryBlockFillColor({
    required int lectureCount,
    required int laboratoryCount,
  }) {
    if (lectureCount > 0 && laboratoryCount > 0) {
      return PdfColor.fromHex('7C3AED');
    }
    if (laboratoryCount > 0) {
      return PdfColor.fromHex('0B3A82');
    }
    return PdfColor.fromHex('0B5D2A');
  }

  static PdfColor _summaryBlockBorderColor({
    required int lectureCount,
    required int laboratoryCount,
  }) {
    if (lectureCount > 0 && laboratoryCount > 0) {
      return PdfColor.fromHex('A78BFA');
    }
    if (laboratoryCount > 0) {
      return PdfColor.fromHex('2563EB');
    }
    return PdfColor.fromHex('16A34A');
  }

  static String _summaryTypeLabel({
    required int lectureCount,
    required int laboratoryCount,
  }) {
    if (lectureCount > 0 && laboratoryCount > 0) return 'MIXED';
    if (laboratoryCount > 0) return 'LAB';
    return 'LECTURE';
  }

  static String _summaryScheduleLine(Schedule schedule) {
    final row = _scheduleRowData(schedule);
    final classType = _isLaboratorySchedule(schedule) ? 'LAB' : 'LEC';
    final faculty = _truncateForPdf(row.faculty, 16);
    final code = _truncateForPdf(row.code, 10);
    final room = _truncateForPdf(row.room, 10);
    return '$faculty | $code | $room | $classType';
  }

  static PdfColor? _calendarCellBackground(
    List<Schedule> schedules, {
    required DayOfWeek day,
    required int hour,
  }) {
    final slotSchedules = _schedulesForCalendarCell(
      schedules,
      day: day,
      hour: hour,
    );
    if (slotSchedules.isEmpty) return null;

    final laboratoryCount = slotSchedules.where(_isLaboratorySchedule).length;
    if (laboratoryCount == 0) {
      return PdfColor.fromHex('0B5D2A');
    }
    if (laboratoryCount == slotSchedules.length) {
      return PdfColor.fromHex('1E4D99');
    }
    return PdfColor.fromHex('7C3AED');
  }

  static PdfColor _calendarCellTextColor(
    List<Schedule> schedules, {
    required DayOfWeek day,
    required int hour,
  }) {
    final schedule = _firstScheduleForCalendarCell(
      schedules,
      day: day,
      hour: hour,
    );
    return schedule == null ? PdfColors.black : PdfColors.white;
  }

  static Schedule? _firstScheduleForCalendarCell(
    List<Schedule> schedules, {
    required DayOfWeek day,
    required int hour,
  }) {
    final matches = _schedulesForCalendarCell(schedules, day: day, hour: hour);
    return matches.isEmpty ? null : matches.first;
  }

  static List<Schedule> _schedulesForCalendarCell(
    List<Schedule> schedules, {
    required DayOfWeek day,
    required int hour,
  }) {
    return schedules.where((schedule) {
      final timeslot = schedule.timeslot;
      if (timeslot == null || timeslot.day != day) return false;
      final start = _parseTimeOfDay(timeslot.startTime);
      final end = _parseTimeOfDay(timeslot.endTime);
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      final hourStartMinutes = hour * 60;
      final hourEndMinutes = (hour + 1) * 60;
      return startMinutes < hourEndMinutes && endMinutes > hourStartMinutes;
    }).toList();
  }

  static bool _isLaboratorySchedule(Schedule schedule) {
    final types = schedule.subject?.types ?? const <SubjectType>[];
    if (types.contains(SubjectType.laboratory) &&
        !types.contains(SubjectType.lecture)) {
      return true;
    }
    final roomName = schedule.room?.name.toUpperCase() ?? '';
    return roomName.contains('LAB');
  }

  static String _calendarCellText(
    List<Schedule> schedules, {
    required DayOfWeek day,
    required int hour,
    bool compact = false,
    bool summaryMode = false,
  }) {
    final slotSchedules = _schedulesForCalendarCell(
      schedules,
      day: day,
      hour: hour,
    );
    if (slotSchedules.isEmpty) return '';

    if (summaryMode) {
      final lectureCount = slotSchedules
          .where((schedule) => !_isLaboratorySchedule(schedule))
          .length;
      final laboratoryCount = slotSchedules.where(_isLaboratorySchedule).length;
      final facultyCount = slotSchedules
          .map(
            (schedule) =>
                schedule.faculty?.name ?? 'Faculty #${schedule.facultyId}',
          )
          .toSet()
          .length;
      return [
        '${slotSchedules.length} class${slotSchedules.length == 1 ? '' : 'es'}',
        if (lectureCount > 0) '$lectureCount Lec',
        if (laboratoryCount > 0) '$laboratoryCount Lab',
        '$facultyCount Faculty',
      ].join('\n');
    }

    final entries = slotSchedules.map((schedule) {
      final row = _scheduleRowData(schedule);
      final classType = _isLaboratorySchedule(schedule) ? 'LAB' : 'LECTURE';
      if (compact) {
        return [
              classType,
              row.code,
              row.section != '-' ? row.section : null,
              row.room != '-' ? row.room : null,
            ]
            .whereType<String>()
            .where((value) => value.trim().isNotEmpty)
            .join(' ');
      }
      return [
            classType,
            row.code,
            row.faculty != '-' ? row.faculty : null,
            row.room != '-' ? row.room : null,
            row.section != '-' ? row.section : null,
            row.time,
          ]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join('\n');
    }).toList();

    if (compact && entries.length > 2) {
      final remaining = entries.length - 2;
      return '${entries.take(2).join('\n')}\n+$remaining more';
    }
    return compact ? entries.join('\n') : entries.join('\n\n');
  }

  static pw.Widget _buildPdfScheduleTable(List<Schedule> schedules) {
    final rows = schedules.map(_scheduleRowData).toList();
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey500, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.4),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FlexColumnWidth(2.4),
        3: pw.FlexColumnWidth(1.7),
        4: pw.FlexColumnWidth(1.5),
        5: pw.FlexColumnWidth(2.1),
        6: pw.FlexColumnWidth(1.3),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _PdfCell('Code', isHeader: true),
            _PdfCell('Subject', isHeader: true),
            _PdfCell('Faculty', isHeader: true),
            _PdfCell('Room', isHeader: true),
            _PdfCell('Day', isHeader: true),
            _PdfCell('Time', isHeader: true),
            _PdfCell('Section', isHeader: true),
          ],
        ),
        ...rows.map(
          (row) => pw.TableRow(
            children: [
              _PdfCell(row.code),
              _PdfCell(row.subject),
              _PdfCell(row.faculty),
              _PdfCell(row.room),
              _PdfCell(row.day),
              _PdfCell(row.time),
              _PdfCell(row.section),
            ],
          ),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildPdfLayoutContent(
    List<Schedule> schedules,
    ScheduleExportLayout layout,
  ) {
    switch (layout) {
      case ScheduleExportLayout.calendar:
        return [_buildPdfWeeklyCalendar(schedules)];
      case ScheduleExportLayout.table:
        return [_buildPdfScheduleTable(schedules)];
      case ScheduleExportLayout.combined:
        return [
          _buildPdfWeeklyCalendar(schedules),
          pw.SizedBox(height: 12),
          _buildPdfScheduleTable(schedules),
        ];
    }
  }

  static DocxDocumentBuilder _appendDocxLayoutContent(
    DocxDocumentBuilder builder,
    List<Schedule> schedules,
    ScheduleExportLayout layout,
  ) {
    switch (layout) {
      case ScheduleExportLayout.calendar:
        builder = builder
            .h2('Calendar View')
            .table(
              _buildCalendarMatrixRows(schedules),
              style: DocxTableStyle.zebra.copyWith(
                headerFill: 'D9E2F3',
                borderColor: '9CA3AF',
              ),
            )
            .p('');
        return builder;
      case ScheduleExportLayout.table:
        builder = builder
            .h2('Table View')
            .table(
              _buildScheduleTableMatrix(schedules),
              style: DocxTableStyle.professional.copyWith(
                evenRowFill: 'F8FAFC',
                borderColor: '94A3B8',
              ),
            )
            .p('');
        return builder;
      case ScheduleExportLayout.combined:
        builder = builder
            .h2('Calendar View')
            .table(
              _buildCalendarMatrixRows(schedules),
              style: DocxTableStyle.zebra.copyWith(
                headerFill: 'D9E2F3',
                borderColor: '9CA3AF',
              ),
            )
            .p('')
            .h2('Table View')
            .table(
              _buildScheduleTableMatrix(schedules),
              style: DocxTableStyle.professional.copyWith(
                evenRowFill: 'F8FAFC',
                borderColor: '94A3B8',
              ),
            )
            .p('');
        return builder;
    }
  }

  static List<String> _buildCsvLayoutContent(
    List<Schedule> schedules,
    ScheduleExportLayout layout, {
    required bool includeGroupColumn,
  }) {
    switch (layout) {
      case ScheduleExportLayout.calendar:
        return _buildCalendarCsvLines(schedules);
      case ScheduleExportLayout.table:
      case ScheduleExportLayout.combined:
        final header = <String>[
          if (includeGroupColumn) 'Group',
          'Code',
          'Subject',
          'Faculty',
          'Room',
          'Day',
          'Time',
          'Section',
        ];
        return [
          _csvLine(header),
          ...schedules.map((schedule) => _csvLine(_scheduleRow(schedule))),
        ];
    }
  }

  static List<String> _buildCalendarCsvLines(List<Schedule> schedules) {
    final rows = _buildCalendarMatrixRows(schedules);
    return rows.map(_csvLine).toList();
  }

  static List<List<String>> _buildCalendarMatrixRows(List<Schedule> schedules) {
    final schedulesWithTimes = schedules
        .where((schedule) => schedule.timeslot != null)
        .toList();
    if (schedulesWithTimes.isEmpty) {
      return [
        ['Calendar View'],
        ['No timeslot data available.'],
      ];
    }

    const days = <DayOfWeek>[
      DayOfWeek.mon,
      DayOfWeek.tue,
      DayOfWeek.wed,
      DayOfWeek.thu,
      DayOfWeek.fri,
      DayOfWeek.sat,
    ];

    final earliestHour = schedulesWithTimes
        .map((schedule) => _parseTimeOfDay(schedule.timeslot!.startTime).hour)
        .reduce((a, b) => a < b ? a : b);
    final latestHour = schedulesWithTimes
        .map((schedule) {
          final end = _parseTimeOfDay(schedule.timeslot!.endTime);
          return end.minute > 0 ? end.hour + 1 : end.hour;
        })
        .reduce((a, b) => a > b ? a : b);

    final startHour = earliestHour < 7 ? earliestHour : 7;
    final endHour = latestHour > 21 ? latestHour : 21;

    final rows = <List<String>>[
      const [
        'Time',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ],
    ];

    for (var hour = startHour; hour < endHour; hour++) {
      rows.add([
        '${_formatHourLabel(hour)} - ${_formatHourLabel(hour + 1)}',
        ...days.map(
          (day) => _calendarCellText(
            schedulesWithTimes,
            day: day,
            hour: hour,
          ),
        ),
      ]);
    }

    return rows;
  }

  static List<List<String>> _buildScheduleTableMatrix(
    List<Schedule> schedules,
  ) {
    return [
      const [
        'Code',
        'Subject',
        'Faculty',
        'Room',
        'Day',
        'Time',
        'Section',
      ],
      ...schedules.map(_scheduleRow),
    ];
  }

  static DocxDocumentBuilder _appendDocxScheduleEntry(
    DocxDocumentBuilder builder,
    _ScheduleRowData row,
  ) {
    return builder
        .p('Code: ${row.code}')
        .p('Subject: ${row.subject}')
        .p('Faculty: ${row.faculty}')
        .p('Room: ${row.room}')
        .p('Day: ${row.day}')
        .p('Time: ${row.time}')
        .p('Section: ${row.section}')
        .p('');
  }

  static String _layoutLabel(ScheduleExportLayout layout) {
    switch (layout) {
      case ScheduleExportLayout.calendar:
        return 'Calendar View';
      case ScheduleExportLayout.table:
        return 'Table View';
      case ScheduleExportLayout.combined:
        return 'Calendar and Table View';
    }
  }

  static String _truncateForPdf(String value, int maxChars) {
    final trimmed = value.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return '${trimmed.substring(0, maxChars - 1)}...';
  }

  static String _firstNonEmpty(List<String?> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return '-';
  }
}

class _ScheduleRowData {
  const _ScheduleRowData({
    required this.code,
    required this.subject,
    required this.faculty,
    required this.room,
    required this.day,
    required this.time,
    required this.section,
  });

  final String code;
  final String subject;
  final String faculty;
  final String room;
  final String day;
  final String time;
  final String section;
}

class _PdfCell extends pw.StatelessWidget {
  _PdfCell(
    this.text, {
    this.isHeader = false,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
  });

  final String text;
  final bool isHeader;
  final double? fontSize;
  final PdfColor? backgroundColor;
  final PdfColor? textColor;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      color: backgroundColor,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        child: pw.Text(
          text,
          softWrap: true,
          style: pw.TextStyle(
            color: textColor ?? PdfColors.black,
            fontSize: fontSize ?? (isHeader ? 9 : 8),
            fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
