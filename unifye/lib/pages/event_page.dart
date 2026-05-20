import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:unifye/core/theme/app_colour.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';
import 'package:unifye/features/event/models/event_summary_model.dart';
import 'package:unifye/widgets/app_button.dart';
import 'package:unifye/main.dart' show baseUrl;

import '../features/auth/models/auth_state.dart';
import '../features/messages/models/chat_model.dart';
// =============================================================================
// Providers
// =============================================================================

final eventsProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<EventSummary>>>((ref) {
  return EventsNotifier(ref);
});

class EventsNotifier extends StateNotifier<AsyncValue<List<EventSummary>>> {
  EventsNotifier(this._ref) : super(const AsyncValue.loading());

  final Ref _ref;

  Future<void> fetchEvents() async {
    state = const AsyncValue.loading();
    try {
      final token = _ref.read(authProvider).token;
      final response = await http.get(
        Uri.parse('$baseUrl/api/event'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        print('Events raw response: ${response.body}'); // ← add this
        final List<dynamic> json = jsonDecode(response.body);
        state = AsyncValue.data(json.map((e) => EventSummary.fromJson(e)).toList());
      } else {
        print('Events fetch failed: ${response.statusCode} ${response.body}');
        state = AsyncValue.error('Failed to load events', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> joinEvent(String eventId) async {
    try {
      final token = _ref.read(authProvider).token;
      final response = await http.post(
        Uri.parse('$baseUrl/api/event/$eventId/join'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        await fetchEvents();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> leaveEvent(String eventId) async {
    try {
      final token = _ref.read(authProvider).token;
      final response = await http.delete(
        Uri.parse('$baseUrl/api/event/$eventId/leave'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        await fetchEvents();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createEvent(Map<String, dynamic> payload) async {
    try {
      final token = _ref.read(authProvider).token;
      final response = await http.post(
        Uri.parse('$baseUrl/api/event'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      if (response.statusCode == 201) {
        await fetchEvents();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

final chatProvider = StateNotifierProvider.family<ChatNotifier, AsyncValue<List<ChatMessage>>, String>((ref, eventId) {
  return ChatNotifier(ref, eventId);
});

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  ChatNotifier(this._ref, this._eventId) : super(const AsyncValue.loading());

  final Ref _ref;
  final String _eventId;

  Future<void> fetchMessages() async {
    try {
      final token = _ref
          .read(authProvider)
          .token;
      final response = await http.get(
        Uri.parse('$baseUrl/api/event/$_eventId/chat'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        state =
            AsyncValue.data(json.map((e) => ChatMessage.fromJson(e)).toList());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendMessage(String content) async {
    try {
      final token = _ref
          .read(authProvider)
          .token;
      final response = await http.post(
        Uri.parse('$baseUrl/api/event/$_eventId/chat'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'content': content}),
      );
      if (response.statusCode == 200) {
        await fetchMessages();
      }
    } catch (_) {}
  }
}

// Extension to safely read token from auth state
extension AuthStateX on AuthState {
  String? get token => maybeWhen(authenticated: (_, t) => t, orElse: () => null);
}

// =============================================================================
// Events Page
// =============================================================================

class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventsProvider.notifier).fetchEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: eventsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => _buildError(),
              data: (events) => events.isEmpty ? _buildEmpty() : _buildEventList(context, events),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  // ─── Sliver App Bar ────────────────────────────────────────────────────────

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Events',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Meet your campus community',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Quick stats strip
                  Row(
                    children: [
                      _buildHeaderStat(Icons.event_available_rounded, 'Upcoming'),
                      const SizedBox(width: 16),
                      _buildHeaderStat(Icons.people_rounded, 'Join & Connect'),
                      const SizedBox(width: 16),
                      _buildHeaderStat(Icons.chat_bubble_rounded, 'Group Chat'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // ─── Event List ────────────────────────────────────────────────────────────

  Widget _buildEventList(BuildContext context, List<EventSummary> events) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSectionLabel('Upcoming Events'),
          ...events.map((event) => _buildEventCard(context, event)),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, EventSummary event) {
    final isFull = event.maxAttendees != null && event.attendeeCount >= event.maxAttendees!;
    final spotsLeft = event.maxAttendees != null ? event.maxAttendees! - event.attendeeCount : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: event.isAttending
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.border,
              ),
              boxShadow: event.isAttending
                  ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date badge
                      _buildDateBadge(event.startsAtUtc),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (event.isAttending)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Joined',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Time
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded,
                                    size: 12, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(event.startsAtUtc),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (event.locationName != null) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded,
                                      size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      event.locationName!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Description ──
                if (event.description != null && event.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Text(
                      event.description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                // ── Footer ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Row(
                    children: [
                      // Attendee avatars
                      _buildAttendeeCount(event.attendeeCount, event.maxAttendees),
                      const Spacer(),
                      if (spotsLeft != null && !isFull)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            '$spotsLeft left',
                            style: TextStyle(
                              fontSize: 12,
                              color: spotsLeft <= 3
                                  ? Colors.orange.shade700
                                  : AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Consumer(
                        builder: (context, ref, _) {
                          return AppButton(
                            onPressed: isFull && !event.isAttending
                                ? null
                                : () => _handleJoinLeave(ref, event),
                            text: isFull && !event.isAttending
                                ? 'Full'
                                : event.isAttending
                                ? 'Leave'
                                : 'Join',
                            type: event.isAttending
                                ? AppButtonType.outline
                                : AppButtonType.primary,
                            size: AppButtonSize.small,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateBadge(DateTime date) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            _monthAbbr(date),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          Text(
            date.day.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(
            _weekday(date),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeCount(int count, int? max) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.people_rounded,
              color: AppColors.primary, size: 14),
        ),
        const SizedBox(width: 6),
        Text(
          max != null ? '$count / $max' : '$count attending',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _handleJoinLeave(WidgetRef ref, EventSummary event) async {
    final notifier = ref.read(eventsProvider.notifier);
    if (event.isAttending) {
      await notifier.leaveEvent(event.id);
    } else {
      await notifier.joinEvent(event.id);
    }
  }

  // ─── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateEventSheet(context),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Create Event',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ─── Empty / Error ─────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_outlined,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'No events yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first to create one!',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.textTertiary, size: 40),
          const SizedBox(height: 12),
          const Text('Could not load events',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          AppButton(
            onPressed: () => ref.read(eventsProvider.notifier).fetchEvents(),
            text: 'Retry',
            type: AppButtonType.outline,
            size: AppButtonSize.small,
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  String _monthAbbr(DateTime dt) {
    const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return months[dt.month - 1];
  }

  String _weekday(DateTime dt) {
    const days = ['MON','TUE','WED','THU','FRI','SAT','SUN'];
    return days[dt.weekday - 1];
  }

  // ─── Create Event Bottom Sheet ─────────────────────────────────────────────

  void _showCreateEventSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateEventSheet(),
    );
  }
}

// =============================================================================
// Create Event Bottom Sheet
// =============================================================================

class _CreateEventSheet extends ConsumerStatefulWidget {
  const _CreateEventSheet();

  @override
  ConsumerState<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<_CreateEventSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationNameCtrl = TextEditingController();
  final _locationAddressCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationNameCtrl.dispose();
    _locationAddressCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a date and time.')),
      );
      return;
    }

    final startsAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    ).toUtc();

    setState(() => _loading = true);

    final success = await ref.read(eventsProvider.notifier).createEvent({
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      'startsAtUtc': startsAt.toIso8601String(),
      'locationName': _locationNameCtrl.text.trim().isEmpty ? null : _locationNameCtrl.text.trim(),
      'locationAddress': _locationAddressCtrl.text.trim().isEmpty ? null : _locationAddressCtrl.text.trim(),
      'maxAttendees': _maxCtrl.text.trim().isEmpty ? null : int.tryParse(_maxCtrl.text.trim()),
    });

    setState(() => _loading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create event. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.celebration_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Create Event',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSheetLabel('Event Details'),
                    _buildField(_titleCtrl, 'Title *', Icons.title_rounded, maxLines: 1),
                    const SizedBox(height: 12),
                    _buildField(_descCtrl, 'Description', Icons.notes_rounded, maxLines: 3),
                    const SizedBox(height: 20),
                    _buildSheetLabel('Date & Time'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerTile(
                            icon: Icons.calendar_today_rounded,
                            label: _selectedDate == null
                                ? 'Pick Date'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPickerTile(
                            icon: Icons.access_time_rounded,
                            label: _selectedTime == null
                                ? 'Pick Time'
                                : _selectedTime!.format(context),
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSheetLabel('Location'),
                    _buildField(_locationNameCtrl, 'Venue name (e.g. Main Hall)',
                        Icons.business_rounded, maxLines: 1),
                    const SizedBox(height: 12),
                    _buildField(_locationAddressCtrl, 'Address',
                        Icons.location_on_rounded, maxLines: 2),
                    const SizedBox(height: 20),
                    _buildSheetLabel('Capacity'),
                    _buildField(_maxCtrl, 'Max attendees (leave blank for unlimited)',
                        Icons.people_rounded,
                        maxLines: 1,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 32),
                    AppButton(
                      onPressed: _loading ? null : _submit,
                      text: _loading ? 'Creating...' : 'Create Event',
                      type: AppButtonType.primary,
                      isFullWidth: true,
                      size: AppButtonSize.large,
                      icon: _loading ? null : Icons.celebration_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl,
      String hint,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Event Detail Page (with Chat Tab)
// =============================================================================

class EventDetailPage extends ConsumerStatefulWidget {
  final EventSummary event;

  const EventDetailPage({super.key, required this.event});

  @override
  ConsumerState<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends ConsumerState<EventDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.event.isAttending) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatProvider(widget.event.id).notifier).fetchMessages();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildSliverAppBar()],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(),
                  widget.event.isAttending
                      ? _buildChatTab()
                      : _buildChatLockedState(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Date badge row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatEventDate(widget.event.startsAtUtc),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.event.isAttending)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('Attending',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'by ${widget.event.organiserName}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textTertiary,
        indicatorColor: AppColors.primary,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'Group Chat'),
        ],
      ),
    );
  }

  // ─── Details Tab ───────────────────────────────────────────────────────────

  Widget _buildDetailsTab() {
    final ev = widget.event;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info cards
          _buildInfoCard(
            icon: Icons.access_time_rounded,
            title: 'Date & Time',
            content: _formatEventDate(ev.startsAtUtc),
            subtitle: ev.endsAtUtc != null
                ? 'Ends at ${_formatTime(ev.endsAtUtc!)}'
                : null,
          ),
          if (ev.locationName != null || ev.locationAddress != null)
            _buildInfoCard(
              icon: Icons.location_on_rounded,
              title: 'Location',
              content: ev.locationName ?? ev.locationAddress!,
              subtitle: ev.locationName != null ? ev.locationAddress : null,
            ),
          _buildInfoCard(
            icon: Icons.people_rounded,
            title: 'Attendees',
            content: ev.maxAttendees != null
                ? '${ev.attendeeCount} / ${ev.maxAttendees} people'
                : '${ev.attendeeCount} attending',
            subtitle: ev.maxAttendees != null
                ? '${ev.maxAttendees! - ev.attendeeCount} spots remaining'
                : 'Unlimited capacity',
          ),
          if (ev.description != null && ev.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildSectionLabel('About'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                ev.description!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Consumer(
            builder: (ctx, ref, _) {
              final isFull = ev.maxAttendees != null &&
                  ev.attendeeCount >= ev.maxAttendees!;
              return AppButton(
                onPressed: isFull && !ev.isAttending
                    ? null
                    : () => _handleJoinLeave(ref),
                text: ev.isAttending ? 'Leave Event' : isFull ? 'Event Full' : 'Join Event',
                type: ev.isAttending ? AppButtonType.outline : AppButtonType.primary,
                isFullWidth: true,
                size: AppButtonSize.large,
                icon: ev.isAttending
                    ? Icons.logout_rounded
                    : Icons.celebration_rounded,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    String? subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleJoinLeave(WidgetRef ref) async {
    final notifier = ref.read(eventsProvider.notifier);
    if (widget.event.isAttending) {
      await notifier.leaveEvent(widget.event.id);
    } else {
      final joined = await notifier.joinEvent(widget.event.id);
      if (joined && mounted) {
        ref.read(chatProvider(widget.event.id).notifier).fetchMessages();
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ─── Chat Tab ──────────────────────────────────────────────────────────────

  Widget _buildChatLockedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 20),
            const Text(
              'Join to chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join the event to access the group chat and connect with other attendees.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTab() {
    return _ChatView(eventId: widget.event.id);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _formatEventDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · $h:$m $ampm';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }
}

// =============================================================================
// Chat View (extracted widget so it has its own lifecycle)
// =============================================================================

class _ChatView extends ConsumerStatefulWidget {
  final String eventId;

  const _ChatView({required this.eventId});

  @override
  ConsumerState<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<_ChatView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();

    await ref.read(chatProvider(widget.eventId).notifier).sendMessage(text);

    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider(widget.eventId));
    final authState = ref.watch(authProvider);
    final currentUserId = authState.maybeWhen(
      authenticated: (user, _) => user.id,
      orElse: () => '',
    );

    return Column(
      children: [
        Expanded(
          child: chatAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, __) => const Center(
              child: Text('Could not load messages.',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            data: (messages) => messages.isEmpty
                ? const Center(
              child: Text(
                'No messages yet.\nBe the first to say hello! 👋',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              ),
            )
                : ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) => _buildMessageBubble(
                messages[i],
                isMe: messages[i].senderId == currentUserId,
                showSender: i == 0 ||
                    messages[i].senderId != messages[i - 1].senderId,
              ),
            ),
          ),
        ),
        // Input bar
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, MediaQuery.of(context).viewInsets.bottom + 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: _sending
                      ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(
      ChatMessage message, {
        required bool isMe,
        required bool showSender,
      }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 4,
        top: showSender ? 12 : 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            if (showSender)
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage: message.senderImageUrl != null
                    ? NetworkImage('$baseUrl${message.senderImageUrl}')
                    : null,
                child: message.senderImageUrl == null
                    ? Text(
                  message.senderName.isNotEmpty
                      ? message.senderName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700),
                )
                    : null,
              )
            else
              const SizedBox(width: 32),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (showSender && !isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    message.senderName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isMe
                      ? const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: isMe ? null : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  border: isMe
                      ? null
                      : Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: isMe ? Colors.white : AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
