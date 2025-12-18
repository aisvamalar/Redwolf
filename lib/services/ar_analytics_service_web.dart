// Web implementation for AR Analytics
import 'dart:html' as html;

class WebUtils {
  static String getUserAgent() {
    return html.window.navigator.userAgent;
  }

  static String getCurrentUrl() {
    return html.window.location.href;
  }

  static String getScreenResolution() {
    return '${html.window.screen?.width}x${html.window.screen?.height}';
  }

  static String getViewportSize() {
    return '${html.window.innerWidth}x${html.window.innerHeight}';
  }

  static bool isMobileDevice() {
    final userAgent = getUserAgent().toLowerCase();
    return userAgent.contains('mobile') ||
        userAgent.contains('android') ||
        userAgent.contains('iphone') ||
        userAgent.contains('ipad');
  }

  static Map<String, dynamic> getDeviceInfo() {
    return {
      'user_agent': getUserAgent(),
      'screen_resolution': getScreenResolution(),
      'viewport_size': getViewportSize(),
      'is_mobile': isMobileDevice(),
      'language': html.window.navigator.language,
      'platform': html.window.navigator.platform,
      'cookie_enabled': html.window.navigator.cookieEnabled,
      'online': html.window.navigator.onLine,
    };
  }
}

