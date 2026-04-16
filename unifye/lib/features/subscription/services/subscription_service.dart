// lib/features/subscription/services/subscription_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:unifye/features/subscription/models/subscription_plan.dart';
import 'package:unifye/main.dart' show baseUrl;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubscriptionApiService {
  final String _base;
  final String? _token;

  SubscriptionApiService({String? token})
      : _base = baseUrl,
        _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  /// Fetches all available subscription plans (public endpoint)
  Future<List<SubscriptionPlan>> fetchAllPlans() async {
    final res = await http.get(
      Uri.parse('$_base/api/subscriptions/plans'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load plans: ${res.body}');
    }
    final List<dynamic> json = jsonDecode(res.body) as List<dynamic>;
    return json
        .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the current user's subscription and permissions
  Future<UserSubscriptionStatus> fetchMySubscription() async {
    final res = await http.get(
      Uri.parse('$_base/api/subscriptions/me'),
      headers: _headers,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load subscription: ${res.body}');
    }
    return UserSubscriptionStatus.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  /// Creates a Stripe Checkout Session and returns the checkout URL
  Future<String> createCheckoutSession({
    required String targetTier,
    required bool isAnnual,
    String successUrl = 'https://unifye.app/payment/success',
    String cancelUrl = 'https://unifye.app/payment/cancel',
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/subscriptions/checkout'),
      headers: _headers,
      body: jsonEncode({
        'targetTier': targetTier,
        'isAnnual': isAnnual,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to create checkout session: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['checkoutUrl'] as String;
  }

  /// Creates a Stripe Billing Portal session URL
  Future<String> createBillingPortalSession({
    String returnUrl = 'https://unifye.app/settings',
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/subscriptions/billing-portal'),
      headers: _headers,
      body: jsonEncode({'returnUrl': returnUrl}),
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to create billing portal session: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['portalUrl'] as String;
  }
}

final subscriptionServiceProvider = Provider.family<SubscriptionApiService, String?>(
  (ref, token) => SubscriptionApiService(token: token),
);
