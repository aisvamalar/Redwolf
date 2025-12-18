// Web implementation
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebUtils {
  static String getBaseUrl() {
    return html.window.location.origin;
  }

  static html.VideoElement createVideoElement() {
    return html.VideoElement();
  }

  static void registerViewFactory(
    String key,
    html.Element Function(int) factory,
  ) {
    ui_web.platformViewRegistry.registerViewFactory(key, factory);
  }
}

