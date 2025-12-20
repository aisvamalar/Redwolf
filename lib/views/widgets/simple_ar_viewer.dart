import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'simple_ar_viewer_web_stub.dart'
    if (dart.library.html) 'simple_ar_viewer_web.dart'
    as web_utils;

/// Simple AR Viewer using Google Scene Viewer
/// Uses model-viewer's built-in Scene Viewer for best AR quality
class SimpleARViewer extends StatefulWidget {
  final String modelUrl;
  final String? altText;
  final String? productName;
  final VoidCallback? onBackPressed;

  const SimpleARViewer({
    super.key,
    required this.modelUrl,
    this.altText,
    this.productName,
    this.onBackPressed,
  });

  @override
  State<SimpleARViewer> createState() => _SimpleARViewerState();
}

class _SimpleARViewerState extends State<SimpleARViewer> {
  String? _iframeKey;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _iframeKey = 'simple-ar-${widget.modelUrl.hashCode}';
      _registerARViewer();
      _setupMessageListener();
    }
  }

  void _setupMessageListener() {
    if (!kIsWeb) return;

    web_utils.WebUtils.getMessageStream().listen((event) {
      if (event.data is Map && event.data['type'] == 'ar_back') {
        if (widget.onBackPressed != null) {
          widget.onBackPressed!();
        } else if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _registerARViewer() {
    if (!kIsWeb || _iframeKey == null) return;

    final iframe = web_utils.WebUtils.createIFrameElement();
    if (iframe == null) return;

    iframe.id = _iframeKey!;
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.allow = 'camera; xr-spatial-tracking';
    iframe.srcdoc = _createArHtml();

    web_utils.WebUtils.registerViewFactory(_iframeKey!, (int viewId) => iframe);
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _iframeKey != null) {
      return HtmlElementView(viewType: _iframeKey!);
    } else {
      return _buildUnsupportedView();
    }
  }

  Widget _buildUnsupportedView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.view_in_ar, size: 80, color: Color(0xFFDC2626)),
            const SizedBox(height: 24),
            const Text(
              'AR Not Available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'AR features require a web browser with AR support.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Escapes a string for use in JavaScript
  String _escapeJsString(String? value) {
    if (value == null) return "''";
    return "'${value.replaceAll("'", "\\'").replaceAll('\n', '\\n').replaceAll('\r', '\\r')}'";
  }

  String _createArHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>AR Viewer - ${widget.productName ?? '3D Model'}</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    html, body {
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: #000;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
    #ar-container {
      width: 100%;
      height: 100%;
      position: relative;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .info-text {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 16px 24px;
      border-radius: 20px;
      font-size: 14px;
      z-index: 100;
      text-align: center;
      max-width: 90%;
      backdrop-filter: blur(10px);
    }
    .error-text {
      background: rgba(239, 68, 68, 0.95);
    }
  </style>
</head>
<body>
  <div id="ar-container">
    <div class="info-text" id="info-text">
      Opening AR view...
    </div>
  </div>

  <script>
    const infoText = document.getElementById('info-text');
    
    // Check if this is an Android device
    const isAndroid = /android/i.test(navigator.userAgent);
    
    // Model URL and configuration - escape single quotes in URL
    const modelUrl = ${_escapeJsString(widget.modelUrl)};
    const encodedModelUrl = encodeURIComponent(modelUrl);
    const productTitle = ${_escapeJsString(widget.productName ?? '3D Model')};
    const encodedTitle = encodeURIComponent(productTitle);
    
    // Fallback URL for non-Android or when Scene Viewer is unavailable
    const fallbackUrl = 'https://arvr.google.com/scene-viewer?file=' + encodedModelUrl + '&title=' + encodedTitle;
    
    // Intent URL for Android - opens Scene Viewer directly
    const intentUrl = 'intent://arvr.google.com/scene-viewer/1.0?file=' + encodedModelUrl + 
                      '&mode=ar_only' +
                      '&title=' + encodedTitle +
                      '#Intent;scheme=https;package=com.google.ar.core;action=android.intent.action.VIEW;S.browser_fallback_url=' + 
                      encodeURIComponent(fallbackUrl) + ';end;';
    
    // Function to open Scene Viewer
    function openSceneViewer() {
      try {
        if (isAndroid) {
          // Use intent URL for Android devices
          window.location.href = intentUrl;
        } else {
          // Use fallback URL for other platforms
          window.location.href = fallbackUrl;
        }
        
        // Show loading message
        infoText.textContent = 'Opening Scene Viewer...';
        
        // If we're still here after a delay, show error
        setTimeout(() => {
          if (document.hasFocus()) {
            infoText.textContent = 'Please ensure Google ARCore is installed and try again.';
            infoText.classList.add('error-text');
          }
        }, 2000);
      } catch (error) {
        console.error('Error opening Scene Viewer:', error);
        infoText.textContent = 'Failed to open AR. Please try again.';
        infoText.classList.add('error-text');
      }
    }
    
    // Auto-open Scene Viewer when page loads
    window.addEventListener('load', () => {
      // Small delay to ensure page is ready
      setTimeout(() => {
        openSceneViewer();
      }, 300);
    });
    
    // Also try to open immediately if page is already loaded
    if (document.readyState === 'complete' || document.readyState === 'interactive') {
      setTimeout(() => {
        openSceneViewer();
      }, 300);
    }
    
    // Handle back navigation from Scene Viewer
    function goBack() {
      if (window.parent) {
        window.parent.postMessage({ type: 'ar_back' }, '*');
      } else {
        window.history.back();
      }
    }
    
    // Listen for visibility change (when user returns from Scene Viewer)
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        // User opened Scene Viewer
        infoText.style.display = 'none';
      } else {
        // User returned from Scene Viewer
        setTimeout(() => {
          goBack();
        }, 500);
      }
    });
  </script>
</body>
</html>
''';
  }
}
