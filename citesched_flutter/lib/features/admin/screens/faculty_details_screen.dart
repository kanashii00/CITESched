import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final facultyScheduleProvider = FutureProvider.family<List<Schedule>, int>((
  ref,
  facultyId,
) async {
  ref.watch(scheduleSyncTriggerProvider);
  return await client.admin.getFacultySchedule(facultyId);
});

String _facultyInitial(String name) {
  if (name.isEmpty) {
    return '?';
  }
  return name[0].toUpperCase();
}

Color _facultyStatusColor(EmploymentStatus? status, bool inverted) {
  if (status == null) {
    return Colors.grey;
  }
  if (status == EmploymentStatus.fullTime) {
    if (inverted) {
      return Colors.white;
    }
    return Colors.green;
  }
  if (inverted) {
    return Colors.white70;
  }
  return Colors.blue;
}

String _scheduleSummary(Schedule schedule) {
  return '${schedule.timeslot?.day ?? "N/A"} | ${schedule.timeslot?.startTime} - ${schedule.timeslot?.endTime} | Room ${schedule.room?.name ?? "N/A"}';
}

class FacultyDetailsScreen extends ConsumerWidget {
  final Faculty faculty;

  const FacultyDetailsScreen({super.key, required this.faculty});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(facultyScheduleProvider(faculty.id!));
    final subjectsAsync = ref.watch(subjectsProvider);
    final currentLoad = scheduleAsync.maybeWhen(
      data: (schedules) => schedules.fold<double>(
        0,
        (sum, s) => sum + (s.units ?? s.subject?.units.toDouble() ?? 0),
      ),
      orElse: () => 0,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;

    const maroonColor = Color(0xFF720045);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // Header (Standardized Maroon Gradient Banner)
          AdminHeaderContainer(
            primaryColor: maroonColor,
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            boxShadow: [
              BoxShadow(
                color: maroonColor.withValues(alpha: 0.3),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: isMobile ? 12 : 16),
                    CircleAvatar(
                      radius: isMobile ? 28 : 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        _facultyInitial(faculty.name),
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 16 : 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            faculty.name,
                            maxLines: isMobile ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 20 : 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                faculty.facultyId,
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 14 : 16,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              _buildStatusChip(
                                faculty.employmentStatus,
                                inverted: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 16 : 20),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 20,
                    vertical: isMobile ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Icon(
                        Icons.email_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        faculty.email,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Program Info Bar
                  Container(
                    margin: const EdgeInsets.only(bottom: 32),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: maroonColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(Icons.business_rounded, color: maroonColor),
                        Text(
                          'PROGRAM ASSIGNMENT:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          (faculty.program?.name ?? '—').toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: maroonColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Row
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildSimpleStatCard(
                        'Max Load',
                        '${faculty.maxLoad} Units',
                        Icons.speed,
                        Colors.blue,
                        cardBg,
                        isMobile: isMobile,
                      ),
                      _buildSimpleStatCard(
                        'Current Load',
                        '${currentLoad.toStringAsFixed(1)} Units',
                        Icons.trending_up,
                        Colors.green,
                        cardBg,
                        isMobile: isMobile,
                      ),
                      _buildSimpleStatCard(
                        'Shift',
                        (faculty.shiftPreference?.name ?? 'ANY').toUpperCase(),
                        Icons.access_time,
                        Colors.orange,
                        cardBg,
                        isMobile: isMobile,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: maroonColor),
                      const SizedBox(width: 12),
                      Text(
                        'Handled Subjects',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  subjectsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        Center(child: Text('Error loading subjects: $err')),
                    data: (subjects) {
                      final handledSubjects = subjects
                          .where((subject) => subject.facultyId == faculty.id)
                          .toList()
                        ..sort((a, b) => a.code.compareTo(b.code));

                      if (handledSubjects.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No handled subjects assigned to this faculty.',
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: handledSubjects.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final subject = handledSubjects[index];
                            final subjectTypes = subject.types;

                            return ListTiles(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: maroonColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.auto_stories_rounded,
                                  color: maroonColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '${subject.code} • ${subject.name}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${subject.program.name.toUpperCase()} | ${subject.units} units',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  if (subjectTypes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: subjectTypes
                                          .map(
                                            (type) =>
                                                _buildSubjectTypeBadge(type),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Teaching Timetable Section
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: maroonColor),
                      const SizedBox(width: 12),
                      Text(
                        'Teaching Timetable',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  scheduleAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        Center(child: Text('Error loading schedule: $err')),
                    data: (schedules) {
                      if (schedules.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Text(
                              'No classes scheduled for this faculty.',
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: schedules.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final s = schedules[index];
                            return ListTiles(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: maroonColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.book,
                                  color: maroonColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                s.subject?.name ?? 'Unknown Subject',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                _scheduleSummary(s),
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Section: ${s.section}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(EmploymentStatus? status, {bool inverted = false}) {
    if (status == null) return const Text('—');
    final color = _facultyStatusColor(status, inverted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: inverted
            ? Colors.white.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: inverted
              ? Colors.white.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSimpleStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    Color cardBg,
    {required bool isMobile}
  ) {
    return SizedBox(
      width: isMobile ? double.infinity : 260,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSubjectTypeBadge(SubjectType type) {
    late final Color color;
    late final String label;

    switch (type) {
      case SubjectType.lecture:
        color = Colors.blue;
        label = 'LECTURE';
        break;
      case SubjectType.laboratory:
        color = Colors.green;
        label = 'LABORATORY';
        break;
      case SubjectType.blended:
        color = Colors.deepPurple;
        label = 'BLENDED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// Simple Helper ListTiles to avoid dependency issues if using custom widgets
class ListTiles extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget subtitle;
  final Widget? trailing;

  const ListTiles({
    super.key,
    this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title,
                const SizedBox(height: 4),
                subtitle,
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}
