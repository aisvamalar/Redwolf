// Web implementation
import 'dart:html' as html;

class WebUtils {
  static String getCurrentUrl() {
    return html.window.location.href;
  }
  
  static Future<bool> shareContent(String title, String text, String url) async {
    try {
      await html.window.navigator.share({
        'title': title,
        'text': text,
        'url': url,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> copyToClipboard(String text) async {
    try {
      await html.window.navigator.clipboard?.writeText(text);
      return true;
    } catch (e) {
      return false;
    }
  }
}

















