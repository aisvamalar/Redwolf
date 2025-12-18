// Web implementation
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:async';

class WebUtils {
  static html.IFrameElement createIFrameElement() {
    return html.IFrameElement();
  }

  static void registerViewFactory(
    String key,
    html.Element Function(int) factory,
  ) {
    ui_web.platformViewRegistry.registerViewFactory(key, factory);
  }

  static Stream<html.MessageEvent> getMessageStream() {
    return html.window.onMessage;
  }
}

