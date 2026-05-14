import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/core/theme/app_colour.dart';

import 'message_page.dart';

// ─────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────

class ConversationPreview {
  final String userId;
  final String userName;
  final String? imageUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  const ConversationPreview({
    required this.userId,
    required this.userName,
    this.imageUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isOnline = false,
  });
}

// ─────────────────────────────────────────────────────────────
// Mock data — replace with your Riverpod provider / API
// ─────────────────────────────────────────────────────────────

final _mockConversations = [
  ConversationPreview(
    userId: '1',
    userName: 'Sophia',
    lastMessage: 'Are you free this weekend? 😊',
    lastMessageAt: DateTime.now().subtract(const Duration(minutes: 3)),
    unreadCount: 2,
    isOnline: true,
  ),
  ConversationPreview(
    userId: '2',
    userName: 'Mia',
    lastMessage: 'That sounds amazing, let\'s do it!',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
    unreadCount: 0,
    isOnline: true,
  ),
  ConversationPreview(
    userId: '3',
    userName: 'Leah',
    lastMessage: 'Haha okay 😂',
    lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
    unreadCount: 0,
    isOnline: false,
  ),
  ConversationPreview(
    userId: '4',
    userName: 'Emma',
    lastMessage: 'You never told me you could play guitar!',
    lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
    unreadCount: 1,
    isOnline: false,
  ),
  ConversationPreview(
    userId: '5',
    userName: 'Jade',
    lastMessage: 'Good morning ☀️',
    lastMessageAt: DateTime.now().subtract(const Duration(days: 2)),
    unreadCount: 0,
    isOnline: false,
  ),
];

// ─────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() =>
      _ConversationsPageState();
}

class _ConversationsPageState
    extends ConsumerState<ConversationsPage> {
  final TextEditingController _searchController =
  TextEditingController();

  String _searchQuery = '';

  List<ConversationPreview> get _filtered {
    if (_searchQuery.isEmpty) return _mockConversations;
    return _mockConversations
        .where((c) => c.userName
        .toLowerCase()
        .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildOnlineRow(),
            const SizedBox(height: 8),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_mockConversations.length} conversations',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          _GradientIconButton(
            icon: Icons.edit_outlined,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search messages...',
                  hintStyle: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Online Now Row ───────────────────────────────────────

  Widget _buildOnlineRow() {
    final online =
    _mockConversations.where((c) => c.isOnline).toList();
    if (online.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            'Online Now',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: online.length,
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final c = online[index];
              return GestureDetector(
                onTap: () => _openChat(c),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        _buildAvatar(
                          name: c.userName,
                          imageUrl: c.imageUrl,
                          radius: 28,
                          hasBorder: true,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.background,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c.userName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'All Messages',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ─── Conversation List ────────────────────────────────────

  Widget _buildList() {
    final list = _filtered;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 52,
              color: AppColors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'No conversations found',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) =>
          _ConversationTile(
            conversation: list[index],
            onTap: () => _openChat(list[index]),
          ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────

  void _openChat(ConversationPreview c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagePage(
          userId: c.userId,
          userName: c.userName,
          imageUrl: c.imageUrl,
          isOnline: c.isOnline,
        ),
      ),
    );
  }

  Widget _buildAvatar({
    required String name,
    String? imageUrl,
    required double radius,
    bool hasBorder = false,
  }) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      backgroundImage:
      imageUrl != null ? NetworkImage(imageUrl) : null,
      child: imageUrl == null
          ? Text(
        name[0].toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.7,
        ),
      )
          : null,
    );

    if (hasBorder) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.background,
          child: CircleAvatar(
            radius: radius - 2,
            backgroundColor: AppColors.primary,
            backgroundImage:
            imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? Text(
              name[0].toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.7,
              ),
            )
                : null,
          ),
        ),
      );
    }

    return avatar;
  }
}

// ─────────────────────────────────────────────────────────────
// Conversation Tile
// ─────────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  final ConversationPreview conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: hasUnread
                ? AppColors.primary.withOpacity(0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnread
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    backgroundImage: conversation.imageUrl != null
                        ? NetworkImage(conversation.imageUrl!)
                        : null,
                    child: conversation.imageUrl == null
                        ? Text(
                      conversation.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    )
                        : null,
                  ),
                  if (conversation.isOnline)
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.userName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(conversation.lastMessageAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            style: TextStyle(
                              fontSize: 13,
                              color: hasUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 20,
                            ),
                            height: 20,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                              ),
                              borderRadius:
                              BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${conversation.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}';
  }
}

// ─────────────────────────────────────────────────────────────
// Gradient Icon Button
// ─────────────────────────────────────────────────────────────

class _GradientIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GradientIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.edit_outlined,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}
