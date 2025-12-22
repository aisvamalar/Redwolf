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

  /// Open USDZ file in AR Quick Look on iOS/iPad Safari
  /// This creates an anchor element with rel="ar" attribute which triggers AR Quick Look
  static Future<bool> openUsdzInAR(String usdzUrl) async {
    try {
      print('Opening USDZ in AR: $usdzUrl');
      
      // Method 1: Create an anchor element with rel="ar" attribute
      // This is the proper way to trigger AR Quick Look on iOS/iPad Safari
      final anchor = html.AnchorElement()
        ..href = usdzUrl
        ..rel = 'ar'
        ..style.position = 'absolute'
        ..style.left = '-9999px'
        ..style.top = '-9999px'
        ..setAttribute('download', ''); // Some browsers need this
      
      // Add to document body
      html.document.body?.append(anchor);
      
      // Programmatically click the anchor
      anchor.click();
      
      print('Anchor clicked for USDZ AR');
      
      // Remove the anchor after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          anchor.remove();
        } catch (e) {
          print('Error removing anchor: $e');
        }
      });
      
      return true;
    } catch (e) {
      print('Error opening USDZ in AR with anchor method: $e');
      // Fallback: try window.location (direct navigation)
      try {
        print('Trying window.location fallback');
        html.window.location.href = usdzUrl;
        return true;
      } catch (e2) {
        print('Error with window.location fallback: $e2');
        // Final fallback: try window.open
        try {
          print('Trying window.open fallback');
          html.window.open(usdzUrl, '_blank');
          return true;
        } catch (e3) {
          print('Error with window.open fallback: $e3');
          return false;
        }
      }
    }
  }
}

















