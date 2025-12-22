import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Conditional imports for web-only APIs
import 'device_detection_service_stub.dart'
    if (dart.library.html) 'device_detection_service_web.dart' as web_utils;

/// Service to detect device type and AR capabilities
class DeviceDetectionService {
  /// Check if the device is mobile (phone) based on screen width
  static bool isMobileByWidth(double width) {
    return width < 600;
  }

  /// Check if the device is tablet based on screen width
  static bool isTabletByWidth(double width) {
    return width >= 600 && width < 1024;
  }

  /// Check if the device is desktop/laptop based on screen width
  static bool isDesktopByWidth(double width) {
    return width >= 1024;
  }

  /// Check if the device is mobile (phone) using user agent
  static bool isMobileByUserAgent() {
    if (kIsWeb) {
      try {
        final userAgent = web_utils.WebUtils.getUserAgent();
        return userAgent.contains('mobile') && 
               !userAgent.contains('tablet') &&
               !userAgent.contains('ipad');
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Check if the device is tablet using user agent
  static bool isTabletByUserAgent() {
    if (kIsWeb) {
      try {
        final userAgent = web_utils.WebUtils.getUserAgent();
        return userAgent.contains('tablet') || 
               userAgent.contains('ipad') ||
               (userAgent.contains('android') && !userAgent.contains('mobile'));
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Check if the device is mobile (phone) - uses context if available
  static bool isMobile(BuildContext? context) {
    if (context != null) {
      final width = MediaQuery.of(context).size.width;
      return isMobileByWidth(width);
    }
    return isMobileByUserAgent();
  }

  /// Check if the device is tablet - uses context if available
  static bool isTablet(BuildContext? context) {
    if (context != null) {
      final width = MediaQuery.of(context).size.width;
      return isTabletByWidth(width);
    }
    return isTabletByUserAgent();
  }

  /// Check if the device is desktop/laptop - uses context if available
  static bool isDesktop(BuildContext? context) {
    if (context != null) {
      final width = MediaQuery.of(context).size.width;
      return isDesktopByWidth(width);
    }
    // Fallback: if not mobile or tablet, assume desktop
    return !isMobileByUserAgent() && !isTabletByUserAgent();
  }

  /// Check if device is mobile or tablet (AR capable devices)
  static bool isMobileOrTablet(BuildContext? context) {
    return isMobile(context) || isTablet(context);
  }

  /// Check if WebXR is supported (for AR)
  /// Note: WebXR detection requires JavaScript interop which is complex
  /// For now, we'll rely on device type and camera availability
  static Future<bool> isWebXRSupported() async {
    if (!kIsWeb) return false;
    
    try {
      // model-viewer supports AR on mobile/tablet devices
      // We'll check device type instead of WebXR API directly
      final userAgent = web_utils.WebUtils.getUserAgent();
      return userAgent.contains('mobile') || 
             userAgent.contains('tablet') ||
             userAgent.contains('android') ||
             userAgent.contains('iphone') ||
             userAgent.contains('ipad');
    } catch (e) {
      return false;
    }
  }

  /// Check if camera is available
  static Future<bool> isCameraAvailable() async {
    if (!kIsWeb) return false;
    
    try {
      return await web_utils.WebUtils.checkCameraAvailability();
    } catch (e) {
      return false;
    }
  }

  /// Check if AR is available on this device
  static Future<bool> isARAvailable(BuildContext? context) async {
    // AR is only available on mobile/tablet
    if (!isMobileOrTablet(context)) {
      return false;
    }
    
    // Check for WebXR or model-viewer AR support
    final webXRSupported = await isWebXRSupported();
    final cameraAvailable = await isCameraAvailable();
    
    // AR requires either WebXR or camera access capability
    return webXRSupported || cameraAvailable;
  }

  /// Get device type as string
  static String getDeviceType(BuildContext? context) {
    if (isMobile(context)) return 'mobile';
    if (isTablet(context)) return 'tablet';
    return 'desktop';
  }

  /// Get device type by width
  static String getDeviceTypeByWidth(double width) {
    if (isMobileByWidth(width)) return 'mobile';
    if (isTabletByWidth(width)) return 'tablet';
    return 'desktop';
  }

  /// Check if device has touch capability
  static bool hasTouchSupport() {
    if (kIsWeb) {
      try {
        return web_utils.WebUtils.hasTouchSupport();
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Check if device is iOS (iPhone/iPad)
  static bool isIOS(BuildContext? context) {
    if (kIsWeb) {
      try {
        final userAgent = web_utils.WebUtils.getUserAgent().toLowerCase();
        // Check for explicit iOS device strings
        final hasIOSDevice = userAgent.contains('iphone') || 
                             userAgent.contains('ipad') ||
                             userAgent.contains('ipod');
        
        // Also check for iPadOS 13+ which might identify as Mac but has touch support
        // iPadOS 13+ Safari reports as "Macintosh" but has touch support
        if (!hasIOSDevice && context != null) {
          final hasTouch = hasTouchSupport();
          final isTablet = isTabletByWidth(MediaQuery.of(context).size.width);
          // If it's a tablet with touch support and Safari-like user agent, likely iPad
          if (hasTouch && isTablet && userAgent.contains('safari') && !userAgent.contains('chrome') && !userAgent.contains('firefox')) {
            return true; // Likely iPad running iPadOS 13+
          }
        }
        
        return hasIOSDevice;
      } catch (e) {
        return false;
      }
    }
    return false;
  }
}
