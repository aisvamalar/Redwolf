// Web implementation
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class WebUtils {
  static html.IFrameElement createIFrameElement() {
    return html.IFrameElement();
  }
  
  static void registerViewFactory(String key, dynamic Function(int) factory) {
    ui_web.platformViewRegistry.registerViewFactory(key, factory);
  }
}































