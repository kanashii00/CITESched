import 'package:citesched_client/citesched_client.dart';
import 'dart:async';

import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'faculty_details_screen.dart';
import 'package:citesched_flutter/core/providers/conflict_provider.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/core/providers/schedule_sync_provider.dart';

import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:citesched_flutter/core/utils/error_handler.dart';

const String kEndTimeAfterStartMessage = 'End time must be after start time.';
const String kDeletePermanentlyLabel = 'Delete Permanently';
const String kAddFacultyMemberLabel = 'Add Faculty Member';
const String kSelectStartTimeLabel = 'Select Start Time';
const String kSelectEndTimeLabel = 'Select End Time';
const String kFullTimeLabel = 'Full-Time';
const String kPartTimeLabel = 'Part-Time';

String _employmentStatusLabel(EmploymentStatus status) {
  if (status == EmploymentStatus.fullTime) {
    return kFullTimeLabel;
  }
  return kPartTimeLabel;
}

String _nameInitial(String name) {
  if (name.isEmpty) {
    return '?';
  }
  return name[0].toUpperCase();
}

String _dayLabelOrUnknown(int dayIndex, List<String> labels) {
  if (dayIndex < 0 || dayIndex >= labels.length) {
    return '?';
  }
  return labels[dayIndex];
}

String? _requiredValidator(String? value) {
  if (value?.isEmpty ?? true) {
    return 'Required';
  }
  return null;
}

String? _emailValidator(String? value) {
  if (value?.isEmpty ?? true) return 'Required';
  if (!value!.contains('@')) return 'Invalid email';
  return null;
}

String? _passwordValidator(String? value) {
  if (value?.isEmpty ?? true) return 'Required';
  if (value!.length < 8) return 'Min 8 chars';
  return null;
}

String _shiftPreferenceLabel(FacultyShiftPreference pref) {
  switch (pref) {
    case FacultyShiftPreference.any:
      return 'Any Time (Flexible)';
    case FacultyShiftPreference.morning:
      return 'Morning (7:00 AM to 12:00 PM)';
    case FacultyShiftPreference.afternoon:
      return 'Afternoon (1:00 PM to 6:00 PM)';
    case FacultyShiftPreference.evening:
      return 'Evening (6:00 PM to 9:00 PM)';
    case FacultyShiftPreference.custom:
      return 'Custom';
  }
}

// Helper extension for conflicts (already in core/providers/conflict_provider.dart)

class FacultyManagementScreen extends ConsumerStatefulWidget {
  final int? targetFacultyId;

  const FacultyManagementScreen({super.key, this.targetFacultyId});

  @override
  ConsumerState<FacultyManagementScreen> createState() =>
      _FacultyManagementScreenState();
}

class _FacultyManagementScreenState
    extends ConsumerState<FacultyManagementScreen> {
  String _searchQuery = '';
  Program? _selectedProgram;
  bool _isShowingArchived = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedFacultyIds = {};
  bool _hasAutoOpenedTargetFaculty = false;

  // Color scheme matching admin sidebar
  final Color maroonColor = const Color(0xFF720045);
  final Color innerMenuBg = const Color(0xFF7b004f);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  void _syncSelectedFaculty(List<Faculty> facultyList) {
    final visibleIds = facultyList
        .map((faculty) => faculty.id)
        .whereType<int>()
        .toSet();
    final intersection = _selectedFacultyIds.intersection(visibleIds);
    if (intersection.length != _selectedFacultyIds.length) {
      _selectedFacultyIds
        ..clear()
        ..addAll(intersection);
    }
  }

  void _toggleSelectAllFaculty(List<Faculty> facultyList, bool? isSelected) {
    final shouldSelect = isSelected ?? false;
    setState(() {
      _selectedFacultyIds.clear();
      if (shouldSelect) {
        _selectedFacultyIds.addAll(
          facultyList.map((faculty) => faculty.id).whereType<int>(),
        );
      }
    });
  }

  void _toggleFacultySelection(int facultyId, bool? isSelected) {
    setState(() {
      if (isSelected ?? false) {
        _selectedFacultyIds.add(facultyId);
      } else {
        _selectedFacultyIds.remove(facultyId);
      }
    });
  }

  Future<void> _archiveSelectedFaculty(List<Faculty> facultyList) async {
    final selected = facultyList
        .where((faculty) => _selectedFacultyIds.contains(faculty.id))
        .toList();
    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Selected Faculty',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Archive ${selected.length} selected faculty members?',
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
        for (final faculty in selected) {
          await client.admin.updateFaculty(
            faculty.copyWith(isActive: false),
          );
        }
        _selectedFacultyIds.clear();
        ref.invalidate(facultyListProvider);
        ref.invalidate(archivedFacultyListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected faculty archived successfully'),
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

  Future<void> _deleteSelectedFaculty(List<Faculty> facultyList) async {
    final selected = facultyList
        .where((faculty) => _selectedFacultyIds.contains(faculty.id))
        .toList();
    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Selected Faculty',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'PERMANENTLY delete ${selected.length} selected faculty members? This cannot be undone.',
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
        for (final faculty in selected) {
          await client.admin.deleteFaculty(faculty.id!);
        }
        _selectedFacultyIds.clear();
        ref.invalidate(facultyListProvider);
        ref.invalidate(archivedFacultyListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected faculty deleted permanently'),
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

  void _showAddFacultyModal() {
    debugPrint('Opening Add Faculty Modal...');
    showDialog(
      context: context,
      builder: (context) => _AddFacultyModal(
        maroonColor: maroonColor,
        onSuccess: () {
          debugPrint('Add Faculty Success!');
          notifyScheduleDataChanged(ref);
          ref.invalidate(facultyListProvider);
        },
      ),
    );
  }

  void _showEditFacultyModal(Faculty faculty) {
    debugPrint('Opening Edit Faculty Modal for: ${faculty.name}');
    showDialog(
      context: context,
      builder: (context) => _EditFacultyModal(
        faculty: faculty,
        maroonColor: maroonColor,
        onSuccess: () {
          debugPrint('Edit Faculty Success!');
          notifyScheduleDataChanged(ref);
          ref.invalidate(facultyListProvider);
        },
      ),
    );
  }

  void _maybeAutoOpenTargetFaculty(List<Faculty> facultyList) {
    final targetFacultyId = widget.targetFacultyId;
    if (_hasAutoOpenedTargetFaculty || targetFacultyId == null) return;

    Faculty? targetFaculty;
    try {
      targetFaculty = facultyList.firstWhere((f) => f.id == targetFacultyId);
    } catch (_) {
      targetFaculty = null;
    }
    if (targetFaculty == null) return;

    _hasAutoOpenedTargetFaculty = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showEditFacultyModal(targetFaculty!);
    });
  }

  void _archiveFaculty(Faculty faculty) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Faculty',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to archive ${faculty.name}? They will be hidden from active lists.',
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
        final archivedFaculty = faculty.copyWith(isActive: false);
        await client.admin.updateFaculty(archivedFaculty);
        ref.invalidate(facultyListProvider);
        ref.invalidate(archivedFacultyListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faculty archived successfully'),
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

  void _restoreFaculty(Faculty faculty) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restore Faculty',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to restore ${faculty.name}? They will reappear in active lists.',
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
        final restoredFaculty = faculty.copyWith(isActive: true);
        await client.admin.updateFaculty(restoredFaculty);
        ref.invalidate(facultyListProvider);
        ref.invalidate(archivedFacultyListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faculty restored successfully'),
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

  void _permanentDeleteFaculty(Faculty faculty) async {
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
          'Are you sure you want to PERMANENTLY delete ${faculty.name}? This action cannot be undone.',
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
        await client.admin.deleteFaculty(faculty.id!);
        ref.invalidate(facultyListProvider);
        ref.invalidate(archivedFacultyListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faculty permanently deleted'),
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
    final facultyAsync = _isShowingArchived
        ? ref.watch(archivedFacultyListProvider)
        : ref.watch(facultyListProvider);
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
                                    Icons.people_outline_rounded,
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
                                        'Faculty Management',
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
                                        'Manage instructors, workloads, and schedules',
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
                                onPressed: _showAddFacultyModal,
                                icon: const Icon(
                                  Icons.person_add_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  kAddFacultyMemberLabel,
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
                                    Icons.people_outline_rounded,
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
                                        'Faculty Management',
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
                                        'Manage instructors, workloads, and schedules',
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
                                onPressed: _showAddFacultyModal,
                                icon: const Icon(
                                  Icons.person_add_rounded,
                                  size: 24,
                                ),
                                label: Text(
                                  kAddFacultyMemberLabel,
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
                              _buildProgramFilter(facultyAsync, isDark),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(flex: 3, child: _buildSearchBar(isDark)),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: _buildProgramFilter(
                                  facultyAsync,
                                  isDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              _buildViewToggle(isDark),
                            ],
                          ),
                    const SizedBox(height: 32),
                    facultyAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
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
                              'Error loading faculty',
                              style: GoogleFonts.poppins(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: GoogleFonts.poppins(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.refresh(facultyListProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      data: (facultyList) {
                        _maybeAutoOpenTargetFaculty(facultyList);
                        final filteredFaculty = _filteredFaculty(facultyList);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _syncSelectedFaculty(filteredFaculty);
                        });

                        if (filteredFaculty.isEmpty) {
                          return _buildEmptyFacultyState();
                        }

                        if (useCompactList) {
                          return _buildMobileFacultyList(
                            filteredFaculty,
                            isDark,
                          );
                        }

                        return _buildDesktopFacultyTable(
                          context,
                          filteredFaculty,
                          conflictsAsync,
                          isDark,
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

  Color _getStatusColor(EmploymentStatus? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case EmploymentStatus.fullTime:
        return Colors.green;
      case EmploymentStatus.partTime:
        return Colors.orange;
    }
  }

  String _getStatusText(EmploymentStatus? status) {
    if (status == null) return '?';
    switch (status) {
      case EmploymentStatus.fullTime:
        return kFullTimeLabel;
      case EmploymentStatus.partTime:
        return kPartTimeLabel;
    }
  }

  IconData _getStatusIcon(EmploymentStatus? status) {
    if (status == null) return Icons.help_outline;
    switch (status) {
      case EmploymentStatus.fullTime:
        return Icons.verified;
      case EmploymentStatus.partTime:
        return Icons.schedule;
    }
  }

  Color _getShiftColor(FacultyShiftPreference? preference) {
    if (preference == null) return Colors.grey;
    switch (preference) {
      case FacultyShiftPreference.morning:
        return Colors.orange;
      case FacultyShiftPreference.afternoon:
        return Colors.blue;
      case FacultyShiftPreference.evening:
        return Colors.indigo;
      case FacultyShiftPreference.any:
        return Colors.teal;
      case FacultyShiftPreference.custom:
        return Colors.purple;
    }
  }

  String _getShiftText(FacultyShiftPreference? preference) {
    if (preference == null) return 'Any';
    switch (preference) {
      case FacultyShiftPreference.morning:
        return 'Morning';
      case FacultyShiftPreference.afternoon:
        return 'Afternoon';
      case FacultyShiftPreference.evening:
        return 'Evening';
      case FacultyShiftPreference.any:
        return 'Any';
      case FacultyShiftPreference.custom:
        return 'Custom';
    }
  }

  IconData _getShiftIcon(FacultyShiftPreference? preference) {
    if (preference == null) return Icons.access_time;
    switch (preference) {
      case FacultyShiftPreference.morning:
        return Icons.wb_sunny;
      case FacultyShiftPreference.afternoon:
        return Icons.wb_cloudy;
      case FacultyShiftPreference.evening:
        return Icons.nightlight_round;
      case FacultyShiftPreference.any:
        return Icons.all_inclusive;
      case FacultyShiftPreference.custom:
        return Icons.tune;
    }
  }

  String _getShiftLabel(FacultyShiftPreference? preference) =>
      _getShiftText(preference);

  List<Faculty> _filteredFaculty(List<Faculty> facultyList) {
    return facultyList.where((faculty) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          faculty.name.toLowerCase().contains(_searchQuery) ||
          faculty.email.toLowerCase().contains(_searchQuery) ||
          faculty.facultyId.toLowerCase().contains(_searchQuery);
      final matchesProgram =
          _selectedProgram == null || faculty.program == _selectedProgram;
      return matchesSearch && matchesProgram;
    }).toList();
  }

  Widget _buildEmptyFacultyState() {
    final hasQuery = _searchQuery.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? const Color(0xFF94A3B8) : Colors.grey[600]!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: isDark ? Colors.white24 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasQuery ? 'No faculty found' : 'No faculty members yet',
            style: GoogleFonts.poppins(fontSize: 18, color: textMuted),
          ),
          if (!hasQuery) ...[
            const SizedBox(height: 8),
            Text(
              'Click "Add Faculty" to get started',
              style: GoogleFonts.poppins(
                color: textMuted.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
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
    if (!index.isEven) return null;
    return isDark
        ? Colors.white.withValues(alpha: 0.02)
        : Colors.grey.withValues(alpha: 0.02);
  }

  Widget _buildDesktopFacultyTable(
    BuildContext context,
    List<Faculty> filteredFaculty,
    AsyncValue<List<ScheduleConflict>> conflictsAsync,
    bool isDark,
  ) {
    final allSelected =
        filteredFaculty.isNotEmpty &&
        _selectedFacultyIds.length == filteredFaculty.length;
    final anySelected = _selectedFacultyIds.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: maroonColor, width: 4)),
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
          _buildTableHeader(
            filteredFaculty.length,
            selectedCount: _selectedFacultyIds.length,
            onArchiveSelected: anySelected && !_isShowingArchived
                ? () => _archiveSelectedFaculty(filteredFaculty)
                : null,
            onDeleteSelected: anySelected && _isShowingArchived
                ? () => _deleteSelectedFaculty(filteredFaculty)
                : null,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowColor: WidgetStateProperty.all(maroonColor),
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
                    decoration: const BoxDecoration(color: Colors.transparent),
                    columns: [
                      DataColumn(
                        label: Checkbox(
                          value: allSelected,
                          onChanged: (value) => _toggleSelectAllFaculty(
                            filteredFaculty,
                            value,
                          ),
                          activeColor: Colors.white,
                          checkColor: maroonColor,
                        ),
                      ),
                      const DataColumn(label: Text('FACULTY ID')),
                      const DataColumn(label: Text('NAME')),
                      const DataColumn(label: Text('EMAIL')),
                      const DataColumn(label: Text('PROGRAM')),
                      const DataColumn(label: Text('STATUS')),
                      const DataColumn(label: Text('CONFLICTS')),
                      const DataColumn(label: Text('SHIFT')),
                      const DataColumn(label: Text('MAX LOAD')),
                      const DataColumn(label: Text('ACTIONS')),
                    ],
                    rows: filteredFaculty
                        .asMap()
                        .entries
                        .map(
                          (entry) => _facultyDataRow(
                            context,
                            entry.value,
                            entry.key,
                            conflictsAsync,
                            isDark,
                          ),
                        )
                        .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(
    int count, {
    required int selectedCount,
    VoidCallback? onArchiveSelected,
    VoidCallback? onDeleteSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: maroonColor.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.people_rounded, color: maroonColor, size: 20),
          const SizedBox(width: 8),
          Text(
            'Faculty Members',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: maroonColor,
            ),
          ),
          if (selectedCount > 0) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: maroonColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$selectedCount selected',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: maroonColor,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (onArchiveSelected != null) ...[
            TextButton.icon(
              onPressed: onArchiveSelected,
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: Text(
                'Archive Selected',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(foregroundColor: maroonColor),
            ),
            const SizedBox(width: 12),
          ],
          if (onDeleteSelected != null) ...[
            TextButton.icon(
              onPressed: onDeleteSelected,
              icon: const Icon(Icons.delete_forever_outlined, size: 18),
              label: Text(
                'Delete Selected',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: maroonColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count Total',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _facultyDataRow(
    BuildContext context,
    Faculty faculty,
    int index,
    AsyncValue<List<ScheduleConflict>> conflictsAsync,
    bool isDark,
  ) {
    return DataRow(
      color: WidgetStateProperty.resolveWith(
        (states) => _resolveRowColor(states, index, isDark),
      ),
      cells: [
        DataCell(
          Checkbox(
            value:
                faculty.id != null && _selectedFacultyIds.contains(faculty.id),
            onChanged: faculty.id == null
                ? null
                : (value) => _toggleFacultySelection(faculty.id!, value),
            activeColor: maroonColor,
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: maroonColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              faculty.facultyId,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: maroonColor,
              ),
            ),
          ),
        ),
        DataCell(
          conflictsAsync.when(
            loading: () => _facultyNameCell(faculty),
            error: (error, _) => _facultyNameCell(faculty),
            data: (conflicts) {
              final hasNameConflict = conflicts.hasConflictForFaculty(
                faculty.id!,
              );
              return _facultyNameCell(faculty, hasConflict: hasNameConflict);
            },
          ),
        ),
        DataCell(
          Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                faculty.email,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            (faculty.program?.name ?? 'N/A').toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(faculty.employmentStatus),
                  _getStatusColor(
                    faculty.employmentStatus,
                  ).withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(
                    faculty.employmentStatus,
                  ).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(faculty.employmentStatus),
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  faculty.employmentStatus != null
                      ? faculty.employmentStatus!.name.toUpperCase()
                      : 'UNKNOWN',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          conflictsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (error, _) => const SizedBox.shrink(),
            data: (conflicts) {
              final hasConflict = conflicts.hasConflictForFaculty(faculty.id!);
              return _conflictBadge(hasConflict);
            },
          ),
        ),
        DataCell(
          Row(
            children: [
              Icon(
                _getShiftIcon(faculty.shiftPreference),
                size: 15,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 6),
              Text(
                _getShiftLabel(faculty.shiftPreference),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            '${faculty.maxLoad?.toStringAsFixed(1) ?? 'N/A'} hrs',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              if (!_isShowingArchived) ...[
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FacultyDetailsScreen(faculty: faculty),
                    ),
                  ),
                  icon: Icon(
                    Icons.open_in_new,
                    color: maroonColor,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () => _showEditFacultyModal(faculty),
                  icon: Icon(
                    Icons.edit_rounded,
                    color: maroonColor,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () => _archiveFaculty(faculty),
                  icon: Icon(
                    Icons.archive_outlined,
                    color: maroonColor,
                    size: 20,
                  ),
                ),
              ] else ...[
                IconButton(
                  onPressed: () => _restoreFaculty(faculty),
                  icon: Icon(
                    Icons.restore_rounded,
                    color: maroonColor,
                    size: 20,
                  ),
                ),
                IconButton(
                  onPressed: () => _permanentDeleteFaculty(faculty),
                  icon: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _facultyNameCell(Faculty faculty, {bool hasConflict = false}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: maroonColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              _nameInitial(faculty.name),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          faculty.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        if (hasConflict) ...[
          const SizedBox(width: 6),
          const Icon(Icons.warning_rounded, color: Colors.red, size: 16),
        ],
      ],
    );
  }

  Widget _conflictBadge(bool hasConflict) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasConflict
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.green.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasConflict ? Icons.warning_rounded : Icons.check_circle_rounded,
            size: 14,
            color: hasConflict ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            hasConflict ? 'Has Conflicts' : 'Clear',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasConflict ? Colors.red : Colors.green,
            ),
          ),
        ],
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
          color: isDark
              ? Colors.grey[800]!
              : const Color.fromARGB(255, 0, 0, 0),
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
              cursorColor: isDark ? Colors.white : Colors.black87,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isDark
                    ? const Color.fromARGB(255, 0, 0, 0)
                    : Colors.black87,
              ),
              decoration: InputDecoration(
                filled: false,
                fillColor: Colors.transparent,
                hintText: 'Search faculty...',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                border: InputBorder.none,
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
    );
  }

  Widget _buildProgramFilter(
    AsyncValue<List<Faculty>> facultyAsync,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown<Program?>(
          value: _selectedProgram,
          items: [
            null,
            ...const [Program.it, Program.emc],
          ],
          onChanged: (value) {
            setState(() {
              _selectedProgram = value;
            });
          },
          itemLabel: (program) =>
              program == null ? 'ALL' : program.name.toUpperCase(),
          bgBody: isDark ? const Color(0xFF1E293B) : Colors.white,
          textPrimary: isDark ? Colors.white : Colors.black87,
          textMuted: Colors.grey,
          primaryPurple: maroonColor,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
    required Color bgBody,
    required Color textPrimary,
    required Color textMuted,
    required Color primaryPurple,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: bgBody,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textMuted),
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textPrimary,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildMobileFacultyList(List<Faculty> facultyList, bool isDark) {
    return ListView.builder(
      itemCount: facultyList.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final faculty = facultyList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: maroonColor.withValues(alpha: 0.1),
              child: Text(
                faculty.name[0],
                style: GoogleFonts.poppins(
                  color: maroonColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              faculty.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              (faculty.program?.name ?? '�').toUpperCase(),
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(Icons.email, 'Email', faculty.email),
                    _buildDetailRow(
                      Icons.badge,
                      'ID',
                      faculty.facultyId,
                    ),
                    _buildDetailRow(
                      Icons.verified,
                      'Status',
                      _getStatusText(faculty.employmentStatus),
                      color: _getStatusColor(faculty.employmentStatus),
                    ),
                    _buildDetailRow(
                      Icons.schedule,
                      'Shift',
                      _getShiftText(faculty.shiftPreference),
                      color: _getShiftColor(faculty.shiftPreference),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!_isShowingArchived) ...[
                          TextButton.icon(
                            onPressed: () => _showEditFacultyModal(faculty),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: maroonColor,
                            ),
                            label: Text(
                              'Edit',
                              style: TextStyle(color: maroonColor),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _archiveFaculty(faculty),
                            icon: Icon(
                              Icons.archive_outlined,
                              color: maroonColor,
                            ),
                            label: Text(
                              'Archive',
                              style: TextStyle(color: maroonColor),
                            ),
                          ),
                        ] else ...[
                          TextButton.icon(
                            onPressed: () => _restoreFaculty(faculty),
                            icon: Icon(
                              Icons.restore_rounded,
                              color: maroonColor,
                            ),
                            label: Text(
                              'Restore',
                              style: TextStyle(color: maroonColor),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _permanentDeleteFaculty(faculty),
                            icon: const Icon(
                              Icons.delete_forever_rounded,
                              color: Colors.red,
                            ),
                            label: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Add Faculty Modal
class _AddFacultyModal extends StatefulWidget {
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _AddFacultyModal({
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  State<_AddFacultyModal> createState() => _AddFacultyModalState();
}

class _AddFacultyModalState extends State<_AddFacultyModal> {
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
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _facultyIdController = TextEditingController();
  final _maxLoadController = TextEditingController();
  final _preferredHoursController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  EmploymentStatus? _employmentStatus;
  FacultyShiftPreference? _shiftPreference;
  Program? _program;
  bool _isActive = true;
  bool _isLoading = false;
  String? _customPreferredHours;

  // ─── Faculty Availability (Day Picker) ───────────────────────────────
  final List<_AvailabilityEntry> _availabilities = [];
  DayOfWeek _selectedDay = DayOfWeek.mon;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _facultyIdController.dispose();
    _maxLoadController.dispose();
    _preferredHoursController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async => _submitAddFaculty();

  Future<void> _submitAddFaculty() async {
    debugPrint('Submitting Add Faculty form...');
    if (!_formKey.currentState!.validate()) {
      debugPrint('Add Faculty validation failed');
      return;
    }
    // Validate nullable dropdowns
    if (_employmentStatus == null || _program == null) {
      _showErrorDialog(context, 'Employment status and program are required.');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorDialog(context, 'Passwords do not match.');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final facultyId = _facultyIdController.text.trim();

      final createdAccount = await client.setup.createAccount(
        userName: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
        role: 'faculty',
        facultyId: facultyId,
        maxLoad: int.tryParse(_maxLoadController.text) ?? 18,
        employmentStatus: _employmentStatus?.name,
        shiftPreference: _shiftPreference?.name,
        program: _program?.name,
      );

      if (!createdAccount) {
        throw Exception('Failed to create faculty account.');
      }

      final facultyList = await client.admin.getAllFaculty(isActive: true);
      final inactiveFacultyList = await client.admin.getAllFaculty(
        isActive: false,
      );
      Faculty? existing;
      for (final f in facultyList) {
        if (f.email.toLowerCase() == email.toLowerCase() ||
            f.facultyId.toLowerCase() == facultyId.toLowerCase()) {
          existing = f;
          break;
        }
      }
      if (existing == null) {
        for (final f in inactiveFacultyList) {
          if (f.email.toLowerCase() == email.toLowerCase() ||
              f.facultyId.toLowerCase() == facultyId.toLowerCase()) {
            existing = f;
            break;
          }
        }
      }

      if (existing == null) {
        final now = DateTime.now();
        existing = await client.admin.createFaculty(
          Faculty(
            name: _nameController.text.trim(),
            email: email,
            maxLoad: int.tryParse(_maxLoadController.text) ?? 0,
            employmentStatus: _employmentStatus!,
            shiftPreference: _shiftPreference,
            preferredHours: _customPreferredHours,
            facultyId: facultyId,
            userInfoId: 0,
            program: _program,
            isActive: _isActive,
            currentLoad: 0,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final updated = existing.copyWith(
        name: _nameController.text.trim(),
        email: email,
        facultyId: facultyId,
        maxLoad: int.tryParse(_maxLoadController.text) ?? 0,
        employmentStatus: _employmentStatus!,
        shiftPreference: _shiftPreference,
        preferredHours: _customPreferredHours,
        program: _program!,
        isActive: _isActive,
        updatedAt: DateTime.now(),
      );

      final created = await client.admin.updateFaculty(updated);

      // Save faculty availability if any were added
      if (_availabilities.isNotEmpty && created.id != null) {
        final avails = _availabilities
            .map(
              (e) => FacultyAvailability(
                facultyId: created.id!,
                dayOfWeek: e.day,
                startTime:
                    '${e.start.hour.toString().padLeft(2, '0')}:${e.start.minute.toString().padLeft(2, '0')}',
                endTime:
                    '${e.end.hour.toString().padLeft(2, '0')}:${e.end.minute.toString().padLeft(2, '0')}',
                isPreferred: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .toList();
        await client.admin.setFacultyAvailability(created.id!, avails);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faculty added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppErrorDialog.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => _buildAddFacultyDialog(context);

  Widget _buildAddFacultyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryPurple = widget.maroonColor; // Use maroon as primaryPurple
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bgBody = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F6);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF333333);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? double.infinity : 650,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.9 : 750,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with Gradient
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 28,
                vertical: isMobile ? 20 : 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryPurple,
                    const Color(0xFFb5179e),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add New Faculty',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a new faculty profile in the system',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),

            // Main Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 20 : 28),
                child: _buildForm(
                  context,
                  bgBody,
                  primaryPurple,
                  textPrimary,
                  textMuted,
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(19),
                  bottomRight: Radius.circular(19),
                ),
              ),
              child: isMobile
                  ? Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: primaryPurple.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          kAddFacultyMemberLabel,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: textMuted,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: textMuted,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Colors.black.withValues(alpha: 0.1),
                                ),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: primaryPurple.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        kAddFacultyMemberLabel,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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

  Widget _buildForm(
    BuildContext context,
    Color bgBody,
    Color primaryPurple,
    Color textPrimary,
    Color textMuted,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Full Name', Icons.person_outline_rounded, textPrimary),
          TextFormField(
            controller: _nameController,
            decoration: _buildInputDecoration(
              'Jerwin A. Carreon',
              bgBody,
              primaryPurple,
              textMuted,
            ),
            style: GoogleFonts.poppins(fontSize: 15, color: textPrimary),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 20),
          _buildLabel('Email Address', Icons.email_outlined, textPrimary),
          TextFormField(
            controller: _emailController,
            decoration: _buildInputDecoration(
              'jerwin.carreon@jmc.edu.ph',
              bgBody,
              primaryPurple,
              textMuted,
            ),
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(fontSize: 15, color: textPrimary),
            validator: _emailValidator,
          ),
          const SizedBox(height: 20),
          _buildLabel('Faculty ID', Icons.badge_rounded, textPrimary),
          TextFormField(
            controller: _facultyIdController,
            decoration: _buildInputDecoration(
              'FAC-001',
              bgBody,
              primaryPurple,
              textMuted,
            ),
            style: GoogleFonts.poppins(fontSize: 15, color: textPrimary),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 20),
          _buildLabel('Password', Icons.lock_outline_rounded, textPrimary),
          TextFormField(
            controller: _passwordController,
            decoration: _buildInputDecoration(
              'Min 8 characters',
              bgBody,
              primaryPurple,
              textMuted,
            ),
            obscureText: true,
            style: GoogleFonts.poppins(fontSize: 15, color: textPrimary),
            validator: _passwordValidator,
          ),
          const SizedBox(height: 16),
          _buildLabel(
            'Retype Password',
            Icons.lock_outline_rounded,
            textPrimary,
          ),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: _buildInputDecoration(
              'Retype password',
              bgBody,
              primaryPurple,
              textMuted,
            ),
            obscureText: true,
            style: GoogleFonts.poppins(fontSize: 15, color: textPrimary),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(
            height: 20,
          ),
          // Password fields removed for Edit Faculty modal.
          _buildLabel(
            'Max Loads (hours)',
            Icons.access_time_rounded,
            textPrimary,
          ),
          TextFormField(
            controller: _maxLoadController,
            decoration: _buildInputDecoration(
              '21',
              bgBody,
              primaryPurple,
              textMuted,
            ),
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(fontSize: 15, color: textPrimary),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (int.tryParse(value!) == null) return 'Invalid number';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildLabel(
            'Employment Status',
            Icons.work_outline_rounded,
            textPrimary,
          ),
          _buildNullableDropdown<EmploymentStatus>(
            value: _employmentStatus,
            bgBody: bgBody,
            textPrimary: textPrimary,
            textMuted: textMuted,
            primaryPurple: primaryPurple,
            items: EmploymentStatus.values,
            onChanged: (value) => setState(() => _employmentStatus = value),
            itemLabel: _employmentStatusLabel,
            hint: 'Select Status',
          ),
          const SizedBox(height: 20),
          _buildLabel('Shift Preference', Icons.schedule_rounded, textPrimary),
          _buildNullableDropdown<FacultyShiftPreference>(
            value: _shiftPreference,
            bgBody: bgBody,
            textPrimary: textPrimary,
            textMuted: textMuted,
            primaryPurple: primaryPurple,
            items: FacultyShiftPreference.values,
            onChanged: (value) => setState(() => _shiftPreference = value),
            itemLabel: _shiftPreferenceLabel,
            hint: 'Select Shift',
          ),

          const SizedBox(height: 24),
          _buildDayPickerSection(primaryPurple, textPrimary, textMuted, bgBody),
          const SizedBox(height: 24),
          _buildLabel('Program Assignment', Icons.school_outlined, textPrimary),
          _buildNullableDropdown<Program>(
            value: _program,
            bgBody: bgBody,
            textPrimary: textPrimary,
            textMuted: textMuted,
            primaryPurple: primaryPurple,
            items: const [Program.it, Program.emc],
            onChanged: (value) => setState(() => _program = value),
            itemLabel: (prog) => prog.name.toUpperCase(),
            hint: 'Select Program',
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => setState(() => _isActive = !_isActive),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgBody,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: textMuted,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Is Active',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeThumbColor: primaryPurple,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hintText,
    Color bgBody,
    Color primaryPurple,
    Color textMuted,
  ) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: textMuted, fontSize: 14),
      filled: true,
      fillColor: bgBody,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  Widget _buildNullableDropdown<T>({
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
    required Color bgBody,
    required Color textPrimary,
    required Color textMuted,
    required Color primaryPurple,
    String hint = 'Select...',
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: bgBody,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: textMuted,
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textMuted),
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textPrimary,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDayPickerSection(
    Color primaryPurple,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) => _buildDayPickerSectionContent(
    primaryPurple,
    textPrimary,
    textMuted,
    bgBody,
  );

  Widget _buildDayPickerSectionContent(
    Color primaryPurple,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    const days = [
      DayOfWeek.mon,
      DayOfWeek.tue,
      DayOfWeek.wed,
      DayOfWeek.thu,
      DayOfWeek.fri,
      DayOfWeek.sat,
    ];
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 16, color: primaryPurple),
            const SizedBox(width: 6),
            Text(
              'Preferred Teaching Days & Time',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(days.length, (i) {
            final isSelected = _selectedDay == days[i];
            return GestureDetector(
              onTap: () => setState(() {
                _selectedDay = days[i];
                _shiftPreference = FacultyShiftPreference.custom;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primaryPurple : Colors.white,
                  border: Border.all(
                    color: isSelected ? primaryPurple : Colors.black,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryPurple.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  dayLabels[i],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final useVerticalLayout = constraints.maxWidth < 320;
            final arrow = Padding(
              padding: EdgeInsets.symmetric(
                horizontal: useVerticalLayout ? 0 : 10,
                vertical: useVerticalLayout ? 8 : 0,
              ),
              child: Text(
                useVerticalLayout ? '↓' : '→',
                style: const TextStyle(fontSize: 18, color: Colors.black45),
              ),
            );

            Widget buildTimeField({
              required String label,
              required TimeOfDay time,
              required Future<void> Function() onTap,
            }) {
              return Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: bgBody,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: primaryPurple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                              Text(
                                time.format(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final startField = buildTimeField(
              label: 'Start',
              time: _startTime,
              onTap: () async {
                final p = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                  helpText: kSelectStartTimeLabel,
                );
                if (p != null) {
                  setState(() {
                    _startTime = p;
                    _shiftPreference = FacultyShiftPreference.custom;
                  });
                }
              },
            );
            final endField = buildTimeField(
              label: 'End',
              time: _endTime,
              onTap: () async {
                final p = await showTimePicker(
                  context: context,
                  initialTime: _endTime,
                  helpText: kSelectEndTimeLabel,
                );
                if (p != null) {
                  setState(() {
                    _endTime = p;
                    _shiftPreference = FacultyShiftPreference.custom;
                  });
                }
              },
            );

            if (useVerticalLayout) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [startField]),
                  arrow,
                  Row(children: [endField]),
                ],
              );
            }

            return Row(
              children: [
                startField,
                arrow,
                endField,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final sM = _startTime.hour * 60 + _startTime.minute;
              final eM = _endTime.hour * 60 + _endTime.minute;
              if (eM <= sM) {
                AppErrorDialog.show(
                  context,
                  kEndTimeAfterStartMessage,
                );
                return;
              }
              for (final ex in _availabilities) {
                if (ex.day == _selectedDay) {
                  final es = ex.start.hour * 60 + ex.start.minute;
                  final ee = ex.end.hour * 60 + ex.end.minute;
                  if (sM < ee && es < eM) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Overlapping availability for same day'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                }
              }
              setState(() {
                _availabilities.add(
                  _AvailabilityEntry(
                    day: _selectedDay,
                    start: _startTime,
                    end: _endTime,
                  ),
                );
                // Auto-set shift preference to Custom when availability is added
                _shiftPreference = FacultyShiftPreference.custom;
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              'Add Availability',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: primaryPurple, width: 1.5),
              foregroundColor: primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (_availabilities.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryPurple.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryPurple.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Added Availability (${_availabilities.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                  ),
                ),
                const SizedBox(height: 8),
                ..._availabilities.asMap().entries.map((e) {
                  final idx = DayOfWeek.values.indexOf(e.value.day);
                  const dl = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryPurple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _dayLabelOrUnknown(idx, dl),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${e.value.start.format(context)} - ${e.value.end.format(context)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              setState(() => _availabilities.removeAt(e.key)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Edit Faculty Modal (similar to Add but with pre-filled data)
class _EditFacultyModal extends StatefulWidget {
  final Faculty faculty;
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _EditFacultyModal({
    required this.faculty,
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  State<_EditFacultyModal> createState() => _EditFacultyModalState();
}

class _EditFacultyModalState extends State<_EditFacultyModal> {
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
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _facultyIdController;
  late TextEditingController _maxLoadController;
  late TextEditingController _preferredHoursController;

  EmploymentStatus? _employmentStatus;
  FacultyShiftPreference? _shiftPreference;
  Program? _program;
  late bool _isActive;
  bool _isLoading = false;
  bool _isLoadingAvailability = false;
  String? _customPreferredHours;

  // Faculty Availability (Day Picker)
  final List<_AvailabilityEntry> _availabilities = [];
  DayOfWeek _selectedDay = DayOfWeek.mon;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 0);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.faculty.name);
    _emailController = TextEditingController(text: widget.faculty.email);
    _facultyIdController = TextEditingController(
      text: widget.faculty.facultyId,
    );
    _maxLoadController = TextEditingController(
      text: widget.faculty.maxLoad.toString(),
    );
    _preferredHoursController = TextEditingController(
      text: widget.faculty.preferredHours ?? '',
    );
    _employmentStatus = widget.faculty.employmentStatus;
    _shiftPreference =
        widget.faculty.shiftPreference ?? FacultyShiftPreference.any;
    _program = widget.faculty.program;
    _isActive = widget.faculty.isActive;
    _customPreferredHours = widget.faculty.preferredHours;
    _loadExistingAvailability();
  }

  TimeOfDay _timeOfDayFromHHmm(String hhmm) {
    final parts = hhmm.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _loadExistingAvailability() async {
    if (widget.faculty.id == null) return;
    setState(() => _isLoadingAvailability = true);
    try {
      final existing = await client.admin.getFacultyAvailability(
        widget.faculty.id!,
      );
      if (!mounted) return;
      setState(() {
        _availabilities
          ..clear()
          ..addAll(
            existing.map(
              (a) => _AvailabilityEntry(
                day: a.dayOfWeek,
                start: _timeOfDayFromHHmm(a.startTime),
                end: _timeOfDayFromHHmm(a.endTime),
              ),
            ),
          );
      });
    } catch (e) {
      if (mounted) {
        AppErrorDialog.show(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoadingAvailability = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _facultyIdController.dispose();
    _maxLoadController.dispose();
    _preferredHoursController.dispose();
    super.dispose();
  }

  Future<void> _submit() async => _submitEditFaculty();

  Future<void> _submitEditFaculty() async {
    debugPrint('Submitting Edit Faculty form...');
    if (!_formKey.currentState!.validate()) {
      debugPrint('Edit Faculty validation failed');
      return;
    }
    setState(() => _isLoading = true);

    try {
      final updatedFaculty = Faculty(
        id: widget.faculty.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        facultyId: _facultyIdController.text.trim(),
        maxLoad: int.parse(_maxLoadController.text),
        employmentStatus: _employmentStatus,
        shiftPreference: _shiftPreference,
        preferredHours: _customPreferredHours,
        userInfoId: widget.faculty.userInfoId,
        program: _program,
        isActive: _isActive,
        createdAt: widget.faculty.createdAt,
        updatedAt: DateTime.now(),
      );

      await client.admin.updateFaculty(updatedFaculty);

      if (widget.faculty.id != null) {
        final avails = _availabilities
            .map(
              (e) => FacultyAvailability(
                facultyId: widget.faculty.id!,
                dayOfWeek: e.day,
                startTime:
                    '${e.start.hour.toString().padLeft(2, '0')}:${e.start.minute.toString().padLeft(2, '0')}',
                endTime:
                    '${e.end.hour.toString().padLeft(2, '0')}:${e.end.minute.toString().padLeft(2, '0')}',
                isPreferred: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            )
            .toList();
        await client.admin.setFacultyAvailability(widget.faculty.id!, avails);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faculty updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _buildEditFacultyDialog(context);

  Widget _buildEditFacultyDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryPurple = widget.maroonColor;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bgBody = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F6);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF333333);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);
    final isMobile = ResponsiveHelper.isMobile(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile ? double.infinity : 650,
        constraints: BoxConstraints(
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.9 : 750,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with Gradient
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 28,
                vertical: isMobile ? 20 : 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryPurple,
                    const Color(0xFFb5179e),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Faculty Profile',
                          style: GoogleFonts.poppins(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Update information for ${widget.faculty.name}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),

            // Main Body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 20 : 28),
                child: _buildForm(
                  context,
                  bgBody,
                  primaryPurple,
                  textPrimary,
                  textMuted,
                ),
              ),
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(19),
                  bottomRight: Radius.circular(19),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: textMuted,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: primaryPurple.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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

  Widget _buildForm(
    BuildContext context,
    Color bgBody,
    Color primaryPurple,
    Color textPrimary,
    Color textMuted,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Full Name', Icons.person_outline_rounded, textPrimary),
          TextFormField(
            controller: _nameController,
            decoration: _buildInputDecoration(
              'Jerwin A. Carreon',
              bgBody,
              primaryPurple,
              textMuted,
            ),
            style: GoogleFonts.poppins(fontSize: 15, color: textPrimary),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 20),
          _buildLabel('Email Address', Icons.email_outlined, textPrimary),
          TextFormField(
            controller: _emailController,
            decoration: _buildInputDecoration(
              'jerwin.carreon@jmc.edu.ph',
              bgBody,
              primaryPurple,
              textMuted,
            ),
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(fontSize: 15, color: textPrimary),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (!value!.contains('@')) return 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildLabel('Faculty ID', Icons.badge_rounded, textPrimary),
          TextFormField(
            controller: _facultyIdController,
            decoration: _buildInputDecoration(
              'FAC-001',
              bgBody,
              primaryPurple,
              textMuted,
            ),
            style: GoogleFonts.poppins(fontSize: 15, color: textPrimary),
            validator: _requiredValidator,
          ),
          const SizedBox(height: 20),
          _buildLabel(
            'Max Loads (hours)',
            Icons.access_time_rounded,
            textPrimary,
          ),
          TextFormField(
            controller: _maxLoadController,
            decoration: _buildInputDecoration(
              '21',
              bgBody,
              primaryPurple,
              textMuted,
            ),
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(fontSize: 15, color: textPrimary),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Required';
              if (int.tryParse(value!) == null) return 'Invalid number';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _buildLabel(
            'Employment Status',
            Icons.work_outline_rounded,
            textPrimary,
          ),
          _buildDropdown<EmploymentStatus>(
            value: _employmentStatus,
            bgBody: bgBody,
            textPrimary: textPrimary,
            textMuted: textMuted,
            primaryPurple: primaryPurple,
            items: EmploymentStatus.values,
            onChanged: (value) => setState(() => _employmentStatus = value!),
            itemLabel: _employmentStatusLabel,
          ),

          const SizedBox(height: 20),
          _buildLabel('Shift Preference', Icons.schedule_rounded, textPrimary),
          _buildDropdown<FacultyShiftPreference>(
            value: _shiftPreference,
            bgBody: bgBody,
            textPrimary: textPrimary,
            textMuted: textMuted,
            primaryPurple: primaryPurple,
            items: FacultyShiftPreference.values,
            onChanged: (value) => setState(() => _shiftPreference = value),
            itemLabel: _shiftPreferenceLabel,
          ),

          const SizedBox(height: 24),
          if (_isLoadingAvailability)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildDayPickerSection(
              primaryPurple,
              textPrimary,
              textMuted,
              bgBody,
            ),

          const SizedBox(height: 24),
          _buildLabel('Program Assignment', Icons.school_outlined, textPrimary),
          _buildDropdown<Program>(
            value: _program,
            bgBody: bgBody,
            textPrimary: textPrimary,
            textMuted: textMuted,
            primaryPurple: primaryPurple,
            items: const [Program.it, Program.emc],
            onChanged: (value) => setState(() => _program = value!),
            itemLabel: (prog) => prog.name.toUpperCase(),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => setState(() => _isActive = !_isActive),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgBody,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: textMuted,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Is Active',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                    activeThumbColor: primaryPurple,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String hintText,
    Color bgBody,
    Color primaryPurple,
    Color textMuted,
  ) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.poppins(color: textMuted, fontSize: 14),
      filled: true,
      fillColor: bgBody,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryPurple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemLabel,
    required Color bgBody,
    required Color textPrimary,
    required Color textMuted,
    required Color primaryPurple,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: bgBody,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textMuted),
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: textPrimary,
            fontWeight: FontWeight.w500,
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Day Picker Section ──────────────────────────────────────────
  Widget _buildDayPickerSection(
    Color primaryPurple,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    const days = [
      DayOfWeek.mon,
      DayOfWeek.tue,
      DayOfWeek.wed,
      DayOfWeek.thu,
      DayOfWeek.fri,
      DayOfWeek.sat,
    ];
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 16, color: primaryPurple),
            const SizedBox(width: 6),
            Text(
              'Preferred Teaching Days & Time',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Day toggle chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(days.length, (i) {
            final day = days[i];
            final isSelected = _selectedDay == day;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedDay = day;
                _shiftPreference = FacultyShiftPreference.custom;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? primaryPurple : Colors.white,
                  border: Border.all(
                    color: isSelected ? primaryPurple : Colors.black,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryPurple.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  dayLabels[i],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        // Start / End time row
        LayoutBuilder(
          builder: (context, constraints) {
            final useVerticalLayout = constraints.maxWidth < 320;
            final arrow = Padding(
              padding: EdgeInsets.symmetric(
                horizontal: useVerticalLayout ? 0 : 10,
                vertical: useVerticalLayout ? 8 : 0,
              ),
              child: Text(
                useVerticalLayout ? '↓' : '→',
                style: const TextStyle(fontSize: 18, color: Colors.black45),
              ),
            );

            Widget buildTimeField({
              required String label,
              required TimeOfDay time,
              required Future<void> Function() onTap,
            }) {
              return Expanded(
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: bgBody,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: primaryPurple,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: textMuted,
                                ),
                              ),
                              Text(
                                time.format(context),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final startField = buildTimeField(
              label: 'Start',
              time: _startTime,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _startTime,
                  helpText: kSelectStartTimeLabel,
                );
                if (picked != null) {
                  setState(() {
                    _startTime = picked;
                    _shiftPreference = FacultyShiftPreference.custom;
                  });
                }
              },
            );
            final endField = buildTimeField(
              label: 'End',
              time: _endTime,
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _endTime,
                  helpText: kSelectEndTimeLabel,
                );
                if (picked != null) {
                  setState(() {
                    _endTime = picked;
                    _shiftPreference = FacultyShiftPreference.custom;
                  });
                }
              },
            );

            if (useVerticalLayout) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [startField]),
                  arrow,
                  Row(children: [endField]),
                ],
              );
            }

            return Row(
              children: [
                startField,
                arrow,
                endField,
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        // Add button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final startMins = _startTime.hour * 60 + _startTime.minute;
              final endMins = _endTime.hour * 60 + _endTime.minute;
              if (endMins <= startMins) {
                _showErrorDialog(context, kEndTimeAfterStartMessage);
                return;
              }
              // Check duplicate day/time overlap
              for (final existing in _availabilities) {
                if (existing.day == _selectedDay) {
                  final eStart =
                      existing.start.hour * 60 + existing.start.minute;
                  final eEnd = existing.end.hour * 60 + existing.end.minute;
                  if (startMins < eEnd && eStart < endMins) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Overlapping availability for same day'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                }
              }
              setState(() {
                _availabilities.add(
                  _AvailabilityEntry(
                    day: _selectedDay,
                    start: _startTime,
                    end: _endTime,
                  ),
                );
                // Auto-set shift preference to Custom when availability is added
                _shiftPreference = FacultyShiftPreference.custom;
              });
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              'Add Availability',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(color: primaryPurple, width: 1.5),
              foregroundColor: primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (_availabilities.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryPurple.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primaryPurple.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Added Availability (${_availabilities.length})',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryPurple,
                  ),
                ),
                const SizedBox(height: 8),
                ..._availabilities.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  const dayLabels2 = [
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun',
                  ];
                  final dayIdx = DayOfWeek.values.indexOf(e.day);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryPurple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _dayLabelOrUnknown(dayIdx, dayLabels2),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${e.start.format(context)} - ${e.end.format(context)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () =>
                              setState(() => _availabilities.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Simple data class to hold a faculty availability entry in the UI before saving.
class _AvailabilityEntry {
  final DayOfWeek day;
  final TimeOfDay start;
  final TimeOfDay end;

  const _AvailabilityEntry({
    required this.day,
    required this.start,
    required this.end,
  });
}
