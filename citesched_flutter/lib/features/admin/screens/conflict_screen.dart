import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/features/admin/screens/admin_layout.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:citesched_flutter/core/utils/error_handler.dart';

class ConflictScreen extends StatefulWidget {
  final String? filterType;

  const ConflictScreen({super.key, this.filterType});

  @override
  State<ConflictScreen> createState() => _ConflictScreenState();
}

class _ConflictScreenState extends State<ConflictScreen> {
  static const String _sourceFacultyLoadingTimetable =
      'FACULTY LOADING · TIMETABLE';
  List<ScheduleConflict> _conflicts = [];
  bool _isLoading = true;
  final Set<String> _resolvingConflictKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _fetchConflicts();
  }

  Future<void> _fetchConflicts() async {
    setState(() => _isLoading = true);
    try {
      final conflicts = await client.admin.getAllConflicts();
      if (!mounted) return;
      setState(() {
        _conflicts = conflicts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppErrorDialog.show(context, e);
    }
  }

  // ─── Conflict Type Metadata ──────────────────────────────────────

  static const _typeConfig = <String, _ConflictTypeConfig>{
    'room_conflict': _ConflictTypeConfig(
      label: 'ROOM CONFLICT',
      source: _sourceFacultyLoadingTimetable,
      icon: Icons.meeting_room_rounded,
      color: Colors.red,
      severity: 'CRITICAL',
    ),
    'faculty_conflict': _ConflictTypeConfig(
      label: 'FACULTY TIME CONFLICT',
      source: _sourceFacultyLoadingTimetable,
      icon: Icons.person_off_rounded,
      color: Colors.deepOrange,
      severity: 'CRITICAL',
    ),
    'section_conflict': _ConflictTypeConfig(
      label: 'SECTION CONFLICT',
      source: _sourceFacultyLoadingTimetable,
      icon: Icons.groups_rounded,
      color: Colors.purple,
      severity: 'CRITICAL',
    ),
    'program_mismatch': _ConflictTypeConfig(
      label: 'PROGRAM MISMATCH',
      source: 'SUBJECTS · ROOMS',
      icon: Icons.compare_arrows_rounded,
      color: Colors.amber,
      severity: 'WARNING',
    ),
    'capacity_exceeded': _ConflictTypeConfig(
      label: 'CAPACITY EXCEEDED',
      source: 'ROOMS · SUBJECTS',
      icon: Icons.group_add_rounded,
      color: Colors.orange,
      severity: 'WARNING',
    ),
    'max_load_exceeded': _ConflictTypeConfig(
      label: 'MAX LOAD EXCEEDED',
      source: 'FACULTY LOADING · FACULTY MANAGEMENT',
      icon: Icons.warning_amber_rounded,
      color: Colors.brown,
      severity: 'WARNING',
    ),
    'room_inactive': _ConflictTypeConfig(
      label: 'ROOM INACTIVE',
      source: 'ROOMS · TIMETABLE',
      icon: Icons.block_rounded,
      color: Colors.grey,
      severity: 'WARNING',
    ),
    'faculty_unavailable': _ConflictTypeConfig(
      label: 'FACULTY UNAVAILABLE',
      source: 'FACULTY MANAGEMENT · TIMETABLE',
      icon: Icons.event_busy_rounded,
      color: Colors.indigo,
      severity: 'WARNING',
    ),
    'generation_failed': _ConflictTypeConfig(
      label: 'GENERATION FAILED',
      source: 'SCHEDULE GENERATOR',
      icon: Icons.error_outline_rounded,
      color: Colors.red,
      severity: 'CRITICAL',
    ),
  };

  _ConflictTypeConfig _getConfig(String type) {
    return _typeConfig[type] ??
        const _ConflictTypeConfig(
          label: 'UNKNOWN',
          source: 'UNKNOWN MODULE',
          icon: Icons.help_outline_rounded,
          color: Colors.grey,
          severity: 'INFO',
        );
  }

  // ─── Conflict Summary Stats ──────────────────────────────────────

  Map<String, int> _getConflictCounts() {
    var counts = <String, int>{};
    for (var c in _filteredConflicts()) {
      counts[c.type] = (counts[c.type] ?? 0) + 1;
    }
    return counts;
  }

  List<ScheduleConflict> _filteredConflicts() {
    if (widget.filterType == null) return _conflicts;
    return _conflicts.where((c) => c.type == widget.filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const maroonColor = Color(0xFF720045);
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.grey[300]! : Colors.grey[700]!;
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(maroonColor: maroonColor, isMobile: isMobile),

            const SizedBox(height: 32),

            // Summary Stat Chips
            if (!_isLoading && _filteredConflicts().isNotEmpty) ...[
              _buildSummaryChips(maroonColor, cardBg, isDark),
              const SizedBox(height: 24),
            ],

            Expanded(
              child: _buildContentArea(
                isDark: isDark,
                cardBg: cardBg,
                maroonColor: maroonColor,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required Color maroonColor,
    required bool isMobile,
  }) {
    return AdminHeaderContainer(
      primaryColor: maroonColor,
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: maroonColor.withValues(alpha: 0.3),
          blurRadius: 25,
          offset: const Offset(0, 12),
        ),
      ],
      child: isMobile
          ? _buildMobileHeader(maroonColor)
          : _buildDesktopHeader(maroonColor),
    );
  }

  Widget _buildMobileHeader(Color maroonColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildHeaderIcon(iconSize: 28, padding: const EdgeInsets.all(14)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Conflicts',
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
                    _headerMessage,
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
        SizedBox(
          width: double.infinity,
          child: _buildRefreshButton(
            maroonColor: maroonColor,
            iconSize: 20,
            fontSize: 14,
            horizontalPadding: 16,
            verticalPadding: 14,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(Color maroonColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildHeaderIcon(iconSize: 32, padding: const EdgeInsets.all(16)),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Conflicts',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _headerMessage,
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
        const SizedBox(width: 16),
        _buildRefreshButton(
          maroonColor: maroonColor,
          iconSize: 22,
          fontSize: 15,
          horizontalPadding: 28,
          verticalPadding: 18,
          letterSpacing: 0.5,
        ),
      ],
    );
  }

  Widget _buildHeaderIcon({
    required double iconSize,
    required EdgeInsets padding,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Icon(
        Icons.warning_amber_rounded,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }

  String get _headerMessage {
    if (_isLoading) {
      return 'Scanning all modules for conflicts...';
    }
    if (_conflicts.isEmpty) {
      return 'No scheduling conflicts detected';
    }

    final suffix = _conflicts.length == 1 ? '' : 's';
    return '${_conflicts.length} conflict$suffix detected across modules';
  }

  Widget _buildRefreshButton({
    required Color maroonColor,
    required double iconSize,
    required double fontSize,
    required double horizontalPadding,
    required double verticalPadding,
    required double letterSpacing,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _fetchConflicts,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF720045)),
              ),
            )
          : Icon(Icons.refresh_rounded, size: iconSize),
      label: Text(
        _isLoading ? 'Scanning...' : 'Refresh',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
          letterSpacing: letterSpacing,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: maroonColor,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildContentArea({
    required bool isDark,
    required Color cardBg,
    required Color maroonColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredConflicts().isEmpty) {
      return _buildEmptyState(textMuted);
    }

    return _buildConflictList(
      isDark,
      cardBg,
      maroonColor,
      textPrimary,
      textMuted,
    );
  }

  Widget _buildSummaryChips(Color maroonColor, Color cardBg, bool isDark) {
    final counts = _getConflictCounts();
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: counts.entries.map((e) {
        final config = _getConfig(e.key);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: config.color.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: config.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(config.icon, size: 16, color: config.color),
              const SizedBox(width: 8),
              Text(
                '${e.value}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: config.color,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                config.label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: config.color.withValues(alpha: 0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(Color textMuted) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_rounded,
              size: 64,
              color: Colors.green.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'All Clear!',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No conflicts across Faculty Loading, Rooms, Subjects, or Timetable.',
            style: GoogleFonts.poppins(fontSize: 15, color: textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictList(
    bool isDark,
    Color cardBg,
    Color maroonColor,
    Color textPrimary,
    Color textMuted,
  ) {
    final filteredConflicts = _filteredConflicts();
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  Icons.warning_amber_rounded,
                  color: maroonColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Conflict Records',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: maroonColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: maroonColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${filteredConflicts.length} items',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredConflicts.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final conflict = filteredConflicts[index];
                final conflictKey = _conflictKey(conflict, index);
                return _buildConflictTile(
                  conflict: conflict,
                  conflictKey: conflictKey,
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictTile({
    required ScheduleConflict conflict,
    required String conflictKey,
    required Color cardBg,
    required Color textPrimary,
    required Color textMuted,
  }) {
    final config = _getConfig(conflict.type);
    final isResolving = _resolvingConflictKeys.contains(conflictKey);
    final severityColor = _severityColor(config.severity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: config.color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConflictMetadata(
                  config: config,
                  severityColor: severityColor,
                  textMuted: textMuted,
                ),
                const SizedBox(height: 6),
                Text(
                  conflict.message,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                if (conflict.details != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    conflict.details!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: isResolving
                        ? null
                        : () => _resolveConflict(
                            conflict,
                            conflictKey: conflictKey,
                          ),
                    icon: isResolving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_fix_high, size: 16),
                    label: Text(
                      isResolving ? 'Checking...' : 'Suggest Fix',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: config.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictMetadata({
    required _ConflictTypeConfig config,
    required Color severityColor,
    required Color textMuted,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildConflictBadge(
          backgroundColor: config.color.withValues(alpha: 0.1),
          text: config.label,
          textColor: config.color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
        const SizedBox(width: 8),
        _buildConflictBadge(
          backgroundColor: Colors.grey.withValues(alpha: 0.1),
          text: config.source,
          textColor: textMuted,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: severityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 11,
                color: severityColor,
              ),
              const SizedBox(width: 3),
              Text(
                config.severity,
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: severityColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConflictBadge({
    required Color backgroundColor,
    required String text,
    required Color textColor,
    required double fontSize,
    required FontWeight fontWeight,
    required double letterSpacing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: textColor,
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }

  Color _severityColor(String severity) {
    return severity == 'CRITICAL' ? Colors.red : Colors.orange;
  }

  String _conflictKey(ScheduleConflict conflict, int index) {
    return [
      '$index',
      conflict.type,
      '${conflict.scheduleId ?? -1}',
      '${conflict.conflictingScheduleId ?? -1}',
      '${conflict.facultyId ?? -1}',
      '${conflict.roomId ?? -1}',
      '${conflict.subjectId ?? -1}',
    ].join('|');
  }

  Future<void> _resolveConflict(
    ScheduleConflict conflict, {
    required String conflictKey,
  }) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _resolvingConflictKeys.add(conflictKey));
    try {
      final options = await _buildResolutionOptions(conflict);
      if (!mounted) return;

      if (options.isEmpty) {
        await _showManualResolutionDialog(conflict);
        return;
      }

      final selectedOption = await _showResolutionPlannerDialog(
        conflict: conflict,
        options: options,
      );
      if (!mounted || selectedOption == null) return;

      switch (selectedOption.kind) {
        case _ResolutionOptionKind.autoApply:
          final suggestion = selectedOption.suggestion;
          if (suggestion == null) return;
          await client.admin.updateSchedule(suggestion.updatedSchedule);
          await _fetchConflicts();
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text(suggestion.successMessage)),
          );
          break;
        case _ResolutionOptionKind.openFacultyEdit:
          final facultyId = conflict.facultyId;
          if (facultyId == null) return;
          navigator.push(
            MaterialPageRoute(
              builder: (_) => AdminLayout(
                initialIndex: 1,
                initialFacultyIdToEdit: facultyId,
              ),
            ),
          );
          break;
        case _ResolutionOptionKind.openModule:
          final moduleIndex = selectedOption.moduleIndex;
          if (moduleIndex == null) return;
          navigator.push(
            MaterialPageRoute(
              builder: (_) => AdminLayout(initialIndex: moduleIndex),
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      AppErrorDialog.show(context, e);
    } finally {
      if (mounted) {
        setState(() => _resolvingConflictKeys.remove(conflictKey));
      }
    }
  }

  Future<List<_ResolutionOption>> _buildResolutionOptions(
    ScheduleConflict conflict,
  ) async {
    final options = <_ResolutionOption>[];
    final suggestion = await _buildResolutionSuggestion(conflict);

    if (suggestion != null) {
      options.add(
        _ResolutionOption(
          kind: _ResolutionOptionKind.autoApply,
          title: suggestion.title,
          description: suggestion.summary,
          impactLabel: 'Applies the safest available system-generated fix.',
          recommendationLabel: 'Recommended',
          suggestion: suggestion,
        ),
      );
    }

    if (conflict.type == 'max_load_exceeded' && conflict.facultyId != null) {
      options.add(
        const _ResolutionOption(
          kind: _ResolutionOptionKind.openFacultyEdit,
          title: 'Edit Faculty Max Load',
          description:
              'Open Faculty Management and update the faculty max load if the overload is valid and approved.',
          impactLabel: 'Best when the higher load is legitimate and approved.',
          recommendationLabel: 'Common fix',
        ),
      );
      options.add(
        const _ResolutionOption(
          kind: _ResolutionOptionKind.openModule,
          title: 'Rebalance Subject Assignments',
          description:
              'Open Faculty Loading and move one or more assigned subjects to another eligible faculty member.',
          impactLabel: 'Best when the max load should remain unchanged.',
          moduleIndex: 2,
        ),
      );
      return options;
    }

    final moduleIndex = _manualResolutionIndex(conflict.type);
    if (moduleIndex != null) {
      options.add(
        _ResolutionOption(
          kind: _ResolutionOptionKind.openModule,
          title: 'Open Related Module',
          description:
              'Review the source module manually and adjust room, faculty, section, or timeslot there.',
          impactLabel: 'Gives you full control before making changes.',
          moduleIndex: moduleIndex,
          recommendationLabel: suggestion == null ? 'Recommended' : null,
        ),
      );
    }

    if (suggestion == null && conflict.scheduleId != null) {
      options.add(
        const _ResolutionOption(
          kind: _ResolutionOptionKind.openModule,
          title: 'Inspect Timetable Placement',
          description:
              'Open the timetable module to compare nearby slots, room usage, and section availability first.',
          impactLabel: 'Helpful when you want to diagnose the schedule pattern before editing.',
          moduleIndex: 5,
        ),
      );
    }

    return options;
  }

  Future<_ResolutionSuggestion?> _buildResolutionSuggestion(
    ScheduleConflict conflict,
  ) async {
    final scheduleId = conflict.scheduleId;
    if (scheduleId == null) return null;

    switch (conflict.type) {
      case 'room_conflict':
      case 'room_inactive':
      case 'capacity_exceeded':
      case 'program_mismatch':
      case 'room_type_mismatch':
        return await _suggestRoomOrTimeslotResolution(conflict);
      case 'faculty_conflict':
      case 'section_conflict':
      case 'faculty_unavailable':
      case 'lab_start_time':
      case 'insufficient_block':
        return await _suggestTimeslotResolution(conflict);
      default:
        return null;
    }
  }

  Future<_ResolutionSuggestion?> _suggestRoomOrTimeslotResolution(
    ScheduleConflict conflict,
  ) async {
    final schedule = await _loadSchedule(conflict.scheduleId);
    if (schedule == null || schedule.timeslotId == null) return null;

    final rooms = await client.admin.getAllRooms(isActive: true);
    final timeslots = await client.admin.getAllTimeslots();

    final currentTimeslot = _findTimeslot(timeslots, schedule.timeslotId);
    if (currentTimeslot == null) return null;
    final currentRoom = rooms.where((r) => r.id == schedule.roomId).firstOrNull;

    final preferredRooms = rooms.where((r) => r.id != schedule.roomId).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    for (final room in preferredRooms) {
      final candidate = schedule.copyWith(
        roomId: room.id,
        room: room,
        updatedAt: DateTime.now(),
      );
      if (await _isValidCandidate(candidate)) {
        return _ResolutionSuggestion(
          title: 'Suggested Room Change',
          summary:
              'Move this class to ${room.name} while keeping the same day and time.',
          currentSlotLabel: _buildSlotLabel(
            timeslot: currentTimeslot,
            room: currentRoom,
          ),
          proposedSlotLabel: _buildSlotLabel(
            timeslot: currentTimeslot,
            room: room,
          ),
          updatedSchedule: candidate,
          successMessage:
              'Conflict resolved by moving the class to ${room.name}.',
        );
      }
    }

    return await _findTimeslotBasedSuggestion(
      schedule: schedule,
      timeslots: timeslots,
      rooms: rooms,
      title: 'Suggested Reschedule',
    );
  }

  Future<_ResolutionSuggestion?> _suggestTimeslotResolution(
    ScheduleConflict conflict,
  ) async {
    final schedule = await _loadSchedule(conflict.scheduleId);
    if (schedule == null || schedule.timeslotId == null) return null;

    final timeslots = await client.admin.getAllTimeslots();
    final rooms = await client.admin.getAllRooms(isActive: true);

    return await _findTimeslotBasedSuggestion(
      schedule: schedule,
      timeslots: timeslots,
      rooms: rooms,
      title: 'Suggested Time Change',
    );
  }

  Future<_ResolutionSuggestion?> _findTimeslotBasedSuggestion({
    required Schedule schedule,
    required List<Timeslot> timeslots,
    required List<Room> rooms,
    required String title,
  }) async {
    final currentTimeslot = _findTimeslot(timeslots, schedule.timeslotId);
    if (currentTimeslot == null) return null;

    final durationMinutes = _timeslotDurationMinutes(currentTimeslot);
    final candidateTimeslots =
        timeslots
            .where((t) => t.id != currentTimeslot.id)
            .where((t) => _timeslotDurationMinutes(t) == durationMinutes)
            .where((t) => !_overlapsLunch(t))
            .toList()
          ..sort((a, b) => _compareTimeslotCloseness(currentTimeslot, a, b));

    final roomOptions = <Room?>[
      rooms.where((r) => r.id == schedule.roomId).firstOrNull,
      ...rooms.where((r) => r.id != schedule.roomId),
    ].whereType<Room>().toList();
    final currentRoom = roomOptions.where((r) => r.id == schedule.roomId).firstOrNull;

    for (final timeslot in candidateTimeslots) {
      for (final room in roomOptions) {
        final candidate = schedule.copyWith(
          timeslotId: timeslot.id,
          timeslot: timeslot,
          roomId: room.id,
          room: room,
          updatedAt: DateTime.now(),
        );
        if (await _isValidCandidate(candidate)) {
          final summary = _buildSuggestionSummary(
            schedule: schedule,
            timeslot: timeslot,
            room: room,
          );
          return _ResolutionSuggestion(
            title: title,
            summary: summary,
            currentSlotLabel: _buildSlotLabel(
              timeslot: currentTimeslot,
              room: currentRoom,
            ),
            proposedSlotLabel: _buildSlotLabel(timeslot: timeslot, room: room),
            updatedSchedule: candidate,
            successMessage:
                'Conflict resolved by rescheduling to ${timeslot.day.name.toUpperCase()} ${_formatTimeslot(timeslot)}.',
          );
        }
      }
    }

    return null;
  }

  String _buildSuggestionSummary({
    required Schedule schedule,
    required Timeslot timeslot,
    required Room room,
  }) {
    final slotText =
        '${timeslot.day.name.toUpperCase()} ${_formatTimeslot(timeslot)}';
    final roomChanged = room.id != schedule.roomId;

    if (roomChanged) {
      return 'Move this class to $slotText in ${room.name}.';
    }

    return 'Move this class to $slotText and keep the same room.';
  }

  Future<Schedule?> _loadSchedule(int? scheduleId) async {
    if (scheduleId == null) return null;
    final schedules = await client.admin.getAllSchedules(isActive: true);
    try {
      return schedules.firstWhere((s) => s.id == scheduleId);
    } catch (_) {
      return null;
    }
  }

  Timeslot? _findTimeslot(List<Timeslot> timeslots, int? timeslotId) {
    if (timeslotId == null) return null;
    try {
      return timeslots.firstWhere((t) => t.id == timeslotId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isValidCandidate(Schedule candidate) async {
    final conflicts = await client.admin.validateSchedule(candidate);
    return conflicts.isEmpty;
  }

  int _timeslotDurationMinutes(Timeslot timeslot) {
    return _parseMinutes(timeslot.endTime) - _parseMinutes(timeslot.startTime);
  }

  int _parseMinutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  bool _overlapsLunch(Timeslot timeslot) {
    final start = _parseMinutes(timeslot.startTime);
    final end = _parseMinutes(timeslot.endTime);
    return start < (13 * 60) && end > (12 * 60);
  }

  int _compareTimeslotCloseness(
    Timeslot current,
    Timeslot a,
    Timeslot b,
  ) {
    final aDay = (a.day.index - current.day.index).abs();
    final bDay = (b.day.index - current.day.index).abs();
    if (aDay != bDay) return aDay.compareTo(bDay);

    final aStart =
        (_parseMinutes(a.startTime) - _parseMinutes(current.startTime)).abs();
    final bStart =
        (_parseMinutes(b.startTime) - _parseMinutes(current.startTime)).abs();
    return aStart.compareTo(bStart);
  }

  String _formatTimeslot(Timeslot timeslot) {
    return '${timeslot.startTime} - ${timeslot.endTime}';
  }

  String _buildSlotLabel({
    required Timeslot timeslot,
    required Room? room,
  }) {
    final roomLabel = room?.name ?? 'No room';
    return '${timeslot.day.name.toUpperCase()} ${_formatTimeslot(timeslot)} • $roomLabel';
  }

  Future<_ResolutionOption?> _showResolutionPlannerDialog({
    required ScheduleConflict conflict,
    required List<_ResolutionOption> options,
  }) {
    final config = _getConfig(conflict.type);
    final toolkit = _toolkitItemsForConflict(conflict);
    final initialSelectedIndex = options.indexWhere(
      (option) => option.recommendationLabel != null,
    );

    return showDialog<_ResolutionOption>(
      context: context,
      builder: (dialogContext) {
        var selectedIndex = initialSelectedIndex >= 0 ? initialSelectedIndex : 0;
        final isMobile = ResponsiveHelper.isMobile(dialogContext);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selected = options[selectedIndex];
            return AlertDialog(
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: isMobile ? 24 : 32,
              ),
              titlePadding: EdgeInsets.zero,
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Container(
                padding: EdgeInsets.all(isMobile ? 18 : 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF720045),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(config.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suggest Fix',
                            style: GoogleFonts.poppins(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            conflict.message,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.86),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: isMobile ? double.maxFinite : 680,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose how you want to resolve this conflict',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(options.length, (index) {
                        final option = options[index];
                        final isSelected = index == selectedIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setDialogState(() {
                              selectedIndex = index;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? config.color.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? config.color
                                      : Colors.grey.withValues(alpha: 0.25),
                                  width: isSelected ? 1.4 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Radio<int>(
                                    value: index,
                                    groupValue: selectedIndex,
                                    activeColor: config.color,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setDialogState(() {
                                        selectedIndex = value;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            Text(
                                              option.title,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (option.recommendationLabel != null)
                                              _buildConflictBadge(
                                                backgroundColor: config.color.withValues(
                                                  alpha: 0.12,
                                                ),
                                                text: option.recommendationLabel!,
                                                textColor: config.color,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.4,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          option.description,
                                          style: GoogleFonts.poppins(fontSize: 12),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          option.impactLabel,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey[700],
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
                      }),
                      const SizedBox(height: 14),
                      _buildResolutionPreviewCard(selected),
                      const SizedBox(height: 16),
                      _buildToolkitSection(config: config, items: toolkit),
                    ],
                  ),
                ),
              ),
              actionsPadding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                0,
                isMobile ? 16 : 24,
                isMobile ? 16 : 20,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF720045),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Continue', style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showManualResolutionDialog(ScheduleConflict conflict) async {
    final index = _manualResolutionIndex(conflict.type);
    final rootNavigator = Navigator.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Manual Resolution Needed',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'No safe automatic suggestion is available for this specific conflict yet. Would you like to open the related module and resolve it manually?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          if (index != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                rootNavigator.push(
                  MaterialPageRoute(
                    builder: (_) => AdminLayout(initialIndex: index),
                  ),
                );
              },
              child: Text('Open Module', style: GoogleFonts.poppins()),
            ),
        ],
      ),
    );
  }

  int? _manualResolutionIndex(String type) {
    switch (type) {
      case 'room_conflict':
      case 'faculty_conflict':
      case 'section_conflict':
      case 'generation_failed':
      case 'lab_start_time':
      case 'insufficient_block':
        return 5;
      case 'capacity_exceeded':
      case 'room_inactive':
      case 'room_type_mismatch':
        return 4;
      case 'program_mismatch':
        return 3;
      case 'max_load_exceeded':
      case 'faculty_unavailable':
        return 2;
      default:
        return null;
    }
  }

  Widget _buildResolutionPreviewCard(_ResolutionOption option) {
    final suggestion = option.suggestion;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF720045).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF720045).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How this fix works',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(option.description, style: GoogleFonts.poppins(fontSize: 12)),
          if (suggestion != null) ...[
            const SizedBox(height: 12),
            Text(
              'Current',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              suggestion.currentSlotLabel,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Text(
              'Proposed',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              suggestion.proposedSlotLabel,
              style: GoogleFonts.poppins(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolkitSection({
    required _ConflictTypeConfig config,
    required List<_ToolkitItem> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handyman_rounded, size: 18, color: config.color),
              const SizedBox(width: 8),
              Text(
                'Fix Toolkit',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: config.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, size: 16, color: config.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.description,
                          style: GoogleFonts.poppins(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ToolkitItem> _toolkitItemsForConflict(ScheduleConflict conflict) {
    switch (conflict.type) {
      case 'max_load_exceeded':
        return const [
          _ToolkitItem(
            icon: Icons.scale_rounded,
            title: 'Compare assigned units against policy',
            description:
                'Check whether the overload is temporary, approved, or caused by duplicate assignments.',
          ),
          _ToolkitItem(
            icon: Icons.swap_horiz_rounded,
            title: 'Rebalance faculty assignments',
            description:
                'Move one or more subjects to another qualified faculty member if the max load should stay fixed.',
          ),
          _ToolkitItem(
            icon: Icons.edit_note_rounded,
            title: 'Update max load only when justified',
            description:
                'Raise the max load only if the department approved the change.',
          ),
        ];
      case 'room_conflict':
      case 'capacity_exceeded':
      case 'room_inactive':
      case 'program_mismatch':
      case 'room_type_mismatch':
        return const [
          _ToolkitItem(
            icon: Icons.meeting_room_rounded,
            title: 'Validate room compatibility',
            description:
                'Check room type, active status, capacity, and program fit before moving the class.',
          ),
          _ToolkitItem(
            icon: Icons.schedule_rounded,
            title: 'Preserve the current timeslot when possible',
            description:
                'A room change is usually less disruptive than moving the class to another day or time.',
          ),
          _ToolkitItem(
            icon: Icons.groups_rounded,
            title: 'Verify section demand',
            description:
                'Make sure the destination room still supports the enrolled section and subject needs.',
          ),
        ];
      default:
        return const [
          _ToolkitItem(
            icon: Icons.fact_check_rounded,
            title: 'Review linked schedules first',
            description:
                'Confirm which faculty, room, section, and timeslot records are colliding before changing anything.',
          ),
          _ToolkitItem(
            icon: Icons.event_available_rounded,
            title: 'Choose the least disruptive open slot',
            description:
                'Prefer nearby timeslots that preserve duration and avoid breaking other assignments.',
          ),
          _ToolkitItem(
            icon: Icons.rule_rounded,
            title: 'Revalidate after every change',
            description:
                'Run conflict checking again after edits to confirm the fix did not create a new issue.',
          ),
        ];
    }
  }
}

/// Internal config for conflict type display.
class _ConflictTypeConfig {
  final String label;
  final String source;
  final IconData icon;
  final Color color;
  final String severity;

  const _ConflictTypeConfig({
    required this.label,
    required this.source,
    required this.icon,
    required this.color,
    required this.severity,
  });
}

class _ResolutionSuggestion {
  final String title;
  final String summary;
  final String currentSlotLabel;
  final String proposedSlotLabel;
  final Schedule updatedSchedule;
  final String successMessage;

  const _ResolutionSuggestion({
    required this.title,
    required this.summary,
    required this.currentSlotLabel,
    required this.proposedSlotLabel,
    required this.updatedSchedule,
    required this.successMessage,
  });
}

enum _ResolutionOptionKind { autoApply, openFacultyEdit, openModule }

class _ResolutionOption {
  final _ResolutionOptionKind kind;
  final String title;
  final String description;
  final String impactLabel;
  final String? recommendationLabel;
  final _ResolutionSuggestion? suggestion;
  final int? moduleIndex;

  const _ResolutionOption({
    required this.kind,
    required this.title,
    required this.description,
    required this.impactLabel,
    this.recommendationLabel,
    this.suggestion,
    this.moduleIndex,
  });
}

class _ToolkitItem {
  final IconData icon;
  final String title;
  final String description;

  const _ToolkitItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
