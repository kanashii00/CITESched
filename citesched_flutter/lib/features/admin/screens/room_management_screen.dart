import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'room_details_screen.dart';
import 'package:citesched_flutter/core/utils/responsive_helper.dart';
import 'package:citesched_flutter/features/admin/widgets/admin_header_container.dart';
import 'package:citesched_flutter/core/providers/conflict_provider.dart';

import 'package:citesched_flutter/core/providers/admin_providers.dart';
import 'package:citesched_flutter/core/utils/error_handler.dart';

const String kDeletePermanentlyLabel = 'Delete Permanently';
const String kAddNewRoomLabel = 'Add New Room';
const String kRoomNameLabel = 'Room Name';
const String kSavingLabel = 'Saving...';
const List<Program> kRoomProgramOptions = [
  Program.it,
  Program.emc,
  Program.both,
];

String _roomProgramLabel(Program program) {
  switch (program) {
    case Program.it:
      return 'IT';
    case Program.emc:
      return 'EMC';
    case Program.both:
      return 'Both IT and EMC';
  }
}

String _normalizeRoomCatalogName(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
}

bool _roomNameLooksLikeLab(String value) {
  final normalizedName = _normalizeRoomCatalogName(value);
  return normalizedName.contains('LAB');
}

List<RoomType> _allowedRoomTypesForName(String roomName) {
  if (_roomNameLooksLikeLab(roomName)) {
    return const [RoomType.laboratory, RoomType.lecture];
  }
  return const [RoomType.lecture, RoomType.laboratory];
}

String? _validateRoomCatalogInput({
  required String roomName,
}) {
  final normalizedName = _normalizeRoomCatalogName(roomName);
  if (normalizedName.isEmpty) {
    return 'Room name is required.';
  }

  return null;
}

class RoomManagementScreen extends ConsumerStatefulWidget {
  const RoomManagementScreen({super.key});

  @override
  ConsumerState<RoomManagementScreen> createState() =>
      _RoomManagementScreenState();
}

class _RoomManagementScreenState extends ConsumerState<RoomManagementScreen> {
  String _searchQuery = '';
  Program? _selectedProgram;
  bool? _selectedActiveStatus;
  bool _isShowingArchived = false;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedRoomIds = {};

  final Color maroonColor = const Color(0xFF720045);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _syncSelectedRooms(List<Room> rooms) {
    final visibleIds = rooms.map((room) => room.id).whereType<int>().toSet();
    final intersection = _selectedRoomIds.intersection(visibleIds);
    if (intersection.length != _selectedRoomIds.length) {
      _selectedRoomIds
        ..clear()
        ..addAll(intersection);
    }
  }

  void _toggleSelectAllRooms(List<Room> rooms, bool? isSelected) {
    final shouldSelect = isSelected ?? false;
    setState(() {
      _selectedRoomIds.clear();
      if (shouldSelect) {
        _selectedRoomIds.addAll(
          rooms.map((room) => room.id).whereType<int>(),
        );
      }
    });
  }

  void _toggleRoomSelection(int roomId, bool? isSelected) {
    setState(() {
      if (isSelected ?? false) {
        _selectedRoomIds.add(roomId);
      } else {
        _selectedRoomIds.remove(roomId);
      }
    });
  }

  Future<void> _archiveSelectedRooms(List<Room> rooms) async {
    final selected = rooms
        .where((room) => _selectedRoomIds.contains(room.id))
        .toList();
    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Selected Rooms',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Archive ${selected.length} selected rooms?',
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
        for (final room in selected) {
          await client.admin.updateRoom(room.copyWith(isActive: false));
        }
        _selectedRoomIds.clear();
        ref.invalidate(roomListProvider);
        ref.invalidate(archivedRoomListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected rooms archived successfully'),
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

  Future<void> _deleteSelectedRooms(List<Room> rooms) async {
    final selected = rooms
        .where((room) => _selectedRoomIds.contains(room.id))
        .toList();
    if (selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Selected Rooms',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'PERMANENTLY delete ${selected.length} selected rooms? This cannot be undone.',
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
        for (final room in selected) {
          await client.admin.deleteRoom(room.id!);
        }
        _selectedRoomIds.clear();
        ref.invalidate(roomListProvider);
        ref.invalidate(archivedRoomListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Selected rooms deleted permanently'),
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

  void _showAddRoomModal() {
    showDialog(
      context: context,
      builder: (context) => _AddRoomModal(
        maroonColor: maroonColor,
        onSuccess: () {
          ref.invalidate(roomListProvider);
        },
      ),
    );
  }

  void _showEditRoomModal(Room room) {
    showDialog(
      context: context,
      builder: (context) => _EditRoomModal(
        room: room,
        maroonColor: maroonColor,
        onSuccess: () {
          ref.invalidate(roomListProvider);
        },
      ),
    );
  }

  void _archiveRoom(Room room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Archive Room',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to archive ${room.name}? It will be hidden from assignments.',
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
        final archivedRoom = room.copyWith(isActive: false);
        await client.admin.updateRoom(archivedRoom);
        ref.invalidate(roomListProvider);
        ref.invalidate(archivedRoomListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room archived successfully'),
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

  void _restoreRoom(Room room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restore Room',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to restore ${room.name}? It will reappear in active lists.',
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
        final restoredRoom = room.copyWith(isActive: true);
        await client.admin.updateRoom(restoredRoom);
        ref.invalidate(roomListProvider);
        ref.invalidate(archivedRoomListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room restored successfully'),
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

  void _permanentDeleteRoom(Room room) async {
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
          'Are you sure you want to PERMANENTLY delete ${room.name}? This action cannot be undone.',
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
        await client.admin.deleteRoom(room.id!);
        ref.invalidate(roomListProvider);
        ref.invalidate(archivedRoomListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Room permanently deleted'),
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
    final roomsAsync = _isShowingArchived
        ? ref.watch(archivedRoomListProvider)
        : ref.watch(roomListProvider);
    final conflictsAsync = ref.watch(allConflictsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textMuted = isDark ? const Color(0xFF94A3B8) : Colors.grey[600];
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
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.room_preferences_rounded,
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
                                          'Room Management',
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
                                          'Manage classroom facilities and academic capacities',
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
                                  onPressed: _showAddRoomModal,
                                  icon: const Icon(Icons.add_rounded, size: 20),
                                  label: Text(
                                    kAddNewRoomLabel,
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
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.room_preferences_rounded,
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
                                            'Room Management',
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
                                            'Manage classroom facilities and academic capacities',
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
                                  onPressed: _showAddRoomModal,
                                  icon: const Icon(
                                    Icons.add_rounded,
                                    size: 24,
                                  ),
                                  label: Text(
                                    kAddNewRoomLabel,
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
                                    Expanded(
                                      child: _buildProgramFilter(isDark),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildStatusFilter(isDark)),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildSearchBar(isDark),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: _buildProgramFilter(isDark),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: _buildStatusFilter(isDark),
                                ),
                                const SizedBox(width: 16),
                                _buildViewToggle(isDark),
                              ],
                            ),
                      const SizedBox(height: 24),
                      roomsAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                        data: (rooms) {
                          final filtered = rooms.where((r) {
                            final matchesSearch = r.name.toLowerCase().contains(
                              _searchQuery,
                            );
                            final matchesProgram =
                                _selectedProgram == null ||
                                r.program == _selectedProgram;
                            final matchesStatus =
                                _selectedActiveStatus == null ||
                                r.isActive == _selectedActiveStatus;
                            return matchesSearch &&
                                matchesProgram &&
                                matchesStatus;
                          }).toList();
                          final allSelected =
                              filtered.isNotEmpty &&
                              _selectedRoomIds.length == filtered.length;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            _syncSelectedRooms(filtered);
                          });

                          if (useCompactList) {
                            return _buildMobileRoomList(filtered, isDark);
                          }

                          if (filtered.isEmpty) {
                            return Center(
                              child: Text(
                                'No rooms found',
                                style: GoogleFonts.poppins(color: textMuted),
                              ),
                            );
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
                                        Icons.meeting_room_rounded,
                                        color: maroonColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Rooms',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: maroonColor,
                                        ),
                                      ),
                                      if (_selectedRoomIds.isNotEmpty) ...[
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
                                            '${_selectedRoomIds.length} selected',
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
                                          _selectedRoomIds.isNotEmpty) ...[
                                        TextButton.icon(
                                          onPressed: () =>
                                              _archiveSelectedRooms(filtered),
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
                                          _selectedRoomIds.isNotEmpty) ...[
                                        TextButton.icon(
                                          onPressed: () => _deleteSelectedRooms(
                                            filtered,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                                    final availableWidth = constraints.maxWidth;
                                    final extraWidth = (availableWidth - 760)
                                        .clamp(0.0, 480.0);
                                    final tableHorizontalMargin =
                                        24.0 + (extraWidth / 12);
                                    final tableColumnSpacing =
                                        32.0 + (extraWidth / 6);

                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: availableWidth,
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
                                          columnSpacing: tableColumnSpacing,
                                          horizontalMargin:
                                              tableHorizontalMargin,
                                          decoration: const BoxDecoration(
                                            color: Colors.transparent,
                                          ),
                                          columns: [
                                            DataColumn(
                                              label: Checkbox(
                                                value: allSelected,
                                                onChanged: (value) =>
                                                    _toggleSelectAllRooms(
                                                      filtered,
                                                      value,
                                                    ),
                                                activeColor: Colors.white,
                                                checkColor: maroonColor,
                                              ),
                                            ),
                                            const DataColumn(
                                              label: Text('ROOM'),
                                            ),
                                            const DataColumn(
                                              label: Text('CAPACITY'),
                                            ),
                                            const DataColumn(
                                              label: Text('TYPE'),
                                            ),
                                            const DataColumn(
                                              label: Text('PROGRAM'),
                                            ),
                                            const DataColumn(
                                              label: Text('STATUS'),
                                            ),
                                            const DataColumn(
                                              label: Text('ACTIONS'),
                                            ),
                                          ],
                                          rows: filtered.asMap().entries.map((
                                            entry,
                                          ) {
                                            final room = entry.value;
                                            final index = entry.key;

                                            return DataRow(
                                              color:
                                                  WidgetStateProperty.resolveWith<
                                                    Color?
                                                  >(
                                                    (states) =>
                                                        _resolveRowColor(
                                                          states,
                                                          index,
                                                          isDark,
                                                        ),
                                                  ),
                                              cells: [
                                                DataCell(
                                                  Checkbox(
                                                    value:
                                                        room.id != null &&
                                                        _selectedRoomIds
                                                            .contains(
                                                              room.id,
                                                            ),
                                                    onChanged: room.id == null
                                                        ? null
                                                        : (value) =>
                                                              _toggleRoomSelection(
                                                                room.id!,
                                                                value,
                                                              ),
                                                    activeColor: maroonColor,
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    children: [
                                                      if (conflictsAsync.maybeWhen(
                                                        data: (conflicts) =>
                                                            conflicts
                                                                .hasConflictForRoom(
                                                                  room.id!,
                                                                ),
                                                        orElse: () => false,
                                                      ))
                                                        const Tooltip(
                                                          message:
                                                              'Room has a schedule conflict',
                                                          child: Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                  right: 8,
                                                                ),
                                                            child: Icon(
                                                              Icons
                                                                  .warning_rounded,
                                                              color:
                                                                  Colors.orange,
                                                              size: 20,
                                                            ),
                                                          ),
                                                        ),
                                                      Text(
                                                        room.name,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    room.capacity.toString(),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    room.type.name
                                                        .toUpperCase(),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(
                                                    _roomProgramLabel(
                                                      room.program,
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: room.isActive
                                                          ? Colors.green
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                )
                                                          : Colors.red
                                                                .withValues(
                                                                  alpha: 0.1,
                                                                ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      room.isActive
                                                          ? 'ACTIVE'
                                                          : 'INACTIVE',
                                                      style: TextStyle(
                                                        color: room.isActive
                                                            ? Colors.green
                                                            : Colors.red,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      if (!_isShowingArchived) ...[
                                                        Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            onTap: () => Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    RoomDetailsScreen(
                                                                      room:
                                                                          room,
                                                                    ),
                                                              ),
                                                            ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: maroonColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .open_in_new,
                                                                color:
                                                                    maroonColor,
                                                                size: 18,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            onTap: () =>
                                                                _showEditRoomModal(
                                                                  room,
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: maroonColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .edit_outlined,
                                                                color:
                                                                    maroonColor,
                                                                size: 18,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            onTap: () =>
                                                                _archiveRoom(
                                                                  room,
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: maroonColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .archive_outlined,
                                                                color:
                                                                    maroonColor,
                                                                size: 18,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ] else ...[
                                                        Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            onTap: () =>
                                                                _restoreRoom(
                                                                  room,
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: maroonColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons
                                                                    .restore_rounded,
                                                                color:
                                                                    maroonColor,
                                                                size: 18,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Material(
                                                          color: Colors
                                                              .transparent,
                                                          child: InkWell(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                            onTap: () =>
                                                                _permanentDeleteRoom(
                                                                  room,
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    8,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: Colors
                                                                    .red
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .delete_forever_rounded,
                                                                color:
                                                                    Colors.red,
                                                                size: 18,
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
                hintText: 'Search room name...',
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

  Widget _buildMobileRoomList(List<Room> rooms, bool isDark) {
    return ListView.builder(
      itemCount: rooms.length,
      padding: const EdgeInsets.only(bottom: 24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final room = rooms[index];
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
                builder: (_) => RoomDetailsScreen(room: room),
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
                              room.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: maroonColor,
                              ),
                            ),
                            Text(
                              'Capacity: ${room.capacity}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[600],
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
                              onPressed: () => _showEditRoomModal(room),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.archive_outlined,
                                color: maroonColor,
                              ),
                              tooltip: 'Archive Room',
                              onPressed: () => _archiveRoom(room),
                            ),
                          ] else ...[
                            IconButton(
                              icon: Icon(
                                Icons.restore_rounded,
                                color: maroonColor,
                              ),
                              tooltip: 'Restore Room',
                              onPressed: () => _restoreRoom(room),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.red,
                              ),
                              tooltip: kDeletePermanentlyLabel,
                              onPressed: () => _permanentDeleteRoom(room),
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
                        Icons.people_alt_outlined,
                        '${room.capacity} Pax',
                        Colors.blue,
                      ),
                      _buildInfoChip(
                        Icons.category_outlined,
                        room.type.name.toUpperCase(),
                        Colors.purple,
                      ),
                      _buildInfoChip(
                        Icons.school_outlined,
                        _roomProgramLabel(room.program),
                        Colors.orange,
                      ),
                      _buildInfoChip(
                        room.isActive
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        room.isActive ? 'Active' : 'Inactive',
                        room.isActive ? Colors.green : Colors.red,
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
            ...kRoomProgramOptions.map(
              (p) => DropdownMenuItem(
                value: p,
                child: Text(
                  _roomProgramLabel(p),
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

  Widget _buildStatusFilter(bool isDark) {
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
        child: DropdownButton<bool>(
          value: _selectedActiveStatus,
          hint: Row(
            children: [
              Icon(Icons.toggle_on_outlined, color: maroonColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ResponsiveHelper.isMobile(context) ? 'Stat' : 'Status',
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
            DropdownMenuItem(
              value: true,
              child: Text('Active', style: GoogleFonts.poppins(fontSize: 14)),
            ),
            DropdownMenuItem(
              value: false,
              child: Text('Inactive', style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ],
          onChanged: (v) => setState(() => _selectedActiveStatus = v),
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

class _AddRoomModal extends StatefulWidget {
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _AddRoomModal({required this.maroonColor, required this.onSuccess});

  @override
  State<_AddRoomModal> createState() => _AddRoomModalState();
}

class _AddRoomModalState extends State<_AddRoomModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _capacityController = TextEditingController(text: '40');

  RoomType _type = RoomType.lecture;
  Program _program = Program.it;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _handleRoomNameChanged(String value) {
    setState(() {
      _type = _roomNameLooksLikeLab(value)
          ? RoomType.laboratory
          : RoomType.lecture;
    });
  }

  @override
  Widget build(BuildContext context) => _buildAddRoomDialog(context);

  Widget _buildAddRoomDialog(BuildContext context) {
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
                          Icons.add_home_work_rounded,
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
                              kAddNewRoomLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Enter room details below',
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
                      _buildSectionTitle('Room Info', Icons.room, textPrimary),
                      const SizedBox(height: 16),
                      isMobile
                          ? Column(
                              children: [
                                _buildTextField(
                                  kRoomNameLabel,
                                  _nameController,
                                  isDark,
                                  hint: 'e.g., CL1',
                                  onChanged: _handleRoomNameChanged,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  'Capacity',
                                  _capacityController,
                                  isDark,
                                  isNumber: true,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    kRoomNameLabel,
                                    _nameController,
                                    isDark,
                                    hint: 'e.g., CL1',
                                    onChanged: _handleRoomNameChanged,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    'Capacity',
                                    _capacityController,
                                    isDark,
                                    isNumber: true,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'Classification',
                        Icons.category_outlined,
                        textPrimary,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<Program>(
                        initialValue: _program,
                        decoration: _inputDecoration('Program', isDark),
                        dropdownColor: cardBg,
                        items: kRoomProgramOptions
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  _roomProgramLabel(p),
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _program = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<RoomType>(
                        initialValue: _type,
                        decoration: _inputDecoration('Room Type', isDark),
                        dropdownColor: cardBg,
                        items: _allowedRoomTypesForName(_nameController.text)
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t.name.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),

                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Active Status',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Enable or disable this room for scheduling',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                          value: _isActive,
                          activeThumbColor: widget.maroonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
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
                              _isLoading ? kSavingLabel : 'Create Room',
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
                            _isLoading ? kSavingLabel : 'Create Room',
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
    ValueChanged<String>? onChanged,
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
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: _inputDecoration(null, isDark, hint: hint),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
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

  Future<void> _submit() async => _submitAddRoom();

  Future<void> _submitAddRoom() async {
    if (!_formKey.currentState!.validate()) return;
    final normalizedName = _normalizeRoomCatalogName(_nameController.text);
    final parsedCapacity = int.tryParse(_capacityController.text.trim());
    final validationMessage = _validateRoomCatalogInput(
      roomName: normalizedName,
    );
    if (validationMessage != null) {
      AppErrorDialog.show(context, validationMessage);
      return;
    }
    if (parsedCapacity == null || parsedCapacity <= 0) {
      AppErrorDialog.show(context, 'Room capacity must be greater than 0.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final activeRooms = await client.admin.getAllRooms(isActive: true);
      final archivedRooms = await client.admin.getAllRooms(isActive: false);
      final allRooms = [...activeRooms, ...archivedRooms];
      final duplicate = allRooms.any(
        (existingRoom) =>
            _normalizeRoomCatalogName(existingRoom.name) == normalizedName,
      );
      if (duplicate) {
        throw Exception('Room $normalizedName already exists.');
      }

      final room = Room(
        name: normalizedName,
        capacity: parsedCapacity,
        type: _type,
        program: _program,
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await client.admin.createRoom(room);
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppErrorDialog.show(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _EditRoomModal extends StatefulWidget {
  final Room room;
  final Color maroonColor;
  final VoidCallback onSuccess;

  const _EditRoomModal({
    required this.room,
    required this.maroonColor,
    required this.onSuccess,
  });

  @override
  State<_EditRoomModal> createState() => _EditRoomModalState();
}

class _EditRoomModalState extends State<_EditRoomModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _capacityController;

  late RoomType _type;
  late Program _program;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room.name);
    _capacityController = TextEditingController(
      text: widget.room.capacity.toString(),
    );
    _type = widget.room.type;
    _program = widget.room.program;
    _isActive = widget.room.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  void _handleRoomNameChanged(String value) {
    setState(() {
      _type = _roomNameLooksLikeLab(value)
          ? RoomType.laboratory
          : RoomType.lecture;
    });
  }

  @override
  Widget build(BuildContext context) => _buildEditRoomDialog(context);

  Widget _buildEditRoomDialog(BuildContext context) {
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
                            Icons.edit_location_alt_rounded,
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
                                'Edit Room',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Update room details below',
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
                            Icons.edit_location_alt_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Room',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Update room details below',
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
                          icon: const Icon(Icons.close, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.18,
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
                      _buildSectionTitle('Room Info', Icons.room, textPrimary),
                      const SizedBox(height: 16),
                      isMobile
                          ? Column(
                              children: [
                                _buildTextField(
                                  kRoomNameLabel,
                                  _nameController,
                                  isDark,
                                  hint: 'e.g., IT LAB 327',
                                  onChanged: _handleRoomNameChanged,
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  'Capacity',
                                  _capacityController,
                                  isDark,
                                  isNumber: true,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    kRoomNameLabel,
                                    _nameController,
                                    isDark,
                                    hint: 'e.g., IT LAB 327',
                                    onChanged: _handleRoomNameChanged,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    'Capacity',
                                    _capacityController,
                                    isDark,
                                    isNumber: true,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),

                      const SizedBox(height: 24),
                      _buildSectionTitle(
                        'Classification',
                        Icons.category_outlined,
                        textPrimary,
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<Program>(
                        initialValue: _program,
                        decoration: _inputDecoration('Program', isDark),
                        dropdownColor: cardBg,
                        items: kRoomProgramOptions
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  _roomProgramLabel(p),
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _program = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<RoomType>(
                        initialValue: _type,
                        decoration: _inputDecoration('Room Type', isDark),
                        dropdownColor: cardBg,
                        items: _allowedRoomTypesForName(_nameController.text)
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t.name.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),

                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: SwitchListTile(
                          title: Text(
                            'Active Status',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Enable or disable this room for scheduling',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                          value: _isActive,
                          activeThumbColor: widget.maroonColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
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
    ValueChanged<String>? onChanged,
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
          onChanged: onChanged,
          style: GoogleFonts.poppins(
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: _inputDecoration(null, isDark, hint: hint),
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
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

  Future<void> _submit() async => _submitEditRoom();

  Future<void> _submitEditRoom() async {
    if (!_formKey.currentState!.validate()) return;
    final normalizedName = _normalizeRoomCatalogName(_nameController.text);
    final parsedCapacity = int.tryParse(_capacityController.text.trim());
    final validationMessage = _validateRoomCatalogInput(
      roomName: normalizedName,
    );
    if (validationMessage != null) {
      AppErrorDialog.show(context, validationMessage);
      return;
    }
    if (parsedCapacity == null || parsedCapacity <= 0) {
      AppErrorDialog.show(context, 'Room capacity must be greater than 0.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final activeRooms = await client.admin.getAllRooms(isActive: true);
      final archivedRooms = await client.admin.getAllRooms(isActive: false);
      final allRooms = [...activeRooms, ...archivedRooms];
      final duplicate = allRooms.any(
        (existingRoom) =>
            existingRoom.id != widget.room.id &&
            _normalizeRoomCatalogName(existingRoom.name) == normalizedName,
      );
      if (duplicate) {
        throw Exception('Room $normalizedName already exists.');
      }

      final room = widget.room.copyWith(
        name: normalizedName,
        capacity: parsedCapacity,
        type: _type,
        program: _program,
        isActive: _isActive,
        updatedAt: DateTime.now(),
      );
      await client.admin.updateRoom(room);
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        AppErrorDialog.show(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
