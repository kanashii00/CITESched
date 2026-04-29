import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/core/utils/schedule_export_service.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/auth/widgets/logout_confirmation_dialog.dart';
import 'package:citesched_flutter/features/auth/widgets/password_reset_dialog.dart';
import 'package:citesched_flutter/core/widgets/theme_mode_toggle.dart';
import 'package:citesched_flutter/core/widgets/draggable_fab.dart';
import 'package:citesched_flutter/core/widgets/nlp_query_dialog.dart';
import 'package:citesched_flutter/features/nlp/providers/chat_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';
import 'package:citesched_flutter/core/widgets/full_screen_calendar_scaffold.dart';

final facultyScheduleProvider = FutureProvider<List<ScheduleInfo>>((ref) async {
  ref.watch(scheduleSyncTriggerProvider);
  return await client.timetable.getPersonalSchedule();
});

final facultyAvailabilityProvider = FutureProvider<List<FacultyAvailability>>((
  ref,
) async {
  ref.watch(scheduleSyncTriggerProvider);
  try {
    final myFaculty = await client.faculty.getMyProfile();
    if (myFaculty?.id == null) return [];
    return await client.admin.getFacultyAvailability(myFaculty!.id!);
  } catch (e) {
    return [];
  }
});

const _weeklyCalendarLabel = 'Weekly Calendar';

class FacultyDashboardScreen extends ConsumerStatefulWidget {
  const FacultyDashboardScreen({super.key});

  @override
  ConsumerState<FacultyDashboardScreen> createState() =>
      _FacultyDashboardScreenState();
}

class _FacultyDashboardScreenState extends ConsumerState<FacultyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final Color maroonColor = const Color(0xFF720045);

  String _getDayName(DayOfWeek? day) {
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
        return '—';
    }
  }

  int _parseTimeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  bool _isWithinPreferredAvailability(
    Schedule schedule,
    List<FacultyAvailability> availabilities,
  ) {
    final timeslot = schedule.timeslot;
    if (timeslot == null) return true;
    final preferred = availabilities.where((a) => a.isPreferred).toList();
    if (preferred.isEmpty) return true;

    final tsStart = _parseTimeToMinutes(timeslot.startTime);
    final tsEnd = _parseTimeToMinutes(timeslot.endTime);
    for (final a in preferred) {
      if (a.dayOfWeek != timeslot.day) continue;
      final aStart = _parseTimeToMinutes(a.startTime);
      final aEnd = _parseTimeToMinutes(a.endTime);
      if (tsStart >= aStart && tsEnd <= aEnd) return true;
    }
    return false;
  }

  double _computeAssignedHours(List<ScheduleInfo> schedules) {
    double totalMinutes = 0;
    for (final info in schedules) {
      final ts = info.schedule.timeslot;
      if (ts == null) continue;
      final start = _parseTimeToMinutes(ts.startTime);
      final end = _parseTimeToMinutes(ts.endTime);
      if (end > start) totalMinutes += (end - start);
    }
    return totalMinutes / 60.0;
  }

  double _computePreferredHours(List<FacultyAvailability> availabilities) {
    double totalMinutes = 0;
    for (final a in availabilities.where((a) => a.isPreferred)) {
      final start = _parseTimeToMinutes(a.startTime);
      final end = _parseTimeToMinutes(a.endTime);
      if (end > start) totalMinutes += (end - start);
    }
    return totalMinutes / 60.0;
  }

  double _computeAssignedHoursWithinPreferred(
    List<ScheduleInfo> schedules,
    List<FacultyAvailability> availabilities,
  ) => _computeAssignedHoursWithinPreferredImpl(
        schedules,
        availabilities,
      );

  double _computeAssignedHoursWithinPreferredImpl(
    List<ScheduleInfo> schedules,
    List<FacultyAvailability> availabilities,
  ) {
    final preferred = availabilities.where((a) => a.isPreferred).toList();
    double overlapMinutes = 0;

    for (final info in schedules) {
      final ts = info.schedule.timeslot;
      if (ts == null) continue;
      final tsStart = _parseTimeToMinutes(ts.startTime);
      final tsEnd = _parseTimeToMinutes(ts.endTime);

      for (final a in preferred) {
        if (a.dayOfWeek != ts.day) continue;
        final aStart = _parseTimeToMinutes(a.startTime);
        final aEnd = _parseTimeToMinutes(a.endTime);
        final overlapStart = tsStart > aStart ? tsStart : aStart;
        final overlapEnd = tsEnd < aEnd ? tsEnd : aEnd;
        if (overlapEnd > overlapStart) {
          overlapMinutes += (overlapEnd - overlapStart);
        }
      }
    }

    return overlapMinutes / 60.0;
  }

  List<String> _computeFreeSlotLabels(
    List<ScheduleInfo> schedules,
    List<FacultyAvailability> availabilities,
  ) => _computeFreeSlotLabelsImpl(schedules, availabilities);

  List<String> _computeFreeSlotLabelsImpl(
    List<ScheduleInfo> schedules,
    List<FacultyAvailability> availabilities,
  ) {
    final preferred = availabilities.where((a) => a.isPreferred).toList();
    if (preferred.isEmpty) return const [];

    final assignedByDay = <DayOfWeek, List<_MinuteRange>>{};
    for (final info in schedules) {
      final ts = info.schedule.timeslot;
      if (ts == null) continue;
      final start = _parseTimeToMinutes(ts.startTime);
      final end = _parseTimeToMinutes(ts.endTime);
      assignedByDay.putIfAbsent(ts.day, () => []).add(_MinuteRange(start, end));
    }

    for (final entry in assignedByDay.entries) {
      entry.value.sort((a, b) => a.start.compareTo(b.start));
    }

    final freeSlots = <String>[];
    for (final a in preferred) {
      final window = _MinuteRange(
        _parseTimeToMinutes(a.startTime),
        _parseTimeToMinutes(a.endTime),
      );

      var segments = <_MinuteRange>[window];
      final assigned = assignedByDay[a.dayOfWeek] ?? const <_MinuteRange>[];
      for (final block in assigned) {
        segments = segments.expand((segment) {
          if (block.end <= segment.start || block.start >= segment.end) {
            return [segment];
          }
          final next = <_MinuteRange>[];
          if (block.start > segment.start) {
            next.add(_MinuteRange(segment.start, block.start));
          }
          if (block.end < segment.end) {
            next.add(_MinuteRange(block.end, segment.end));
          }
          return next;
        }).toList();
      }

      for (final s in segments) {
        if ((s.end - s.start) >= 30) {
          freeSlots.add(
            '${_getDayName(a.dayOfWeek)} ${_formatMinutes(s.start)}-${_formatMinutes(s.end)}',
          );
        }
      }
    }

    return freeSlots;
  }

  String _formatMinutes(int totalMinutes) {
    final hour24 = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    var hour12 = hour24 % 12;
    if (hour12 == 0) hour12 = 12;
    final minuteText = minute.toString().padLeft(2, '0');
    return '$hour12:$minuteText$period';
  }

  @override
  Widget build(BuildContext context) => _buildFacultyDashboard(context);

  Widget _buildFacultyDashboard(BuildContext context) {
    final scheduleAsync = ref.watch(facultyScheduleProvider);
    final availabilityAsync = ref.watch(facultyAvailabilityProvider);
    final historyAsync = ref.watch(chatHistoryProvider(20));
    final user = ref.watch(authProvider);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    Widget buildHeaderActions(bool compact) {
      final actions = [
        scheduleAsync.maybeWhen(
          data: (schedules) => schedules.isEmpty
              ? const SizedBox()
              : ElevatedButton.icon(
                  onPressed: () async {
                    await ScheduleExportService.exportFacultySchedulePdf(
                      facultyName: user?.userName ?? 'Faculty',
                      schedules: schedules,
                    );
                  },
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 18,
                  ),
                  label: Text(
                    'Export PDF',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: maroonColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
          orElse: () => const SizedBox(),
        ),
        scheduleAsync.maybeWhen(
          data: (schedules) => schedules.isEmpty
              ? const SizedBox()
              : ElevatedButton.icon(
                  onPressed: () async {
                    final result =
                        await ScheduleExportService.exportFacultyScheduleDocx(
                          facultyName: user?.userName ?? 'Faculty',
                          schedules: schedules,
                        );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result != null
                              ? 'DOCX exported: $result'
                              : 'DOCX export canceled.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.description_rounded,
                    size: 18,
                  ),
                  label: Text(
                    'Export DOCX',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF37474F),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
          orElse: () => const SizedBox(),
        ),
        ElevatedButton.icon(
          onPressed: () => showPasswordResetDialog(
            context,
            initialEmail: user?.email,
            lockEmail: user?.email?.isNotEmpty == true,
            title: 'Reset Password',
            subtitle:
                'Verify your email and choose a new password for your faculty account.',
          ),
          icon: const Icon(Icons.lock_reset_rounded, size: 18),
          label: Text(
            'Reset Password',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.white30),
            ),
            elevation: 0,
          ),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => const LogoutConfirmationDialog(),
            );
            if (confirm == true) {
              ref.read(authProvider.notifier).signOut();
            }
          },
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text(
            'Sign Out',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Colors.white30),
            ),
            elevation: 0,
          ),
        ),
        const ThemeModeToggle(compact: true),
      ];

      if (!compact) {
        return Row(
          children: [
            actions[0],
            const SizedBox(width: 12),
            actions[1],
            const SizedBox(width: 12),
            actions[2],
            const SizedBox(width: 12),
            actions[3],
            const SizedBox(width: 12),
            actions[4],
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (actions[0] is! SizedBox)
            SizedBox(width: double.infinity, child: actions[0]),
          if (actions[0] is! SizedBox) const SizedBox(height: 10),
          if (actions[1] is! SizedBox)
            SizedBox(width: double.infinity, child: actions[1]),
          if (actions[1] is! SizedBox) const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: actions[2]),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: actions[3]),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: actions[4]),
        ],
      );
    }

    final scaffold = Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        padding: ResponsiveHelper.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // ── Welcome Banner ──────────────────────────────────────
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveHelper.isMobile(context) ? 16 : 28,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        maroonColor,
                        const Color(0xFF8e005b),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: maroonColor.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.18),
                                  child: Text(
                                    (user?.userName?[0] ?? 'F').toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome, Professor',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        user?.userName ?? 'Faculty Member',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            buildHeaderActions(true),
                          ],
                        )
                      : Row(
                          children: [
                            CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.white.withValues(alpha: 0.18),
                              child: Text(
                                (user?.userName?[0] ?? 'F').toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, Professor',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    user?.userName ?? 'Faculty Member',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            buildHeaderActions(false),
                          ],
                        ),
                ),

                const SizedBox(height: 28),

                scheduleAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                  data: (schedules) {
                    final availabilities = availabilityAsync.maybeWhen(
                      data: (v) => v,
                      orElse: () => <FacultyAvailability>[],
                    );
                    final totalUnits = schedules.fold<double>(
                      0,
                      (sum, s) =>
                          sum +
                          (s.schedule.units ??
                              s.schedule.subject?.units.toDouble() ??
                              0),
                    );
                    final maxLoad = schedules.isNotEmpty
                        ? schedules.first.schedule.faculty?.maxLoad?.toDouble()
                        : null;
                    final outsidePreferred = schedules
                        .where(
                          (s) => !_isWithinPreferredAvailability(
                            s.schedule,
                            availabilities,
                          ),
                        )
                        .length;
                    final assignedHours = _computeAssignedHours(schedules);
                    final preferredHours = _computePreferredHours(
                      availabilities,
                    );
                    final assignedWithinPreferred =
                        _computeAssignedHoursWithinPreferred(
                          schedules,
                          availabilities,
                        );
                    final vacantHours = preferredHours > assignedWithinPreferred
                        ? preferredHours - assignedWithinPreferred
                        : 0.0;
                    final freeSlots = _computeFreeSlotLabels(
                      schedules,
                      availabilities,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _metricCard(
                                label: 'Assigned Units',
                                value: totalUnits.toStringAsFixed(1),
                                icon: Icons.stacked_bar_chart_rounded,
                                color: Colors.blue,
                                cardBg: cardBg,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _metricCard(
                                label: 'Max Load',
                                value: maxLoad?.toStringAsFixed(1) ?? '--',
                                icon: Icons.speed_rounded,
                                color: Colors.green,
                                cardBg: cardBg,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _metricCard(
                                label: 'Outside Preferred',
                                value: outsidePreferred.toString(),
                                icon: Icons.warning_amber_rounded,
                                color: outsidePreferred > 0
                                    ? Colors.red
                                    : Colors.orange,
                                cardBg: cardBg,
                              ),
                            ),
                          ],
                        ),
                        if (outsidePreferred > 0) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              '$outsidePreferred class(es) are outside your preferred availability window.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _metricCard(
                                label: 'Assigned Hours',
                                value: assignedHours.toStringAsFixed(1),
                                icon: Icons.access_time_rounded,
                                color: Colors.indigo,
                                cardBg: cardBg,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _metricCard(
                                label: 'Vacant Hours',
                                value: vacantHours.toStringAsFixed(1),
                                icon: Icons.hourglass_bottom_rounded,
                                color: Colors.teal,
                                cardBg: cardBg,
                              ),
                            ),
                          ],
                        ),
                        if (freeSlots.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.teal.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              'Free Slots: ${freeSlots.take(6).join(' | ')}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.teal[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),

                Text(
                  'Assistant History',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                historyAsync.when(
                  loading: () => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const LinearProgressIndicator(minHeight: 6),
                  ),
                  error: (err, _) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Could not load history: $err',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'No assistant history yet. Ask a question in the NLP chat to start.',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      );
                    }

                    final visible = items.take(6).toList();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: maroonColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final entry = visible[index];
                          final isUser = entry.sender == 'user';
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: isUser
                                    ? maroonColor.withValues(alpha: 0.15)
                                    : Colors.green.withValues(alpha: 0.15),
                                child: Icon(
                                  isUser ? Icons.person : Icons.smart_toy,
                                  size: 14,
                                  color: isUser ? maroonColor : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUser ? 'You' : 'CITESched AI',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.text,
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── Tab bar ─────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: maroonColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: maroonColor.withValues(alpha: 0.2),
                      ),
                    ),
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
                      Tab(
                        icon: Icon(Icons.view_week_rounded, size: 18),
                        text: _weeklyCalendarLabel,
                      ),
                      Tab(
                        icon: Icon(Icons.table_rows_rounded, size: 18),
                        text: 'Schedule Table',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Tab views ────────────────────────────────────────────
                scheduleAsync.when(
                  loading: () => const Center(
                    heightFactor: 5,
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => Center(
                    heightFactor: 4,
                    child: Text(
                      'Error loading schedule: $err',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ),
                  data: (schedules) {
                    if (schedules.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No schedules assigned yet.',
                              style: GoogleFonts.poppins(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return SizedBox(
                      height: 640,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // ── Tab 1: Calendar ──────────────────────────
                          availabilityAsync.when(
                            data: (availabilities) => CalendarViewCard(
                              title: _weeklyCalendarLabel,
                              maroonColor: maroonColor,
                              cardBg: cardBg,
                              isDark: isDark,
                              calendarHeight: 700,
                              onFullScreen: () =>
                                  Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FullScreenCalendarScaffold(
                                    title: _weeklyCalendarLabel,
                                    backgroundColor: isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8F9FA),
                                    useMaxWidthConstraint: false,
                                    child: WeeklyCalendarView(
                                      schedules: schedules,
                                      availabilities: availabilities,
                                      maroonColor: maroonColor,
                                    ),
                                  ),
                                ),
                              ),
                              child: WeeklyCalendarView(
                                schedules: schedules,
                                availabilities: availabilities,
                                maroonColor: maroonColor,
                              ),
                            ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (err, _) => CalendarViewCard(
                              title: _weeklyCalendarLabel,
                              maroonColor: maroonColor,
                              cardBg: cardBg,
                              isDark: isDark,
                              calendarHeight: 700,
                              onFullScreen: () =>
                                  Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FullScreenCalendarScaffold(
                                    title: _weeklyCalendarLabel,
                                    backgroundColor: isDark
                                        ? const Color(0xFF0F172A)
                                        : const Color(0xFFF8F9FA),
                                    useMaxWidthConstraint: false,
                                    child: WeeklyCalendarView(
                                      schedules: schedules,
                                      maroonColor: maroonColor,
                                    ),
                                  ),
                                ),
                              ),
                              child: WeeklyCalendarView(
                                schedules: schedules,
                                maroonColor: maroonColor,
                              ),
                            ),
                          ),

                          // ── Tab 2: Schedule Table ───────────────────
                          _buildScheduleTable(
                            context,
                            schedules,
                            cardBg,
                            isDark,
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ],
        ),
      ),
    );

    return Stack(
      children: [
        scaffold,
        DraggableFab(
          child: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const NLPQueryDialog(),
              );
            },
            backgroundColor: const Color(0xFF4f003b),
            foregroundColor: Colors.white,
            child: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'Hey ask me some questions!',
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleTable(
    BuildContext context,
    List<ScheduleInfo> schedules,
    Color cardBg,
    bool isDark,
  ) => _buildScheduleTableImpl(context, schedules, cardBg, isDark);

  Widget _buildScheduleTableImpl(
    BuildContext context,
    List<ScheduleInfo> schedules,
    Color cardBg,
    bool isDark,
  ) {
    final isMobile = ResponsiveHelper.isMobile(context);
    // Sort by day then time
    final dayOrder = {
      DayOfWeek.mon: 0,
      DayOfWeek.tue: 1,
      DayOfWeek.wed: 2,
      DayOfWeek.thu: 3,
      DayOfWeek.fri: 4,
      DayOfWeek.sat: 5,
      DayOfWeek.sun: 6,
    };
    final sorted = List<ScheduleInfo>.from(schedules)
      ..sort((a, b) {
        final da = dayOrder[a.schedule.timeslot?.day] ?? 99;
        final db = dayOrder[b.schedule.timeslot?.day] ?? 99;
        if (da != db) return da.compareTo(db);
        return (a.schedule.timeslot?.startTime ?? '').compareTo(
          b.schedule.timeslot?.startTime ?? '',
        );
      });

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final info = sorted[index];
            final s = info.schedule;
            final ts = s.timeslot;
            final hasConflict = info.conflicts.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasConflict
                    ? Colors.red.withValues(alpha: 0.05)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.grey.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasConflict
                      ? Colors.red.withValues(alpha: 0.2)
                      : (isDark ? Colors.white12 : Colors.grey.shade200),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: hasConflict ? Colors.red : maroonColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getDayName(ts?.day),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (hasConflict)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Conflict',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.red[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ts == null
                        ? 'Time TBD'
                        : '${ts.startTime} - ${ts.endTime}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.subject?.name ?? 'Subject',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    children: [
                      _miniChip(
                        label: 'Section',
                        value: s.section,
                      ),
                      _miniChip(
                        label: 'Room',
                        value: s.room?.name ?? '--',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: maroonColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                _tableHeader('DAY', flex: 2),
                _tableHeader('TIME', flex: 3),
                _tableHeader('SUBJECT', flex: 4),
                _tableHeader('SECTION', flex: 2),
                _tableHeader('ROOM', flex: 2),
              ],
            ),
          ),

          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final info = sorted[index];
                final s = info.schedule;
                final ts = s.timeslot;
                final hasConflict = info.conflicts.isNotEmpty;
                final isEven = index.isEven;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: hasConflict
                        ? Colors.red.withValues(alpha: 0.04)
                        : isEven
                        ? (isDark
                              ? Colors.white.withValues(alpha: 0.02)
                              : Colors.grey.withValues(alpha: 0.03))
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _tableCell(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: hasConflict ? Colors.red : maroonColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getDayName(ts?.day),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: hasConflict ? Colors.red : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _tableCell(
                        flex: 3,
                        child: Text(
                          ts != null ? '${ts.startTime} – ${ts.endTime}' : '—',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      _tableCell(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              s.subject?.name ?? '—',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (s.subject?.code != null)
                              Text(
                                s.subject!.code,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      _tableCell(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: maroonColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            s.section,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: maroonColor,
                            ),
                          ),
                        ),
                      ),
                      _tableCell(
                        flex: 2,
                        child: Row(
                          children: [
                            Icon(
                              Icons.meeting_room_rounded,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              s.room?.name ?? '—',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: maroonColor.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  '${sorted.length} subject/s assigned this term',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: maroonColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: maroonColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: maroonColor,
        ),
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color cardBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tableCell({required int flex, required Widget child}) {
    return Expanded(flex: flex, child: child);
  }
}

class _MinuteRange {
  final int start;
  final int end;

  const _MinuteRange(this.start, this.end);
}
