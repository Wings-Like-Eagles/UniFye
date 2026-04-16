// lib/features/subscription/models/subscription_plan.dart
// Models for UniFye subscription plans — maps to backend SubscriptionPlanDto

class SubscriptionPlan {
  final String id;
  final String tier;
  final String displayName;
  final String? description;
  final String? badgeLabel;
  final String? badgeColourHex;
  final double monthlyPriceZar;
  final double? annualPriceZar;
  final bool isActive;
  final int sortOrder;
  final PlanPermissions permissions;

  const SubscriptionPlan({
    required this.id,
    required this.tier,
    required this.displayName,
    this.description,
    this.badgeLabel,
    this.badgeColourHex,
    required this.monthlyPriceZar,
    this.annualPriceZar,
    required this.isActive,
    required this.sortOrder,
    required this.permissions,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      tier: json['tier'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String?,
      badgeLabel: json['badgeLabel'] as String?,
      badgeColourHex: json['badgeColourHex'] as String?,
      monthlyPriceZar: (json['monthlyPriceZar'] as num).toDouble(),
      annualPriceZar: (json['annualPriceZar'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool,
      sortOrder: json['sortOrder'] as int,
      permissions: PlanPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
    );
  }

  bool get isFree => tier.toLowerCase() == 'free';
  bool get isPlus => tier.toLowerCase() == 'plus';
  bool get isCommunityPro => tier.toLowerCase() == 'communitypro';
  bool get isCampusEnterprise => tier.toLowerCase() == 'campusenterprise';

  double? get annualMonthlySavingZar {
    if (annualPriceZar == null) return null;
    return (monthlyPriceZar * 12) - annualPriceZar!;
  }

  int? get annualSavingPercent {
    if (annualPriceZar == null) return null;
    final annual = monthlyPriceZar * 12;
    return (((annual - annualPriceZar!) / annual) * 100).round();
  }
}

class PlanPermissions {
  final int dailySwipeLimit;
  final int maxActiveMatches;
  final bool canSeeWhoLikedMe;
  final bool canSendMedia;
  final bool canSendVoiceNotes;
  final bool hasReadReceipts;
  final int weeklyProfileBoostCount;
  final bool hasVerifiedOrganiserBadge;
  final int maxJoinedCommunities;
  final bool canCreateCommunity;
  final int maxOwnedCommunities;
  final int communityMemberCap;
  final bool canCreateEvents;
  final int monthlyEventLimit;
  final bool canGenerateQrCheckin;
  final bool canExportAttendees;
  final bool canPinAnnouncements;
  final bool eventsPriorityListing;
  final String analyticsAccess;
  final bool canExportAnalyticsPdf;
  final int maxAccountAdmins;
  final bool canBroadcastMessages;
  final bool hasWebhookAccess;
  final bool hasWhiteLabel;
  final bool hasSlaSupport;
  final bool hasDedicatedManager;
  final int leaderboardVisibilityCap;

  const PlanPermissions({
    required this.dailySwipeLimit,
    required this.maxActiveMatches,
    required this.canSeeWhoLikedMe,
    required this.canSendMedia,
    required this.canSendVoiceNotes,
    required this.hasReadReceipts,
    required this.weeklyProfileBoostCount,
    required this.hasVerifiedOrganiserBadge,
    required this.maxJoinedCommunities,
    required this.canCreateCommunity,
    required this.maxOwnedCommunities,
    required this.communityMemberCap,
    required this.canCreateEvents,
    required this.monthlyEventLimit,
    required this.canGenerateQrCheckin,
    required this.canExportAttendees,
    required this.canPinAnnouncements,
    required this.eventsPriorityListing,
    required this.analyticsAccess,
    required this.canExportAnalyticsPdf,
    required this.maxAccountAdmins,
    required this.canBroadcastMessages,
    required this.hasWebhookAccess,
    required this.hasWhiteLabel,
    required this.hasSlaSupport,
    required this.hasDedicatedManager,
    required this.leaderboardVisibilityCap,
  });

  factory PlanPermissions.fromJson(Map<String, dynamic> json) {
    return PlanPermissions(
      dailySwipeLimit: json['dailySwipeLimit'] as int,
      maxActiveMatches: json['maxActiveMatches'] as int,
      canSeeWhoLikedMe: json['canSeeWhoLikedMe'] as bool,
      canSendMedia: json['canSendMedia'] as bool,
      canSendVoiceNotes: json['canSendVoiceNotes'] as bool,
      hasReadReceipts: json['hasReadReceipts'] as bool,
      weeklyProfileBoostCount: json['weeklyProfileBoostCount'] as int,
      hasVerifiedOrganiserBadge: json['hasVerifiedOrganiserBadge'] as bool,
      maxJoinedCommunities: json['maxJoinedCommunities'] as int,
      canCreateCommunity: json['canCreateCommunity'] as bool,
      maxOwnedCommunities: json['maxOwnedCommunities'] as int,
      communityMemberCap: json['communityMemberCap'] as int,
      canCreateEvents: json['canCreateEvents'] as bool,
      monthlyEventLimit: json['monthlyEventLimit'] as int,
      canGenerateQrCheckin: json['canGenerateQrCheckin'] as bool,
      canExportAttendees: json['canExportAttendees'] as bool,
      canPinAnnouncements: json['canPinAnnouncements'] as bool,
      eventsPriorityListing: json['eventsPriorityListing'] as bool,
      analyticsAccess: json['analyticsAccess'] as String,
      canExportAnalyticsPdf: json['canExportAnalyticsPdf'] as bool,
      maxAccountAdmins: json['maxAccountAdmins'] as int,
      canBroadcastMessages: json['canBroadcastMessages'] as bool,
      hasWebhookAccess: json['hasWebhookAccess'] as bool,
      hasWhiteLabel: json['hasWhiteLabel'] as bool,
      hasSlaSupport: json['hasSlaSupport'] as bool,
      hasDedicatedManager: json['hasDedicatedManager'] as bool,
      leaderboardVisibilityCap: json['leaderboardVisibilityCap'] as int,
    );
  }

  bool get hasUnlimitedSwipes => dailySwipeLimit == -1;
  bool get hasUnlimitedMatches => maxActiveMatches == -1;
  bool get hasUnlimitedEvents => monthlyEventLimit == -1;
  bool get hasAnyAnalytics => analyticsAccess != 'none';
  bool get hasAdvancedAnalytics => analyticsAccess == 'advanced';

  String get swipeLimitLabel => dailySwipeLimit == -1 ? 'Unlimited' : '$dailySwipeLimit/day';
  String get matchLimitLabel => maxActiveMatches == -1 ? 'Unlimited' : '$maxActiveMatches matches';
  String get communityLimitLabel => maxJoinedCommunities == -1 ? 'Unlimited' : '$maxJoinedCommunities spaces';
  String get eventLimitLabel => monthlyEventLimit == -1
      ? 'Unlimited events'
      : monthlyEventLimit == 0
          ? 'No event creation'
          : '$monthlyEventLimit events/month';
  String get boostLimitLabel => weeklyProfileBoostCount == -1
      ? 'Unlimited boosts'
      : weeklyProfileBoostCount == 0
          ? 'No profile boosts'
          : '$weeklyProfileBoostCount boost${weeklyProfileBoostCount > 1 ? "s" : ""}/week';
  String get leaderboardLabel =>
      leaderboardVisibilityCap == -1 ? 'Full leaderboard' : 'Top $leaderboardVisibilityCap only';
}

class UserSubscriptionStatus {
  final String tier;
  final String status;
  final bool isAnnualBilling;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final bool isPendingCancellation;
  final bool isTrialing;
  final DateTime? trialEnd;
  final int? daysRemainingInPeriod;
  final bool isAccessible;
  final PlanPermissions permissions;

  const UserSubscriptionStatus({
    required this.tier,
    required this.status,
    required this.isAnnualBilling,
    this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.isPendingCancellation,
    required this.isTrialing,
    this.trialEnd,
    this.daysRemainingInPeriod,
    required this.isAccessible,
    required this.permissions,
  });

  factory UserSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionStatus(
      tier: json['tier'] as String,
      status: json['status'] as String,
      isAnnualBilling: json['isAnnualBilling'] as bool,
      currentPeriodEnd: json['currentPeriodEnd'] != null
          ? DateTime.parse(json['currentPeriodEnd'] as String)
          : null,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool,
      isPendingCancellation: json['isPendingCancellation'] as bool,
      isTrialing: json['isTrialing'] as bool,
      trialEnd: json['trialEnd'] != null
          ? DateTime.parse(json['trialEnd'] as String)
          : null,
      daysRemainingInPeriod: json['daysRemainingInPeriod'] as int?,
      isAccessible: json['isAccessible'] as bool,
      permissions: PlanPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
    );
  }

  bool get isFree => tier.toLowerCase() == 'free';
  String get tierDisplayName {
    switch (tier.toLowerCase()) {
      case 'free':
        return 'Free';
      case 'plus':
        return 'Plus';
      case 'communitypro':
        return 'Community Pro';
      case 'campusenterprise':
        return 'Campus / Enterprise';
      default:
        return tier;
    }
  }
}
