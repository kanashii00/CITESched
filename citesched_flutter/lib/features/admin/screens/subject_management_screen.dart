import 'package:citesched_client/citesched_client.dart';
import 'dart:async';

import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'subject_details_screen.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/core/providers/conflict_provider.dart';
import 'package:citesched_flutter/core/utils/error_handler.dart';

// Local provider removed in favor of shared subjectsProvider

const kDeletePermanentlyLabel = 'Delete Permanently';
const kRestoreSubjectLabel = 'Restore Subject';
const kAddNewSubjectLabel = 'Add New Subject';
const kYearLevelLabel = 'Year Level';
const kSubjectCodeLabel = 'Subject Code';
const kSubjectCodeHint = 'e.g., ITEC 101';
const kSubjectTypesLabel = 'Subject Types';
const kStudentCountLabel = 'Student Count';
const kFirstSemesterLabel = '1st Semester';
const kSecondSemesterLabel = '2nd Semester';
const kSavingLabel = 'Saving...';

String _programLabel(Program program) {
  switch (program) {
    case Program.it:
      return 'IT';
    case Program.emc:
      return 'EMC';
    case Program.both:
      return 'Both IT and EMC';
  }
}

String _normalizeSubjectCodeValue(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
}

String _semesterLabel(int term) {
  return term == 1 ? kFirstSemesterLabel : kSecondSemesterLabel;
}

List<Faculty> _dedupeFacultyById(List<Faculty> facultyList) {
  final byId = <int, Faculty>{};
  for (final faculty in facultyList) {
    final id = faculty.id;
    if (id == null) continue;
    byId[id] = faculty;
  }

  return byId.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

class SubjectManagementScreen extends ConsumerStatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  ConsumerState<SubjectManagementScreen> createState() =>
      _SubjectManagementScreenState();
}

class _SubjectManagementScreenState
    extends ConsumerState<SubjectManagementScreen> {
  String _searchQuery = '';
  int? _selectedYearLevel;
  Program? _selectedProgram;
  bool _isShowingArchived = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedSubjectIds = {};
  final Color maroonColor = const Color(0xFF720045);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  void _syncSelectedSubjects(List<Subject> subjects) {
    final visibleIds = subjects
        .map((subject) => subject.id)
        .whereType<int>()
        .toSet();
    final intersection = _selectedSubjectIds.intersection(visibleIds);
    if (intersection.length != _selectedSubjectIds.length) {
      _selectedSubjectIds
        ..clear()
        ..addAll(intersection);
    }
  }

  void _toggleSelectAllSubjects(List<Subject> subjects, bool? isSelected) {
    final shouldSelect = isSelected ?? false;
    setState(() {
      _selectedSubjectIds.clear();
      if (shouldSelect) {
        _selectedSubjectIds.addAll(
          subjects.map((subject) => subject.id).whereType<int>(),
        );
      }
    });
  }

  void _toggleSubjectSelection(int subjectId, bool? isSelected) {
    setState(() {
      if (isSelected ?? false) {
        _selectedSubjectIds.add(subjectId);
      } else {
        _selectedSubjectIds.remove(subjectId);
      }
    });
  }

  Future<void> _archiveSelectedSubjects(List<Subject> subjects) async {
    final selected = subjects
        .where((subject) => _selectedSubjectIds.contains(subject.id))
        .toList();
    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Selected Subjects',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Archive ${selected.length} selected subjects?',
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
        for (final subject in selected) {
          await client.admin.updateSubject(
            subject.copyWith(isActive: false),
          );
        }
        _selectedSubjectIds.clear();
        ref.invalidate(subjectsProvider);
        ref.invalidate(archivedSubjectsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected subjects archived successfully'),
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

  Future<void> _deleteSelectedSubjects(List<Subject> subjects) async {
    final selected = subjects
        .where((subject) => _selectedSubjectIds.contains(subject.id))
        .toList();
    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Selected Subjects',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'PERMANENTLY delete ${selected.length} selected subjects? This cannot be undone.',
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
            child: Text(kDeletePermanentlyLabel, style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        for (final subject in selected) {
          await client.admin.deleteSubject(subject.id!);
        }
        _selectedSubjectIds.clear();
        ref.invalidate(subjectsProvider);
        ref.invalidate(archivedSubjectsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected subjects deleted permanently'),
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

  void _showAddSubjectModal() {
    showDialog(
      context: context,
      builder: (context) => _AddSubjectModal(
        maroonColor: maroonColor,
        onSuccess: () {
          ref.invalidate(subjectsProvider);
        },
      ),
    );
  }

  void _showEditSubjectModal(Subject subject) {
    showDialog(
      context: context,
      builder: (context) => _EditSubjectModal(
        subject: subject,
        maroonColor: maroonColor,
        onSuccess: () {
          ref.invalidate(subjectsProvider);
        },
      ),
    );
  }

  void _archiveSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Subject',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to archive ${subject.name}? It will be hidden from assignments.',
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
        final archivedSubject = subject.copyWith(isActive: false);
        await client.admin.updateSubject(archivedSubject);
        ref.invalidate(subjectsProvider);
        ref.invalidate(archivedSubjectsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject archived successfully'),
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

  void _restoreSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          kRestoreSubjectLabel,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to restore ${subject.name}? It will reappear in active lists.',
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
        final restoredSubject = subject.copyWith(isActive: true);
        await client.admin.updateSubject(restoredSubject);
        ref.invalidate(subjectsProvider);
        ref.invalidate(archivedSubjectsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject restored successfully'),
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

  void _permanentDeleteSubject(Subject subject) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Permanent Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to PERMANENTLY delete ${subject.name}? This action cannot be undone.',
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
            child: Text(kDeletePermanentlyLabel, style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await client.admin.deleteSubject(subject.id!);
        ref.invalidate(subjectsProvider);
        ref.invalidate(archivedSubjectsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subject permanently deleted'),
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
  Widget build(BuildContext context) => _buildMainScreen(context);

  Widget _buildMainScreen(BuildContext context) {
    final subjectsAsync = _isShowingArchived
        ? ref.watch(archivedSubjectsProvider)
        : ref.watch(subjectsProvider);
    final conflictsAsync = ref.watch(allConflictsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useStackedHeader = constraints.maxWidth < 1100;
          final useCompactList = constraints.maxWidth < 1400;

          return SingleChildScrollView(
          padding: EdgeInsets.all(useStackedHeader ? 16 : 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminHeaderContainer(
                  primaryColor: maroonColor,
                  padding: EdgeInsets.all(useStackedHeader ? 20 : 32),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: maroonColor.withValues(alpha: 0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
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
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.auto_stories_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Subject Management',
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
                                        'Manage academic subjects, curricula, and units',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _showAddSubjectModal,
                                icon: const Icon(Icons.add_rounded, size: 20),
                                label: Text(
                                  kAddNewSubjectLabel,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: maroonColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
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
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.auto_stories_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Subject Management',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Manage academic subjects, curricula, and units',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          letterSpacing: 0.2,
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
                                onPressed: _showAddSubjectModal,
                                icon: const Icon(Icons.add_rounded, size: 24),
                                label: Text(
                                  kAddNewSubjectLabel,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: maroonColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
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
                ),
                const SizedBox(height: 32),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    useStackedHeader
                        ? Column(
                            children: [
                              _buildViewToggle(isDark),
                              const SizedBox(height: 16),
                              _buildSearchBar(isDark),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _buildYearFilter(isDark)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildProgramFilter(isDark)),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(flex: 3, child: _buildSearchBar(isDark)),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildYearFilter(isDark),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _buildProgramFilter(isDark),
                              ),
                              const SizedBox(width: 16),
                              _buildViewToggle(isDark),
                            ],
                          ),
                    const SizedBox(height: 24),
                    subjectsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('Error: $error')),
                      data: (subjects) {
                        final filtered = subjects.where((s) {
                          final matchesSearch =
                              s.code.toLowerCase().contains(_searchQuery) ||
                              s.name.toLowerCase().contains(_searchQuery);
                          final matchesYear =
                              _selectedYearLevel == null ||
                              s.yearLevel == _selectedYearLevel;
                          final matchesProgram =
                              _selectedProgram == null ||
                              s.program == _selectedProgram;
                          return matchesSearch && matchesYear && matchesProgram;
                        }).toList();
                        final allSelected =
                            filtered.isNotEmpty &&
                            _selectedSubjectIds.length == filtered.length;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _syncSelectedSubjects(filtered);
                        });

                        if (useCompactList) {
                          return _buildMobileSubjectList(filtered, isDark);
                        }

                        return Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border(
                              left: BorderSide(color: maroonColor, width: 4),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Table Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: maroonColor.withValues(alpha: 0.05),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.book_rounded,
                                      color: maroonColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Subjects',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: maroonColor,
                                      ),
                                    ),
                                    if (_selectedSubjectIds.isNotEmpty) ...[
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: maroonColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${_selectedSubjectIds.length} selected',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: maroonColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    if (!_isShowingArchived &&
                                        _selectedSubjectIds.isNotEmpty) ...[
                                      TextButton.icon(
                                        onPressed: () =>
                                            _archiveSelectedSubjects(filtered),
                                        icon: const Icon(
                                          Icons.archive_outlined,
                                        ),
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
                                      const SizedBox(width: 12),
                                    ],
                                    if (_isShowingArchived &&
                                        _selectedSubjectIds.isNotEmpty) ...[
                                      TextButton.icon(
                                        onPressed: () =>
                                            _deleteSelectedSubjects(filtered),
                                        icon: const Icon(
                                          Icons.delete_forever_outlined,
                                        ),
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
                                      const SizedBox(width: 12),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: maroonColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${filtered.length} Total',
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
                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minWidth: constraints.maxWidth,
                                      ),
                                      child: DataTable(
                                        showCheckboxColumn: false,
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              maroonColor,
                                            ),
                                        headingTextStyle: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          letterSpacing: 0.5,
                                        ),
                                        dataRowMinHeight: 65,
                                        dataRowMaxHeight: 85,
                                        columnSpacing: 32,
                                        horizontalMargin: 24,
                                        decoration: const BoxDecoration(
                                          color: Colors.transparent,
                                        ),
                                        columns: [
                                          DataColumn(
                                            label: Checkbox(
                                              value: allSelected,
                                              onChanged: (value) =>
                                                  _toggleSelectAllSubjects(
                                                    filtered,
                                                    value,
                                                  ),
                                              activeColor: Colors.white,
                                              checkColor: maroonColor,
                                            ),
                                          ),
                                          const DataColumn(label: Text('CODE')),
                                          const DataColumn(label: Text('TITLE')),
                                          const DataColumn(label: Text('UNITS')),
                                          const DataColumn(
                                            label: Text('PROGRAM'),
                                          ),
                                          const DataColumn(
                                            label: Text('YEAR/TERM'),
                                          ),
                                          const DataColumn(label: Text('TYPE')),
                                          const DataColumn(
                                            label: Text('STUDENTS'),
                                          ),
                                          const DataColumn(
                                            label: Text('ACTIONS'),
                                          ),
                                        ],
                                        rows: filtered.asMap().entries.map((
                                          entry,
                                        ) {
                                    final subject = entry.value;
                                    final index = entry.key;

                                    return DataRow(
                                      color:
                                          WidgetStateProperty.resolveWith<
                                            Color?
                                          >(
                                            (states) => _resolveRowColor(
                                              states,
                                              index,
                                              isDark,
                                            ),
                                          ),
                                      cells: [
                                        DataCell(
                                          Checkbox(
                                            value:
                                                subject.id != null &&
                                                _selectedSubjectIds.contains(
                                                  subject.id,
                                                ),
                                            onChanged: subject.id == null
                                                ? null
                                                : (value) =>
                                                      _toggleSubjectSelection(
                                                        subject.id!,
                                                        value,
                                                      ),
                                            activeColor: maroonColor,
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              if (conflictsAsync.maybeWhen(
                                                data: (conflicts) => conflicts
                                                    .hasConflictForSubject(
                                                      subject.id!,
                                                    ),
                                                orElse: () => false,
                                              ))
                                                const Tooltip(
                                                  message:
                                                      'Subject has a schedule conflict',
                                                  child: Padding(
                                                    padding: EdgeInsets.only(
                                                      right: 8,
                                                    ),
                                                    child: Icon(
                                                      Icons.warning_rounded,
                                                      color: Colors.orange,
                                                      size: 20,
                                                    ),
                                                  ),
                                                ),
                                              Text(
                                                subject.code,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(subject.name)),
                                        DataCell(
                                          Text(
                                            subject.units.toString(),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            subject.program.name.toUpperCase(),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${subject.yearLevel ?? "-"} / ${subject.term ?? "-"}',
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            subject.types
                                                .map(
                                                  (t) => t.name.toUpperCase(),
                                                )
                                                .join(' / '),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            subject.studentsCount.toString(),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              if (!_isShowingArchived) ...[
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.open_in_new,
                                                    color: maroonColor,
                                                  ),
                                                  onPressed: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          SubjectDetailsScreen(
                                                            subject: subject,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: maroonColor,
                                                  ),
                                                  onPressed: () =>
                                                      _showEditSubjectModal(
                                                        subject,
                                                      ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.archive_outlined,
                                                    color: maroonColor,
                                                  ),
                                                  tooltip: 'Archive Subject',
                                                  onPressed: () =>
                                                      _archiveSubject(
                                                        subject,
                                                      ),
                                                ),
                                              ] else ...[
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    onTap: () =>
                                                        _restoreSubject(
                                                          subject,
                                                        ),
                                                    child: Tooltip(
                                                      message:
                                                          kRestoreSubjectLabel,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: maroonColor
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Icon(
                                                          Icons.restore_rounded,
                                                          color: maroonColor,
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 8,
                                                ),
                                                Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    onTap: () =>
                                                        _permanentDeleteSubject(
                                                          subject,
                                                        ),
                                                    child: Tooltip(
                                                      message:
                                                          kDeletePermanentlyLabel,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.red
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
                                                          color: Colors.red,
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
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
                      },
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
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: maroonColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              cursorColor: isDark ? Colors.white : Colors.black87,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                hintText: 'Search code or title...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
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
    );
  }

  Widget _buildMobileSubjectList(List<Subject> subjects, bool isDark) {
    return ListView.builder(
      itemCount: subjects.length,
      padding: const EdgeInsets.only(bottom: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final subject = subjects[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubjectDetailsScreen(subject: subject),
              ),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.code,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: maroonColor,
                              ),
                            ),
                            Text(
                              subject.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (!_isShowingArchived) ...[
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: maroonColor,
                                size: 20,
                              ),
                              onPressed: () => _showEditSubjectModal(subject),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.archive_outlined,
                                color: maroonColor,
                                size: 20,
                              ),
                              onPressed: () => _archiveSubject(subject),
                            ),
                          ] else ...[
                            IconButton(
                              icon: Icon(
                                Icons.restore_rounded,
                                color: maroonColor,
                                size: 20,
                              ),
                              tooltip: kRestoreSubjectLabel,
                              onPressed: () => _restoreSubject(subject),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.red,
                                size: 20,
                              ),
                              tooltip: kDeletePermanentlyLabel,
                              onPressed: () => _permanentDeleteSubject(subject),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip(
                        Icons.numbers_rounded,
                        '${subject.units} Units',
                        Colors.blue,
                      ),
                      _buildInfoChip(
                        Icons.school_outlined,
                        subject.program.name.toUpperCase(),
                        Colors.purple,
                      ),
                      _buildInfoChip(
                        Icons.calendar_today_outlined,
                        'Year ${subject.yearLevel ?? "-"}',
                        Colors.orange,
                      ),
                      _buildInfoChip(
                        Icons.groups_outlined,
                        '${subject.studentsCount} Students',
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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

  Widget _buildYearFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYearLevel,
          hint: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: maroonColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ResponsiveHelper.isMobile(context) ? 'Year' : kYearLevelLabel,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'All',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            ...List.generate(
              4,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(
                  'Year ${i + 1}',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedYearLevel = v),
        ),
      ),
    );
  }

  Widget _buildProgramFilter(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Program?>(
          value: _selectedProgram,
          hint: Row(
            children: [
              Icon(Icons.school_outlined, color: maroonColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ResponsiveHelper.isMobile(context) ? 'Prog' : 'Program',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'All',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            ...const [Program.it, Program.emc].map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(
                  p.name.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedProgram = v),
        ),
      ),
    );
  }

  Color? _resolveRowColor(
    Set<WidgetState> states,
    int index,
    bool isDark,
  ) {
    if (states.contains(WidgetState.hovered)) {
      return maroonColor.withValues(alpha: 0.05);
    }
    if (!index.isEven) {
      return null;
    }
    return isDark
        ? Colors.white.withValues(alpha: 0.02)
        : Colors.grey.withValues(alpha: 0.02);
  }
}

class _AddSubjectModal extends ConsumerStatefulWidget {
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _AddSubjectModal({required this.maroonColor, required this.onSuccess});

  @override
  ConsumerState<_AddSubjectModal> createState() => _AddSubjectModalState();
}

class _AddSubjectModalState extends ConsumerState<_AddSubjectModal> {
  void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;
    String cleanMessage = message.replaceAll('Exception: ', '').trim();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              'Action Failed',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(cleanMessage, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _unitsController = TextEditingController(text: '3');
  final _studentsCountController = TextEditingController(text: '40');

  int? _yearLevel;
  int? _term;
  final List<SubjectType> _selectedTypes = [];
  Program _program = Program.it;
  List<Faculty> _facultyList = [];
  final Set<String> _existingSubjectCodes = {};
  int? _selectedFacultyId;
  bool _isLoading = false;
  String? _facultyLoadError;

  @override
  void initState() {
    super.initState();
    _loadFaculty();
    _loadExistingSubjectCodes();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _unitsController.dispose();
    _studentsCountController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculty() async {
    try {
      final list = await client.admin.getAllFaculty(isActive: true);
      if (!mounted) return;
      setState(() {
        _facultyList = _dedupeFacultyById(list);
        _facultyLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _facultyLoadError = 'Failed to load faculty list: $e';
      });
    }
  }

  Future<void> _loadExistingSubjectCodes() async {
    try {
      final results = await Future.wait([
        client.admin.getAllSubjects(isActive: true),
        client.admin.getAllSubjects(isActive: false),
      ]);
      if (!mounted) return;
      setState(() {
        _existingSubjectCodes
          ..clear()
          ..addAll(
            results.expand(
              (subjects) => subjects.map(
                (subject) => _normalizeSubjectCodeValue(subject.code),
              ),
            ),
          );
      });
    } catch (_) {
      // Backend validation still prevents duplicate saves if this preload fails.
    }
  }

  String? _validateSubjectCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    if (_existingSubjectCodes.contains(_normalizeSubjectCodeValue(value))) {
      return 'Subject code already exists';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) => _buildAddSubjectDialog(context);

  Widget _buildAddSubjectDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF333333);
    final textMuted = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    final isMobile = ResponsiveHelper.isMobile(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? double.infinity : 650,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.9 : 800,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.maroonColor.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.maroonColor, const Color(0xFF8e005b)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 420;
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Icon(
                          Icons.library_add_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kAddNewSubjectLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Enter subject details below',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: isCompact ? 11 : 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 20 : 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Subject Information',
                        Icons.info_outline,
                        textPrimary,
                      ),
                      const SizedBox(height: 16),
                      isMobile
                          ? Column(
                              children: [
                                _buildTextField(
                                  kSubjectCodeLabel,
                                  _codeController,
                                  isDark,
                                  hint: kSubjectCodeHint,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  'Units',
                                  _unitsController,
                                  isDark,
                                  isNumber: true,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    kSubjectCodeLabel,
                                    _codeController,
                                    isDark,
                                    hint: kSubjectCodeHint,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    'Units',
                                    _unitsController,
                                    isDark,
                                    isNumber: true,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Subject Title',
                        _nameController,
                        isDark,
                        hint: 'e.g., Introduction to Computing',
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'Classification',
                        Icons.category_outlined,
                        textPrimary,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<Program>(
                        initialValue: _program,
                        isExpanded: true,
                        decoration: _inputDecoration('Program', isDark),
                        dropdownColor: cardBg,
                        items: const [Program.it, Program.emc]
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  _programLabel(p),
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _program = v!;
                          if (_selectedFacultyId != null) {
                            final match = _facultyList.where(
                              (f) =>
                                  f.id == _selectedFacultyId &&
                                  (f.program == null || f.program == _program),
                            );
                            if (match.isEmpty) _selectedFacultyId = null;
                          }
                        }),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        initialValue: _selectedFacultyId,
                        decoration: _inputDecoration(
                          'Assigned Faculty',
                          isDark,
                        ),
                        dropdownColor: cardBg,
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Unassigned',
                              style: GoogleFonts.poppins(color: textPrimary),
                            ),
                          ),
                          ..._facultyList
                              .where(
                                (f) =>
                                    f.program == null ||
                                    f.program == _program ||
                                    (_program == Program.it &&
                                        f.program == Program.emc),
                              )
                              .map(
                                (f) => DropdownMenuItem<int?>(
                                  value: f.id,
                                  child: Text(
                                    f.name,
                                    style: GoogleFonts.poppins(
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                        onChanged: _facultyLoadError == null
                            ? (v) => setState(() => _selectedFacultyId = v)
                            : null,
                      ),
                      if (_facultyLoadError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _facultyLoadError!,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  kSubjectTypesLabel,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: SubjectType.values.map((type) {
                                    final isSelected = _selectedTypes.contains(
                                      type,
                                    );
                                    return FilterChip(
                                      label: Text(type.name.toUpperCase()),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedTypes.add(type);
                                          } else {
                                            _selectedTypes.remove(type);
                                          }
                                          if (!selected &&
                                              type == SubjectType.blended) {
                                            _selectedTypes.remove(
                                              SubjectType.lecture,
                                            );
                                            _selectedTypes.remove(
                                              SubjectType.laboratory,
                                            );
                                            return;
                                          }
                                          if (selected &&
                                              (type == SubjectType.lecture ||
                                                  type ==
                                                      SubjectType.laboratory) &&
                                              _selectedTypes.contains(
                                                SubjectType.blended,
                                              )) {
                                            _selectedTypes.remove(
                                              SubjectType.blended,
                                            );
                                            return;
                                          }
                                          if (_selectedTypes.contains(
                                            SubjectType.blended,
                                          )) {
                                            if (!_selectedTypes.contains(
                                              SubjectType.lecture,
                                            )) {
                                              _selectedTypes.add(
                                                SubjectType.lecture,
                                              );
                                            }
                                            if (!_selectedTypes.contains(
                                              SubjectType.laboratory,
                                            )) {
                                              _selectedTypes.add(
                                                SubjectType.laboratory,
                                              );
                                            }
                                          }
                                          final hasLecture = _selectedTypes
                                              .contains(SubjectType.lecture);
                                          final hasLab = _selectedTypes
                                              .contains(
                                                SubjectType.laboratory,
                                              );
                                          if (hasLecture && hasLab) {
                                            if (!_selectedTypes.contains(
                                              SubjectType.blended,
                                            )) {
                                              _selectedTypes.add(
                                                SubjectType.blended,
                                              );
                                            }
                                          } else {
                                            _selectedTypes.remove(
                                              SubjectType.blended,
                                            );
                                          }
                                        });
                                      },
                                      selectedColor: widget.maroonColor
                                          .withValues(alpha: 0.2),
                                      checkmarkColor: widget.maroonColor,
                                      labelStyle: GoogleFonts.poppins(
                                        color: isSelected
                                            ? widget.maroonColor
                                            : textPrimary,
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  kStudentCountLabel,
                                  _studentsCountController,
                                  isDark,
                                  isNumber: true,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        kSubjectTypesLabel,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.grey[300]
                                              : Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        children: SubjectType.values.map((
                                          type,
                                        ) {
                                          final isSelected = _selectedTypes
                                              .contains(type);
                                          return FilterChip(
                                            label: Text(
                                              type.name.toUpperCase(),
                                            ),
                                            selected: isSelected,
                                            onSelected: (selected) {
                                              setState(() {
                                                if (selected) {
                                                  _selectedTypes.add(type);
                                                } else {
                                                  _selectedTypes.remove(type);
                                                }
                                                if (!selected &&
                                                    type ==
                                                        SubjectType.blended) {
                                                  _selectedTypes.remove(
                                                    SubjectType.lecture,
                                                  );
                                                  _selectedTypes.remove(
                                                    SubjectType.laboratory,
                                                  );
                                                  return;
                                                }
                                                if (selected &&
                                                    (type ==
                                                            SubjectType
                                                                .lecture ||
                                                        type ==
                                                            SubjectType
                                                                .laboratory) &&
                                                    _selectedTypes.contains(
                                                      SubjectType.blended,
                                                    )) {
                                                  _selectedTypes.remove(
                                                    SubjectType.blended,
                                                  );
                                                  return;
                                                }
                                                if (_selectedTypes.contains(
                                                  SubjectType.blended,
                                                )) {
                                                  if (!_selectedTypes.contains(
                                                    SubjectType.lecture,
                                                  )) {
                                                    _selectedTypes.add(
                                                      SubjectType.lecture,
                                                    );
                                                  }
                                                  if (!_selectedTypes.contains(
                                                    SubjectType.laboratory,
                                                  )) {
                                                    _selectedTypes.add(
                                                      SubjectType.laboratory,
                                                    );
                                                  }
                                                }
                                                final hasLecture =
                                                    _selectedTypes.contains(
                                                      SubjectType.lecture,
                                                    );
                                                final hasLab = _selectedTypes
                                                    .contains(
                                                      SubjectType.laboratory,
                                                    );
                                                if (hasLecture && hasLab) {
                                                  if (!_selectedTypes.contains(
                                                    SubjectType.blended,
                                                  )) {
                                                    _selectedTypes.add(
                                                      SubjectType.blended,
                                                    );
                                                  }
                                                } else {
                                                  _selectedTypes.remove(
                                                    SubjectType.blended,
                                                  );
                                                }
                                              });
                                            },
                                            selectedColor: widget.maroonColor
                                                .withValues(alpha: 0.2),
                                            checkmarkColor: widget.maroonColor,
                                            labelStyle: GoogleFonts.poppins(
                                              color: isSelected
                                                  ? widget.maroonColor
                                                  : textPrimary,
                                              fontSize: 12,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    kStudentCountLabel,
                                    _studentsCountController,
                                    isDark,
                                    isNumber: true,
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'Schedule Placement',
                        Icons.calendar_month_outlined,
                        textPrimary,
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final yearLevels = ref
                              .watch(studentsProvider)
                              .maybeWhen(
                                data: (students) {
                                  final levels =
                                      students
                                          .map((s) => s.yearLevel)
                                          .whereType<int>()
                                          .toSet()
                                          .toList()
                                        ..sort();
                                  return levels.isEmpty
                                      ? <int>[1, 2, 3, 4]
                                      : levels;
                                },
                                orElse: () => <int>[1, 2, 3, 4],
                              );
                          final safeYearLevel = yearLevels.contains(_yearLevel)
                              ? _yearLevel
                              : yearLevels.first;
                          if (_yearLevel != safeYearLevel) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(() => _yearLevel = safeYearLevel);
                            });
                          }

                          return isMobile
                              ? Column(
                                  children: [
                                    DropdownButtonFormField<int>(
                                      initialValue: safeYearLevel,
                                      decoration: _inputDecoration(
                                        kYearLevelLabel,
                                        isDark,
                                      ),
                                      dropdownColor: cardBg,
                                      items: yearLevels
                                          .map(
                                            (level) => DropdownMenuItem(
                                              value: level,
                                              child: Text(
                                                'Year $level',
                                                style: GoogleFonts.poppins(
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _yearLevel = v!),
                                    ),
                                    const SizedBox(height: 16),
                                    DropdownButtonFormField<int>(
                                      initialValue: _term,
                                      decoration: _inputDecoration(
                                        'Semester',
                                        isDark,
                                      ),
                                      dropdownColor: cardBg,
                                      items: [1, 2]
                                          .map(
                                            (i) => DropdownMenuItem(
                                              value: i,
                                              child: Text(
                                                _semesterLabel(i),
                                                style: GoogleFonts.poppins(
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _term = v!),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        initialValue: safeYearLevel,
                                        decoration: _inputDecoration(
                                          kYearLevelLabel,
                                          isDark,
                                        ),
                                        dropdownColor: cardBg,
                                        items: yearLevels
                                            .map(
                                              (level) => DropdownMenuItem(
                                                value: level,
                                                child: Text(
                                                  'Year $level',
                                                  style: GoogleFonts.poppins(
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _yearLevel = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        initialValue: _term,
                                        decoration: _inputDecoration(
                                          'Semester',
                                          isDark,
                                        ),
                                        dropdownColor: cardBg,
                                        items: [1, 2]
                                            .map(
                                              (i) => DropdownMenuItem(
                                                value: i,
                                                child: Text(
                                                  _semesterLabel(i),
                                                  style: GoogleFonts.poppins(
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _term = v!),
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: isMobile
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 20),
                            label: Text(
                              _isLoading ? kSavingLabel : 'Create Subject',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.maroonColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(color: textMuted),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(color: textMuted),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            _isLoading ? kSavingLabel : 'Create Subject',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.maroonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: widget.maroonColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isDark, {
    bool isNumber = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: _inputDecoration(null, isDark, hint: hint),
          validator: label == kSubjectCodeLabel
              ? _validateSubjectCode
              : (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String? label, bool isDark, {String? hint}) {
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
      labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
      filled: true,
      fillColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.maroonColor, width: 2),
      ),
    );
  }

  Future<void> _submit() async => _submitAddSubject();

  Future<void> _submitAddSubject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypes.isEmpty) {
      _showErrorDialog(context, 'Select at least one subject type.');
      return;
    }
    final parsedUnits = int.tryParse(_unitsController.text.trim());
    if (parsedUnits == null || parsedUnits <= 0) {
      _showErrorDialog(context, 'Units must be a positive number.');
      return;
    }
    final parsedStudents = int.tryParse(_studentsCountController.text.trim());
    if (parsedStudents == null || parsedStudents < 0) {
      _showErrorDialog(context, 'Student count must be 0 or greater.');
      return;
    }
    if (_existingSubjectCodes.contains(
      _normalizeSubjectCodeValue(_codeController.text),
    )) {
      _showErrorDialog(context, 'Subject code already exists.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final subject = Subject(
        code: _codeController.text.trim(),
        name: _nameController.text,
        units: parsedUnits,
        studentsCount: parsedStudents,
        yearLevel: _yearLevel,
        term: _term,
        facultyId: _selectedFacultyId,
        types: _selectedTypes,
        program: _program,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await client.admin.createSubject(subject);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      widget.onSuccess();
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Subject created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _EditSubjectModal extends ConsumerStatefulWidget {
  final Subject subject;
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _EditSubjectModal({
    required this.subject,
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  ConsumerState<_EditSubjectModal> createState() => _EditSubjectModalState();
}

class _EditSubjectModalState extends ConsumerState<_EditSubjectModal> {
  void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;
    String cleanMessage = message.replaceAll('Exception: ', '').trim();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Text(
              'Action Failed',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(cleanMessage, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _unitsController;
  late TextEditingController _studentsCountController;

  late int _yearLevel;
  late int _term;
  late List<SubjectType> _selectedTypes;
  late Program _program;
  List<Faculty> _facultyList = [];
  final Set<String> _existingSubjectCodes = {};
  int? _selectedFacultyId;
  bool _isLoading = false;
  String? _facultyLoadError;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.subject.code);
    _nameController = TextEditingController(text: widget.subject.name);
    _unitsController = TextEditingController(
      text: widget.subject.units.toString(),
    );
    _studentsCountController = TextEditingController(
      text: widget.subject.studentsCount.toString(),
    );
    _yearLevel = widget.subject.yearLevel ?? 1;
    _term = widget.subject.term ?? 1;
    _selectedTypes = List.from(widget.subject.types);
    _program = widget.subject.program;
    _selectedFacultyId = widget.subject.facultyId;
    _loadFaculty();
    _loadExistingSubjectCodes();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _unitsController.dispose();
    _studentsCountController.dispose();
    super.dispose();
  }

  Future<void> _loadFaculty() async {
    try {
      final list = await client.admin.getAllFaculty(isActive: true);
      if (!mounted) return;
      setState(() {
        _facultyList = _dedupeFacultyById(list);
        final hasSelected =
            _selectedFacultyId != null &&
            _facultyList.any((f) => f.id == _selectedFacultyId);
        if (!hasSelected) _selectedFacultyId = null;
        _facultyLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _facultyLoadError = 'Failed to load faculty list: $e';
      });
    }
  }

  Future<void> _loadExistingSubjectCodes() async {
    try {
      final results = await Future.wait([
        client.admin.getAllSubjects(isActive: true),
        client.admin.getAllSubjects(isActive: false),
      ]);
      if (!mounted) return;
      setState(() {
        _existingSubjectCodes
          ..clear()
          ..addAll(
            results.expand(
              (subjects) => subjects
                  .where((subject) => subject.id != widget.subject.id)
                  .map((subject) => _normalizeSubjectCodeValue(subject.code)),
            ),
          );
      });
    } catch (_) {
      // Backend validation still prevents duplicate saves if this preload fails.
    }
  }

  String? _validateSubjectCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    if (_existingSubjectCodes.contains(_normalizeSubjectCodeValue(value))) {
      return 'Subject code already exists';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) => _buildEditSubjectDialog(context);

  Widget _buildEditSubjectDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF333333);
    final textMuted = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final isMobile = ResponsiveHelper.isMobile(context);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? double.infinity : 650,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.9 : 800,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.maroonColor.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [widget.maroonColor, const Color(0xFF8e005b)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: isMobile
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Subject',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Update subject details below',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Subject',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Update subject details below',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.black),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.05,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        'Subject Information',
                        Icons.info_outline,
                        textPrimary,
                      ),
                      const SizedBox(height: 16),
                      isMobile
                          ? Column(
                              children: [
                                _buildTextField(
                                  kSubjectCodeLabel,
                                  _codeController,
                                  isDark,
                                  hint: kSubjectCodeHint,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  'Units',
                                  _unitsController,
                                  isDark,
                                  isNumber: true,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    kSubjectCodeLabel,
                                    _codeController,
                                    isDark,
                                    hint: kSubjectCodeHint,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    'Units',
                                    _unitsController,
                                    isDark,
                                    isNumber: true,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Subject Title',
                        _nameController,
                        isDark,
                        hint: 'e.g., Introduction to Computing',
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'Classification',
                        Icons.category_outlined,
                        textPrimary,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<Program>(
                        initialValue: _program,
                        isExpanded: true,
                        decoration: _inputDecoration('Program', isDark),
                        dropdownColor: cardBg,
                        items: const [Program.it, Program.emc]
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  _programLabel(p),
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _program = v!;
                          if (_selectedFacultyId != null) {
                            final match = _facultyList.where(
                              (f) =>
                                  f.id == _selectedFacultyId &&
                                  (f.program == null || f.program == _program),
                            );
                            if (match.isEmpty) _selectedFacultyId = null;
                          }
                        }),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        initialValue: _selectedFacultyId,
                        decoration: _inputDecoration(
                          'Assigned Faculty',
                          isDark,
                        ),
                        dropdownColor: cardBg,
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(
                              'Unassigned',
                              style: GoogleFonts.poppins(color: textPrimary),
                            ),
                          ),
                          ..._facultyList
                              .where(
                                (f) =>
                                    f.program == null ||
                                    f.program == _program ||
                                    (_program == Program.it &&
                                        f.program == Program.emc),
                              )
                              .map(
                                (f) => DropdownMenuItem<int?>(
                                  value: f.id,
                                  child: Text(
                                    f.name,
                                    style: GoogleFonts.poppins(
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                        onChanged: _facultyLoadError == null
                            ? (v) => setState(() => _selectedFacultyId = v)
                            : null,
                      ),
                      if (_facultyLoadError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _facultyLoadError!,
                          style: GoogleFonts.poppins(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      Text(
                        kSubjectTypesLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: SubjectType.values.map((type) {
                          final isSelected = _selectedTypes.contains(type);
                          return FilterChip(
                            label: Text(type.name.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTypes.add(type);
                                } else {
                                  _selectedTypes.remove(type);
                                }
                                if (!selected && type == SubjectType.blended) {
                                  _selectedTypes.remove(SubjectType.lecture);
                                  _selectedTypes.remove(
                                    SubjectType.laboratory,
                                  );
                                  return;
                                }
                                if (selected &&
                                    (type == SubjectType.lecture ||
                                        type == SubjectType.laboratory) &&
                                    _selectedTypes.contains(
                                      SubjectType.blended,
                                    )) {
                                  _selectedTypes.remove(SubjectType.blended);
                                  return;
                                }
                                if (_selectedTypes.contains(
                                  SubjectType.blended,
                                )) {
                                  if (!_selectedTypes.contains(
                                    SubjectType.lecture,
                                  )) {
                                    _selectedTypes.add(SubjectType.lecture);
                                  }
                                  if (!_selectedTypes.contains(
                                    SubjectType.laboratory,
                                  )) {
                                    _selectedTypes.add(
                                      SubjectType.laboratory,
                                    );
                                  }
                                }
                                final hasLecture = _selectedTypes.contains(
                                  SubjectType.lecture,
                                );
                                final hasLab = _selectedTypes.contains(
                                  SubjectType.laboratory,
                                );
                                if (hasLecture && hasLab) {
                                  if (!_selectedTypes.contains(
                                    SubjectType.blended,
                                  )) {
                                    _selectedTypes.add(SubjectType.blended);
                                  }
                                } else {
                                  _selectedTypes.remove(SubjectType.blended);
                                }
                              });
                            },
                            selectedColor: widget.maroonColor.withValues(
                              alpha: 0.2,
                            ),
                            checkmarkColor: widget.maroonColor,
                            labelStyle: GoogleFonts.poppins(
                              color: isSelected
                                  ? widget.maroonColor
                                  : textPrimary,
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),
                      _buildTextField(
                        kStudentCountLabel,
                        _studentsCountController,
                        isDark,
                        isNumber: true,
                      ),

                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'Schedule Placement',
                        Icons.calendar_month_outlined,
                        textPrimary,
                      ),
                      const SizedBox(height: 16),
                      Builder(
                        builder: (context) {
                          final yearLevels = ref
                              .watch(studentsProvider)
                              .maybeWhen(
                                data: (students) {
                                  final levels =
                                      students
                                          .map((s) => s.yearLevel)
                                          .whereType<int>()
                                          .toSet()
                                          .toList()
                                        ..sort();
                                  return levels.isEmpty
                                      ? <int>[1, 2, 3, 4]
                                      : levels;
                                },
                                orElse: () => <int>[1, 2, 3, 4],
                              );
                          final safeYearLevel = yearLevels.contains(_yearLevel)
                              ? _yearLevel
                              : yearLevels.first;
                          if (_yearLevel != safeYearLevel) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              setState(() => _yearLevel = safeYearLevel);
                            });
                          }

                          return isMobile
                              ? Column(
                                  children: [
                                    DropdownButtonFormField<int>(
                                      initialValue: safeYearLevel,
                                      decoration: _inputDecoration(
                                        kYearLevelLabel,
                                        isDark,
                                      ),
                                      dropdownColor: cardBg,
                                      items: yearLevels
                                          .map(
                                            (level) => DropdownMenuItem(
                                              value: level,
                                              child: Text(
                                                'Year $level',
                                                style: GoogleFonts.poppins(
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _yearLevel = v!),
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<int>(
                                      initialValue: _term,
                                      decoration: _inputDecoration(
                                        'Semester',
                                        isDark,
                                      ),
                                      dropdownColor: cardBg,
                                      items: [1, 2]
                                          .map(
                                            (i) => DropdownMenuItem(
                                              value: i,
                                              child: Text(
                                                _semesterLabel(i),
                                                style: GoogleFonts.poppins(
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _term = v!),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        initialValue: safeYearLevel,
                                        decoration: _inputDecoration(
                                          kYearLevelLabel,
                                          isDark,
                                        ),
                                        dropdownColor: cardBg,
                                        items: yearLevels
                                            .map(
                                              (level) => DropdownMenuItem(
                                                value: level,
                                                child: Text(
                                                  'Year $level',
                                                  style: GoogleFonts.poppins(
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _yearLevel = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        initialValue: _term,
                                        decoration: _inputDecoration(
                                          'Semester',
                                          isDark,
                                        ),
                                        dropdownColor: cardBg,
                                        items: [1, 2]
                                            .map(
                                              (i) => DropdownMenuItem(
                                                value: i,
                                                child: Text(
                                                  _semesterLabel(i),
                                                  style: GoogleFonts.poppins(
                                                    color: textPrimary,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _term = v!),
                                      ),
                                    ),
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            side: BorderSide(color: borderColor),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(color: textMuted),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            _isLoading ? kSavingLabel : 'Save Changes',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.maroonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(color: textMuted),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _submit,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            _isLoading ? kSavingLabel : 'Save Changes',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.maroonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: widget.maroonColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isDark, {
    bool isNumber = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: _inputDecoration(null, isDark, hint: hint),
          validator: label == kSubjectCodeLabel
              ? _validateSubjectCode
              : (value) => value == null || value.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String? label, bool isDark, {String? hint}) {
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
      labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
      filled: true,
      fillColor: bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.maroonColor, width: 2),
      ),
    );
  }

  Future<void> _submit() async => _submitEditSubject();

  Future<void> _submitEditSubject() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTypes.isEmpty) {
      _showErrorDialog(context, 'Select at least one subject type.');
      return;
    }
    final parsedUnits = int.tryParse(_unitsController.text.trim());
    if (parsedUnits == null || parsedUnits <= 0) {
      _showErrorDialog(context, 'Units must be a positive number.');
      return;
    }
    final parsedStudents = int.tryParse(_studentsCountController.text.trim());
    if (parsedStudents == null || parsedStudents < 0) {
      _showErrorDialog(context, 'Student count must be 0 or greater.');
      return;
    }
    if (_existingSubjectCodes.contains(
      _normalizeSubjectCodeValue(_codeController.text),
    )) {
      _showErrorDialog(context, 'Subject code already exists.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final subject = widget.subject.copyWith(
        code: _codeController.text.trim(),
        name: _nameController.text,
        units: parsedUnits,
        studentsCount: parsedStudents,
        yearLevel: _yearLevel,
        term: _term,
        facultyId: _selectedFacultyId,
        types: _selectedTypes,
        program: _program,
        updatedAt: DateTime.now(),
      );
      await client.admin.updateSubject(subject);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      widget.onSuccess();
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Subject updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
