import 'dart:convert';
import 'dart:math' as math;

import 'package:citesched_client/citesched_client.dart';
import 'package:citesched_flutter/core/utils/date_utils.dart';
import 'package:citesched_flutter/core/utils/schedule_export_service.dart';
import 'package:citesched_flutter/core/widgets/full_screen_calendar_scaffold.dart';
import 'package:citesched_flutter/features/auth/providers/auth_provider.dart';
import 'package:citesched_flutter/features/admin/widgets/weekly_calendar_view.dart';
import 'package:citesched_flutter/features/admin/screens/admin_layout.dart';
import 'package:citesched_flutter/features/nlp/providers/chat_history_provider.dart';
import 'package:citesched_flutter/features/nlp/providers/nlp_query_chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:serverpod_auth_client/serverpod_auth_client.dart';

class NLPQueryDialog extends ConsumerStatefulWidget {
  const NLPQueryDialog({super.key});

  @override
  ConsumerState<NLPQueryDialog> createState() => _NLPQueryDialogState();
}

class _NLPQueryDialogState extends ConsumerState<NLPQueryDialog> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _showHistory = false;
  bool _showSuggestionsPanel = false;
  bool _showJumpToBottom = false;
  double? _dialogWidth;
  double? _dialogHeight;
  String? _selectedSessionId;
  Offset _dialogOffset = Offset.zero;

  final Color maroonColor = const Color(0xFF720045);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScrollChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusInput();
      _jumpToBottom(immediate: true);
    });
  }

  Future<void> _sendQuery() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    _queryController.clear();
    setState(() {
      _showSuggestionsPanel = false;
    });
    await ref.read(nlpQueryChatProvider.notifier).sendQuery(query);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _jumpToBottom();
    });
  }

  void _jumpToBottom({bool immediate = false}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (immediate) {
      _scrollController.jumpTo(target);
      return;
    }
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleScrollChanged() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final shouldShow =
        position.maxScrollExtent - position.pixels > 120;
    if (shouldShow != _showJumpToBottom && mounted) {
      setState(() => _showJumpToBottom = shouldShow);
    }
  }

  void _focusInput() {
    if (!mounted) return;
    FocusScope.of(context).requestFocus(_inputFocusNode);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _inputFocusNode.dispose();
    _scrollController.removeListener(_handleScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleHistory() {
    setState(() {
      _showHistory = !_showHistory;
      _showSuggestionsPanel = false;
      _selectedSessionId = null;
    });
    if (!_showHistory) {
      _focusInput();
      _scrollToBottom();
    }
  }

  void _toggleSuggestions() {
    setState(() {
      _showSuggestionsPanel = !_showSuggestionsPanel;
      _showHistory = false;
      _selectedSessionId = null;
    });
    if (!_showSuggestionsPanel) {
      _focusInput();
      _scrollToBottom();
    }
  }

  List<String> _roleSuggestions() {
    final selectedRole = ref.read(authProvider.notifier).selectedRole;
    final scopes = ref.read(authProvider)?.scopeNames ?? const [];
    if (selectedRole == 'admin' || scopes.contains('admin')) {
      return [
        'Generate schedule',
        'Show schedule conflicts',
        'Find free room',
      ];
    }
    if (selectedRole == 'faculty') {
      return [
        'Show my schedule today',
        'Show my weekly timetable',
        'Check teaching load',
        'Detect my schedule conflicts',
        'Show my assigned sections',
        'Find my available hours',
        'What is my next class?',
      ];
    }
    if (selectedRole == 'student') {
      return [
        'Show my schedule today',
        'Show my weekly class timetable',
        'View my subjects',
        'Show my section timetable',
        'Find next class',
        'What room is my next class?',
        'Do I have class conflicts?',
      ];
    }
    if (scopes.contains('faculty')) {
      return [
        'Show my schedule today',
        'Show my weekly timetable',
        'Check teaching load',
        'Detect my schedule conflicts',
        'Show my assigned sections',
        'Find my available hours',
        'What is my next class?',
      ];
    }
    return [
      'Show my schedule today',
      'Show my weekly class timetable',
      'View my subjects',
      'Show my section timetable',
      'Find next class',
      'Do I have class conflicts?',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(nlpQueryChatProvider);
    final sessionsAsync = ref.watch(chatHistorySessionsProvider(30));
    final historyAsync = _watchSelectedHistory();
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = _dialogBackground(isDark);
    final bounds = _dialogBounds(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Transform.translate(
          offset: _dialogOffset,
          child: Container(
            width: bounds.width,
            height: bounds.height,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: [
                _buildDialogContent(
                  auth: auth,
                  isDark: isDark,
                  messages: chatState.messages,
                  isLoading: chatState.isLoading,
                  sessionsAsync: sessionsAsync,
                  historyAsync: historyAsync,
                ),
                ..._buildResizeHandles(bounds),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AsyncValue<List<ChatHistory>>? _watchSelectedHistory() {
    final selectedSessionId = _selectedSessionId;
    if (selectedSessionId == null) return null;
    return ref.watch(chatHistorySessionProvider(selectedSessionId));
  }

  Color _dialogBackground(bool isDark) {
    return isDark ? const Color(0xFF1E293B) : Colors.white;
  }

  _DialogBounds _dialogBounds(BuildContext context) {
    final media = MediaQuery.of(context);
    final isMobile = media.size.width < 768;
    const preferredMinWidth = 320.0;
    const preferredMinHeight = 360.0;
    final maxWidth = isMobile ? media.size.width * 0.96 : media.size.width * 0.52;
    final maxHeight = isMobile ? media.size.height * 0.86 : media.size.height * 0.82;
    final minWidth = math.min(preferredMinWidth, maxWidth);
    final minHeight = math.min(preferredMinHeight, maxHeight);
    final defaultWidth = isMobile ? media.size.width * 0.92 : 460.0;
    final defaultHeight = isMobile ? media.size.height * 0.72 : 620.0;
    final width = (_dialogWidth ?? defaultWidth).clamp(
      minWidth,
      maxWidth,
    );
    final height = (_dialogHeight ?? defaultHeight).clamp(
      minHeight,
      maxHeight,
    );
    return _DialogBounds(
      minWidth: minWidth,
      minHeight: minHeight,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      width: width,
      height: height,
    );
  }

  Widget _buildDialogContent({
    required UserInfo? auth,
    required bool isDark,
    required List<Map<String, dynamic>> messages,
    required bool isLoading,
    required AsyncValue<List<ChatSessionSummary>> sessionsAsync,
    required AsyncValue<List<ChatHistory>>? historyAsync,
  }) {
    return Column(
      children: [
        _buildDialogHeader(auth),
        _buildChatMessagesArea(
          messages,
          isLoading,
          sessionsAsync,
          historyAsync,
        ),
        _buildInputArea(isDark, isLoading),
      ],
    );
  }

  Widget _buildDialogHeader(UserInfo? auth) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          final media = MediaQuery.of(context);
          final bounds = _dialogBounds(context);
          final proposed = _dialogOffset + details.delta;
          final minDx = -(media.size.width - bounds.width - 12);
          final maxDx = 0.0;
          final minDy = -(media.size.height - bounds.height - media.padding.top - 12);
          final maxDy = 0.0;
          _dialogOffset = Offset(
            proposed.dx.clamp(minDx, maxDx),
            proposed.dy.clamp(minDy, maxDy),
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [maroonColor, const Color(0xFF9d005f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return constraints.maxWidth < 560
                ? _buildCompactHeader(context, auth)
                : _buildWideHeader(context, auth);
          },
        ),
      ),
    );
  }

  Widget _buildCompactHeader(BuildContext context, UserInfo? auth) {
    final actionButtons = _buildHeaderActions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _toggleHistory,
              tooltip: _historyLabel(auth),
              icon: Icon(
                _showHistory ? Icons.chat_bubble_outline : Icons.history,
                color: Colors.white,
              ),
            ),
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildHeaderTitle()),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: actionButtons,
          ),
        ),
      ],
    );
  }

  Widget _buildWideHeader(BuildContext context, UserInfo? auth) {
    final actionButtons = _buildHeaderActions();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: _toggleHistory,
          tooltip: _historyLabel(auth),
          icon: Icon(
            _showHistory ? Icons.chat_bubble_outline : Icons.history,
            color: Colors.white,
          ),
        ),
        const Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildHeaderTitle()),
        const SizedBox(width: 8),
        Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...actionButtons,
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatMessagesArea(
    List<Map<String, dynamic>> messages,
    bool isLoading,
    AsyncValue<List<ChatSessionSummary>> sessionsAsync,
    AsyncValue<List<ChatHistory>>? historyAsync,
  ) {
    return Expanded(
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: messages.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == messages.length) {
                return _TypingIndicator(maroonColor: maroonColor);
              }

              final msg = messages[index];
              return _MessageBubble(messageData: msg, maroonColor: maroonColor);
            },
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: AnimatedOpacity(
              opacity: _showJumpToBottom ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: !_showJumpToBottom,
                child: FloatingActionButton.small(
                  heroTag: 'nlp_jump_bottom',
                  backgroundColor: maroonColor,
                  foregroundColor: Colors.white,
                  onPressed: _scrollToBottom,
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ),
            ),
          ),
          if (_showHistory)
            Align(
              alignment: Alignment.centerRight,
              child: _buildHistoryPanel(sessionsAsync, historyAsync),
            ),
          if (_showSuggestionsPanel)
            Align(
              alignment: Alignment.centerRight,
              child: _buildSuggestionsPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              focusNode: _inputFocusNode,
              autofocus: true,
              onSubmitted: (_) => _sendQuery(),
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Ask about schedules, rooms, load...",
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: maroonColor,
            shape: const CircleBorder(),
            elevation: 2,
            child: IconButton(
              onPressed: isLoading ? null : _sendQuery,
              icon: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResizeHandles(_DialogBounds bounds) {
    return [
      _ResizeEdge(
        alignment: Alignment.centerLeft,
        cursor: SystemMouseCursors.resizeLeftRight,
        sensitivity: 1,
        onDrag: (delta) {
          setState(() {
            _dialogWidth = (bounds.width - delta.dx).clamp(
              bounds.minWidth,
              bounds.maxWidth,
            );
          });
        },
        vertical: true,
        color: maroonColor,
      ),
      _ResizeEdge(
        alignment: Alignment.centerRight,
        cursor: SystemMouseCursors.resizeLeftRight,
        sensitivity: 1,
        onDrag: (delta) {
          setState(() {
            _dialogWidth = (bounds.width + delta.dx).clamp(
              bounds.minWidth,
              bounds.maxWidth,
            );
          });
        },
        vertical: true,
        color: maroonColor,
      ),
      _ResizeEdge(
        alignment: Alignment.topCenter,
        cursor: SystemMouseCursors.resizeUpDown,
        sensitivity: 1,
        onDrag: (delta) {
          setState(() {
            _dialogHeight = (bounds.height - delta.dy).clamp(
              bounds.minHeight,
              bounds.maxHeight,
            );
          });
        },
        vertical: false,
        color: maroonColor,
      ),
      _ResizeEdge(
        alignment: Alignment.bottomCenter,
        cursor: SystemMouseCursors.resizeUpDown,
        sensitivity: 1,
        onDrag: (delta) {
          setState(() {
            _dialogHeight = (bounds.height + delta.dy).clamp(
              bounds.minHeight,
              bounds.maxHeight,
            );
          });
        },
        vertical: false,
        color: maroonColor,
      ),
      _ResizeCorner(
        alignment: Alignment.topLeft,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        sensitivity: 1,
        onDrag: (delta) {
          setState(() {
            _dialogWidth = (bounds.width - delta.dx).clamp(
              bounds.minWidth,
              bounds.maxWidth,
            );
            _dialogHeight = (bounds.height - delta.dy).clamp(
              bounds.minHeight,
              bounds.maxHeight,
            );
          });
        },
        color: maroonColor,
      ),
      _ResizeCorner(
        alignment: Alignment.topRight,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        sensitivity: 1,
        onDrag: (delta) {
          setState(() {
            _dialogWidth = (bounds.width + delta.dx).clamp(
              bounds.minWidth,
              bounds.maxWidth,
            );
            _dialogHeight = (bounds.height - delta.dy).clamp(
              bounds.minHeight,
              bounds.maxHeight,
            );
          });
        },
        color: maroonColor,
      ),
      _ResizeCorner(
        alignment: Alignment.bottomLeft,
        cursor: SystemMouseCursors.resizeUpRightDownLeft,
        sensitivity: 1,
        onDrag: (delta) {
          setState(() {
            _dialogWidth = (bounds.width - delta.dx).clamp(
              bounds.minWidth,
              bounds.maxWidth,
            );
            _dialogHeight = (bounds.height + delta.dy).clamp(
              bounds.minHeight,
              bounds.maxHeight,
            );
          });
        },
        color: maroonColor,
      ),
      _ResizeCorner(
        alignment: Alignment.bottomRight,
        cursor: SystemMouseCursors.resizeUpLeftDownRight,
        sensitivity: 1,
        onDrag: (delta) {
          setState(() {
            _dialogWidth = (bounds.width + delta.dx).clamp(
              bounds.minWidth,
              bounds.maxWidth,
            );
            _dialogHeight = (bounds.height + delta.dy).clamp(
              bounds.minHeight,
              bounds.maxHeight,
            );
          });
        },
        color: maroonColor,
      ),
    ];
  }

  Widget _buildHeaderTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CITESched AI',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          'Powered by NLP Service',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHeaderActions() {
    return [
      TextButton.icon(
        onPressed: _toggleSuggestions,
        icon: const Icon(
          Icons.lightbulb_outline,
          color: Colors.white,
        ),
        label: Text(
          'Suggest',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      TextButton.icon(
        onPressed: () {
          ref.read(nlpQueryChatProvider.notifier).clearChat();
          setState(() {
            _showHistory = false;
            _showSuggestionsPanel = false;
            _selectedSessionId = null;
          });
        },
        icon: const Icon(
          Icons.add_comment,
          color: Colors.white,
        ),
        label: Text(
          'New Chat',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];
  }

  String _historyLabel(UserInfo? auth) {
    final selectedRole = ref.read(authProvider.notifier).selectedRole;
    final scopes = auth?.scopeNames ?? const [];
    if (selectedRole == 'admin' || scopes.contains('admin') && selectedRole == null) {
      return 'Admin History';
    }
    if (selectedRole == 'faculty' ||
        scopes.contains('faculty') && selectedRole == null) {
      return 'Faculty History';
    }
    if (selectedRole == 'student' ||
        scopes.contains('student') && selectedRole == null) {
      return 'Student History';
    }
    return 'History';
  }

  Widget _buildSuggestionsPanel() {
    final suggestions = _roleSuggestions();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 320,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: maroonColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: maroonColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Suggested Queries',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showSuggestionsPanel = false;
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: suggestions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final text = suggestions[index];
                return ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.shade50,
                  title: Text(
                    text,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  trailing: Icon(
                    Icons.send_rounded,
                    color: maroonColor,
                    size: 18,
                  ),
                  onTap: () {
                    _queryController.text = text;
                    _sendQuery();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPanel(
    AsyncValue<List<ChatSessionSummary>> sessionsAsync,
    AsyncValue<List<ChatHistory>>? historyAsync,
  ) {
    if (_selectedSessionId != null && historyAsync != null) {
      return _buildPanelContainer(
        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              _buildHistoryStatusText('Could not load history: $err'),
          data: _buildHistoryDetailsBody,
        ),
      );
    }

    return _buildPanelContainer(
      sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            _buildHistoryStatusText('Could not load history: $err'),
        data: _buildSessionsBody,
      ),
    );
  }

  Widget _buildPanelContainer(Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 320,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: maroonColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHistoryStatusText(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
      ),
    );
  }

  Widget _buildHistoryDetailsBody(List<ChatHistory> items) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedSessionId = null),
              ),
              const SizedBox(width: 8),
              Text(
                'Chat Details',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _deleteSelectedSession,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: items.isEmpty
              ? _buildHistoryStatusText('No messages in this chat.')
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryMessageBubble(items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryMessageBubble(ChatHistory entry) {
    final isUser = entry.sender == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color messageColor;
    if (isUser) {
      messageColor = Colors.white;
    } else if (isDark) {
      messageColor = Colors.white70;
    } else {
      messageColor = Colors.black87;
    }
    Color? bubbleColor;
    if (isUser) {
      bubbleColor = maroonColor;
    } else if (isDark) {
      bubbleColor = Colors.white.withValues(alpha: 0.08);
    } else {
      bubbleColor = Colors.grey[200];
    }
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 240),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          entry.text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: messageColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsBody(List<ChatSessionSummary> sessions) {
    if (sessions.isEmpty) return _buildHistoryStatusText('No history yet.');

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildSessionTile(sessions[index]),
    );
  }

  Widget _buildSessionTile(ChatSessionSummary entry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: maroonColor.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          entry.title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          entry.lastMessageText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => _deleteSession(entry.sessionId),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => _openSession(entry),
      ),
    );
  }

  Future<void> _deleteSelectedSession() async {
    final sessionId = _selectedSessionId;
    if (sessionId == null) return;
    await _deleteSession(sessionId);
    if (!mounted) return;
    setState(() {
      _selectedSessionId = null;
      _showHistory = false;
    });
    _focusInput();
    _scrollToBottom();
  }

  Future<void> _deleteSession(String sessionId) async {
    await ref.read(chatHistoryDeleteProvider(sessionId).future);
    ref.read(nlpQueryChatProvider.notifier).closeDeletedSession(sessionId);
    ref.invalidate(chatHistorySessionsProvider);
    ref.invalidate(chatHistorySessionProvider);
    if (!mounted) return;
    setState(() {
      if (_selectedSessionId == sessionId) {
        _selectedSessionId = null;
        _showHistory = false;
      }
    });
    _focusInput();
    _scrollToBottom();
  }

  Future<void> _openSession(ChatSessionSummary entry) async {
    final historyItems = await ref.read(
      chatHistorySessionProvider(entry.sessionId).future,
    );
    if (!mounted) return;
    ref
        .read(nlpQueryChatProvider.notifier)
        .loadSessionHistory(
          sessionId: entry.sessionId,
          sessionTitle: entry.title,
          history: historyItems,
        );
    setState(() {
      _showHistory = false;
      _showSuggestionsPanel = false;
      _selectedSessionId = entry.sessionId;
    });
    _focusInput();
    _scrollToBottom();
  }
}

class _DialogBounds {
  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;
  final double width;
  final double height;

  const _DialogBounds({
    required this.minWidth,
    required this.minHeight,
    required this.maxWidth,
    required this.maxHeight,
    required this.width,
    required this.height,
  });
}

class _ResizeEdge extends StatelessWidget {
  final Alignment alignment;
  final MouseCursor cursor;
  final void Function(Offset delta) onDrag;
  final bool vertical;
  final Color color;
  final double sensitivity;

  const _ResizeEdge({
    required this.alignment,
    required this.cursor,
    required this.onDrag,
    required this.vertical,
    required this.color,
    required this.sensitivity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) => onDrag(details.delta * sensitivity),
            child: Container(
              width: vertical ? 12 : 80,
              height: vertical ? 80 : 12,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Container(
                  width: vertical ? 2 : 36,
                  height: vertical ? 36 : 2,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResizeCorner extends StatelessWidget {
  final Alignment alignment;
  final MouseCursor cursor;
  final void Function(Offset delta) onDrag;
  final Color color;
  final double sensitivity;

  const _ResizeCorner({
    required this.alignment,
    required this.cursor,
    required this.onDrag,
    required this.color,
    required this.sensitivity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) => onDrag(details.delta * sensitivity),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.drag_handle,
                size: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final Color maroonColor;
  const _TypingIndicator({required this.maroonColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: maroonColor.withValues(alpha: 0.1),
            radius: 18,
            child: Icon(Icons.smart_toy_rounded, color: maroonColor, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => _Dot(delay: i * 200, color: maroonColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  final Color color;
  const _Dot({required this.delay, required this.color});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: widget.color.withValues(
              alpha: 0.3 + (0.7 * _animation.value),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> messageData;
  final Color maroonColor;

  const _MessageBubble({
    required this.messageData,
    required this.maroonColor,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = messageData['isUser'] as bool;
    final isError = messageData['isError'] ?? false;
    final text = messageData['text'] as String;
    final schedules = messageData['schedules'] as List?;
    final dataJson = messageData['dataJson'] as String?;
    final scheduleView = messageData['scheduleView'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildMessageRow(context, isUser, isError, text),
          ..._buildMessageExtras(context, schedules, dataJson, scheduleView),
        ],
      ),
    );
  }

  Widget _buildMessageRow(
    BuildContext context,
    bool isUser,
    bool isError,
    String text,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) _buildBotAvatar(),
        if (!isUser) const SizedBox(width: 12),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bubbleColor(isUser, isError, isDark),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              border: isError
                  ? Border.all(color: Colors.red.withValues(alpha: 0.3))
                  : null,
            ),
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.4,
                color: _bubbleTextColor(isUser, isError, isDark),
              ),
            ),
          ),
        ),
        if (isUser) const SizedBox(width: 12),
        if (isUser) _buildUserAvatar(),
      ],
    );
  }

  List<Widget> _buildMessageExtras(
    BuildContext context,
    List? schedules,
    String? dataJson,
    String? scheduleView,
  ) {
    final widgets = <Widget>[];
    final hasSchedules = schedules != null && schedules.isNotEmpty;
    final showTimetable = messageData['showTimetable'] == true;

    if (hasSchedules) {
      widgets.add(const SizedBox(height: 12));
      if (showTimetable) {
        widgets.add(
          _buildStructuredSchedulePreview(
            context,
            schedules,
            scheduleView ?? 'calendar',
          ),
        );
      } else {
        widgets.add(_buildScheduleCards(context, schedules));
      }
      widgets.add(const SizedBox(height: 10));
      widgets.add(_buildScheduleExportActions(context, schedules));
    }

    if (dataJson != null) {
      widgets.add(const SizedBox(height: 12));
      widgets.add(_buildDataSummary(context, dataJson));
    }

    return widgets;
  }

  Widget _buildBotAvatar() {
    return CircleAvatar(
      backgroundColor: maroonColor.withValues(alpha: 0.1),
      radius: 18,
      child: Icon(Icons.smart_toy_rounded, color: maroonColor, size: 20),
    );
  }

  Widget _buildUserAvatar() {
    return CircleAvatar(
      backgroundColor: maroonColor.withValues(alpha: 0.1),
      radius: 18,
      child: Icon(Icons.person_rounded, color: maroonColor, size: 20),
    );
  }

  Color _bubbleColor(bool isUser, bool isError, bool isDark) {
    if (isUser) return maroonColor;
    if (isError) return Colors.red.withValues(alpha: 0.05);
    return isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[100]!;
  }

  Color _bubbleTextColor(bool isUser, bool isError, bool isDark) {
    if (isUser) return Colors.white;
    if (isError) return Colors.red.shade700;
    return isDark ? Colors.white : const Color(0xFF2D3748);
  }

  Widget _buildScheduleCards(BuildContext context, List schedules) {
    final scrollController = ScrollController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (schedules.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 12),
              child: Row(
                children: [
                  Text(
                    '${schedules.length} schedules',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: maroonColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Swipe to view more',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.swipe_rounded,
                    size: 14,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 122,
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: schedules.length > 1,
              child: ListView.separated(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                primary: false,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(right: 12),
                itemCount: schedules.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final s = schedules[index];
                  return Container(
                    width: 208,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: maroonColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.subject?.name ?? 'Unknown Subject',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: maroonColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.room_outlined,
                              size: 10,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                s.room?.name ?? 'TBA',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 10,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                s.timeslot != null
                                    ? CITESchedDateUtils.formatTimeslot(
                                        s.timeslot!.day,
                                        s.timeslot!.startTime,
                                        s.timeslot!.endTime,
                                      )
                                    : 'TBA',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleExportActions(BuildContext context, List schedules) {
    final normalizedSchedules = schedules.whereType<Schedule>().toList();
    if (normalizedSchedules.isEmpty) return const SizedBox.shrink();

    final buttonStyle = OutlinedButton.styleFrom(
      foregroundColor: maroonColor,
      side: BorderSide(color: maroonColor.withValues(alpha: 0.35)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      textStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );

    Future<void> exportCsv() async {
      await ScheduleExportService.exportSchedulesCsv(
        title: 'CITESched_AI_Schedule',
        schedules: normalizedSchedules,
      );
    }

    Future<void> exportPdf() async {
      await ScheduleExportService.exportSchedulesPdf(
        title: 'CITESched AI Schedule',
        schedules: normalizedSchedules,
      );
    }

    Future<void> exportDocx() async {
      await ScheduleExportService.exportSchedulesDocx(
        title: 'CITESched AI Schedule',
        schedules: normalizedSchedules,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: exportCsv,
            style: buttonStyle,
            icon: const Icon(Icons.table_chart_rounded, size: 16),
            label: const Text('CSV'),
          ),
          OutlinedButton.icon(
            onPressed: exportPdf,
            style: buttonStyle,
            icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
            label: const Text('PDF'),
          ),
          OutlinedButton.icon(
            onPressed: exportDocx,
            style: buttonStyle,
            icon: const Icon(Icons.description_rounded, size: 16),
            label: const Text('DOCX'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSummary(BuildContext context, String dataJson) {
    final data = _parseSummaryData(dataJson);
    if (data == null || data['count'] == null) return const SizedBox();

    final count = data['count'] as int? ?? 0;
    final room = data['room'];
    final faculty = data['faculty'];

    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallChip(context, "Room: $room", Colors.orange),
              _buildSmallChip(context, "Faculty: $faculty", Colors.red),
            ],
          ),
          const SizedBox(height: 8),
          if (count > 0) _buildResolveConflictButton(context),
        ],
      ),
    );
  }

  Map<String, dynamic>? _parseSummaryData(String dataJson) {
    try {
      final parsed = jsonDecode(dataJson);
      if (parsed is Map<String, dynamic>) return parsed;
    } catch (_) {
      return null;
    }
    return null;
  }

  Widget _buildResolveConflictButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AdminLayout(initialIndex: 6),
            ),
          );
        },
        icon: const Icon(Icons.warning_rounded, size: 16),
        label: Text(
          'Resolve Conflicts',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red.shade400,
        ),
      ),
    );
  }

  Widget _buildTimetablePreview(
    BuildContext context,
    List schedules,
    bool showTimetable,
  ) {
    if (!showTimetable) return const SizedBox();
    final scheduleInfos = schedules
        .cast<Schedule>()
        .map((s) => ScheduleInfo(schedule: s, conflicts: const []))
        .toList();
    if (scheduleInfos.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timetable Preview',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: maroonColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: maroonColor.withValues(alpha: 0.15)),
            ),
            child: WeeklyCalendarView(
              schedules: scheduleInfos,
              maroonColor: maroonColor,
              isStudentView: true,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenCalendarScaffold(
                    title: 'Timetable',
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8F9FA),
                    child: WeeklyCalendarView(
                      schedules: scheduleInfos,
                      maroonColor: maroonColor,
                      isStudentView: true,
                    ),
                  ),
                ),
              ),
              icon: const Icon(Icons.fullscreen_rounded, size: 14),
              label: Text(
                'Full Screen',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(foregroundColor: maroonColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredSchedulePreview(
    BuildContext context,
    List schedules,
    String preferredView,
  ) {
    final scheduleInfos = schedules
        .cast<Schedule>()
        .map((s) => ScheduleInfo(schedule: s, conflicts: const []))
        .toList();
    if (scheduleInfos.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(left: 48, top: 4),
      child: _ChatScheduleViewSwitcher(
        maroonColor: maroonColor,
        isDark: Theme.of(context).brightness == Brightness.dark,
        scheduleInfos: scheduleInfos,
        preferredView: preferredView,
      ),
    );
  }

  Widget _buildSmallChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
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
}

enum _ChatScheduleView { table, calendar }

class _ChatScheduleViewSwitcher extends StatefulWidget {
  final Color maroonColor;
  final bool isDark;
  final List<ScheduleInfo> scheduleInfos;
  final String preferredView;

  const _ChatScheduleViewSwitcher({
    required this.maroonColor,
    required this.isDark,
    required this.scheduleInfos,
    required this.preferredView,
  });

  @override
  State<_ChatScheduleViewSwitcher> createState() =>
      _ChatScheduleViewSwitcherState();
}

class _ChatScheduleViewSwitcherState extends State<_ChatScheduleViewSwitcher> {
  late _ChatScheduleView _view;

  @override
  void initState() {
    super.initState();
    _view = widget.preferredView == 'table'
        ? _ChatScheduleView.table
        : _ChatScheduleView.calendar;
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white;
    final isTableView = _view == _ChatScheduleView.table;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Table View'),
              selected: isTableView,
              selectedColor: widget.maroonColor,
              checkmarkColor: Colors.white,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: isTableView
                    ? Colors.white
                    : (widget.isDark ? Colors.white70 : widget.maroonColor),
              ),
              onSelected: (_) => setState(() => _view = _ChatScheduleView.table),
            ),
            ChoiceChip(
              label: const Text('Calendar View'),
              selected: !isTableView,
              selectedColor: widget.maroonColor,
              checkmarkColor: Colors.white,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: !isTableView
                    ? Colors.white
                    : (widget.isDark ? Colors.white70 : widget.maroonColor),
              ),
              onSelected: (_) =>
                  setState(() => _view = _ChatScheduleView.calendar),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (isTableView)
          _buildScheduleTable(context, cardBg)
        else
          _buildScheduleCalendar(context, cardBg),
      ],
    );
  }

  Widget _buildScheduleTable(BuildContext context, Color cardBg) {
    final scrollController = ScrollController();
    final sorted = List<ScheduleInfo>.from(widget.scheduleInfos)
      ..sort((a, b) {
        final dayCompare =
            a.schedule.timeslot?.day.index.compareTo(b.schedule.timeslot?.day.index ?? 0) ?? 0;
        if (dayCompare != 0) return dayCompare;
        return (a.schedule.timeslot?.startTime ?? '').compareTo(
          b.schedule.timeslot?.startTime ?? '',
        );
      });

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.maroonColor.withValues(alpha: 0.15)),
      ),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Day')),
              DataColumn(label: Text('Time')),
              DataColumn(label: Text('Subject')),
              DataColumn(label: Text('Section')),
              DataColumn(label: Text('Room')),
            ],
            rows: sorted.map((info) {
              final s = info.schedule;
              final ts = s.timeslot;
              return DataRow(
                cells: [
                  DataCell(Text(ts?.day.name.toUpperCase() ?? 'TBA')),
                  DataCell(Text(
                    ts == null
                        ? 'TBA'
                        : '${ts.startTime} - ${ts.endTime}',
                  )),
                  DataCell(Text(s.subject?.name ?? s.subject?.code ?? 'Unknown')),
                  DataCell(Text(s.section)),
                  DataCell(Text(s.room?.name ?? 'TBA')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCalendar(BuildContext context, Color cardBg) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.maroonColor.withValues(alpha: 0.15)),
      ),
      child: WeeklyCalendarView(
        schedules: widget.scheduleInfos,
        maroonColor: widget.maroonColor,
        isStudentView: true,
      ),
    );
  }
}
