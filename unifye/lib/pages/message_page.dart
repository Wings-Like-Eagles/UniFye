import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/core/theme/app_colour.dart';

import '../features/messages/models/chat_model.dart';
import '../features/messages/providers/message_provider.dart';

// ─────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────

class MessagePage extends ConsumerStatefulWidget {
  final String currentUserId; // <-- Added: needed to derive isMine
  final String userId;
  final String userName;
  final String? imageUrl;
  final bool isOnline;

  const MessagePage({
    super.key,
    required this.currentUserId,
    required this.userId,
    required this.userName,
    this.imageUrl,
    this.isOnline = false,
  });

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  bool _showSendButton = false;

  late final AnimationController _sendBtnController;

  // Fix: removed `final` so the list can be reassigned in setState
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _loadMessages();

    _sendBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _showSendButton) {
        setState(() => _showSendButton = hasText);
        if (hasText) {
          _sendBtnController.forward();
        } else {
          _sendBtnController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  /// Derives whether a message belongs to the current user.
  bool _isMine(ChatMessage message) =>
      message.senderId == widget.currentUserId;

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: _buildAppBar(),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Future<void> _loadMessages() async {
    try {
      final repository = ref.read(messageRepositoryProvider);

      final messages = await repository.getMessages(
        otherUserId: widget.userId,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── App Bar ──────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),

              // Avatar with gradient ring when online
              Container(
                decoration: widget.isOnline
                    ? const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                )
                    : null,
                padding:
                widget.isOnline ? const EdgeInsets.all(2) : null,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  backgroundImage: widget.imageUrl != null
                      ? NetworkImage(widget.imageUrl!)
                      : null,
                  child: widget.imageUrl == null
                      ? Text(
                    widget.userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                      : null,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    widget.isOnline
                        ? ShaderMask(
                      shaderCallback: (bounds) =>
                          const LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                            ],
                          ).createShader(bounds),
                      child: const Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    )
                        : const Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: _showChatOptions,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Message List ─────────────────────────────────────────

  Widget _buildMessageList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final prev = index > 0 ? _messages[index - 1] : null;
          final next = index < _messages.length - 1
              ? _messages[index + 1]
              : null;

          // Fix: use sentAtUtc instead of sentAt
          final showTimestamp = prev == null ||
              message.sentAtUtc
                  .difference(prev.sentAtUtc)
                  .inMinutes
                  .abs() >
                  10;

          // Fix: derive isMine via senderId comparison
          final isGroupedWithNext = next != null &&
              _isMine(next) == _isMine(message) &&
              message.sentAtUtc
                  .difference(next.sentAtUtc)
                  .inMinutes
                  .abs() <=
                  10;

          return Column(
            children: [
              if (showTimestamp)
                _buildTimestampDivider(message.sentAtUtc),
              _buildMessageBubble(
                message,
                groupedWithNext: isGroupedWithNext,
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Timestamp Divider ────────────────────────────────────

  Widget _buildTimestampDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.border.withOpacity(0),
                    AppColors.border,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatFullTime(date),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.border,
                    AppColors.border.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Message Bubble ───────────────────────────────────────

  Widget _buildMessageBubble(
      ChatMessage message, {
        required bool groupedWithNext,
      }) {
    // Fix: derive isMine locally
    final isMine = _isMine(message);

    const r18 = Radius.circular(18);
    const r4 = Radius.circular(4);

    final borderRadius = BorderRadius.only(
      topLeft: r18,
      topRight: r18,
      bottomLeft: isMine ? r18 : (groupedWithNext ? r4 : r18),
      bottomRight: isMine ? (groupedWithNext ? r4 : r18) : r18,
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _onMessageLongPress(message),
        child: Container(
          margin: EdgeInsets.only(
            bottom: groupedWithNext ? 3 : 10,
            left: isMine ? 60 : 0,
            right: isMine ? 0 : 60,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            gradient: isMine
                ? const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            )
                : null,
            color: isMine ? null : AppColors.surface,
            borderRadius: borderRadius,
            border:
            isMine ? null : Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: isMine
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // Fix: use content instead of message
                message.content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color:
                  isMine ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    // Fix: use sentAtUtc instead of sentAt
                    _formatTime(message.sentAtUtc),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? Colors.white60
                          : AppColors.textSecondary,
                    ),
                  ),
                  // Fix: MessageStatus removed — model has no status field.
                  // Show a static sent indicator for own messages only.
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all_rounded,
                      size: 13,
                      color: Colors.white60,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Input Bar ────────────────────────────────────────────

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _InputIconButton(
              icon: Icons.add_rounded,
              onTap: () {},
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                          EdgeInsets.symmetric(vertical: 12),
                          isCollapsed: false,
                        ),
                      ),
                    ),
                    if (!_showSendButton)
                      _InputIconButton(
                        icon: Icons.mic_none_rounded,
                        onTap: () {},
                        padding: const EdgeInsets.only(right: 4),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: _showSendButton
                  ? _SendButton(
                key: const ValueKey('send'),
                onTap: _sendMessage,
              )
                  : _InputIconButton(
                key: const ValueKey('mic'),
                icon: Icons.mic_none_rounded,
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final repository = ref.read(messageRepositoryProvider);

      final message = await repository.sendMessage(
        receiverId: widget.userId,
        message: text,
      );

      setState(() => _messages.add(message));
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _onMessageLongPress(ChatMessage message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MessageOptionsSheet(
        message: message,
        isMine: _isMine(message),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ChatOptionsSheet(userName: widget.userName),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Formatters
  // ─────────────────────────────────────────────────────────────

  String _formatTime(DateTime date) {
    final h = date.toLocal().hour.toString().padLeft(2, '0');
    final m = date.toLocal().minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatFullTime(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);
    if (diff.inDays == 0) return 'Today ${_formatTime(date)}';
    if (diff.inDays == 1) return 'Yesterday ${_formatTime(date)}';
    return '${local.day}/${local.month}/${local.year} ${_formatTime(date)}';
  }
}

// ─────────────────────────────────────────────────────────────
// Send Button
// ─────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Input Icon Button
// ─────────────────────────────────────────────────────────────

class _InputIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  const _InputIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Message Options Bottom Sheet
// ─────────────────────────────────────────────────────────────

class _MessageOptionsSheet extends StatelessWidget {
  final ChatMessage message;
  // Fix: isMine passed in since the sheet has no access to currentUserId
  final bool isMine;

  const _MessageOptionsSheet({
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _SheetTile(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: () {
              // Fix: use content instead of message
              Clipboard.setData(ClipboardData(text: message.content));
              Navigator.pop(context);
            },
          ),
          _SheetTile(
            icon: Icons.reply_rounded,
            label: 'Reply',
            onTap: () => Navigator.pop(context),
          ),
          // Fix: use passed isMine instead of message.isMine
          if (isMine)
            _SheetTile(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              isDestructive: true,
              onTap: () => Navigator.pop(context),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Chat Options Bottom Sheet
// ─────────────────────────────────────────────────────────────

class _ChatOptionsSheet extends StatelessWidget {
  final String userName;

  const _ChatOptionsSheet({required this.userName});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          _SheetTile(
            icon: Icons.person_outline_rounded,
            label: 'View Profile',
            onTap: () => Navigator.pop(context),
          ),
          _SheetTile(
            icon: Icons.notifications_off_outlined,
            label: 'Mute Notifications',
            onTap: () => Navigator.pop(context),
          ),
          _SheetTile(
            icon: Icons.block_rounded,
            label: 'Block $userName',
            isDestructive: true,
            onTap: () => Navigator.pop(context),
          ),
          _SheetTile(
            icon: Icons.flag_outlined,
            label: 'Report',
            isDestructive: true,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Sheet Tile
// ─────────────────────────────────────────────────────────────

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
    isDestructive ? const Color(0xFFEF4444) : AppColors.textPrimary;

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }
}
