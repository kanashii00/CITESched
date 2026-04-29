import 'dart:convert';
import 'dart:convert';
import 'dart:typed_data';

import 'package:citesched_client/citesched_client.dart';
import 'package:docx_creator/docx_creator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ScheduleExportService {
  static Future<void> exportSchedulesPdf({
    required String title,
    required List<Schedule> schedules,
    String? subtitle,
  }) async {
    final sorted = _sortedSchedules(schedules);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
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
            _buildPdfScheduleTable(sorted),
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
  }) async {
    final sorted = _sortedSchedules(schedules);
    var builder = docx().h1(title);
    if (subtitle != null && subtitle.trim().isNotEmpty) {
      builder = builder.p(subtitle.trim());
    }
    if (sorted.isEmpty) {
      builder = builder.p('No schedules assigned.');
    } else {
      builder = builder.h2('Schedule');
      for (final schedule in sorted) {
        builder = _appendDocxScheduleEntry(
          builder,
          _scheduleRowData(schedule),
        );
      }
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
  }) async {
    final sorted = _sortedSchedules(schedules);
    final lines = <String>[
      _csvLine(const [
        'Code',
        'Subject',
        'Faculty',
        'Room',
        'Day',
        'Time',
        'Section',
      ]),
      ...sorted.map((schedule) => _csvLine(_scheduleRow(schedule))),
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
  }) async {
    final groups = _groupSchedules(schedules, grouping);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
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

          for (final entry in groups.entries) {
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
            widgets.add(
              _buildPdfScheduleTable(_sortedSchedules(entry.value)),
            );
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

  static Future<String?> exportGroupedSchedulesDocx({
    required String title,
    required List<Schedule> schedules,
    required String grouping,
  }) async {
    final groups = _groupSchedules(schedules, grouping);
    var builder = docx()
        .h1(title)
        .p('Grouped by ${grouping.toUpperCase()}');

    if (groups.isEmpty) {
      builder = builder.p('No schedules available.');
    } else {
      for (final entry in groups.entries) {
        builder = builder.h2(entry.key);
        for (final schedule in _sortedSchedules(entry.value)) {
          builder = _appendDocxScheduleEntry(
            builder,
            _scheduleRowData(schedule),
          );
        }
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
  }) async {
    final groups = _groupSchedules(schedules, grouping);
    final lines = <String>[
      _csvLine(const [
        'Group',
        'Code',
        'Subject',
        'Faculty',
        'Room',
        'Day',
        'Time',
        'Section',
      ]),
    ];

    for (final entry in groups.entries) {
      for (final schedule in _sortedSchedules(entry.value)) {
        lines.add(_csvLine([entry.key, ..._scheduleRow(schedule)]));
      }
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
      ts != null ? '${ts.startTime} - ${ts.endTime}' : null,
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
        'section' => schedule.section.isEmpty ? 'Unassigned Section' : schedule.section,
        'year' => _yearGroupLabel(schedule),
        'room' => schedule.room?.name ?? 'Room Unassigned',
        _ => 'All Schedules',
      };
      groups.putIfAbsent(key, () => <Schedule>[]).add(schedule);
    }
    return groups;
  }

  static String _yearGroupLabel(Schedule schedule) {
    final yearLevel =
        schedule.sectionRef?.yearLevel ?? schedule.subject?.yearLevel;
    if (yearLevel == null || yearLevel <= 0) return 'Year Unassigned';
    return 'Year $yearLevel';
  }

  static String _csvLine(List<String> values) {
    return values
        .map((value) => '"${value.replaceAll('"', '""')}"')
        .join(',');
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
  _PdfCell(this.text, {this.isHeader = false});

  final String text;
  final bool isHeader;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        softWrap: true,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}
