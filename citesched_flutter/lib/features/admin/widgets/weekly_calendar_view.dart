import 'package:citesched_client/citesched_client.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarViewCard extends StatelessWidget {
  final String title;
  final Color maroonColor;
  final Color cardBg;
  final bool isDark;
  final double calendarHeight;
  final VoidCallback? onFullScreen;
  final Widget child;

  const CalendarViewCard({
    super.key,
    required this.title,
    required this.maroonColor,
    required this.cardBg,
    required this.isDark,
    required this.calendarHeight,
    required this.child,
    this.onFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SizedBox(
      width: double.infinity,
      height: calendarHeight,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.calendar_view_week_rounded, color: maroonColor),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onFullScreen != null)
                  TextButton.icon(
                    onPressed: onFullScreen,
                    icon: const Icon(Icons.fullscreen_rounded),
                    label: Text(
                      'Full Screen',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class WeeklyCalendarView extends StatefulWidget {
  final List<ScheduleInfo> schedules;
  final List<FacultyAvailability>? availabilities;
  final Function(Schedule)? onEdit;
  final Color maroonColor;
  final bool isInstructorView;
  final Faculty? selectedFaculty;
  final bool isStudentView;
  final double dayWidth;

  const WeeklyCalendarView({
    super.key,
    required this.schedules,
    required this.maroonColor,
    this.availabilities,
    this.isInstructorView = false,
    this.selectedFaculty,
    this.onEdit,
    this.isStudentView = false,
    this.dayWidth = 150,
  });

  @override
  State<WeeklyCalendarView> createState() => _WeeklyCalendarViewState();
}

class _WeeklyCalendarViewState extends State<WeeklyCalendarView> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  static const String _lunchLabel = 'LUNCH TIME';
  static const Color _lectureFillColor = Color(0xFF0B5D2A);
  static const Color _lectureBorderColor = Color(0xFF16A34A);
  static const Color _laboratoryFillColor = Color(0xFF0B3A82);
  static const Color _laboratoryBorderColor = Color(0xFF2563EB);

  List<ScheduleInfo> get schedules => widget.schedules;
  List<FacultyAvailability>? get availabilities => widget.availabilities;
  Function(Schedule)? get onEdit => widget.onEdit;
  Color get maroonColor => widget.maroonColor;
  bool get isInstructorView => widget.isInstructorView;
  Faculty? get selectedFaculty => widget.selectedFaculty;
  bool get isStudentView => widget.isStudentView;
  double get dayWidth => widget.dayWidth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToEarliestSchedule();
    });
  }

  @override
  void didUpdateWidget(covariant WeeklyCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.schedules != widget.schedules) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToEarliestSchedule();
      });
    }
  }

  void _jumpToEarliestSchedule() {
    if (!_verticalController.hasClients) return;
    const int startHour = 7;
    final withTimeslot = schedules
        .where((s) => s.schedule.timeslot != null)
        .toList();
    if (withTimeslot.isEmpty) return;
    final earliest = withTimeslot
        .map((s) => _parseTime(s.schedule.timeslot!.startTime))
        .reduce((a, b) {
          final aMin = a.hour * 60 + a.minute;
          final bMin = b.hour * 60 + b.minute;
          return aMin <= bMin ? a : b;
        });
    final hourHeight = isStudentView ? 64.0 : 100.0;
    final target =
        ((earliest.hour - startHour - 1).clamp(0, 24) +
            (earliest.minute / 60.0)) *
        hourHeight;
    _verticalController.jumpTo(
      target.clamp(0.0, _verticalController.position.maxScrollExtent),
    );
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gridColor = isDark ? Colors.white12 : Colors.black12;

    // Config
    final double hourHeight = isStudentView ? 64.0 : 100.0;
    const int startHour = 7;
    const int endHour = 21; // 7AM–9PM
    final List<DayOfWeek> days = [
      DayOfWeek.mon,
      DayOfWeek.tue,
      DayOfWeek.wed,
      DayOfWeek.thu,
      DayOfWeek.fri,
      DayOfWeek.sat,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const headerHeight = 40.0;
        const legendHeight = 30.0;
        const headerSpacing = 8.0;
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0.0;
        final stretchedDayWidth = availableWidth > 80
            ? ((availableWidth - 80) / days.length)
            : dayWidth;
        final effectiveDayWidth = stretchedDayWidth > dayWidth
            ? stretchedDayWidth
            : dayWidth;
        final totalWidth = 80 + (effectiveDayWidth * days.length);
        final fullGridHeight = hourHeight * (endHour - startHour + 1);
        final hasBoundedHeight = constraints.maxHeight.isFinite;
        final availableHeight = hasBoundedHeight
            ? constraints.maxHeight
            : fullGridHeight + headerHeight + legendHeight + headerSpacing;
        final reservedHeight = headerHeight + legendHeight + headerSpacing;
        final gridViewportHeight = hasBoundedHeight
            ? (availableHeight - reservedHeight).clamp(0.0, double.infinity)
            : fullGridHeight;

        return SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            height: hasBoundedHeight ? availableHeight : null,
            child: Column(
              children: [
                _buildLegendRow(),
                const SizedBox(height: headerSpacing),
                _buildDayHeaderRow(days, effectiveDayWidth, gridColor),
                SizedBox(
                  height: gridViewportHeight,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      width: totalWidth,
                      height: fullGridHeight,
                      child: Stack(
                        children: [
                          // 1. Grid Background (no headers)
                          _buildGrid(
                            context,
                            days,
                            startHour,
                            endHour,
                            hourHeight,
                            effectiveDayWidth,
                            gridColor,
                          ),

                          // 1.5 Lunch Time Cardbox (shared across admin, faculty, and student views)
                          _buildLunchCardbox(
                            days,
                            startHour,
                            endHour,
                            hourHeight,
                            effectiveDayWidth,
                          ),

                          // 2. Preference Cardboxes (High Visibility Black/Faded Highlight)
                          if (availabilities != null)
                            ...availabilities!
                                .where((a) => a.isPreferred)
                                .map(
                                  (avail) => _buildPreferenceCardbox(
                                    avail,
                                    days,
                                    startHour,
                                    hourHeight,
                                    effectiveDayWidth,
                                  ),
                                ),

                          // 3. Shift Preference Watermarks (Faded vertical labels)
                          if (selectedFaculty != null && availabilities == null)
                            ...days.map(
                              (day) => _buildShiftWatermark(
                                day,
                                days,
                                startHour,
                                hourHeight,
                                effectiveDayWidth,
                              ),
                            ),

                          // 4. Schedule Blocks
                          ...schedules.map(
                            (info) => _buildScheduleBlock(
                              context,
                              info,
                              days,
                              startHour,
                              hourHeight,
                              effectiveDayWidth,
                            ),
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
      },
    );
  }

  Widget _buildDayHeaderRow(
    List<DayOfWeek> days,
    double dayWidth,
    Color gridColor,
  ) {
    return Row(
      children: [
        const SizedBox(width: 80),
        ...days.map(
          (day) => Container(
            width: dayWidth,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isDayHighlighted(day)
                  ? maroonColor.withValues(alpha: 0.1)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(color: gridColor),
                left: BorderSide(color: gridColor),
              ),
            ),
            child: Text(
              _getDayName(day),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _isDayHighlighted(day) ? maroonColor : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendRow() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildLegendChip(
            label: 'LECTURE',
            fillColor: _lectureFillColor,
            borderColor: _lectureBorderColor,
          ),
          _buildLegendChip(
            label: 'LABORATORY',
            fillColor: _laboratoryFillColor,
            borderColor: _laboratoryBorderColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip({
    required String label,
    required Color fillColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: borderColor, width: 1.2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF334155),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<DayOfWeek> days,
    int startHour,
    int endHour,
    double hourHeight,
    double dayWidth,
    Color gridColor,
  ) {
    final prefRange = _getPreferenceRange();

    return Column(
      children: [
        // Time Rows
        Expanded(
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: endHour - startHour + 1,
            itemBuilder: (context, index) {
              final hour = startHour + index;
              final isPreferredTime =
                  prefRange != null &&
                  hour >= prefRange.start &&
                  hour < prefRange.end;

              return Container(
                height: hourHeight,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: gridColor)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      alignment: Alignment.topCenter,
                      padding: const EdgeInsets.all(4),
                      decoration: isPreferredTime
                          ? const BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                            )
                          : null,
                      child: Column(
                        children: [
                          Text(
                            _formatHour(hour),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isPreferredTime
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                          if (isPreferredTime)
                            Text(
                              'PREF',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...days.map(
                      (day) => Container(
                        width: dayWidth,
                        decoration: BoxDecoration(
                          color: _gridCellColor(
                            day,
                            hour,
                            isPreferredTime,
                          ),
                          border: Border(left: BorderSide(color: gridColor)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  _PreferenceRange? _getPreferenceRange() {
    if (selectedFaculty == null) return null;

    final shift = selectedFaculty!.shiftPreference;
    if (shift == null) return null;

    switch (shift) {
      case FacultyShiftPreference.morning:
        return _PreferenceRange(7, 12);
      case FacultyShiftPreference.afternoon:
        return _PreferenceRange(13, 18);
      case FacultyShiftPreference.evening:
        return _PreferenceRange(18, 21);
      case FacultyShiftPreference.any:
        return _PreferenceRange(7, 21);
      case FacultyShiftPreference.custom:
        if (selectedFaculty!.preferredHours == null) return null;
        return _parseCustomHours(selectedFaculty!.preferredHours!);
    }
  }

  _PreferenceRange? _parseCustomHours(String hours) {
    try {
      // Expected format: "7:00 AM - 12:00 PM"
      final parts = hours.split('-');
      if (parts.length != 2) return null;

      final startStr = parts[0].trim();
      final endStr = parts[1].trim();

      final startTime = _parseTimeString(startStr);
      final endTime = _parseTimeString(endStr);

      return _PreferenceRange(
        startTime.hour,
        endTime.hour + (endTime.minute > 0 ? 1 : 0),
      );
    } catch (e) {
      debugPrint('Error parsing custom hours: $e');
      return null;
    }
  }

  TimeOfDay _parseTimeString(String timeStr) {
    // Format: "7:00 AM" or "12:00 PM"
    final timeParts = timeStr.split(' ');
    final amPm = timeParts[1].toUpperCase();
    final parts = timeParts[0].split(':');

    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);

    if (amPm == 'PM' && hour != 12) hour += 12;
    if (amPm == 'AM' && hour == 12) hour = 0;

    return TimeOfDay(hour: hour, minute: minute);
  }

  Widget _buildPreferenceCardbox(
    FacultyAvailability avail,
    List<DayOfWeek> days,
    int startHour,
    double hourHeight,
    double dayWidth,
  ) {
    final dayIndex = days.indexOf(avail.dayOfWeek);
    if (dayIndex == -1) return const SizedBox.shrink();

    final start = _parseTime(avail.startTime);
    final end = _parseTime(avail.endTime);
    final isLunchSlot =
        start.hour == 12 &&
        start.minute == 0 &&
        end.hour == 13 &&
        end.minute == 0;

    final double top =
        (start.hour - startHour + start.minute / 60.0) * hourHeight;
    final double height =
        (end.hour - start.hour + (end.minute - start.minute) / 60.0) *
        hourHeight;
    final double left = 80 + (dayIndex * dayWidth);

    return Positioned(
      top: top + 2,
      left: left + 4,
      width: dayWidth - 8,
      height: height - 4,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.2),
              width: 2.5,
              style: BorderStyle
                  .none, // Dashed look via custom painter? No, just use a solid faded border for now
            ),
          ),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.stars_rounded,
                    size: 22,
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLunchSlot
                        ? _lunchLabel
                        : _buildAssignedSlotLabel(avail, start, end),
                    textAlign: TextAlign.center,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isLunchSlot
                          ? Colors.black54
                          : Colors.black.withValues(alpha: 0.65),
                      letterSpacing: 0.2,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftWatermark(
    DayOfWeek day,
    List<DayOfWeek> days,
    int startHour,
    double hourHeight,
    double dayWidth,
  ) {
    final prefRange = _getPreferenceRange();
    if (prefRange == null) return const SizedBox.shrink();

    final dayIndex = days.indexOf(day);
    final double top = (prefRange.start - startHour) * hourHeight;
    final double height = (prefRange.end - prefRange.start) * hourHeight;
    final double left = 80 + (dayIndex * dayWidth);

    // Build label
    String shiftLabel = '';
    String timeRange = '';
    switch (selectedFaculty?.shiftPreference) {
      case FacultyShiftPreference.morning:
        shiftLabel = 'Morning';
        timeRange = '7AM – 12PM';
        break;
      case FacultyShiftPreference.afternoon:
        shiftLabel = 'Afternoon';
        timeRange = '1PM – 6PM';
        break;
      case FacultyShiftPreference.evening:
        shiftLabel = 'Evening';
        timeRange = '6PM – 9PM';
        break;
      case FacultyShiftPreference.any:
        shiftLabel = 'Any Shift';
        timeRange = 'Flexible';
        break;
      case FacultyShiftPreference.custom:
        shiftLabel = 'Custom';
        timeRange = selectedFaculty?.preferredHours ?? '';
        break;
      default:
        break;
    }

    return Positioned(
      top: top + 4,
      left: left + 4,
      width: dayWidth - 8,
      height: height - 8,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: maroonColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: maroonColor.withValues(alpha: 0.35),
              width: 2.0,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.stars_rounded,
                size: 20,
                color: maroonColor.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 6),
              Text(
                'PREFERRED',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: maroonColor.withValues(alpha: 0.8),
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                shiftLabel.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: maroonColor.withValues(alpha: 0.6),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (timeRange.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: maroonColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    timeRange,
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: maroonColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleBlock(
    BuildContext context,
    ScheduleInfo info,
    List<DayOfWeek> days,
    int startHour,
    double hourHeight,
    double dayWidth,
  ) {
    final schedule = info.schedule;
    final timeslot = schedule.timeslot;
    if (timeslot == null) return const SizedBox.shrink();

    final dayIndex = days.indexOf(timeslot.day);
    if (dayIndex == -1) return const SizedBox.shrink();

    final startTime = _parseTime(timeslot.startTime);
    final hoursOverride = schedule.hours;
    final endTime = hoursOverride != null && hoursOverride > 0
        ? _addHours(startTime, hoursOverride)
        : _parseTime(timeslot.endTime);

    final double top =
        (startTime.hour - startHour + startTime.minute / 60.0) * hourHeight;
    final double height =
        (endTime.hour -
            startTime.hour +
            (endTime.minute - startTime.minute) / 60.0) *
        hourHeight;
    final double left = 80 + (dayIndex * dayWidth);

    final bool hasAvailabilityViolation = _isOutsidePreferredAvailability(
      schedule,
    );
    final bool hasConflict =
        info.conflicts.isNotEmpty || hasAvailabilityViolation;
    final bool isLunchSlot = _isLunchSlot(schedule, timeslot);
    final loadTypes = schedule.loadTypes ?? schedule.subject?.types ?? const [];
    final classType = _classTypeLabel(
      loadTypes,
      schedule.room?.name,
    );

    // Styles
    final Color typeFillColor = classType == 'LAB'
        ? _laboratoryFillColor
        : _lectureFillColor;
    final Color blockColor = _blockFillColor(
      hasConflict: hasConflict,
      typeFillColor: typeFillColor,
    );

    final Color typeOutlineColor = classType == 'LAB'
        ? _laboratoryBorderColor
        : _lectureBorderColor;

    final Color borderColor = _blockBorderColor(
      hasConflict: hasConflict,
      typeOutlineColor: typeOutlineColor,
    );

    return Positioned(
      top: top + 2,
      left: left + 4,
      width: dayWidth - 8,
      height: height - 4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showScheduleDetails(context, info),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: blockColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: hasConflict ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLunchSlot) ...[
                  Expanded(
                    child: Center(
                      child: Text(
                        _lunchLabel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: _buildStandardCardContent(
                      schedule: schedule,
                      timeRange:
                          '${_formatTimeOfDay(startTime)} - ${_formatTimeOfDay(endTime)}',
                      classType: classType,
                      hasConflict: hasConflict,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLunchCardbox(
    List<DayOfWeek> days,
    int startHour,
    int endHour,
    double hourHeight,
    double dayWidth,
  ) {
    const lunchStartHour = 12;
    const lunchEndHour = 13;
    if (lunchStartHour < startHour || lunchEndHour > endHour + 1) {
      return const SizedBox.shrink();
    }

    final double top = (lunchStartHour - startHour) * hourHeight + 2;
    final double height = (lunchEndHour - lunchStartHour) * hourHeight - 4;
    const double left = 80 + 4;
    final double width = (dayWidth * days.length) - 8;

    return Positioned(
      top: top,
      left: left,
      width: width,
      height: height,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              _lunchLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black.withValues(alpha: 0.55),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _gridCellColor(
    DayOfWeek day,
    int hour,
    bool isPreferredTime,
  ) {
    if (isPreferredTime) {
      return Colors.black.withValues(alpha: 0.04);
    }
    if (_isDayHighlighted(day) && _isTimeHighlighted(hour)) {
      return maroonColor.withValues(alpha: 0.03);
    }
    return Colors.transparent;
  }

  Color _blockFillColor({
    required bool hasConflict,
    required Color typeFillColor,
  }) {
    if (hasConflict) return const Color(0xFF2D0000);
    return typeFillColor;
  }

  Color _blockBorderColor({
    required bool hasConflict,
    required Color typeOutlineColor,
  }) {
    if (hasConflict) return Colors.red.shade400;
    return typeOutlineColor;
  }

  bool _isLunchSlot(Schedule schedule, Timeslot timeslot) {
    final code = schedule.subject?.code.toLowerCase() ?? '';
    final name = schedule.subject?.name.toLowerCase() ?? '';
    if (code.contains('lunch') || name.contains('lunch')) return true;

    final start = _parseTime(timeslot.startTime);
    final end = _parseTime(timeslot.endTime);
    return start.hour == 12 &&
        start.minute == 0 &&
        end.hour == 13 &&
        end.minute == 0;
  }

  TimeOfDay _addHours(TimeOfDay start, double hours) {
    final totalMinutes =
        (start.hour * 60 + start.minute) + (hours * 60).round();
    final clamped = totalMinutes.clamp(0, 24 * 60 - 1);
    final h = clamped ~/ 60;
    final m = clamped % 60;
    return TimeOfDay(hour: h, minute: m);
  }

  String _classTypeLabel(List<SubjectType> types, String? roomName) {
    final hasLecture = types.contains(SubjectType.lecture);
    final hasLab = types.contains(SubjectType.laboratory);
    if (roomName != null) {
      final normalized = roomName.trim().toUpperCase();
      if (normalized.contains('LAB')) return 'LAB';
    }
    if (hasLab && !hasLecture) return 'LAB';
    if (hasLecture && !hasLab) return 'LECTURE';
    // If mixed or blended, choose a single label (default to Lecture).
    return 'LECTURE';
  }

  Widget _buildStandardCardContent({
    required Schedule schedule,
    required String timeRange,
    required String classType,
    required bool hasConflict,
  }) {
    final subj = schedule.subject;
    final faculty = schedule.faculty?.name ?? 'TBA';
    final room = (schedule.room?.name ?? 'Room TBA').toUpperCase();
    final subjectLine = [
      if (subj?.code != null && subj!.code.isNotEmpty) subj.code,
      if (subj?.name != null && subj!.name.isNotEmpty) subj.name,
    ].join(' - ');

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final isTiny = availableHeight <= 56;
        final isCompact = availableHeight <= 88;
        final showFaculty = !isTiny;
        final showSubject = availableHeight > 68;
        final showSection = availableHeight > 96;
        final showRoom = availableHeight > 112;

        return ClipRect(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  timeRange,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: isTiny ? 12 : 15,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!isTiny) const SizedBox(height: 2),
              if (!isTiny)
                Text(
                  classType,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 10 : 12,
                    color: Colors.white70,
                    letterSpacing: 0.8,
                  ),
                ),
              if (!isTiny) SizedBox(height: isCompact ? 2 : 4),
              if (showFaculty || showSubject || showSection || showRoom)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showFaculty)
                        Text(
                          faculty,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: isCompact ? 12 : 15,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      if (showSubject)
                        Text(
                          subjectLine.isEmpty ? 'Subject TBA' : subjectLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: isCompact ? 10 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.0,
                          ),
                        ),
                      if (showSection)
                        Text(
                          'Section: ${schedule.section}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white70,
                            height: 1.0,
                          ),
                        ),
                      if (showRoom)
                        Text(
                          'Room: $room',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white70,
                            height: 1.0,
                          ),
                        ),
                    ],
                  ),
                ),
              if (hasConflict && !isTiny)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: Colors.red[300],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showScheduleDetails(BuildContext context, ScheduleInfo info) {
    final schedule = info.schedule;
    final hasConflict = info.conflicts.isNotEmpty;
    final hasAvailabilityViolation = _isOutsidePreferredAvailability(schedule);
    final shouldShowConflict = hasConflict || hasAvailabilityViolation;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              shouldShowConflict ? Icons.warning_rounded : Icons.event_note,
              color: shouldShowConflict ? Colors.red : maroonColor,
            ),
            const SizedBox(width: 12),
            const Text('Schedule Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem('Subject', schedule.subject?.name ?? 'N/A'),
            _buildDetailItem('Code', schedule.subject?.code ?? 'N/A'),
            _buildDetailItem(
              'Instructor',
              schedule.faculty?.name ?? 'Unassigned',
            ),
            _buildDetailItem('Room', schedule.room?.name ?? 'N/A'),
            _buildDetailItem('Section', schedule.section),
            _buildDetailItem(
              'Year Level',
              schedule.subject?.yearLevel?.toString() ?? 'N/A',
            ),
            _buildDetailItem(
              'Time',
              '${schedule.timeslot?.day.name.toUpperCase()} ${schedule.timeslot?.startTime} - ${schedule.timeslot?.endTime}',
            ),
            if (shouldShowConflict) ...[
              const Divider(height: 24),
              Text(
                'CONFLICT DETECTED:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              ...info.conflicts.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• ${c.message}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.red[800],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (onEdit != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onEdit?.call(schedule);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: maroonColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Edit Schedule'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  bool _isDayHighlighted(DayOfWeek day) {
    if (!isInstructorView) return false;
    return schedules.any((s) => s.schedule.timeslot?.day == day);
  }

  bool _isTimeHighlighted(int hour) {
    if (!isInstructorView) return false;
    return schedules.any((s) {
      final ts = s.schedule.timeslot;
      if (ts == null) return false;
      final start = _parseTime(ts.startTime);
      final end = _parseTime(ts.endTime);
      return hour >= start.hour && hour < end.hour;
    });
  }

  bool _isOutsidePreferredAvailability(Schedule schedule) {
    if (availabilities == null) return false;
    final preferred = availabilities!.where((a) => a.isPreferred).toList();
    if (preferred.isEmpty) return false;
    final timeslot = schedule.timeslot;
    if (timeslot == null) return false;

    final tsStart = _parseTime(timeslot.startTime);
    final tsEnd = _parseTime(timeslot.endTime);
    final tsStartMinutes = tsStart.hour * 60 + tsStart.minute;
    final tsEndMinutes = tsEnd.hour * 60 + tsEnd.minute;

    for (final a in preferred) {
      if (a.dayOfWeek != timeslot.day) continue;
      final aStart = _parseTime(a.startTime);
      final aEnd = _parseTime(a.endTime);
      final aStartMinutes = aStart.hour * 60 + aStart.minute;
      final aEndMinutes = aEnd.hour * 60 + aEnd.minute;
      if (tsStartMinutes >= aStartMinutes && tsEndMinutes <= aEndMinutes) {
        return false;
      }
    }

    return true;
  }

  TimeOfDay _parseTime(String time) {
    final raw = time.trim().toUpperCase();
    if (raw.isEmpty) return const TimeOfDay(hour: 0, minute: 0);

    final ampmMatch = RegExp(r'([AP]M)$').firstMatch(raw);
    String value = raw;
    String? suffix;
    if (ampmMatch != null) {
      suffix = ampmMatch.group(1);
      value = raw.substring(0, ampmMatch.start).trim();
    }

    final parts = value.split(':');
    int hour = int.tryParse(parts.first) ?? 0;
    int minute = 0;
    if (parts.length > 1) {
      minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    if (suffix == 'PM' && hour < 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;

    hour = hour.clamp(0, 23);
    minute = minute.clamp(0, 59);
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _buildAssignedSlotLabel(
    FacultyAvailability avail,
    TimeOfDay prefStart,
    TimeOfDay prefEnd,
  ) {
    final prefStartMinutes = prefStart.hour * 60 + prefStart.minute;
    final prefEndMinutes = prefEnd.hour * 60 + prefEnd.minute;

    for (final info in schedules) {
      final ts = info.schedule.timeslot;
      if (ts == null) continue;
      if (ts.day != avail.dayOfWeek) continue;

      final tsStart = _parseTime(ts.startTime);
      final tsEnd = _parseTime(ts.endTime);
      final tsStartMinutes = tsStart.hour * 60 + tsStart.minute;
      final tsEndMinutes = tsEnd.hour * 60 + tsEnd.minute;

      final overlaps =
          tsStartMinutes < prefEndMinutes && tsEndMinutes > prefStartMinutes;
      if (!overlaps) {
        continue;
      }

      final timeLabel =
          '${_formatTimeOfDay(tsStart)} - ${_formatTimeOfDay(tsEnd)}';
      final dayLabel = _getDayName(avail.dayOfWeek);
      final facultyName =
          info.schedule.faculty?.name ?? selectedFaculty?.name ?? '';
      final subjectCode = info.schedule.subject?.code ?? '';
      final subjectName = info.schedule.subject?.name ?? '';
      final subjectLine = [
        subjectCode,
        subjectName,
      ].where((s) => s.trim().isNotEmpty).join(' – ');

      return [
        '$dayLabel $timeLabel',
        facultyName,
        subjectLine,
      ].where((s) => s.trim().isNotEmpty).join('\n');
    }

    final dayLabel = _getDayName(avail.dayOfWeek);
    final timeLabel =
        '${_formatTimeOfDay(prefStart)} - ${_formatTimeOfDay(prefEnd)}';
    final facultyName = selectedFaculty?.name ?? 'Instructor';
    return [
      '$dayLabel $timeLabel',
      facultyName,
      'No subject assigned',
    ].join('\n');
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  String _getDayName(DayOfWeek day) {
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
}

class _PreferenceRange {
  final int start;
  final int end;
  _PreferenceRange(this.start, this.end);
}
//testing
