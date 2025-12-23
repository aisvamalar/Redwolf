// Web implementation
import 'dart:html' as html;

class WebUtils {
  static String getCurrentUrl() {
    return html.window.location.href;
  }
  
  static String getUserAgent() {
    return html.window.navigator.userAgent;
  }
  
  static int getMaxTouchPoints() {
    try {
      return html.window.navigator.maxTouchPoints ?? 0;
    } catch (e) {
      return 0;
    }
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
  /// 2. The href pointing to a USDZ file (from products/usdz/ folder)
  /// 3. User interaction (click) to trigger AR
  /// 
  /// Note: Autorotate is controlled by the USDZ file itself, not URL parameters.
  /// The USDZ file must have autorotate enabled in its metadata for it to work.
  static Future<bool> openUsdzInAR(String usdzUrl) async {
    try {
      print('Opening USDZ in AR Quick Look: $usdzUrl');
      
      // Validate URL - ensure it's a USDZ file from the usdz/ folder
      if (usdzUrl.isEmpty) {
        print('Invalid USDZ URL: URL is empty');
        return false;
      }
      
      final lowerUrl = usdzUrl.toLowerCase();
      if (!lowerUrl.contains('usdz')) {
        print('Invalid USDZ URL: URL does not contain .usdz extension');
        print('URL: $usdzUrl');
        return false;
      }
      
      // Verify URL points to Supabase storage usdz/ folder
      if (!lowerUrl.contains('/usdz/') && !lowerUrl.contains('usdz%')) {
        print('Warning: USDZ URL may not be from usdz/ folder');
        print('URL: $usdzUrl');
        // Continue anyway as URL might be encoded
      }
      
      // Method 1: Create an anchor element with rel="ar" attribute
      // This is Apple's recommended way to trigger AR Quick Look on iOS/iPad Safari
      // The rel="ar" attribute tells Safari to open the file in AR Quick Look
      // Note: Autorotate must be enabled in the USDZ file itself, not via URL
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
      print('USDZ URL: $usdzUrl');
      
      // Programmatically click the anchor
      // This must be triggered by user interaction (which it is, from button click)
      anchor.click();
      
      print('Anchor clicked - AR Quick Look should open on iPad/iPhone');
      print('Note: Autorotate is controlled by the USDZ file metadata, not URL parameters');
      
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

















