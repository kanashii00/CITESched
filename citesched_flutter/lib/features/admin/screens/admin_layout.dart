import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/core/theme/design_system.dart';
import 'package:citesched_flutter/features/admin/screens/admin_dashboard_screen.dart';
import 'package:citesched_flutter/features/admin/screens/faculty_management_screen.dart';
import 'package:citesched_flutter/features/admin/screens/faculty_loading_screen.dart';
import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/features/admin/screens/subject_management_screen.dart';
import 'package:citesched_flutter/features/admin/screens/room_management_screen.dart';
import 'package:citesched_flutter/features/admin/screens/timetable_screen.dart';
import 'package:citesched_flutter/features/admin/screens/conflict_screen.dart';
import 'package:citesched_flutter/features/admin/screens/report_screen.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_sidebar.dart';
import 'package:citesched_flutter/core/widgets/app_header.dart';
import 'package:citesched_flutter/core/widgets/draggable_fab.dart';
import 'package:citesched_flutter/core/widgets/nlp_query_dialog.dart';
import 'package:flutter/material.dart';

class AdminLayout extends StatefulWidget {
  final int initialIndex;
  final Schedule? initialEditSchedule;
  final int? initialFacultyIdToEdit;

  const AdminLayout({
    super.key,
    this.initialIndex = 0,
    this.initialEditSchedule,
    this.initialFacultyIdToEdit,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  late int _selectedIndex;

  final List<String> _titles = [
    'Dashboard',
    'Faculty Management',
    'Faculty Loading',
    'Subject Management',
    'Room Management',
    'Timetable',
    'Conflicts',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final screens = [
      const AdminDashboardScreen(),
      FacultyManagementScreen(
        targetFacultyId: widget.initialFacultyIdToEdit,
      ),
      FacultyLoadingScreen(
        initialEditSchedule: widget.initialEditSchedule,
      ),
      const SubjectManagementScreen(),
      const RoomManagementScreen(),
      const TimetableScreen(),
      const ConflictScreen(),
      const ReportScreen(),
    ];

    final scaffold = Scaffold(
      backgroundColor: DesignSystem.backgroundColor,
      appBar: !isDesktop
          ? AppHeader(
              title: _titles[_selectedIndex],
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            )
          : null,
      drawer: !isDesktop
          ? Drawer(
              width: 260,
              backgroundColor: DesignSystem.headerColor,
              child: AdminSidebar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop)
            AdminSidebar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          Expanded(child: screens[_selectedIndex]),
        ],
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
}
//Testing Github Workflow Automation
