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

class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final scaffold = Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Student Dashboard',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: maroonColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [
          _StudentDashboardActions(),
        ],
      ),
      body: SingleChildScrollView(
        padding: ResponsiveHelper.pagePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                    // Premium Welcome Card
                    Container(
                      padding: EdgeInsets.all(
                        ResponsiveHelper.isMobile(context) ? 16 : 32,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [maroonColor, Color(0xFF8e005b)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: maroonColor.withValues(alpha: 0.3),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
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
                                            'Welcome back, Student!',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white.withValues(
                                                alpha: 0.9,
                                              ),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.4,
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
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) =>
                                            const LogoutConfirmationDialog(),
                                      );
                                      if (confirm == true) {
                                        ref
                                            .read(authProvider.notifier)
                                            .signOut();
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.logout_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Sign Out',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: const BorderSide(
                                          color: Colors.white30,
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
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
                                        'Welcome back, Student!',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
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
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) =>
                                          const LogoutConfirmationDialog(),
                                    );
                                    if (confirm == true) {
                                      ref.read(authProvider.notifier).signOut();
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    'Sign Out',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.2,
                                    ),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: const BorderSide(
                                        color: Colors.white30,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Student Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    profileAsync.when(
                      loading: () => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const LinearProgressIndicator(minHeight: 6),
                      ),
                      error: (err, _) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('Could not load profile: $err'),
                      ),
                      data: (profile) {
                        if (profile == null) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Profile not found for this account.',
                            ),
                          );
                        }
                        if (isMobile) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _infoRow(
                                  'Student ID',
                                  profile.studentNumber,
                                ),
                                const SizedBox(height: 8),
                                _infoRow('Name', profile.name),
                                const SizedBox(height: 8),
                                _infoRow('Program', profile.course),
                                const SizedBox(height: 8),
                                _infoRow(
                                  'Section',
                                  profile.section ?? 'Unassigned',
                                ),
                                const SizedBox(height: 8),
                                _infoRow(
                                  'Year Level',
                                  '${profile.yearLevel}',
                                ),
                              ],
                            ),
                          );
                        }

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: LayoutBuilder(
                            builder: (context, tableConstraints) {
                              final minTableWidth = tableConstraints.maxWidth;
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: minTableWidth,
                                  ),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                      maroonColor.withValues(alpha: 0.08),
                                    ),
                                    horizontalMargin: 12,
                                    columnSpacing: 24,
                                    columns: [
                                      _tableHeader('STUDENT ID'),
                                      _tableHeader('NAME'),
                                      _tableHeader('PROGRAM'),
                                      _tableHeader('SECTION'),
                                      _tableHeader('YEAR LEVEL'),
                                    ],
                                    rows: [
                                      DataRow(
                                        cells: [
                                          DataCell(Text(profile.studentNumber)),
                                          DataCell(Text(profile.name)),
                                          DataCell(Text(profile.course)),
                                          DataCell(
                                            Text(
                                              profile.section ?? 'Unassigned',
                                            ),
                                          ),
                                          DataCell(
                                            Text('${profile.yearLevel}'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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

                    Text(
                      'My Classes Schedule',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

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
                                        'Some classes do not have an assigned day/time yet. '
                                        'Ask the admin to set a timeslot in Faculty Loading.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    await ScheduleExportService.exportStudentSchedulePdf(
                                      student: profileAsync.value,
                                      schedules: schedules,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: maroonColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Export PDF'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final result =
                                        await ScheduleExportService.exportStudentScheduleDocx(
                                          student: profileAsync.value,
                                          schedules: schedules,
                                        );
                                    if (!context.mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result != null
                                              ? 'DOCX exported: $result'
                                              : 'DOCX export canceled.',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.description_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Export DOCX'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            CalendarViewCard(
                              title: 'My Weekly Schedule',
                              maroonColor: maroonColor,
                              cardBg: cardBg,
                              isDark: isDark,
                              calendarHeight:
                                  ResponsiveHelper.calendarHeight(context) + 90,
                              onFullScreen: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FullScreenCalendarScaffold(
                                    title: 'My Weekly Schedule',
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
                            const SizedBox(height: 24),
                            Text(
                              'Subjects (read-only)',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: schedules.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 12),
                                itemBuilder: (context, index) {
                                  final info = schedules[index];
                                  final sched = info.schedule;
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 4,
                                    ),
                                    title: Text(
                                      '${sched.subject?.code ?? 'TBA'} - ${sched.subject?.name ?? 'Subject'}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      [
                                        'Section: ${sched.section}',
                                        if (sched.timeslot != null)
                                          '${sched.timeslot!.day.name.toUpperCase()} ${sched.timeslot!.startTime}-${sched.timeslot!.endTime}',
                                        'Room: ${sched.room?.name ?? 'Room TBD'}',
                                      ].join(' | '),
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    trailing: Text(
                                      sched.faculty?.name ?? 'Faculty',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  );
                                },
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
}

class _StudentDashboardActions extends ConsumerWidget {
  const _StudentDashboardActions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Reset password',
          onPressed: () => showPasswordResetDialog(
            context,
            initialEmail: user?.email,
            lockEmail: user?.email?.isNotEmpty == true,
            title: 'Reset Password',
            subtitle:
                'Use the verification code from your email to update your student password.',
          ),
          icon: const Icon(Icons.lock_reset_rounded),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 12),
          child: ThemeModeToggle(compact: true),
        ),
      ],
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
