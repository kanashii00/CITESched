import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/core/utils/schedule_export_service.dart';
import 'package:citesched_flutter/core/utils/session_context.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/auth/widgets/logout_confirmation_dialog.dart';
import 'package:citesched_flutter/features/auth/widgets/password_reset_dialog.dart';
import 'package:citesched_flutter/core/widgets/draggable_fab.dart';
import 'package:citesched_flutter/core/widgets/nlp_query_dialog.dart';
import 'package:citesched_flutter/core/widgets/theme_mode_toggle.dart';
import 'package:citesched_flutter/features/nlp/providers/chat_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';
import 'package:citesched_flutter/core/widgets/full_screen_calendar_scaffold.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';

final currentSignedInEmailProvider = FutureProvider<String?>((ref) async {
  final sessionContext = await fetchSessionContext();
  final email = sessionContext.email?.trim().toLowerCase();
  if (email != null && email.isNotEmpty) {
    return email;
  }

  final fallbackEmail = ref.watch(authProvider)?.email?.trim().toLowerCase();
  if (fallbackEmail == null || fallbackEmail.isEmpty) {
    return null;
  }
  return fallbackEmail;
});

final currentSignedInNameProvider = FutureProvider<String?>((ref) async {
  final sessionContext = await fetchSessionContext();
  final liveName = sessionContext.userName?.trim();
  if (liveName != null && liveName.isNotEmpty) {
    return liveName;
  }

  final fallbackName = ref.watch(authProvider)?.userName?.trim();
  if (fallbackName == null || fallbackName.isEmpty) {
    return null;
  }
  return fallbackName;
});

final myProfileProvider = FutureProvider<Student?>((ref) async {
  try {
    final profile = await client.student.getMyProfile();
    if (profile != null) {
      return profile;
    }
  } catch (_) {}

  final email = await ref.watch(currentSignedInEmailProvider.future);
  if (email == null || email.isEmpty) {
    return null;
  }

  return await client.setup.getStudentProfileByEmail(email: email);
});

final myScheduleProvider = FutureProvider<List<ScheduleInfo>>((ref) async {
  ref.watch(scheduleSyncTriggerProvider);
  return await client.timetable.getPersonalSchedule();
});

const _studentWeeklyCalendarLabel = 'Weekly Calendar';

class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen>
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

  int _parseTimeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return 0;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(myScheduleProvider);
    final profileAsync = ref.watch(myProfileProvider);
    final signedInNameAsync = ref.watch(currentSignedInNameProvider);
    final historyAsync = ref.watch(chatHistoryProvider(20));
    final user = ref.watch(authProvider);
    final isMobile = ResponsiveHelper.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const maroonColor = Color(0xFF720045);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    Widget buildHeaderActions(bool compact) {
      final actions = [
        scheduleAsync.maybeWhen(
          data: (schedules) => schedules.isEmpty
              ? const SizedBox()
              : ElevatedButton.icon(
                  onPressed: () async {
                    await ScheduleExportService.exportStudentSchedulePdf(
                      student: profileAsync.value,
                      schedules: schedules,
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
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
                        await ScheduleExportService.exportStudentScheduleDocx(
                          student: profileAsync.value,
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
                  icon: const Icon(Icons.description_rounded, size: 18),
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
          onPressed: profileAsync.value == null
              ? null
              : () => showDialog<void>(
                    context: context,
                    builder: (_) => _EditOwnStudentProfileDialog(
                      student: profileAsync.value!,
                      onSaved: () {
                        ref.invalidate(myProfileProvider);
                        ref.invalidate(myScheduleProvider);
                      },
                    ),
                  ),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: Text(
            'Edit Profile',
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
          onPressed: () => showPasswordResetDialog(
            context,
            initialEmail: user?.email,
            lockEmail: user?.email?.isNotEmpty == true,
            title: 'Reset Password',
            subtitle:
                'Use the verification code from your email to update your student password.',
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
            const SizedBox(width: 12),
            actions[5],
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
          SizedBox(width: double.infinity, child: actions[4]),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: actions[5]),
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
                    // Welcome Banner
                    Container(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.isMobile(context) ? 16 : 28,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [maroonColor, Color(0xFF8e005b)],
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
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.15),
                                        child: Text(
                                          _studentAvatarInitial(
                                            profileAsync,
                                            user,
                                          ).toUpperCase(),
                                          style: GoogleFonts.poppins(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
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
                                            'Welcome, Student',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withValues(alpha: 0.8),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            profileAsync.value?.name ??
                                                signedInNameAsync.value ??
                                                user?.userName ??
                                                'Student',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.4,
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
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.15,
                                    ),
                                    child: Text(
                                      (profileAsync.value?.name.isNotEmpty ==
                                                  true
                                              ? profileAsync.value!.name[0]
                                              : user?.userName?[0] ?? 'S')
                                          .toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome, Student',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        profileAsync.value?.name ??
                                            signedInNameAsync.value ??
                                            user?.userName ??
                                            'Student',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                buildHeaderActions(false),
                              ],
                            ),
                    ),

                    profileAsync.when(
                      loading: () => const SizedBox(height: 28),
                      error: (err, _) => const SizedBox(height: 28),
                      data: (profile) {
                        if (profile == null) return const SizedBox(height: 28);
                        return const SizedBox(height: 28);
                      },
                    ),

                    scheduleAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (error, stackTrace) => const SizedBox.shrink(),
                      data: (schedules) {
                        final profile = profileAsync.value;
                        final totalUnits = schedules.fold<double>(
                          0,
                          (sum, s) =>
                              sum +
                              (s.schedule.units ??
                                  s.schedule.subject?.units.toDouble() ??
                                  0),
                        );
                        final assignedHours = _computeAssignedHours(schedules);
                        final unscheduledCount =
                            schedules.where((s) => s.schedule.timeslot == null).length;
                        final enrolledSubjects = schedules.length;

                        if (profile == null) {
                          return const SizedBox(height: 20);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _metricCard(
                                    label: 'Program',
                                    value: profile.course,
                                    icon: Icons.school_rounded,
                                    color: Colors.blue,
                                    cardBg: cardBg,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _metricCard(
                                    label: 'Year Level',
                                    value: 'Year ${profile.yearLevel}',
                                    icon: Icons.trending_up_rounded,
                                    color: Colors.green,
                                    cardBg: cardBg,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _metricCard(
                                    label: 'Section',
                                    value: profile.section ?? 'Unassigned',
                                    icon: Icons.groups_rounded,
                                    color: Colors.orange,
                                    cardBg: cardBg,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _metricCard(
                                    label: 'Subjects',
                                    value: enrolledSubjects.toString(),
                                    icon: Icons.menu_book_rounded,
                                    color: Colors.indigo,
                                    cardBg: cardBg,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _metricCard(
                                    label: 'Weekly Hours',
                                    value: assignedHours.toStringAsFixed(1),
                                    icon: Icons.access_time_rounded,
                                    color: Colors.teal,
                                    cardBg: cardBg,
                                  ),
                                ),
                              ],
                            ),
                            if (totalUnits > 0 || unscheduledCount > 0) ...[
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
                                  'Units: ${totalUnits.toStringAsFixed(1)}'
                                  '${unscheduledCount > 0 ? ' | Unscheduled Classes: $unscheduledCount' : ''}'
                                  ' | Student ID: ${profile.studentNumber}',
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

                    const SizedBox(height: 32),

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
                                      color: isUser
                                          ? maroonColor
                                          : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
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
                            text: _studentWeeklyCalendarLabel,
                          ),
                          Tab(
                            icon: Icon(Icons.table_rows_rounded, size: 18),
                            text: 'Schedule Table',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    scheduleAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      data: (schedules) {
                        if (schedules.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(40),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No classes found for your section.',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final scheduled = schedules
                            .where((s) => s.schedule.timeslot != null)
                            .toList();
                        final unscheduledCount =
                            schedules.length - scheduled.length;

                        // Sort schedules by day then start time for consistent render
                        scheduled.sort((a, b) {
                          final ta = a.schedule.timeslot;
                          final tb = b.schedule.timeslot;
                          if (ta == null || tb == null) return 0;
                          final dayOrder = ta.day.index.compareTo(tb.day.index);
                          if (dayOrder != 0) return dayOrder;
                          return ta.startTime.compareTo(tb.startTime);
                        });

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (unscheduledCount > 0) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.amber.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.amber[800],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Some classes do not have an assigned day/time yet. Ask the admin to set a timeslot in Faculty Loading.',
                                        style: GoogleFonts.poppins(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            SizedBox(
                              height: 640,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  CalendarViewCard(
                                    title: _studentWeeklyCalendarLabel,
                                    maroonColor: maroonColor,
                                    cardBg: cardBg,
                                    isDark: isDark,
                                    calendarHeight:
                                        ResponsiveHelper.calendarHeight(context) +
                                        90,
                                    onFullScreen: () =>
                                        Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            FullScreenCalendarScaffold(
                                          title: _studentWeeklyCalendarLabel,
                                          backgroundColor: bgColor,
                                          useMaxWidthConstraint: false,
                                          child: WeeklyCalendarView(
                                            schedules: scheduled,
                                            maroonColor: maroonColor,
                                            isStudentView: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: WeeklyCalendarView(
                                      schedules: scheduled,
                                      maroonColor: maroonColor,
                                      isStudentView: true,
                                    ),
                                  ),
                                  _StudentScheduleTableCard(
                                    schedules: schedules,
                                    cardBg: cardBg,
                                    maroonColor: maroonColor,
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  String _studentAvatarInitial(
    AsyncValue<Student?> profileAsync,
    UserInfo? user,
  ) {
    final profileName = profileAsync.value?.name;
    if (profileName != null && profileName.isNotEmpty) {
      return profileName[0];
    }
    return user?.userName?[0] ?? 'S';
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color cardBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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
}

class _StudentScheduleTableCard extends StatelessWidget {
  const _StudentScheduleTableCard({
    required this.schedules,
    required this.cardBg,
    required this.maroonColor,
  });

  final List<ScheduleInfo> schedules;
  final Color cardBg;
  final Color maroonColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: maroonColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.table_rows_rounded, color: maroonColor, size: 20),
              const SizedBox(width: 10),
              Text(
                'Schedule Table',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final minTableWidth = constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: minTableWidth),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                      maroonColor.withValues(alpha: 0.08),
                    ),
                    horizontalMargin: 12,
                    columnSpacing: 22,
                    columns: [
                      _tableHeader('SUBJECT'),
                      _tableHeader('DAY / TIME'),
                      _tableHeader('ROOM'),
                      _tableHeader('FACULTY'),
                      _tableHeader('SECTION'),
                    ],
                    rows: schedules.map((info) {
                      final sched = info.schedule;
                      final timeslot = sched.timeslot;
                      final subjectLabel =
                          '${sched.subject?.code ?? 'TBA'} - ${sched.subject?.name ?? 'Subject'}';
                      final dayTimeLabel = timeslot == null
                          ? 'No assigned timeslot'
                          : '${timeslot.day.name.toUpperCase()} | ${timeslot.startTime}-${timeslot.endTime}';
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 260,
                              child: Text(
                                subjectLabel,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Text(
                                dayTimeLabel,
                                style: GoogleFonts.poppins(fontSize: 13),
                              ),
                            ),
                          ),
                          DataCell(Text(sched.room?.name ?? 'Room TBD')),
                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Text(
                                sched.faculty?.name ?? 'Faculty TBD',
                              ),
                            ),
                          ),
                          DataCell(Text(sched.section)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EditOwnStudentProfileDialog extends StatefulWidget {
  const _EditOwnStudentProfileDialog({
    required this.student,
    required this.onSaved,
  });

  final Student student;
  final VoidCallback onSaved;

  @override
  State<_EditOwnStudentProfileDialog> createState() =>
      _EditOwnStudentProfileDialogState();
}

class _EditOwnStudentProfileDialogState
    extends State<_EditOwnStudentProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  static const List<String> _allowedCourses = ['BSIT', 'BSEMC'];
  late final TextEditingController _nameCtrl;
  late final TextEditingController _studentNumberCtrl;
  late final TextEditingController _sectionCtrl;
  late String _selectedCourse;
  late int _selectedYearLevel;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.student.name);
    _studentNumberCtrl = TextEditingController(text: widget.student.studentNumber);
    _sectionCtrl = TextEditingController(text: widget.student.section ?? '');
    _selectedCourse =
        _allowedCourses.contains(widget.student.course.trim().toUpperCase())
            ? widget.student.course.trim().toUpperCase()
            : _allowedCourses.first;
    _selectedYearLevel = widget.student.yearLevel.clamp(1, 4);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _studentNumberCtrl.dispose();
    _sectionCtrl.dispose();
    super.dispose();
  }

  String _normalizeSectionCode(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final match = RegExp(r'^\s*(\d+)\s*([A-Za-z][A-Za-z0-9]*)\s*$').firstMatch(
      trimmed,
    );
    if (match == null) return trimmed.toUpperCase();
    return '${match.group(1)!}${match.group(2)!.toUpperCase()}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final normalizedSection = _normalizeSectionCode(_sectionCtrl.text);
      final updated = widget.student.copyWith(
        name: _nameCtrl.text.trim(),
        course: _selectedCourse,
        yearLevel: _selectedYearLevel,
        section: normalizedSection.isEmpty ? null : normalizedSection,
        studentNumber: _studentNumberCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );
      await client.student.updateMyProfile(updated);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maroon = const Color(0xFF720045);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit Student Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.student.email,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _studentNumberCtrl,
                  decoration: const InputDecoration(labelText: 'Student Number'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCourse,
                  decoration: const InputDecoration(labelText: 'Program'),
                  items: _allowedCourses
                      .map(
                        (course) => DropdownMenuItem<String>(
                          value: course,
                          child: Text(course),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCourse = value);
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _selectedYearLevel,
                  decoration: const InputDecoration(labelText: 'Year Level'),
                  items: const [1, 2, 3, 4]
                      .map(
                        (year) => DropdownMenuItem<int>(
                          value: year,
                          child: Text('Year $year'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedYearLevel = value);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sectionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    hintText: 'e.g. 3A',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maroon,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _isSaving ? 'Saving...' : 'Save Changes',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _infoRow(String label, String value) {
  return Row(
    children: [
      SizedBox(
        width: 110,
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ),
    ],
  );
}

DataColumn _tableHeader(String title) {
  return DataColumn(
    label: Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 12,
        letterSpacing: 0.4,
      ),
    ),
  );
}
