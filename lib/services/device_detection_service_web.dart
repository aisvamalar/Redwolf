// Web implementation
import 'dart:html' as html;

class WebUtils {
  static String getUserAgent() {
    return html.window.navigator.userAgent.toLowerCase();
  }
  
  static Future<bool> checkCameraAvailability() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) return false;
      
      final devices = await mediaDevices.enumerateDevices();
      return devices.any((device) => device.kind == 'videoinput');
    } catch (e) {
      return false;
    }
  }
  
  static bool hasTouchSupport() {
    try {
      return html.window.navigator.maxTouchPoints != null && 
             html.window.navigator.maxTouchPoints! > 0;
    } catch (e) {
      return false;
    }
  }
}















