// Web implementation
import 'dart:html' as html;

class WebUtils {
  static String getCurrentUrl() {
    return html.window.location.href;
  }

  /// Get the base URL (origin) of the website
  static String getBaseUrl() {
    try {
      // Get origin (protocol + host + port if any)
      return html.window.location.origin;
    } catch (e) {
      print('Error getting base URL: $e');
      // Fallback: try to construct from current URL
      try {
        final href = html.window.location.href;
        final uri = Uri.parse(href);
        return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      } catch (e2) {
        print('Error parsing URL: $e2');
        return ''; // Return empty string as last resort
      }
    }
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

  /// Enhanced iPad detection
  static bool isIPad() {
    try {
      final userAgent = getUserAgent().toLowerCase();
      final maxTouchPoints = getMaxTouchPoints();

      // Direct iPad detection
      if (userAgent.contains('ipad')) {
        return true;
      }

      // iPadOS 13+ detection (reports as Mac but has touch)
      if ((userAgent.contains('macintel') || userAgent.contains('macintosh')) &&
          maxTouchPoints > 1) {
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Try to open GLB file on iPad using model-viewer approach
  static Future<bool> openGlbOnIPad(String glbUrl) async {
    try {
      if (!isIPad()) {
        return false;
      }

      print('Attempting to open GLB file on iPad: $glbUrl');

      // Method 1: Try to create a model-viewer element
      try {
        final modelViewer = html.Element.tag('model-viewer')
          ..setAttribute('src', glbUrl)
          ..setAttribute('ar', '')
          ..setAttribute('ar-modes', 'webxr scene-viewer quick-look')
          ..setAttribute('camera-controls', '')
          ..setAttribute('auto-rotate', '')
          ..style.width = '100%'
          ..style.height = '400px'
          ..style.position = 'fixed'
          ..style.top = '50%'
          ..style.left = '50%'
          ..style.transform = 'translate(-50%, -50%)'
          ..style.zIndex = '9999'
          ..style.backgroundColor = 'white';

        // Add to body
        html.document.body?.append(modelViewer);

        // Try to activate AR
        final activateAR = html.document.createElement('script');
        activateAR.text = '''
          setTimeout(() => {
            const viewer = document.querySelector('model-viewer');
            if (viewer && viewer.canActivateAR) {
              viewer.activateAR();
            }
          }, 1000);
        ''';
        html.document.head?.append(activateAR);

        // Remove after delay
        Future.delayed(const Duration(seconds: 10), () {
          try {
            modelViewer.remove();
            activateAR.remove();
          } catch (e) {
            print('Error cleaning up model-viewer: $e');
          }
        });

        return true;
      } catch (e) {
        print('Model-viewer approach failed: $e');
      }

      // Method 2: Try direct navigation
      try {
        html.window.location.href = glbUrl;
        return true;
      } catch (e) {
        print('Direct navigation failed: $e');
      }

      return false;
    } catch (e) {
      print('Error opening GLB on iPad: $e');
      return false;
    }
  }

  static Future<bool> shareContent(
    String title,
    String text,
    String url,
  ) async {
    try {
      // Check if Web Share API is supported by trying to access it
      print('🔗 Attempting to use Web Share API');
      await html.window.navigator.share({
        'title': title,
        'text': text,
        'url': url,
      });
      print('✅ Web Share API successful');
      return true;
    } catch (e) {
      print('❌ Web Share API error: $e');
      // Check if user cancelled the share dialog
      if (e.toString().contains('AbortError') ||
          e.toString().contains('NotAllowedError')) {
        print('ℹ️ User cancelled share dialog');
        return true; // Don't show error for user cancellation
      }
      // Check if API is not supported
      if (e.toString().contains('TypeError') ||
          e.toString().contains('not supported')) {
        print('❌ Web Share API not supported on this browser');
      }
      return false;
    }
  }

  static Future<bool> copyToClipboard(String text) async {
    try {
      // Check if Clipboard API is supported
      if (html.window.navigator.clipboard != null) {
        print('📋 Using Clipboard API');
        await html.window.navigator.clipboard!.writeText(text);
        print('✅ Clipboard API successful');
        return true;
      } else {
        print('❌ Clipboard API not supported, trying fallback');
        // Fallback: Create a temporary textarea element
        final textarea = html.TextAreaElement();
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.left = '-999999px';
        textarea.style.top = '-999999px';
        html.document.body?.append(textarea);
        textarea.focus();
        textarea.select();

        final success = html.document.execCommand('copy');
        textarea.remove();

        print(
          success ? '✅ Fallback copy successful' : '❌ Fallback copy failed',
        );
        return success;
      }
    } catch (e) {
      print('❌ Clipboard error: $e');
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
  /// Navigate back - uses browser history on web
  static void navigateBack() {
    try {
      // Try to go back in browser history
      // On web, we always try to go back - if there's no history,
      // the browser will handle it appropriately (usually stays on page)
      html.window.history.back();
    } catch (e) {
      print('Error navigating back: $e');
      // Fallback: navigate to home page if history.back fails
      try {
        html.window.location.href = '/';
      } catch (e2) {
        print('Error navigating to home: $e2');
      }
    }
  }

  static Future<bool> openUsdzInAR(String usdzUrl) async {
    // CRITICAL: Clean and normalize the URL to fix common issues
    // Issues that cause "Opening AR view..." freeze:
    // 1. Trailing spaces in filename (e.g., "file .usdz")
    // 2. Spaces in filename (should be encoded)
    // 3. Mixed case (should be preserved but validated)
    
    // Step 1: Trim trailing spaces from the entire URL
    String cleanedUrl = usdzUrl.trim();
    
    // Step 2: Check for problematic filename patterns
    final uri = Uri.parse(cleanedUrl);
    final pathSegments = uri.pathSegments;
    if (pathSegments.isNotEmpty) {
      final filename = pathSegments.last;
      
      // Check for trailing space in filename (common issue)
      if (filename.endsWith(' ') || filename.endsWith('%20')) {
        print('⚠️ WARNING: Filename has trailing space - this can cause AR to freeze!');
        print('Original filename: "$filename"');
        // Trim the trailing space from the last segment
        final cleanedFilename = filename.trim();
        pathSegments[pathSegments.length - 1] = cleanedFilename;
        // Reconstruct URL with cleaned filename
        final cleanedPath = '/' + pathSegments.join('/');
        cleanedUrl = '${uri.scheme}://${uri.authority}$cleanedPath';
        if (uri.hasQuery) cleanedUrl += '?${uri.query}';
        if (uri.hasFragment) cleanedUrl += '#${uri.fragment}';
        print('Cleaned filename: "$cleanedFilename"');
      }
      
      // Check for spaces in filename (should be encoded)
      if (filename.contains(' ')) {
        print('⚠️ WARNING: Filename contains spaces - encoding them');
        print('Original filename: "$filename"');
      }
      
      // Check for uppercase in filename (less critical but can cause issues)
      if (filename.contains(RegExp(r'[A-Z]'))) {
        print('ℹ️ INFO: Filename contains uppercase letters');
        print('Filename: "$filename"');
        print('Note: For best compatibility, use lowercase filenames');
      }
    }
    
    // Step 3: Properly encode the URL to handle spaces and special characters
    // PRESERVE CASE SENSITIVITY - critical for file names
    // Database stores full URLs like: https://...supabase.co/.../products/usdz/model_1766844803168_model.usdz
    String encodedUrl;

    // Check if URL is already fully encoded (no unencoded spaces)
    // If URL contains %20 or other encoded characters, it might already be encoded
    final hasUnencodedSpaces = cleanedUrl.contains(' ') && !cleanedUrl.contains('%20');
    final needsEncoding = hasUnencodedSpaces || 
                        (cleanedUrl.contains('%') == false && cleanedUrl.contains('&'));

    if (needsEncoding) {
      // URL needs encoding - preserve case while encoding
      try {
        // Parse to get components
        final uriToEncode = Uri.parse(cleanedUrl);

        // Encode path segments individually to preserve case
        // This handles full URLs from database correctly
        final encodedSegments = uriToEncode.pathSegments.map((segment) {
          // Check if segment is already encoded (contains %)
          if (segment.contains('%')) {
            // Already encoded, use as-is to avoid double encoding
            return segment;
          }
          // Uri.encodeComponent preserves case of letters but encodes spaces
          return Uri.encodeComponent(segment);
        }).toList();

        // Reconstruct with preserved case
        final encodedPath = '/' + encodedSegments.join('/');
        encodedUrl = '${uriToEncode.scheme}://${uriToEncode.authority}$encodedPath';

        // Preserve query and fragment
        if (uriToEncode.hasQuery) encodedUrl += '?${uriToEncode.query}';
        if (uriToEncode.hasFragment) encodedUrl += '#${uriToEncode.fragment}';

        print('URL encoding - case preserved');
        print('Original: $usdzUrl');
        print('Cleaned:  $cleanedUrl');
        print('Encoded:  $encodedUrl');
      } catch (e) {
        print('Error in URL parsing, using manual encoding: $e');
        // Manual encoding: encode spaces, preserve everything else
        encodedUrl = cleanedUrl.replaceAll(' ', '%20');
        print('Using manual encoding: $encodedUrl');
      }
    } else {
      // URL is already properly encoded or doesn't need encoding
      // Use cleaned URL to preserve exact case
      // This handles full URLs from database that are already correct
      encodedUrl = cleanedUrl;
      print('URL already encoded or no encoding needed');
      print('Original: $usdzUrl');
      print('Using:    $encodedUrl');
      print('Note: Full URL from database - using as-is');
    }

    try {
      print('Opening USDZ in AR Quick Look');
      print('Original URL: $usdzUrl');
      print('Cleaned URL: $cleanedUrl');
      print('Encoded URL: $encodedUrl');

      // Validate URL - ensure it's a USDZ file from the usdz/ folder
      if (usdzUrl.isEmpty || cleanedUrl.isEmpty) {
        print('❌ Invalid USDZ URL: URL is empty');
        return false;
      }
      
      // Additional validation: Check for common issues
      print('=== USDZ URL Validation ===');
      print('✅ URL is not empty');
      
      // Check if URL points to Supabase storage
      final isSupabaseUrl = encodedUrl.contains('supabase.co') || 
                           encodedUrl.contains('supabase');
      if (isSupabaseUrl) {
        print('✅ URL points to Supabase storage');
        print('⚠️ IMPORTANT: Ensure Supabase storage bucket has correct MIME type:');
        print('   Content-Type: model/vnd.usdz+zip');
        print('   Content-Disposition: inline');
      } else {
        print('⚠️ URL does not appear to be from Supabase storage');
      }

      print('Encoded USDZ URL: $encodedUrl');

      // Case-insensitive check for USDZ extension (but preserve case in URL)
      final lowerUrl = encodedUrl.toLowerCase();
      if (!lowerUrl.contains('usdz')) {
        print('Invalid USDZ URL: URL does not contain .usdz extension');
        print('Original URL: $usdzUrl');
        print('Encoded URL: $encodedUrl');
        return false;
      }

      // Verify URL points to Supabase storage usdz/ folder (case-insensitive check)
      final hasUsdzFolder =
          lowerUrl.contains('/usdz/') ||
          lowerUrl.contains('usdz%') ||
          lowerUrl.contains('/usdz%2f'); // Encoded forward slash
      if (!hasUsdzFolder) {
        print('Warning: USDZ URL may not be from usdz/ folder');
        print('URL: $encodedUrl');
        print('Lower URL: $lowerUrl');
        // Continue anyway as URL might be encoded differently
      }

      // Final check: ensure the encoded URL preserves the original case
      print('=== Case Sensitivity Verification ===');
      final originalHasUpper = usdzUrl.contains(RegExp(r'[A-Z]'));
      final encodedHasUpper = encodedUrl.contains(RegExp(r'[A-Z]'));
      final originalHasLower = usdzUrl.contains(RegExp(r'[a-z]'));
      final encodedHasLower = encodedUrl.contains(RegExp(r'[a-z]'));

      print('Original URL: $usdzUrl');
      print('  Has uppercase: $originalHasUpper');
      print('  Has lowercase: $originalHasLower');
      print('Encoded URL: $encodedUrl');
      print('  Has uppercase: $encodedHasUpper');
      print('  Has lowercase: $encodedHasLower');

      // Verify case is preserved
      if (originalHasUpper != encodedHasUpper ||
          originalHasLower != encodedHasLower) {
        print('⚠️ WARNING: Case may not be fully preserved!');
      } else {
        print('✅ Case sensitivity preserved correctly');
      }
      print('=====================================');

      // Check if this is specifically an iPad
      final isIPadDevice = isIPad();
      print('Is iPad device: $isIPadDevice');

      // Method 1: For iPad, try direct navigation first (most reliable)
      // iPad Safari will automatically open USDZ files in AR Quick Look when navigated to directly
      if (isIPadDevice) {
        try {
          print('iPad detected - trying direct navigation to USDZ URL');
          print('Navigating to: $encodedUrl');
          // Use window.location.href for direct navigation
          // This is the most reliable method for iPad Safari
          html.window.location.href = encodedUrl;
          print('Direct navigation initiated - AR Quick Look should open');
          return true;
        } catch (e) {
          print('Direct navigation failed, trying anchor method: $e');
          // Fall through to anchor method
        }
      }

      // Method 2: Create an anchor element with rel="ar" attribute
      // This is Apple's recommended way to trigger AR Quick Look on iOS/iPad Safari
      // The rel="ar" attribute tells Safari to open the file in AR Quick Look
      // Note: Autorotate must be enabled in the USDZ file itself, not via URL
      final anchor = html.AnchorElement()
        ..href = encodedUrl // Use properly encoded URL
        ..rel = 'ar' // Critical: This attribute triggers AR Quick Look
        ..download = '' // Prevent download, force AR Quick Look
        ..style.position = 'fixed'
        ..style.left = '0'
        ..style.top = '0'
        ..style.width = '1px'
        ..style.height = '1px'
        ..style.opacity = '0'
        ..style.pointerEvents = 'none'
        ..setAttribute('aria-hidden', 'true');

      // Add to document body BEFORE clicking
      html.document.body?.append(anchor);

      print('Anchor element created with rel="ar"');
      print('Original URL: $usdzUrl');
      print('Encoded URL: $encodedUrl');
      print('Anchor href: ${anchor.href}');
      print('Anchor rel: ${anchor.rel}');

      // Programmatically click the anchor
      // This must be triggered by user interaction (which it is, from button click)
      // Use a synchronous click for better reliability
      anchor.click();

      print('Anchor clicked - AR Quick Look should open on iPad/iPhone');
      print(
        'Note: Autorotate is controlled by the USDZ file metadata, not URL parameters',
      );

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

      // Fallback 1: Try direct window.location navigation with encoded URL
      // Safari might open USDZ files directly in AR Quick Look
      try {
        print('Fallback 1: Trying window.location.href with encoded URL');
        print('Using encoded URL: $encodedUrl');
        html.window.location.href = encodedUrl;
        return true;
      } catch (e2) {
        print('Error with window.location fallback: $e2');

        // Fallback 2: Try window.open in new tab with encoded URL
        // Safari might detect USDZ and open in AR Quick Look
        try {
          print('Fallback 2: Trying window.open with encoded URL');
          print('Using encoded URL: $encodedUrl');
          html.window.open(encodedUrl, '_blank');
          return true;
        } catch (e3) {
          print('Error with window.open fallback: $e3');
          return false;
        }
      }
    }
  }
}
