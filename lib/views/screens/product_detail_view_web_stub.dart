// Stub file for non-web platforms
class WebUtils {
  static String getCurrentUrl() => '';
  static String getUserAgent() => '';
  static int getMaxTouchPoints() => 0;
  static String getBaseUrl() => '';
  static Future<bool> shareContent(
    String title,
    String text,
    String url,
  ) async => false;
  static Future<bool> copyToClipboard(String text) async => false;
  static void navigateBack() {}
  static Future<bool> openUsdzInAR(String usdzUrl) async => false;
}
