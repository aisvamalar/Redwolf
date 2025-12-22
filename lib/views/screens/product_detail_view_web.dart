// Web implementation
import 'dart:html' as html;

class WebUtils {
  static String getCurrentUrl() {
    return html.window.location.href;
  }
  
  static String getUserAgent() {
    return html.window.navigator.userAgent;
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
  /// Apple's AR Quick Look requires:
  /// 1. An anchor element with rel="ar" attribute
  /// 2. The href pointing to a USDZ file
  /// 3. User interaction (click) to trigger AR
  static Future<bool> openUsdzInAR(String usdzUrl) async {
    try {
      print('Opening USDZ in AR Quick Look: $usdzUrl');
      
      // Validate URL
      if (usdzUrl.isEmpty || !usdzUrl.toLowerCase().contains('usdz')) {
        print('Invalid USDZ URL: $usdzUrl');
        return false;
      }
      
      // Method 1: Create an anchor element with rel="ar" attribute
      // This is Apple's recommended way to trigger AR Quick Look on iOS/iPad Safari
      // The rel="ar" attribute tells Safari to open the file in AR Quick Look
      final anchor = html.AnchorElement()
        ..href = usdzUrl
        ..rel = 'ar' // Critical: This attribute triggers AR Quick Look
        ..style.position = 'fixed'
        ..style.left = '0'
        ..style.top = '0'
        ..style.width = '1px'
        ..style.height = '1px'
        ..style.opacity = '0'
        ..style.pointerEvents = 'none'
        ..setAttribute('aria-hidden', 'true');
      
      // Add to document body
      html.document.body?.append(anchor);
      
      print('Anchor element created with rel="ar"');
      
      // Programmatically click the anchor
      // This must be triggered by user interaction (which it is, from button click)
      anchor.click();
      
      print('Anchor clicked - AR Quick Look should open');
      
      // Remove the anchor after a delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        try {
          anchor.remove();
          print('Anchor element removed');
        } catch (e) {
          print('Error removing anchor: $e');
        }
      });
      
      return true;
    } catch (e) {
      print('Error opening USDZ in AR with anchor method: $e');
      print('Stack trace: ${StackTrace.current}');
      
      // Fallback 1: Try direct window.location navigation
      // Safari might open USDZ files directly in AR Quick Look
      try {
        print('Fallback 1: Trying window.location.href');
        html.window.location.href = usdzUrl;
        return true;
      } catch (e2) {
        print('Error with window.location fallback: $e2');
        
        // Fallback 2: Try window.open in new tab
        // Safari might detect USDZ and open in AR Quick Look
        try {
          print('Fallback 2: Trying window.open');
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

















