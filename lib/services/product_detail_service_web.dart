// Web implementation
import 'dart:html' as html;

class WebUtils {
  static String getUserAgent() {
    return html.window.navigator.userAgent;
  }
  
  static String getCurrentUrl() {
    return html.window.location.href;
  }
}






























