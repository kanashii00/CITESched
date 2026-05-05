import 'package:citesched_client/citesched_client.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FacultyLoadChart extends StatelessWidget {
  final List<FacultyLoadData> data;

  const FacultyLoadChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) => _buildChart(context);

  Widget _buildChart(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ??
        (isDark ? const Color(0xFFE2E8F0) : Colors.black);
    final axisColor = isDark ? Colors.white70 : Colors.black;
    final gridColor =
        isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05);
    final barColor = isDark ? const Color(0xFFE2E8F0) : Colors.black;
    final barBgColor =
        isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03);
    const warningColor = Color(0xFFDC2626);
    final peakLoad = data.fold<double>(
      0,
      (maxValue, item) => item.currentLoad > maxValue ? item.currentLoad : maxValue,
    );
    final peakCapacity = data.fold<double>(
      0,
      (maxValue, item) => item.maxLoad > maxValue ? item.maxLoad.toDouble() : maxValue,
    );
    final chartCeilingBase = peakLoad > peakCapacity ? peakLoad : peakCapacity;
    final chartMaxY = (chartCeilingBase + 3).clamp(10, 60).toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY,
        minY: 0,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.black,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = data[group.x.toInt()];
              final isOverloaded = item.currentLoad > item.maxLoad;
              return BarTooltipItem(
                '${item.currentLoad.toStringAsFixed(1)} / ${item.maxLoad} units'
                '${isOverloaded ? '\nOver max load' : ''}',
                GoogleFonts.poppins(
                  color: isOverloaded ? warningColor : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 10 : 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isMobile ? 60 : 50,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: isMobile ? 4 : 10,
                    angle: isMobile ? -0.5 : -0.2, // Steeper rotation on mobile
                    child: Text(
                      data[value.toInt()].facultyName,
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontSize: isMobile ? 8 : 10,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: isMobile ? 30 : 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: isMobile ? 9 : 11,
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                final item = data[index];
                if (item.currentLoad <= item.maxLoad) {
                  return const SizedBox.shrink();
                }
                return const SideTitleWidget(
                  axisSide: AxisSide.top,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: warningColor,
                    size: 18,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: gridColor,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: axisColor.withValues(alpha: 0.1), width: 1),
            left: BorderSide(color: axisColor.withValues(alpha: 0.1), width: 1),
          ),
        ),
        barGroups: data.asMap().entries.map((entry) {
          final isOverloaded = entry.value.currentLoad > entry.value.maxLoad;
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.currentLoad,
                color: barColor,
                width: isMobile ? 12 : 22,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                borderSide: BorderSide(
                  color: isOverloaded ? warningColor : Colors.transparent,
                  width: isOverloaded ? 2.2 : 0,
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: entry.value.maxLoad.toDouble(),
                  color: barBgColor,
                ),
              ),
            ],
            showingTooltipIndicators: isOverloaded ? const [0] : const [],
          );
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 250),
    );
  }
}
