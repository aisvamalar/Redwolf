// Stub implementation for non-web platforms
class WebUtils {
  static String getUserAgent() {
    return 'Mobile App';
  }

  static String getCurrentUrl() {
    return 'app://mobile';
  }

  static String getScreenResolution() {
    return 'unknown';
  }

  static String getViewportSize() {
    return 'unknown';
  }

  static bool isMobileDevice() {
    return true; // Always true for mobile app
  }

  static Map<String, dynamic> getDeviceInfo() {
    return {
      'user_agent': getUserAgent(),
      'screen_resolution': getScreenResolution(),
      'viewport_size': getViewportSize(),
      'is_mobile': isMobileDevice(),
      'language': 'en',
      'platform': 'mobile',
      'cookie_enabled': false,
      'online': true,
    };
  }
}

