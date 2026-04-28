import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/core/theme/app_colour.dart';
import 'package:unifye/features/subscription/models/subscription_plan.dart';
import 'package:unifye/features/subscription/providers/subscription_provider.dart';
import 'package:unifye/widgets/app_button.dart';import 'package:url_launcher/url_launcher.dart';

class ChangePlanPage extends ConsumerStatefulWidget {
  const ChangePlanPage({super.key});

  @override
  ConsumerState<ChangePlanPage> createState() => _ChangePlanPageState();
}

class _ChangePlanPageState extends ConsumerState<ChangePlanPage>
    with SingleTickerProviderStateMixin {
  bool _isAnnual = false;
  String? _checkingOutTier;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(subscriptionProvider);
      if (state.plans.isEmpty) {
        ref.read(subscriptionProvider.notifier).loadPlans();
      }
      if (state.mySubscription == null) {
        ref.read(subscriptionProvider.notifier).loadMySubscription();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);
    final mySubscription = ref.watch(mySubscriptionProvider);
    final plans = ref.watch(allPlansProvider);

    // Listen for errors
    ref.listen<SubscriptionState>(subscriptionProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(subscriptionProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
        title: const Text(
          'Choose Your Plan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: state.isLoadingPlans
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildBillingToggle()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final plan = plans[index];
                  return _PlanCard(
                    plan: plan,
                    isAnnual: _isAnnual,
                    currentTier: mySubscription?.tier ?? 'free',
                    isCheckingOut: _checkingOutTier == plan.tier,
                    onSelectPlan: _handleSelectPlan,
                    animationDelay: Duration(milliseconds: index * 80),
                  );
                },
                childCount: plans.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildGuaranteeFooter()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        children: [
          Text(
            'Unlock your full campus\nsocial experience 🎓',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Join thousands of students already connecting on UniFye.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isAnnual ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: !_isAnnual
                      ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                      : null,
                ),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: !_isAnnual
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isAnnual ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _isAnnual
                      ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Annual',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _isAnnual
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (_isAnnual)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Save 25%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (!_isAnnual)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Save 25%',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuaranteeFooter() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Divider(),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_rounded,
                  color: AppColors.success, size: 18),
              SizedBox(width: 8),
              Text(
                '7-day free trial on Plus & Community Pro',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded,
                  color: AppColors.textTertiary, size: 16),
              SizedBox(width: 8),
              Text(
                'Secure payments via Stripe · Cancel anytime',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSelectPlan(SubscriptionPlan plan) async {
    // Campus/Enterprise → open contact sales
    if (plan.isCampusEnterprise) {
      final uri = Uri.parse(
          'mailto:enterprise@unifye.app?subject=Campus%20Enterprise%20Inquiry');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
      return;
    }

    // Free → just navigate back (user is already on free or we do nothing)
    if (plan.isFree) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _checkingOutTier = plan.tier);

    final checkoutUrl = await ref
        .read(subscriptionProvider.notifier)
        .initiateCheckout(
      targetTier: plan.tier,
      isAnnual: _isAnnual,
    );

    if (mounted) {
      setState(() => _checkingOutTier = null);
    }

    if (checkoutUrl != null) {
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

// ─── Plan Card Widget ─────────────────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  final SubscriptionPlan plan;
  final bool isAnnual;
  final String currentTier;
  final bool isCheckingOut;
  final Future<void> Function(SubscriptionPlan) onSelectPlan;
  final Duration animationDelay;

  const _PlanCard({
    required this.plan,
    required this.isAnnual,
    required this.currentTier,
    required this.isCheckingOut,
    required this.onSelectPlan,
    required this.animationDelay,
  });

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isCurrentPlan =>
      widget.currentTier.toLowerCase() == widget.plan.tier.toLowerCase();

  bool get _isMostPopular => widget.plan.badgeLabel == 'Most Popular';

  Color get _planAccentColor {
    final hex = widget.plan.badgeColourHex;
    if (hex == null) return AppColors.textTertiary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  String get _displayPrice {
    if (widget.plan.isFree) return 'Free';
    if (widget.plan.isCampusEnterprise) return 'From R999/mo';
    if (widget.isAnnual && widget.plan.annualPriceZar != null) {
      final monthly = (widget.plan.annualPriceZar! / 12).toStringAsFixed(0);
      return 'R$monthly/mo';
    }
    return 'R${widget.plan.monthlyPriceZar.toStringAsFixed(0)}/mo';
  }

  String? get _billingSubtitle {
    if (widget.plan.isFree || widget.plan.isCampusEnterprise) return null;
    if (widget.isAnnual && widget.plan.annualPriceZar != null) {
      final saving = widget.plan.annualSavingPercent;
      return 'R${widget.plan.annualPriceZar!.toStringAsFixed(0)}/yr · Save $saving%';
    }
    return 'Billed monthly';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isMostPopular
                    ? _planAccentColor
                    : _isCurrentPlan
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
                width: _isMostPopular ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isMostPopular
                      ? _planAccentColor.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: _isMostPopular ? 20 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Badge row
                if (widget.plan.badgeLabel != null) _buildBadge(),

                // Plan header
                _buildPlanHeader(),

                // Feature list (always show key features, expandable for all)
                _buildFeatureList(),

                // Expandable extra features
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _isExpanded
                      ? _buildExpandedFeatures()
                      : const SizedBox.shrink(),
                ),

                // Expand/collapse hint
                _buildExpandToggle(),

                // CTA button
                _buildCTAButton(),

                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      decoration: BoxDecoration(
        color: _planAccentColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        widget.plan.badgeLabel!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plan icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _planAccentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_planIcon(), color: _planAccentColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.plan.displayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_isCurrentPlan) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (widget.plan.description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    widget.plan.description!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Price column
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _displayPrice,
                style: TextStyle(
                  fontSize: widget.plan.isCampusEnterprise ? 14 : 20,
                  fontWeight: FontWeight.w900,
                  color: widget.plan.isFree
                      ? AppColors.success
                      : AppColors.textPrimary,
                ),
              ),
              if (_billingSubtitle != null)
                Text(
                  _billingSubtitle!,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final keyFeatures = _getKeyFeatures(widget.plan);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: keyFeatures
            .map((f) => _FeatureRow(text: f.text, included: f.included))
            .toList(),
      ),
    );
  }

  Widget _buildExpandedFeatures() {
    final extraFeatures = _getExtraFeatures(widget.plan);
    if (extraFeatures.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: extraFeatures
            .map((f) =>
            _FeatureRow(text: f.text, included: f.included, small: true))
            .toList(),
      ),
    );
  }

  Widget _buildExpandToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isExpanded ? 'Show less' : 'See all features',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTAButton() {
    final isCurrentPlan = _isCurrentPlan;
    final isEnterprise = widget.plan.isCampusEnterprise;
    final isFree = widget.plan.isFree;

    String label;
    if (isCurrentPlan) {
      label = 'Your Current Plan';
    } else if (isFree) {
      label = 'Downgrade to Free';
    } else if (isEnterprise) {
      label = 'Contact Sales →';
    } else {
      label = widget.isAnnual && widget.plan.annualPriceZar != null
          ? 'Start 7-Day Trial (Annual)'
          : 'Start 7-Day Free Trial';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: AppButton(
        text: label,
        onPressed: isCurrentPlan ? null : () => widget.onSelectPlan(widget.plan),
        isLoading: widget.isCheckingOut,
        isFullWidth: true,
        type: isCurrentPlan
            ? AppButtonType.outline
            : isFree
            ? AppButtonType.secondary
            : _isMostPopular || isEnterprise
            ? AppButtonType.gradient
            : AppButtonType.primary,
      ),
    );
  }

  IconData _planIcon() {
    if (widget.plan.isFree) return Icons.school_outlined;
    if (widget.plan.isPlus) return Icons.star_rounded;
    if (widget.plan.isCommunityPro) return Icons.local_fire_department_rounded;
    if (widget.plan.isCampusEnterprise) return Icons.account_balance_rounded;
    return Icons.workspace_premium_rounded;
  }
}

// ─── Feature Row Helper ───────────────────────────────────────────────────────

class _FeatureItem {
  final String text;
  final bool included;
  const _FeatureItem(this.text, {this.included = true});
}

List<_FeatureItem> _getKeyFeatures(SubscriptionPlan plan) {
  final p = plan.permissions;
  return [
    _FeatureItem(p.swipeLimitLabel),
    _FeatureItem(p.matchLimitLabel),
    _FeatureItem('See who liked you', included: p.canSeeWhoLikedMe),
    _FeatureItem('Photos & voice notes', included: p.canSendMedia),
    _FeatureItem(p.boostLimitLabel, included: p.weeklyProfileBoostCount > 0),
    _FeatureItem(p.communityLimitLabel),
    _FeatureItem(
      p.canCreateEvents
          ? p.hasUnlimitedEvents
          ? 'Unlimited event creation'
          : '${p.monthlyEventLimit} events/month'
          : 'No event creation',
      included: p.canCreateEvents,
    ),
    _FeatureItem(p.leaderboardLabel),
  ];
}

List<_FeatureItem> _getExtraFeatures(SubscriptionPlan plan) {
  final p = plan.permissions;
  final items = <_FeatureItem>[];

  if (p.hasReadReceipts) items.add(const _FeatureItem('Read receipts'));
  if (p.hasVerifiedOrganiserBadge) {
    items.add(const _FeatureItem('Verified Organiser badge'));
  }
  if (p.canGenerateQrCheckin) {
    items.add(const _FeatureItem('QR code event check-in'));
  }
  if (p.canExportAttendees) {
    items.add(const _FeatureItem('Export attendee list (CSV)'));
  }
  if (p.canPinAnnouncements) {
    items.add(const _FeatureItem('Pin community announcements'));
  }
  if (p.eventsPriorityListing) {
    items.add(const _FeatureItem('Priority event listing'));
  }
  if (p.hasAnyAnalytics) {
    items.add(_FeatureItem(
      p.hasAdvancedAnalytics
          ? 'Advanced event analytics'
          : 'Basic event analytics',
    ));
  }
  if (p.canExportAnalyticsPdf) {
    items.add(const _FeatureItem('Export analytics as PDF'));
  }
  if (p.maxAccountAdmins > 1) {
    items.add(_FeatureItem(
      p.maxAccountAdmins == -1
          ? 'Unlimited team admins'
          : 'Up to ${p.maxAccountAdmins} admins',
    ));
  }
  if (p.canBroadcastMessages) {
    items.add(const _FeatureItem('Broadcast messaging'));
  }
  if (p.hasWebhookAccess) items.add(const _FeatureItem('Webhook integrations'));
  if (p.hasWhiteLabel) items.add(const _FeatureItem('White-label event pages'));
  if (p.hasSlaSupport) items.add(const _FeatureItem('SLA-backed support'));
  if (p.hasDedicatedManager) {
    items.add(const _FeatureItem('Dedicated account manager'));
  }

  return items;
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final bool included;
  final bool small;

  const _FeatureRow({
    required this.text,
    required this.included,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: small ? 3 : 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            included ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: small ? 15 : 18,
            color: included ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: small ? 12 : 13,
                color: included ? AppColors.textPrimary : AppColors.textTertiary,
                fontWeight: included ? FontWeight.w500 : FontWeight.w400,
                decoration: included ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
