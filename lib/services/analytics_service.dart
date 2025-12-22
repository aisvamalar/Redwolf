import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for tracking and retrieving analytics data
class AnalyticsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Track a product page view
  Future<void> trackProductView(String productId) async {
    try {
      await _client.from('analytics').insert({
        'event_type': 'product_view',
        'product_id': productId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - analytics should not break the app
      print('Error tracking product view: $e');
    }
  }

  /// Track an AR view
  Future<void> trackARView(String productId) async {
    try {
      await _client.from('analytics').insert({
        'event_type': 'ar_view',
        'product_id': productId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail - analytics should not break the app
      print('Error tracking AR view: $e');
    }
  }

  /// Get product page views count for the last 30 days
  Future<int> getProductPageViews({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('analytics')
          .select('id')
          .eq('event_type', 'product_view')
          .gte('created_at', startDate.toIso8601String());

      return response.length;
    } catch (e) {
      print('Error fetching product page views: $e');
      return 0;
    }
  }

  /// Get AR views count for the last 30 days
  Future<int> getARViews({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('analytics')
          .select('id')
          .eq('event_type', 'ar_view')
          .gte('created_at', startDate.toIso8601String());

      return response.length;
    } catch (e) {
      print('Error fetching AR views: $e');
      return 0;
    }
  }
}

