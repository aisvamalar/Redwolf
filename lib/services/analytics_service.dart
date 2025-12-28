import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Track when a user views a product detail page
  Future<void> trackProductView(String productId) async {
    try {
      await _supabase.from('analytics').insert({
        'product_id': productId,
        'event_type': 'product_view',
      });
      print('✅ Product view tracked for product: $productId');
    } catch (e) {
      print('❌ Error tracking product view: $e');
      // Don't throw error - analytics shouldn't break the app
    }
  }

  /// Track when a user clicks "View in My Space" (AR button)
  Future<void> trackARView(String productId) async {
    try {
      await _supabase.from('analytics').insert({
        'product_id': productId,
        'event_type': 'ar_view',
      });
      print('✅ AR view tracked for product: $productId');
    } catch (e) {
      print('❌ Error tracking AR view: $e');
      // Don't throw error - analytics shouldn't break the app
    }
  }

  /// Get analytics summary for admin panel
  Future<Map<String, int>> getAnalyticsSummary() async {
    try {
      final response = await _supabase.from('analytics').select('event_type');

      final data = response as List;
      final Map<String, int> summary = {};

      for (final row in data) {
        final eventType = row['event_type'] as String;
        summary[eventType] = (summary[eventType] ?? 0) + 1;
      }

      return summary;
    } catch (e) {
      print('❌ Error getting analytics summary: $e');
      return {};
    }
  }

  /// Get analytics by product for admin panel
  Future<List<Map<String, dynamic>>> getProductAnalytics() async {
    try {
      final data = await _supabase.rpc('get_product_analytics');
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('❌ Error getting product analytics: $e');
      return [];
    }
  }
}
