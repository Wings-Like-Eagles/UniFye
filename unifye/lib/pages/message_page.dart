import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/core/theme/app_colour.dart';

class MessagePage extends ConsumerStatefulWidget {
  final String userName;
  final String? imageUrl;

  const MessagePage({
    super.key,
    required this.userName,
    this.imageUrl,
  });

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage> {
  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      message: 'Hey 👋',
      isMine: false,
      sentAt: DateTime.now().subtract(
        const Duration(minutes: 12),
      ),
    ),
    ChatMessage(
      message: 'Hi there!',
      isMine: true,
      sentAt: DateTime.now().subtract(
        const Duration(minutes: 10),
      ),
    ),
    ChatMessage(
      message: 'How are you doing?',
      isMine: false,
      sentAt: DateTime.now().subtract(
        const Duration(minutes: 8),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: _buildAppBar(),
      ),

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                12,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

                return _buildMessageBubble(message);
              },
            ),
          ),

          _buildInputBar(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // App Bar
  // ─────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                ),
              ),

              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary,
                backgroundImage:
                widget.imageUrl != null
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

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
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

                    const Row(
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: Colors.green,
                        ),

                        SizedBox(width: 6),

                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () {},
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

  // ─────────────────────────────────────────────────────────────
  // Message Bubble
  // ─────────────────────────────────────────────────────────────

  Widget _buildMessageBubble(ChatMessage message) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          constraints: BoxConstraints(
            maxWidth:
            MediaQuery.of(context).size.width * 0.72,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
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
            color: isMine
                ? null
                : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(
                isMine ? 18 : 4,
              ),
              bottomRight: Radius.circular(
                isMine ? 4 : 18,
              ),
            ),
            border: isMine
                ? null
                : Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                message.message,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isMine
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  _formatTime(message.sentAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine
                        ? Colors.white70
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Input Bar
  // ─────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.border,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                  BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color:
                        AppColors.textSecondary,
                      ),
                    ),

                    Expanded(
                      child: TextField(
                        controller:
                        _messageController,
                        minLines: 1,
                        maxLines: 5,
                        decoration:
                        const InputDecoration(
                          hintText:
                          'Type a message...',
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.mic_none_rounded,
                        color:
                        AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Send Message
  // ─────────────────────────────────────────────────────────────

  void _sendMessage() {
    final text =
    _messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          message: text,
          isMine: true,
          sentAt: DateTime.now(),
        ),
      );
    });

    _messageController.clear();

    Future.delayed(
      const Duration(milliseconds: 100),
          () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(
            milliseconds: 300,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');

    final minute =
    date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

// ─────────────────────────────────────────────────────────────
// Chat Message Model
// ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String message;

  final bool isMine;

  final DateTime sentAt;

  ChatMessage({
    required this.message,
    required this.isMine,
    required this.sentAt,
  });
}
