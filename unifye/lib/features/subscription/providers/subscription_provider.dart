import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unifye/features/auth/providers/auth_provider.dart';
import 'package:unifye/features/subscription/models/subscription_plan.dart';
import 'package:unifye/features/subscription/services/subscription_service.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class SubscriptionState {
  final List<SubscriptionPlan> plans;
  final UserSubscriptionStatus? mySubscription;
  final bool isLoadingPlans;
  final bool isLoadingMyPlan;
  final bool isCheckingOut;
  final String? error;
  final String? successMessage;

  const SubscriptionState({
    this.plans = const [],
    this.mySubscription,
    this.isLoadingPlans = false,
    this.isLoadingMyPlan = false,
    this.isCheckingOut = false,
    this.error,
    this.successMessage,
  });

  SubscriptionState copyWith({
    List<SubscriptionPlan>? plans,
    UserSubscriptionStatus? mySubscription,
    bool? isLoadingPlans,
    bool? isLoadingMyPlan,
    bool? isCheckingOut,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SubscriptionState(
      plans: plans ?? this.plans,
      mySubscription: mySubscription ?? this.mySubscription,
      isLoadingPlans: isLoadingPlans ?? this.isLoadingPlans,
      isLoadingMyPlan: isLoadingMyPlan ?? this.isLoadingMyPlan,
      isCheckingOut: isCheckingOut ?? this.isCheckingOut,
      error: clearError ? null : (error ?? this.error),
      successMessage:
      clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionApiService _service;
  final String? _token;

  SubscriptionNotifier(this._service, this._token)
      : super(const SubscriptionState()) {
    loadPlans();
    if (_token != null) loadMySubscription();
  }

  Future<void> loadPlans() async {
    print('[SubscriptionNotifier] loadPlans called');
    state = state.copyWith(isLoadingPlans: true, clearError: true);
    try {
      final plans = await _service.fetchAllPlans();
      print('[SubscriptionNotifier] loaded ${plans.length} plans');
      state = state.copyWith(plans: plans, isLoadingPlans: false);
    } catch (e) {
      print('[SubscriptionNotifier] loadPlans error: $e');
      state = state.copyWith(
        isLoadingPlans: false,
        error: 'Failed to load subscription plans. Please try again.',
      );
    }
  }

  Future<void> loadMySubscription() async {
    state = state.copyWith(isLoadingMyPlan: true, clearError: true);
    try {
      final sub = await _service.fetchMySubscription();
      state = state.copyWith(mySubscription: sub, isLoadingMyPlan: false);
    } catch (e) {
      print('[SubscriptionNotifier] loadMySubscription error: $e');
      state = state.copyWith(
        isLoadingMyPlan: false,
        error: 'Failed to load your subscription.',
      );
    }
  }

  Future<String?> initiateCheckout({
    required String targetTier,
    required bool isAnnual,
  }) async {
    state = state.copyWith(isCheckingOut: true, clearError: true);
    try {
      final url = await _service.createCheckoutSession(
        targetTier: targetTier,
        isAnnual: isAnnual,
      );
      state = state.copyWith(isCheckingOut: false);
      return url;
    } catch (e) {
      state = state.copyWith(
        isCheckingOut: false,
        error: 'Failed to start checkout. Please try again.',
      );
      return null;
    }
  }

  Future<String?> openBillingPortal() async {
    try {
      return await _service.createBillingPortalSession();
    } catch (e) {
      state = state.copyWith(error: 'Failed to open billing portal.');
      return null;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final subscriptionProvider =
StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  // Use ref.read so auth state changes don't tear down the notifier
  // and wipe already-loaded plans. Invalidate manually on login/logout instead.
  final token = ref.read(authProvider).maybeWhen(
    authenticated: (user, token) => token,
    orElse: () => null,
  );
  final service = SubscriptionApiService(token: token);
  return SubscriptionNotifier(service, token);
});

/// Convenience provider — returns the current user's subscription, or null
final mySubscriptionProvider = Provider<UserSubscriptionStatus?>((ref) {
  return ref.watch(subscriptionProvider).mySubscription;
});

/// Convenience provider — returns all available plans sorted by sortOrder
final allPlansProvider = Provider<List<SubscriptionPlan>>((ref) {
  final plans = ref.watch(subscriptionProvider).plans;
  return [...plans]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
});