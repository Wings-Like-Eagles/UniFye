import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/core/theme/app_colour.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────

enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  final String id;
  final String message;
  final bool isMine;
  final DateTime sentAt;
  final MessageStatus status;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isMine,
    required this.sentAt,
    this.status = MessageStatus.sent,
  });

  ChatMessage copyWith({MessageStatus? status}) {
    return ChatMessage(
      id: id,
      message: message,
      isMine: isMine,
      sentAt: sentAt,
      status: status ?? this.status,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────

class MessagePage extends ConsumerStatefulWidget {
  final String userId;
  final String userName;
  final String? imageUrl;
  final bool isOnline;

  const MessagePage({
    super.key,
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

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      message: 'Hey 👋',
      isMine: false,
      sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
      status: MessageStatus.read,
    ),
    ChatMessage(
      id: '2',
      message: 'Hi there! How\'s it going? 😊',
      isMine: true,
      sentAt: DateTime.now().subtract(const Duration(minutes: 10)),
      status: MessageStatus.read,
    ),
    ChatMessage(
      id: '3',
      message: 'How are you doing?',
      isMine: false,
      sentAt: DateTime.now().subtract(const Duration(minutes: 8)),
      status: MessageStatus.read,
    ),
    ChatMessage(
      id: '4',
      message: 'Doing great, thanks for asking! Any plans this weekend?',
      isMine: true,
      sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
      status: MessageStatus.delivered,
    ),
  ];

  @override
  void initState() {
    super.initState();

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
                    ? BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
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

          final showTimestamp = prev == null ||
              message.sentAt
                  .difference(prev.sentAt)
                  .inMinutes
                  .abs() >
                  10;

          final isGroupedWithNext = next != null &&
              next.isMine == message.isMine &&
              message.sentAt
                  .difference(next.sentAt)
                  .inMinutes
                  .abs() <=
                  10;

          return Column(
            children: [
              if (showTimestamp)
                _buildTimestampDivider(message.sentAt),
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
    final isMine = message.isMine;

    const r18 = Radius.circular(18);
    const r4 = Radius.circular(4);

    final borderRadius = BorderRadius.only(
      topLeft: r18,
      topRight: r18,
      bottomLeft: isMine ? r18 : (groupedWithNext ? r4 : r18),
      bottomRight: isMine ? (groupedWithNext ? r4 : r18) : r18,
    );

    return Align(
      alignment:
      isMine ? Alignment.centerRight : Alignment.centerLeft,
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
              colors: [
                AppColors.primary,
                AppColors.secondary,
              ],
            )
                : null,
            color: isMine ? null : AppColors.surface,
            borderRadius: borderRadius,
            border: isMine
                ? null
                : Border.all(color: AppColors.border),
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
                message.message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isMine
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.sentAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? Colors.white60
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(message.status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Status Icon ──────────────────────────────────────────

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white60,
          ),
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.check_rounded,
          size: 13,
          color: Colors.white60,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all_rounded,
          size: 13,
          color: Colors.white60,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all_rounded,
          size: 13,
          color: Colors.white,
        );
    }
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
            // Attach button
            _InputIconButton(
              icon: Icons.add_rounded,
              onTap: () {},
            ),

            const SizedBox(width: 8),

            // Text field
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
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          isCollapsed: false,
                        ),
                      ),
                    ),
                    if (!_showSendButton)
                      _InputIconButton(
                        icon: Icons.mic_none_rounded,
                        onTap: () {},
                        padding:
                        const EdgeInsets.only(right: 4),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send / Mic toggle
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: text,
      isMine: true,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    setState(() => _messages.add(newMessage));
    _messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Simulate status progression
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        final idx =
        _messages.indexWhere((m) => m.id == newMessage.id);
        if (idx != -1) {
          _messages[idx] =
              _messages[idx].copyWith(status: MessageStatus.sent);
        }
      });
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        final idx =
        _messages.indexWhere((m) => m.id == newMessage.id);
        if (idx != -1) {
          _messages[idx] = _messages[idx]
              .copyWith(status: MessageStatus.delivered);
        }
      });
    });
  }

  void _onMessageLongPress(ChatMessage message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MessageOptionsSheet(message: message),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _ChatOptionsSheet(userName: widget.userName),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatFullTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today ${_formatTime(date)}';
    if (diff.inDays == 1) return 'Yesterday ${_formatTime(date)}';
    return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
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
            child: Icon(icon,
                color: AppColors.textSecondary, size: 22),
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

  const _MessageOptionsSheet({required this.message});

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
              Clipboard.setData(
                  ClipboardData(text: message.message));
              Navigator.pop(context);
            },
          ),
          _SheetTile(
            icon: Icons.reply_rounded,
            label: 'Reply',
            onTap: () => Navigator.pop(context),
          ),
          if (message.isMine)
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
