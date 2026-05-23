import 'dart:io';
import 'dart:ui' as BorderType;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colour.dart';
import '../../features/event/providers/event_provider.dart';
import '../app_button.dart';

class _CreateEventSheet extends ConsumerStatefulWidget {
  const _CreateEventSheet();

  @override
  ConsumerState<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<_CreateEventSheet>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────────
  final _titleCtrl        = TextEditingController();
  final _descCtrl         = TextEditingController();
  final _locationNameCtrl = TextEditingController();
  final _locationAddressCtrl = TextEditingController();
  final _maxCtrl          = TextEditingController();

  // ── State ───────────────────────────────────────────────────────────────────
  DateTime?   _selectedDate;
  TimeOfDay?  _selectedTime;
  bool        _loading      = false;
  XFile?      _posterFile;           // picked image
  bool        _posterLoading = false; // while ImagePicker is opening

  // ── Animation ───────────────────────────────────────────────────────────────
  late final AnimationController _previewFadeCtrl;
  late final Animation<double>   _previewFade;
  late final AnimationController _previewScaleCtrl;
  late final Animation<double>   _previewScale;

  @override
  void initState() {
    super.initState();
    _previewFadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350),
    );
    _previewFade = CurvedAnimation(
      parent: _previewFadeCtrl, curve: Curves.easeOut,
    );
    _previewScaleCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400),
    );
    _previewScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _previewScaleCtrl, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationNameCtrl.dispose();
    _locationAddressCtrl.dispose();
    _maxCtrl.dispose();
    _previewFadeCtrl.dispose();
    _previewScaleCtrl.dispose();
    super.dispose();
  }

  // ── Image Picker ─────────────────────────────────────────────────────────────
  Future<void> _pickPoster({bool fromCamera = false}) async {
    // Dismiss any open keyboard first
    FocusScope.of(context).unfocus();

    setState(() => _posterLoading = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 900,
        imageQuality: 88,
      );
      if (file != null) {
        setState(() => _posterFile = file);
        // Play reveal animation
        _previewFadeCtrl.forward(from: 0);
        _previewScaleCtrl.forward(from: 0);
      }
    } finally {
      setState(() => _posterLoading = false);
    }
  }

  void _removePoster() {
    _previewFadeCtrl.reverse().then((_) {
      if (mounted) setState(() => _posterFile = null);
    });
  }

  void _showPosterSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PosterSourceSheet(
        onGallery: () { Navigator.pop(context); _pickPoster(); },
        onCamera:  () { Navigator.pop(context); _pickPoster(fromCamera: true); },
        onRemove:  _posterFile != null ? () { Navigator.pop(context); _removePoster(); } : null,
      ),
    );
  }

  // ── Date / Time ──────────────────────────────────────────────────────────────
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

  // ── Submit ───────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an event title.')),
      );
      return;
    }
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

    // Pass posterFile to your notifier — update createEvent() signature as needed
    final success = await ref.read(eventsProvider.notifier).createEvent(
      {
        'title':           _titleCtrl.text.trim(),
        'description':     _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'startsAtUtc':     startsAt.toIso8601String(),
        'locationName':    _locationNameCtrl.text.trim().isEmpty ? null : _locationNameCtrl.text.trim(),
        'locationAddress': _locationAddressCtrl.text.trim().isEmpty ? null : _locationAddressCtrl.text.trim(),
        'maxAttendees':    _maxCtrl.text.trim().isEmpty ? null : int.tryParse(_maxCtrl.text.trim()),
      },
      // posterFile: _posterFile, // ← add this param to your notifier
    );

    setState(() => _loading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create event. Please try again.')),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────
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
            // ── Handle ────────────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Header ────────────────────────────────────────────────────
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

            // ── Scrollable body ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── POSTER ──────────────────────────────────────────
                    _buildPosterSection(),
                    const SizedBox(height: 24),

                    // ── EVENT DETAILS ───────────────────────────────────
                    _buildSheetLabel('Event Details'),
                    _buildField(_titleCtrl, 'Title *', Icons.title_rounded, maxLines: 1),
                    const SizedBox(height: 12),
                    _buildField(_descCtrl, 'Description', Icons.notes_rounded, maxLines: 3),
                    const SizedBox(height: 20),

                    // ── DATE & TIME ─────────────────────────────────────
                    _buildSheetLabel('Date & Time'),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPickerTile(
                            icon: Icons.calendar_today_rounded,
                            label: _selectedDate == null
                                ? 'Pick Date'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                            isSet: _selectedDate != null,
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
                            isSet: _selectedTime != null,
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── LOCATION ────────────────────────────────────────
                    _buildSheetLabel('Location'),
                    _buildField(_locationNameCtrl, 'Venue name (e.g. Main Hall)',
                        Icons.business_rounded, maxLines: 1),
                    const SizedBox(height: 12),
                    _buildField(_locationAddressCtrl, 'Address',
                        Icons.location_on_rounded, maxLines: 2),
                    const SizedBox(height: 20),

                    // ── CAPACITY ────────────────────────────────────────
                    _buildSheetLabel('Capacity'),
                    _buildField(
                      _maxCtrl,
                      'Max attendees (leave blank for unlimited)',
                      Icons.people_rounded,
                      maxLines: 1,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),

                    // ── SUBMIT ──────────────────────────────────────────
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

  // ── Poster Section ───────────────────────────────────────────────────────────

  Widget _buildPosterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSheetLabel('Event Poster'),
            if (_posterFile != null)
              GestureDetector(
                onTap: _showPosterSourceSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_rounded, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),

        // ── Preview card or upload zone ──────────────────────────────────────
        _posterFile != null
            ? _buildPosterPreview()
            : _buildPosterUploadZone(),
      ],
    );
  }

  /// Full-height preview with a live mock of how the card will look.
  Widget _buildPosterPreview() {
    return FadeTransition(
      opacity: _previewFade,
      child: ScaleTransition(
        scale: _previewScale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── The actual poster preview ──────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Real image
                    Image.file(
                      File(_posterFile!.path),
                      fit: BoxFit.cover,
                    ),

                    // Gradient scrim (matches card rendering)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.55),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // "Looks great" chip – top left
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildChip(
                        Icons.auto_awesome_rounded,
                        'Preview',
                        Colors.white.withOpacity(0.18),
                        Colors.white,
                      ),
                    ),

                    // Remove button – top right
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: _removePoster,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),

                    // Date badge placeholder (bottom-left, mirrors EventCard)
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: _buildMockDateBadge(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Tip row ───────────────────────────────────────────────────────
            const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 12, color: AppColors.textTertiary),
                 SizedBox(width: 5),
                 Text(
                  'This is how your poster will appear on the event card.',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Dotted-border upload zone shown before an image is selected.
  Widget _buildPosterUploadZone() {
    return GestureDetector(
      onTap: _showPosterSourceSheet,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.primary.withOpacity(0.35),
          strokeWidth: 1.8,
          dashWidth: 8,
          gapWidth: 5,
          radius: 20,
        ),
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
          ),
          child: _posterLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          )
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.15),
                      AppColors.secondary.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add Event Poster',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to upload from gallery or camera',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['JPG', 'PNG', 'WEBP'].map((fmt) =>
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        fmt,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mini date badge that mirrors what shows on the event card, so the user
  /// can see exactly how their poster will look in context.
  Widget _buildMockDateBadge() {
    final now = _selectedDate ?? DateTime.now().add(const Duration(days: 1));
    const months = ['JAN','FEB','MAR','APR','MAY','JUN',
      'JUL','AUG','SEP','OCT','NOV','DEC'];
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  months[now.month - 1],
                  style: const TextStyle(
                    color: Colors.white70, fontSize: 9,
                    fontWeight: FontWeight.w700, letterSpacing: 0.8,
                  ),
                ),
                Text(
                  now.day.toString(),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w900, height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                days[now.weekday - 1],
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'TBD',
                style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── Shared field builders (unchanged) ────────────────────────────────────────

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
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSet = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSet
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSet ? AppColors.primary.withOpacity(0.35) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSet ? AppColors.primary : AppColors.textTertiary,
                size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSet ? AppColors.textPrimary : AppColors.textTertiary,
                  fontWeight: isSet ? FontWeight.w600 : FontWeight.w500,
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
// Poster Source Sheet  (small bottom sheet for gallery / camera / remove)
// =============================================================================

class _PosterSourceSheet extends StatelessWidget {
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback? onRemove;

  const _PosterSourceSheet({
    required this.onGallery,
    required this.onCamera,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Event Poster',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose how to add your poster image',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 20),

          // Options row
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: onGallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: onCamera,
                ),
              ),
            ],
          ),

          // Remove option (only shown if image already selected)
          if (onRemove != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade400, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Remove Poster',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.07),
              AppColors.secondary.withOpacity(0.07),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double gapWidth;
  final double radius;

  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.gapWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();

    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashWidth : gapWidth;
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
          old.strokeWidth != strokeWidth ||
          old.dashWidth != dashWidth ||
          old.gapWidth != gapWidth ||
          old.radius != radius;
}
