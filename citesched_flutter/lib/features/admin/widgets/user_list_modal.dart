import 'dart:math' as math;

import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_create_user_form.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/main.dart';
import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserListModal extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const UserListModal({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<UserListModal> createState() => _UserListModalState();
}

class _UserListModalState extends ConsumerState<UserListModal>
    with SingleTickerProviderStateMixin {
  static const Duration _newSignupWindow = Duration(days: 7);
  late TabController _tabController;
  List<Faculty> _faculty = [];
  List<Student> _students = [];
  List<UserRole> _userRoles = [];
  bool _isLoading = true;
  final TextEditingController _facultySearchController =
      TextEditingController();
  final TextEditingController _studentSearchController =
      TextEditingController();
  String _facultySearchQuery = '';
  String _studentSearchQuery = '';
  String? _selectedStudentProgram;
  int? _selectedStudentYearLevel;
  String? _selectedStudentSection;
  final Map<String, List<_StudentAvailabilityEntry>> _studentAvailabilityDrafts =
      {};

  void _archiveFaculty(Faculty faculty) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Faculty',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to archive "${faculty.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
        final toArchive = faculty.copyWith(isActive: false);
        await client.admin.updateFaculty(toArchive);
        _fetchData();
        // Invalidate section providers for immediate reflection in Faculty Loading
        ref.invalidate(sectionListProvider);
        ref.invalidate(studentSectionsProvider);
        ref.invalidate(facultyListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faculty archived successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showError('Error archiving faculty: $e');
      }
    }
  }

  // Filter states
  bool _isShowingArchivedFaculty = false;
  bool _isShowingArchivedStudents = false;
  String _facultyFilter = 'all';
  String _studentSortOrder = 'asc';

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex.clamp(0, 1);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final errors = <String>[];

    Future<T?> loadSafely<T>(Future<T> future, String label) async {
      try {
        return await future;
      } catch (e) {
        errors.add('$label: $e');
        return null;
      }
    }

    try {
      final faculty = await loadSafely(
        client.admin.getAllFaculty(isActive: !_isShowingArchivedFaculty),
        'faculty',
      );
      final students = await loadSafely(
        client.admin.getAllStudents(isActive: !_isShowingArchivedStudents),
        'students',
      );
      final roles = await loadSafely(
        client.admin.getAllUserRoles(),
        'roles',
      );
      if (mounted) {
        setState(() {
          if (faculty != null) _faculty = faculty;
          if (students != null) _students = students;
          if (roles != null) _userRoles = roles;
          _normalizeStudentFilters();
          _isLoading = false;
        });
        if (errors.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Some user data failed to load: ${errors.join(' | ')}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching users: $e')),
        );
      }
    }
  }

  List<Faculty> get _filteredFaculty {
    return _faculty.where((f) {
      final roleEntry = _userRoles.firstWhere(
        (r) => r.userId == f.userInfoId.toString(),
        orElse: () => UserRole(userId: '', role: 'faculty'),
      );
      final roleMatches =
          _facultyFilter == 'all' || roleEntry.role == _facultyFilter;
      final query = _facultySearchQuery.trim().toLowerCase();
      final matchesSearch =
          query.isEmpty ||
          f.name.toLowerCase().contains(query) ||
          f.email.toLowerCase().contains(query) ||
          f.facultyId.toLowerCase().contains(query) ||
          _programNameOrUnknown(f.program).toLowerCase().contains(query) ||
          roleEntry.role.toLowerCase().contains(query);
      return roleMatches && matchesSearch;
    }).toList();
  }

  List<Student> get _sortedStudents {
    final query = _studentSearchQuery.trim().toLowerCase();
    final sorted = _students.where((student) {
      final program = student.course.trim().toUpperCase();
      final section = student.section?.trim() ?? '';
      final matchesProgram =
          _selectedStudentProgram == null || program == _selectedStudentProgram;
      final matchesYear =
          _selectedStudentYearLevel == null ||
          student.yearLevel == _selectedStudentYearLevel;
      final matchesSection =
          _selectedStudentSection == null || section == _selectedStudentSection;
      final matchesSearch =
          query.isEmpty ||
          student.name.toLowerCase().contains(query) ||
          student.email.toLowerCase().contains(query) ||
          student.studentNumber.toLowerCase().contains(query) ||
          student.course.toLowerCase().contains(query) ||
          (student.section?.toLowerCase().contains(query) ?? false);
      return matchesProgram && matchesYear && matchesSection && matchesSearch;
    }).toList();
    sorted.sort((a, b) {
      final comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return _studentSortOrder == 'asc' ? comparison : -comparison;
    });
    return sorted;
  }

  List<MapEntry<String, List<Student>>> get _groupedStudents {
    final grouped = <String, List<Student>>{};

    for (final student in _sortedStudents) {
      final trimmedName = student.name.trim();
      final label = trimmedName.isEmpty
          ? '#'
          : _nameInitial(trimmedName).toUpperCase();
      grouped.putIfAbsent(label, () => []).add(student);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (_studentSortOrder == 'desc') {
      return entries.reversed.toList();
    }

    return entries;
  }

  List<String> get _studentProgramOptions {
    final programs = _students
        .map((student) => student.course.trim().toUpperCase())
        .where((program) => program.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return programs;
  }

  List<int> get _studentYearLevelOptions {
    final yearLevels = _students.map((student) => student.yearLevel).toSet().toList()
      ..sort();
    return yearLevels;
  }

  List<String> get _studentSectionOptions {
    final sections = _students
        .map((student) => student.section?.trim() ?? '')
        .where((section) => section.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sections;
  }

  bool get _hasActiveStudentFilters =>
      _selectedStudentProgram != null ||
      _selectedStudentYearLevel != null ||
      _selectedStudentSection != null;

  void _normalizeStudentFilters() {
    final programs = _studentProgramOptions;
    final yearLevels = _studentYearLevelOptions;
    final sections = _studentSectionOptions;

    if (_selectedStudentProgram != null &&
        !programs.contains(_selectedStudentProgram)) {
      _selectedStudentProgram = null;
    }
    if (_selectedStudentYearLevel != null &&
        !yearLevels.contains(_selectedStudentYearLevel)) {
      _selectedStudentYearLevel = null;
    }
    if (_selectedStudentSection != null &&
        !sections.contains(_selectedStudentSection)) {
      _selectedStudentSection = null;
    }
  }

  void _clearStudentFilters() {
    setState(() {
      _selectedStudentProgram = null;
      _selectedStudentYearLevel = null;
      _selectedStudentSection = null;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _facultySearchController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  // ─── Student CRUD ────────────────────────────────────────────────────────

  void _showAddStudentDialog() {
    showDialog(
      context: context,
      builder: (_) => AdminCreateUserForm(
        onSuccess: () {
          _fetchData();
          ref.invalidate(sectionListProvider);
          ref.invalidate(studentSectionsProvider);
          ref.invalidate(facultyListProvider);
          ref.invalidate(studentsProvider);
        },
        initialRole: 'student',
      ),
    );
  }

  void _showEditStudentDialog(Student student) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditStudentDialog(
        student: student,
        onSuccess: () {
          _fetchData();
          ref.invalidate(sectionListProvider);
          ref.invalidate(studentSectionsProvider);
          ref.invalidate(studentsProvider);
        },
      ),
    );
  }

  void _archiveStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Student',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to archive "${student.name}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
        final toArchive = student.copyWith(isActive: false);
        await client.admin.updateStudent(toArchive);
        _fetchData();
        ref.invalidate(sectionListProvider);
        ref.invalidate(studentSectionsProvider);
        ref.invalidate(studentsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student archived successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showError('Error archiving student: $e');
      }
    }
  }

  void _restoreStudent(Student student) async {
    try {
      final restored = student.copyWith(
        isActive: true,
        academicStatus: StudentAcademicStatus.active,
      );
      await client.admin.updateStudent(restored);
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error restoring student: $e');
    }
  }

  void _deleteStudentPermanently(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Permanently',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to PERMANENTLY delete "${student.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
        await client.admin.deleteStudent(student.id!);
        _fetchData();
        if (mounted) {
          // Refresh section- and student-dependent views (e.g., Faculty Loading dropdowns)
          ref.invalidate(sectionListProvider);
          ref.invalidate(studentSectionsProvider);
          ref.invalidate(studentsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Student deleted permanently'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showError('Error deleting student: $e');
      }
    }
  }

  void _restoreFaculty(Faculty faculty) async {
    try {
      final restored = faculty.copyWith(isActive: true);
      await client.admin.updateFaculty(restored);
      _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faculty restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error restoring faculty: $e');
    }
  }

  void _deleteFacultyPermanently(Faculty faculty) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Permanently',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to PERMANENTLY delete "${faculty.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
        await client.admin.deleteFaculty(faculty.id!);
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Faculty deleted permanently'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        _showError('Error deleting faculty: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _studentMaxYearForCourse(String course) {
    switch (course.trim().toUpperCase()) {
      case 'BSIT':
      case 'BSEMC':
        return 4;
      default:
        return 4;
    }
  }

  bool _isManualSeniorStudent(Student student) {
    return student.academicStatus == StudentAcademicStatus.active &&
        student.yearLevel >= _studentMaxYearForCourse(student.course);
  }

  Future<void> _updateStudentAcademicStatus(
    Student student,
    StudentAcademicStatus status, {
    required String title,
    required String message,
    required String successMessage,
    bool setInactive = false,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF720045),
              foregroundColor: Colors.white,
            ),
            child: Text('Proceed', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final updated = student.copyWith(
        academicStatus: status,
        isActive: setInactive ? false : student.isActive,
        updatedAt: DateTime.now(),
      );
      await client.admin.updateStudent(updated);
      await _fetchData();
      ref.invalidate(studentsProvider);
      ref.invalidate(archivedStudentsProvider);
      ref.invalidate(studentSectionsProvider);
      ref.invalidate(sectionListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error updating student status: $e');
    }
  }

  Widget _buildStudentAcademicStatusBadge(Student student) {
    late final Color color;
    late final String label;

    switch (student.academicStatus) {
      case StudentAcademicStatus.failed:
        color = const Color(0xFFD97706);
        label = 'FAILED';
        break;
      case StudentAcademicStatus.graduated:
        color = const Color(0xFF2E7D32);
        label = 'GRADUATED';
        break;
      case StudentAcademicStatus.active:
        color = Colors.green;
        label = 'STUDENT';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _nameInitial(String name) {
    if (name.isEmpty) {
      return '?';
    }
    return name[0].toUpperCase();
  }

  String _programNameOrUnknown(Program? program) {
    return (program?.name ?? '?').toUpperCase();
  }

  bool _isNewSignup(DateTime createdAt) {
    return createdAt.isAfter(DateTime.now().subtract(_newSignupWindow));
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => _buildUserListDialog(context);

  Widget _buildUserListDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryPurple = isDark
        ? const Color(0xFFa21caf)
        : const Color(0xFF720045);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bgBody = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F6);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF333333);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final dialogHeight = isMobile
        ? screenHeight * 0.9
        : math.min(700.0, screenHeight - 80);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 12 : 40,
      ),
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 900,
        height: dialogHeight,
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
          children: [
            // Header (Standardized Maroon Gradient Banner)
            AdminHeaderContainer(
              primaryColor: primaryPurple,
              padding: EdgeInsets.all(isMobile ? 20 : 32),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Icon(
                                Icons.manage_accounts_rounded,
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
                                    'User Management',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage system users and permissions',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.8),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showAddStudentDialog,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryPurple,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.person_add_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add Student',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.15),
                                padding: const EdgeInsets.all(10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
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
                                Icons.manage_accounts_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User Management',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Manage system users and permissions',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: _showAddStudentDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryPurple,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.person_add_rounded,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Student',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.15),
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            // Tab Bar
            Container(
              color: cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: bgBody,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: primaryPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: textMuted,
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                  padding: const EdgeInsets.all(4),
                  tabs: [
                    Tab(text: isMobile ? 'Staff' : 'Faculty & Admin'),
                    const Tab(text: 'Students'),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: primaryPurple,
                        strokeWidth: 3,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildFacultyList(
                          primaryPurple,
                          textPrimary,
                          textMuted,
                          bgBody,
                        ),
                        _buildStudentList(
                          primaryPurple,
                          textPrimary,
                          textMuted,
                          bgBody,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Faculty Tab (read-only) ─────────────────────────────────────────────

  Widget _buildFacultyList(
    Color primaryColor,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final horizontalPadding = isMobile ? 16.0 : 28.0;

    return ListView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildSearchField(
              controller: _facultySearchController,
              onChanged: (value) => setState(() {
                _facultySearchQuery = value;
              }),
              hintText: 'Search faculty or admin users',
              primaryColor: primaryColor,
              textMuted: textMuted,
              bgBody: bgBody,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      color: textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Role:',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
                _buildFilterChip('All', 'all', primaryColor, textPrimary),
                _buildFilterChip(
                  'Faculty',
                  'faculty',
                  primaryColor,
                  textPrimary,
                ),
                _buildFilterChip(
                  'Admin',
                  'admin',
                  primaryColor,
                  textPrimary,
                ),
              ],
            ),
            _buildArchiveToggle(
              _isShowingArchivedFaculty,
              (v) => setState(() {
                _isShowingArchivedFaculty = v;
                _fetchData();
              }),
              primaryColor,
              textMuted,
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${_filteredFaculty.length} users',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_filteredFaculty.isEmpty)
          SizedBox(
            height: 320,
            child: _buildEmptyState(
              'No faculty members found',
              Icons.people_outline_rounded,
              textMuted,
            ),
          )
        else
          ..._filteredFaculty.asMap().entries.map((entry) {
            final isLast = entry.key == _filteredFaculty.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: _buildFacultyCard(
                entry.value,
                primaryColor,
                textPrimary,
                textMuted,
                bgBody,
              ),
            );
          }),
      ],
    );
  }

  // ─── Students Tab (with CRUD) ────────────────────────────────────────────

  Widget _buildStudentList(
    Color primaryColor,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final newStudentCount = _sortedStudents
        .where((student) => _isNewSignup(student.createdAt))
        .length;
    final horizontalPadding = isMobile ? 16.0 : 28.0;
    final programOptions = _studentProgramOptions;
    final yearLevelOptions = _studentYearLevelOptions;
    final sectionOptions = _studentSectionOptions;

    return ListView(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchField(
                    controller: _studentSearchController,
                    onChanged: (value) => setState(() {
                      _studentSearchQuery = value;
                    }),
                    hintText: 'Search students by name, ID, course, or section',
                    primaryColor: primaryColor,
                    textMuted: textMuted,
                    bgBody: bgBody,
                  ),
                  const SizedBox(height: 12),
                  _buildStudentSortControls(
                    primaryColor: primaryColor,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildSearchField(
                      controller: _studentSearchController,
                      onChanged: (value) => setState(() {
                        _studentSearchQuery = value;
                      }),
                      hintText: 'Search students by name, ID, course, or section',
                      primaryColor: primaryColor,
                      textMuted: textMuted,
                      bgBody: bgBody,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildStudentSortControls(
                    primaryColor: primaryColor,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildArchiveToggle(
                  _isShowingArchivedStudents,
                  (v) => setState(() {
                    _isShowingArchivedStudents = v;
                    _fetchData();
                  }),
                  primaryColor,
                  textMuted,
                ),
                if (newStudentCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '$newStudentCount new',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '${_sortedStudents.length} students',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildStudentFilterDropdown<String>(
                  label: 'Program',
                  value: _selectedStudentProgram,
                  items: programOptions,
                  itemLabel: (program) => program,
                  onChanged: (value) => setState(
                    () => _selectedStudentProgram = value,
                  ),
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  bgBody: bgBody,
                ),
                _buildStudentFilterDropdown<int>(
                  label: 'Year Level',
                  value: _selectedStudentYearLevel,
                  items: yearLevelOptions,
                  itemLabel: (yearLevel) => 'Year $yearLevel',
                  onChanged: (value) => setState(
                    () => _selectedStudentYearLevel = value,
                  ),
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  bgBody: bgBody,
                ),
                _buildStudentFilterDropdown<String>(
                  label: 'Section',
                  value: _selectedStudentSection,
                  items: sectionOptions,
                  itemLabel: (section) => section,
                  onChanged: (value) => setState(
                    () => _selectedStudentSection = value,
                  ),
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  bgBody: bgBody,
                ),
                OutlinedButton.icon(
                  onPressed: sectionOptions.isEmpty
                      ? null
                      : () => _showStudentAvailabilityDialog(
                            _selectedStudentSection,
                          ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(
                      color: primaryColor.withValues(alpha: 0.24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.event_available_rounded, size: 18),
                  label: Text(
                    _selectedStudentSection == null
                        ? 'Set Section Availability'
                        : 'Set ${_selectedStudentSection!} Availability',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (_hasActiveStudentFilters)
                  OutlinedButton.icon(
                    onPressed: _clearStudentFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(
                        color: primaryColor.withValues(alpha: 0.24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                    label: Text(
                      'Clear filters',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_sortedStudents.isEmpty)
          SizedBox(
            height: 320,
            child: _buildEmptyState(
              'No students found',
              Icons.school_outlined,
              textMuted,
            ),
          )
        else
          ..._groupedStudents.map(
            (group) => _buildStudentGroupSection(
              group.key,
              group.value,
              primaryColor,
              textPrimary,
              textMuted,
              bgBody,
            ),
          ),
      ],
    );
  }

  // ─── Cards ───────────────────────────────────────────────────────────────

  Widget _buildFacultyCard(
    Faculty f,
    Color primaryColor,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgBody,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, const Color(0xFFb5179e)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _nameInitial(f.name),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                f.email,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                              _buildRoleBadge(f),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _programNameOrUnknown(f.program),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    if (!_isShowingArchivedFaculty) ...[
                      _buildActionIcon(
                        icon: Icons.archive_outlined,
                        color: Colors.orange,
                        tooltip: 'Archive Faculty',
                        onTap: () => _archiveFaculty(f),
                      ),
                    ] else ...[
                      _buildActionIcon(
                        icon: Icons.settings_backup_restore_rounded,
                        color: Colors.green,
                        tooltip: 'Restore Faculty',
                        onTap: () => _restoreFaculty(f),
                      ),
                      _buildActionIcon(
                        icon: Icons.delete_forever_rounded,
                        color: Colors.red,
                        tooltip: 'Delete Faculty Permanently',
                        onTap: () => _deleteFacultyPermanently(f),
                      ),
                    ],
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, const Color(0xFFb5179e)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _nameInitial(f.name),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            f.email,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRoleBadge(f),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _programNameOrUnknown(f.program),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isShowingArchivedFaculty) ...[
                  _buildActionIcon(
                    icon: Icons.archive_outlined,
                    color: Colors.orange,
                    tooltip: 'Archive Faculty',
                    onTap: () => _archiveFaculty(f),
                  ),
                ] else ...[
                  _buildActionIcon(
                    icon: Icons.settings_backup_restore_rounded,
                    color: Colors.green,
                    tooltip: 'Restore Faculty',
                    onTap: () => _restoreFaculty(f),
                  ),
                  const SizedBox(width: 6),
                  _buildActionIcon(
                    icon: Icons.delete_forever_rounded,
                    color: Colors.red,
                    tooltip: 'Delete Faculty Permanently',
                    onTap: () => _deleteFacultyPermanently(f),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildActionIcon({
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
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    required String hintText,
    required Color primaryColor,
    required Color textMuted,
    required Color bgBody,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: bgBody,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: textMuted.withValues(alpha: 0.8),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: primaryColor,
            size: 20,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                    FocusScope.of(context).unfocus();
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: textMuted,
                    size: 18,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(Faculty f) {
    final roleEntry = _userRoles.firstWhere(
      (r) => r.userId == f.userInfoId.toString(),
      orElse: () => UserRole(userId: '', role: 'faculty'),
    );
    final isAdmin = roleEntry.role == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isAdmin
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isAdmin
              ? Colors.red.withValues(alpha: 0.3)
              : Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        isAdmin ? 'ADMIN' : 'FACULTY',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isAdmin ? Colors.red : Colors.blue,
        ),
      ),
    );
  }

  Widget _buildNewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        'NEW',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFB45309),
        ),
      ),
    );
  }

  Widget _buildStudentCard(
    Student s,
    Color primaryColor,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    const green = Color(0xFF2e7d32);
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgBody,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [green, Color(0xFF4caf50)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _nameInitial(s.name),
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${s.studentNumber} ? ${s.email}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: textMuted,
                                ),
                              ),
                              _buildStudentAcademicStatusBadge(s),
                              if (_isNewSignup(s.createdAt)) _buildNewBadge(),
                            ],
                          ),
                          if (s.section != null && s.section!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Section: ${s.section}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: green.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        s.course,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: green,
                        ),
                      ),
                    ),
                    if (!_isShowingArchivedStudents) ...[
                      if (_isManualSeniorStudent(s))
                        _buildActionIcon(
                          icon: Icons.workspace_premium_rounded,
                          color: const Color(0xFF2E7D32),
                          tooltip: 'Mark as Graduated',
                          onTap: () => _updateStudentAcademicStatus(
                            s,
                            StudentAcademicStatus.graduated,
                            title: 'Graduate Student',
                            message:
                                'Mark "${s.name}" as graduated? This will move the student out of active lists and into the graduated list.',
                            successMessage:
                                'Student marked as graduated successfully.',
                            setInactive: true,
                          ),
                        ),
                      if (_isManualSeniorStudent(s))
                        _buildActionIcon(
                          icon: Icons.gpp_bad_rounded,
                          color: const Color(0xFFD97706),
                          tooltip: 'Mark as Failed',
                          onTap: () => _updateStudentAcademicStatus(
                            s,
                            StudentAcademicStatus.failed,
                            title: 'Mark Student as Failed',
                            message:
                                'Mark "${s.name}" as failed? This student will stay manual and will not be included in automatic year level promotion.',
                            successMessage:
                                'Student marked as failed successfully.',
                          ),
                        ),
                      if (s.academicStatus == StudentAcademicStatus.failed)
                        _buildActionIcon(
                          icon: Icons.restore_rounded,
                          color: const Color(0xFF2E7D32),
                          tooltip: 'Restore Active Status',
                          onTap: () => _updateStudentAcademicStatus(
                            s,
                            StudentAcademicStatus.active,
                            title: 'Restore Active Status',
                            message:
                                'Restore "${s.name}" to active academic status?',
                            successMessage:
                                'Student restored to active status successfully.',
                          ),
                        ),
                      _buildActionIcon(
                        icon: Icons.edit_outlined,
                        color: primaryColor,
                        tooltip: 'Edit Student',
                        onTap: () => _showEditStudentDialog(s),
                      ),
                      _buildActionIcon(
                        icon: Icons.archive_outlined,
                        color: Colors.orange,
                        tooltip: 'Archive Student',
                        onTap: () => _archiveStudent(s),
                      ),
                    ] else ...[
                      _buildActionIcon(
                        icon: Icons.settings_backup_restore_rounded,
                        color: Colors.green,
                        tooltip: 'Restore Student',
                        onTap: () => _restoreStudent(s),
                      ),
                      _buildActionIcon(
                        icon: Icons.delete_forever_rounded,
                        color: Colors.red,
                        tooltip: 'Delete Student Permanently',
                        onTap: () => _deleteStudentPermanently(s),
                      ),
                    ],
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [green, Color(0xFF4caf50)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _nameInitial(s.name),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.name,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${s.studentNumber} ? ${s.email}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStudentAcademicStatusBadge(s),
                          if (_isNewSignup(s.createdAt)) ...[
                            const SizedBox(width: 8),
                            _buildNewBadge(),
                          ],
                        ],
                      ),
                      if (s.section != null && s.section!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Section: ${s.section}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: green.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    s.course,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isShowingArchivedStudents) ...[
                  if (_isManualSeniorStudent(s))
                    _buildActionIcon(
                      icon: Icons.workspace_premium_rounded,
                      color: const Color(0xFF2E7D32),
                      tooltip: 'Mark as Graduated',
                      onTap: () => _updateStudentAcademicStatus(
                        s,
                        StudentAcademicStatus.graduated,
                        title: 'Graduate Student',
                        message:
                            'Mark "${s.name}" as graduated? This will move the student out of active lists and into the graduated list.',
                        successMessage:
                            'Student marked as graduated successfully.',
                        setInactive: true,
                      ),
                    ),
                  if (_isManualSeniorStudent(s)) const SizedBox(width: 6),
                  if (_isManualSeniorStudent(s))
                    _buildActionIcon(
                      icon: Icons.gpp_bad_rounded,
                      color: const Color(0xFFD97706),
                      tooltip: 'Mark as Failed',
                      onTap: () => _updateStudentAcademicStatus(
                        s,
                        StudentAcademicStatus.failed,
                        title: 'Mark Student as Failed',
                        message:
                            'Mark "${s.name}" as failed? This student will stay manual and will not be included in automatic year level promotion.',
                        successMessage:
                            'Student marked as failed successfully.',
                      ),
                    ),
                  if (_isManualSeniorStudent(s)) const SizedBox(width: 6),
                  if (s.academicStatus == StudentAcademicStatus.failed)
                    _buildActionIcon(
                      icon: Icons.restore_rounded,
                      color: const Color(0xFF2E7D32),
                      tooltip: 'Restore Active Status',
                      onTap: () => _updateStudentAcademicStatus(
                        s,
                        StudentAcademicStatus.active,
                        title: 'Restore Active Status',
                        message:
                            'Restore "${s.name}" to active academic status?',
                        successMessage:
                            'Student restored to active status successfully.',
                      ),
                    ),
                  if (s.academicStatus == StudentAcademicStatus.failed)
                    const SizedBox(width: 6),
                  _buildActionIcon(
                    icon: Icons.edit_outlined,
                    color: primaryColor,
                    tooltip: 'Edit Student',
                    onTap: () => _showEditStudentDialog(s),
                  ),
                  const SizedBox(width: 6),
                  _buildActionIcon(
                    icon: Icons.archive_outlined,
                    color: Colors.orange,
                    tooltip: 'Archive Student',
                    onTap: () => _archiveStudent(s),
                  ),
                ] else ...[
                  _buildActionIcon(
                    icon: Icons.settings_backup_restore_rounded,
                    color: Colors.green,
                    tooltip: 'Restore Student',
                    onTap: () => _restoreStudent(s),
                  ),
                  const SizedBox(width: 6),
                  _buildActionIcon(
                    icon: Icons.delete_forever_rounded,
                    color: Colors.red,
                    tooltip: 'Delete Student Permanently',
                    onTap: () => _deleteStudentPermanently(s),
                  ),
                ],
              ],
            ),
    );
  }

  // --- Helpers ─────────────────────────────────────────────────────────────

  Widget _buildStudentSortControls({
    required Color primaryColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort_by_alpha_rounded,
              color: textMuted,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              'Sort:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
          ],
        ),
        _buildSortChip('A → Z', 'asc', primaryColor, textPrimary),
        _buildSortChip('Z → A', 'desc', primaryColor, textPrimary),
      ],
    );
  }

  Future<void> _showStudentAvailabilityDialog(String? section) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xFFa21caf)
        : const Color(0xFF720045);
    final accentColor = const Color(0xFFb5179e);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF333333);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);
    final bgBody = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F6);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    const days = [
      DayOfWeek.mon,
      DayOfWeek.tue,
      DayOfWeek.wed,
      DayOfWeek.thu,
      DayOfWeek.fri,
      DayOfWeek.sat,
    ];
    const dayLabels = {
      DayOfWeek.mon: 'Mon',
      DayOfWeek.tue: 'Tue',
      DayOfWeek.wed: 'Wed',
      DayOfWeek.thu: 'Thu',
      DayOfWeek.fri: 'Fri',
      DayOfWeek.sat: 'Sat',
    };
    final sectionOptions = _studentSectionOptions;
    var currentSection = (() {
      final normalized = (section ?? '').trim();
      if (normalized.isNotEmpty && sectionOptions.contains(normalized)) {
        return normalized;
      }
      if (sectionOptions.isNotEmpty) {
        return sectionOptions.first;
      }
      return '';
    })();
    var selectedDay = days.first;
    var startTime = const TimeOfDay(hour: 8, minute: 0);
    var endTime = const TimeOfDay(hour: 12, minute: 0);
    final availabilities = List<_StudentAvailabilityEntry>.from(
      _studentAvailabilityDrafts[currentSection] ?? const [],
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void loadSectionAvailability(String nextSection) {
              availabilities
                ..clear()
                ..addAll(
                  List<_StudentAvailabilityEntry>.from(
                    _studentAvailabilityDrafts[nextSection] ?? const [],
                  ),
                );
            }

            void persistCurrentSectionAvailability() {
              _studentAvailabilityDrafts[currentSection] =
                  List<_StudentAvailabilityEntry>.from(availabilities);
            }

            Future<void> pickTime({
              required bool isStart,
            }) async {
              final picked = await showTimePicker(
                context: context,
                initialTime: isStart ? startTime : endTime,
                helpText: isStart ? 'Select Start Time' : 'Select End Time',
              );
              if (picked == null) return;
              setDialogState(() {
                if (isStart) {
                  startTime = picked;
                } else {
                  endTime = picked;
                }
              });
            }

            void addAvailability() {
              final startMinutes = startTime.hour * 60 + startTime.minute;
              final endMinutes = endTime.hour * 60 + endTime.minute;

              if (endMinutes <= startMinutes) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('End time must be after start time.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              for (final entry in availabilities) {
                if (entry.day != selectedDay) continue;
                final existingStart =
                    entry.start.hour * 60 + entry.start.minute;
                final existingEnd = entry.end.hour * 60 + entry.end.minute;
                if (startMinutes < existingEnd && existingStart < endMinutes) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Overlapping availability for same day.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
              }

              setDialogState(() {
                availabilities.add(
                  _StudentAvailabilityEntry(
                    day: selectedDay,
                    start: startTime,
                    end: endTime,
                  ),
                );
              });
            }

            Widget buildTimeCard({
              required String label,
              required TimeOfDay time,
              required VoidCallback onTap,
            }) {
              return Expanded(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: bgBody,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                            Text(
                              time.format(context),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: 640,
                constraints: const BoxConstraints(maxWidth: 640, maxHeight: 760),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.16),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, accentColor],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.event_available_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Section Availability',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  currentSection.isEmpty
                                      ? 'No sections available'
                                      : currentSection,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Section',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: bgBody,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: currentSection.isEmpty
                                      ? null
                                      : currentSection,
                                  hint: Text(
                                    'Select a section',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: textMuted,
                                    ),
                                  ),
                                  items: sectionOptions
                                      .map(
                                        (sectionOption) => DropdownMenuItem<String>(
                                          value: sectionOption,
                                          child: Text(
                                            sectionOption,
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: textPrimary,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: sectionOptions.isEmpty
                                      ? null
                                      : (value) {
                                          if (value == null || value == currentSection) {
                                            return;
                                          }
                                          setDialogState(() {
                                            persistCurrentSectionAvailability();
                                            currentSection = value;
                                            loadSectionAvailability(value);
                                          });
                                        },
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: textMuted,
                                  ),
                                  dropdownColor: cardBg,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: days.map((day) {
                                final isSelected = selectedDay == day;
                                return InkWell(
                                  onTap: () => setDialogState(() {
                                    selectedDay = day;
                                  }),
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? primaryColor : cardBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryColor
                                            : Colors.black.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Text(
                                      dayLabels[day]!,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : textPrimary,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 420) {
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          buildTimeCard(
                                            label: 'Start',
                                            time: startTime,
                                            onTap: () => pickTime(isStart: true),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Text(
                                          '→',
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            color: textMuted,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          buildTimeCard(
                                            label: 'End',
                                            time: endTime,
                                            onTap: () => pickTime(isStart: false),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    buildTimeCard(
                                      label: 'Start',
                                      time: startTime,
                                      onTap: () => pickTime(isStart: true),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        '→',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          color: textMuted,
                                        ),
                                      ),
                                    ),
                                    buildTimeCard(
                                      label: 'End',
                                      time: endTime,
                                      onTap: () => pickTime(isStart: false),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: addAvailability,
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                label: Text(
                                  'Add Availability',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: primaryColor,
                                  side: BorderSide(color: primaryColor, width: 1.5),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (availabilities.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: bgBody,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Text(
                                  'No availability added yet.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: textMuted,
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Added Availability (${availabilities.length})',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...availabilities.asMap().entries.map((entry) {
                                      final availability = entry.value;
                                      return Container(
                                        margin: EdgeInsets.only(
                                          bottom: entry.key == availabilities.length - 1
                                              ? 0
                                              : 10,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cardBg,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: primaryColor.withValues(
                                              alpha: 0.12,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                dayLabels[availability.day]!,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                '${availability.start.format(context)} - ${availability.end.format(context)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimary,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () => setDialogState(() {
                                                availabilities.removeAt(entry.key);
                                              }),
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                              ),
                                              color: Colors.redAccent,
                                              tooltip: 'Remove',
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor: textMuted,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
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
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      persistCurrentSectionAvailability();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(dialogContext)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            availabilities.isEmpty
                                                ? '$currentSection availability cleared.'
                                                : '$currentSection availability saved.',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Save Availability',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T item) itemLabel,
    required ValueChanged<T?> onChanged,
    required Color textPrimary,
    required Color textMuted,
    required Color bgBody,
  }) {
    final safeValue = items.contains(value) ? value : null;

    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bgBody,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T?>(
          value: safeValue,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: textMuted),
          hint: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: textMuted.withValues(alpha: 0.9),
            ),
          ),
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: textPrimary,
          ),
          items: [
            DropdownMenuItem<T?>(
              value: null,
              child: Text(
                'All $label',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 13, color: textMuted),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<T?>(
                value: item,
                child: Text(
                  itemLabel(item),
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 13, color: textPrimary),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildStudentGroupSection(
    String label,
    List<Student> students,
    Color primaryColor,
    Color textPrimary,
    Color textMuted,
    Color bgBody,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ),
          ...students.asMap().entries.map((entry) {
            final isLast = entry.key == students.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: _buildStudentCard(
                entry.value,
                primaryColor,
                textPrimary,
                textMuted,
                bgBody,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildArchiveToggle(
    bool value,
    ValueChanged<bool> onChanged,
    Color primaryColor,
    Color textMuted,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value ? 'Archived' : 'Active',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: value ? Colors.orange : textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.orange,
          activeTrackColor: Colors.orange.withValues(alpha: 0.2),
          inactiveThumbColor: Colors.grey.shade400,
          inactiveTrackColor: Colors.grey.shade200,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    Color primaryColor,
    Color textPrimary,
  ) {
    final isSelected = _facultyFilter == value;
    return InkWell(
      onTap: () => setState(() => _facultyFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : textPrimary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(
    String label,
    String value,
    Color primaryColor,
    Color textPrimary,
  ) {
    final isSelected = _studentSortOrder == value;
    return InkWell(
      onTap: () => setState(() => _studentSortOrder = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : textPrimary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(fontSize: 16, color: textMuted),
          ),
        ],
      ),
    );
  }
}

// ── Edit Student Dialog ───────────────────────────────────────────────────────

class _EditStudentDialog extends StatefulWidget {
  final Student student;
  final VoidCallback onSuccess;

  const _EditStudentDialog({
    required this.student,
    required this.onSuccess,
  });

  @override
  State<_EditStudentDialog> createState() => _EditStudentDialogState();
}

class _EditStudentDialogState extends State<_EditStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  static const List<String> _allowedCourses = ['BSIT', 'BSEMC'];
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _sectionCtrl;
  late final TextEditingController _numberCtrl;
  late String _selectedCourse;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.student.name);
    _emailCtrl = TextEditingController(text: widget.student.email);
    _sectionCtrl = TextEditingController(text: widget.student.section ?? '');
    _numberCtrl = TextEditingController(text: widget.student.studentNumber);
    _selectedCourse =
        _allowedCourses.contains(widget.student.course.trim().toUpperCase())
        ? widget.student.course.trim().toUpperCase()
        : _allowedCourses.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _sectionCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  String _normalizeSectionCode(String input) {
    final match = RegExp(r'^\s*(\d+)\s*([A-Za-z][A-Za-z0-9]*)\s*$').firstMatch(
      input,
    );
    if (match == null) return input.trim().toUpperCase();
    return '${match.group(1)!}${match.group(2)!.toUpperCase()}';
  }

  int? _extractYearLevelFromSection(String input) {
    final match = RegExp(r'^\s*(\d+)\s*[A-Za-z][A-Za-z0-9]*\s*$').firstMatch(
      input,
    );
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final normalizedSection = _sectionCtrl.text.trim().isEmpty
          ? null
          : _normalizeSectionCode(_sectionCtrl.text);
      final updated = widget.student.copyWith(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        course: _selectedCourse,
        yearLevel: normalizedSection == null
            ? widget.student.yearLevel
            : (_extractYearLevelFromSection(normalizedSection) ??
                  widget.student.yearLevel),
        section: normalizedSection,
        studentNumber: _numberCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );
      await client.admin.updateStudent(updated);
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _buildArchiveUserDialog(context);

  Widget _buildArchiveUserDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maroon = isDark ? const Color(0xFFa21caf) : const Color(0xFF720045);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bgBody = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF1F6);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF333333);
    final textMuted = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF666666);

    InputDecoration field(String hint, IconData icon) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: textMuted.withValues(alpha: 0.6),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: maroon, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: bgBody,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: maroon, width: 2),
      ),
    );

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 640),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: maroon.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [maroon, const Color(0xFFb5179e)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
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
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Edit Student',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: field(
                          'Full Name',
                          Icons.person_outline_rounded,
                        ),
                        style: GoogleFonts.poppins(color: textPrimary),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _numberCtrl,
                        decoration: field(
                          'Student Number',
                          Icons.badge_rounded,
                        ),
                        style: GoogleFonts.poppins(color: textPrimary),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: field('Email', Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(color: textPrimary),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCourse,
                        decoration: field('Course', Icons.school_rounded),
                        items: _allowedCourses
                            .map(
                              (course) => DropdownMenuItem<String>(
                                value: course,
                                child: Text(
                                  course,
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedCourse = value;
                          });
                        },
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _sectionCtrl,
                        decoration: field(
                          'Year & Section',
                          Icons.group_rounded,
                        ),
                        style: GoogleFonts.poppins(color: textPrimary),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final normalized = _normalizeSectionCode(v);
                          if (_extractYearLevelFromSection(normalized) ==
                              null) {
                            return 'Use format like 3A, 3B, 2A, 2B';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: textMuted,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                                backgroundColor: maroon,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.save_rounded,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Save Changes',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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
          ],
        ),
      ),
    );
  }
}

class _StudentAvailabilityEntry {
  final DayOfWeek day;
  final TimeOfDay start;
  final TimeOfDay end;

  const _StudentAvailabilityEntry({
    required this.day,
    required this.start,
    required this.end,
  });
}
