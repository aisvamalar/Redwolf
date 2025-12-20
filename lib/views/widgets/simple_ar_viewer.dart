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

  String _createArHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>AR Viewer - ${widget.productName ?? '3D Model'}</title>
  <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.3.0/model-viewer.min.js"></script>
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
    model-viewer {
      width: 100%;
      height: 100%;
      display: block;
      background: #000;
    }
    .control-button {
      position: absolute;
      background: rgba(0, 0, 0, 0.6);
      color: white;
      border: 2px solid rgba(255, 255, 255, 0.8);
      width: 48px;
      height: 48px;
      border-radius: 50%;
      font-size: 20px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
      z-index: 100;
      backdrop-filter: blur(10px);
      transition: all 0.2s ease;
    }
    .control-button:hover {
      background: rgba(0, 0, 0, 0.8);
      transform: scale(1.1);
    }
    .control-button:active {
      transform: scale(0.95);
    }
    .back-button {
      top: 20px;
      left: 20px;
      font-size: 24px;
    }
    .reset-button {
      bottom: 20px;
      left: 20px;
      font-size: 20px;
    }
    .zoom-controls {
      position: absolute;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      display: flex;
      flex-direction: column;
      gap: 8px;
      z-index: 100;
    }
    .zoom-button {
      background: rgba(0, 0, 0, 0.6);
      color: white;
      border: 2px solid rgba(255, 255, 255, 0.8);
      width: 44px;
      height: 44px;
      border-radius: 50%;
      font-size: 18px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
      backdrop-filter: blur(10px);
      transition: all 0.2s ease;
    }
    .zoom-button:hover {
      background: rgba(0, 0, 0, 0.8);
      transform: scale(1.1);
    }
    .zoom-button:active {
      transform: scale(0.95);
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
    .controls-bar {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      height: 100px;
      background: linear-gradient(to top, rgba(0, 0, 0, 0.7), transparent);
      pointer-events: none;
      z-index: 99;
    }
  </style>
</head>
<body>
  <div id="ar-container">
    <model-viewer
      id="ar-model"
      src="${widget.modelUrl}"
      alt="${widget.altText ?? widget.productName ?? '3D Model'}"
      ar
      ar-modes="scene-viewer webxr quick-look"
      ar-scale="0.5"
      scale="0.5"
      camera-controls
      shadow-intensity="1.5"
      exposure="1.2"
      environment-image="neutral"
      reveal="auto"
      loading="auto"
      interaction-policy="allow-when-focused"
    >
    </model-viewer>
    
    <div class="controls-bar"></div>
    
    <button class="control-button back-button" onclick="goBack()" title="Exit">×</button>
    <button class="control-button reset-button" onclick="resetModel()" title="Reset">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"></path>
        <path d="M21 3v5h-5"></path>
        <path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"></path>
        <path d="M3 21v-5h5"></path>
      </svg>
    </button>
    
    <div class="zoom-controls">
      <button class="zoom-button" onclick="zoomIn()" title="Zoom In">+</button>
      <button class="zoom-button" onclick="zoomOut()" title="Zoom Out">−</button>
    </div>
    
    <div class="info-text" id="info-text">
      Opening AR view...
    </div>
  </div>

  <script type="module">
    const modelViewer = document.querySelector('#ar-model');
    const infoText = document.getElementById('info-text');
    let arAutoTriggered = false;
    let currentZoom = 2.5;
    const minZoom = 1.0;
    const maxZoom = 8.0;
    const zoomStep = 0.5;

    // Auto-trigger AR when model loads
    modelViewer.addEventListener('load', async () => {
      if (arAutoTriggered) return;
      
      // Small delay to ensure model is fully loaded
      await new Promise(resolve => setTimeout(resolve, 500));
      
      try {
        if (modelViewer.activateAR) {
          arAutoTriggered = true;
          infoText.textContent = 'Opening AR view...';
          
          // Activate AR immediately
          await modelViewer.activateAR();
          
          // Hide info text after AR activates
          setTimeout(() => {
            infoText.style.display = 'none';
          }, 1000);
        } else {
          infoText.textContent = 'AR is not supported on this device/browser.';
          infoText.style.background = 'rgba(239, 68, 68, 0.95)';
        }
      } catch (error) {
        console.error('AR activation error:', error);
        infoText.textContent = 'Failed to open AR. Please try again.';
        infoText.style.background = 'rgba(239, 68, 68, 0.95)';
      }
    });

    // Handle AR status changes
    modelViewer.addEventListener('ar-status', (event) => {
      console.log('AR status:', event.detail.status);
      
      if (event.detail.status === 'session-started') {
        infoText.style.display = 'none';
        // Ensure model is properly scaled and positioned
        try {
          modelViewer.scale = '0.5';
          modelViewer.arScale = '0.5';
        } catch (e) {
          console.log('Scale adjustment:', e);
        }
      } else if (event.detail.status === 'session-ended' || event.detail.status === 'not-presenting') {
        // When AR session ends, go back
        goBack();
      }
    });

    // Handle model placement in AR
    modelViewer.addEventListener('ar-tracking', (event) => {
      // This helps ensure proper tracking and placement
      console.log('AR tracking:', event.detail);
    });

    // Reset model position and zoom
    function resetModel() {
      currentZoom = 2.5;
      modelViewer.cameraOrbit = '0deg 75deg 2.5m';
      modelViewer.scale = '0.5';
      console.log('Model reset');
    }

    // Zoom in
    function zoomIn() {
      if (currentZoom > minZoom) {
        currentZoom = Math.max(minZoom, currentZoom - zoomStep);
        updateCameraZoom();
      }
    }

    // Zoom out
    function zoomOut() {
      if (currentZoom < maxZoom) {
        currentZoom = Math.min(maxZoom, currentZoom + zoomStep);
        updateCameraZoom();
      }
    }

    // Update camera zoom
    function updateCameraZoom() {
      const orbit = modelViewer.cameraOrbit.split(' ');
      if (orbit.length >= 3) {
        modelViewer.cameraOrbit = orbit[0] + ' ' + orbit[1] + ' ' + currentZoom + 'm';
      }
    }

    // Go back navigation
    function goBack() {
      if (window.parent) {
        window.parent.postMessage({ type: 'ar_back' }, '*');
      }
    }

    // Add spin animation for loading
    const style = document.createElement('style');
    style.textContent = `
      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
    `;
    document.head.appendChild(style);
  </script>
</body>
</html>
''';
  }
}
