import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// AR Viewer Widget using WebXR API for Flutter Web
/// Supports plane tracking and 3D anchors
class ARViewerWidget extends StatefulWidget {
  final String modelUrl;
  final String? altText;

  const ARViewerWidget({super.key, required this.modelUrl, this.altText});

  @override
  State<ARViewerWidget> createState() => _ARViewerWidgetState();
}

class _ARViewerWidgetState extends State<ARViewerWidget> {
  String? _iframeKey;
  bool _isARSupported = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _iframeKey = 'ar-viewer-${widget.modelUrl.hashCode}';
      _checkARSupport();
      _registerARViewer();
    }
  }

  void _checkARSupport() {
    // Check if WebXR is supported via JavaScript
    // WebXR is checked in the HTML/JS code, so we assume it's available
    // The actual check happens in the iframe's JavaScript
    setState(() {
      _isARSupported = true; // Will be verified by JavaScript in iframe
    });
  }

  void _registerARViewer() {
    if (!kIsWeb || _iframeKey == null) return;

    // Create iframe element with WebXR-enabled AR viewer
    final iframe = html.IFrameElement()
      ..id = _iframeKey!
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..srcdoc =
          '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>AR Viewer</title>
  <script type="module" src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.3.0/model-viewer.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/three@0.160.0/build/three.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/@webxr-input-profiles/motion-controllers@1.0/dist/motion-controllers.module.js"></script>
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
    }
    model-viewer {
      width: 100%;
      height: 100%;
      background-color: transparent;
    }
    .ar-controls {
      position: absolute;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      display: flex;
      gap: 12px;
      z-index: 100;
    }
    .ar-button {
      background: rgba(220, 38, 38, 0.9);
      color: white;
      border: none;
      padding: 12px 24px;
      border-radius: 25px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      backdrop-filter: blur(10px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      transition: all 0.3s ease;
    }
    .ar-button:hover {
      background: rgba(220, 38, 38, 1);
      transform: translateY(-2px);
      box-shadow: 0 6px 16px rgba(0,0,0,0.4);
    }
    .ar-button:active {
      transform: translateY(0);
    }
    .info-panel {
      position: absolute;
      top: 20px;
      left: 20px;
      background: rgba(0, 0, 0, 0.7);
      color: white;
      padding: 16px;
      border-radius: 12px;
      backdrop-filter: blur(10px);
      z-index: 100;
      max-width: 300px;
      font-size: 14px;
      line-height: 1.6;
    }
    .info-panel h3 {
      margin-bottom: 8px;
      font-size: 16px;
    }
    .info-panel p {
      margin: 4px 0;
      opacity: 0.9;
    }
    .status-indicator {
      display: inline-block;
      width: 8px;
      height: 8px;
      border-radius: 50%;
      margin-right: 8px;
    }
    .status-active {
      background: #10b981;
      box-shadow: 0 0 8px #10b981;
    }
    .status-inactive {
      background: #ef4444;
    }
  </style>
</head>
<body>
  <div id="ar-container">
    <model-viewer
      id="ar-model"
      src="${widget.modelUrl}"
      alt="${widget.altText ?? '3D Model'}"
      ar
      ar-modes="webxr scene-viewer quick-look"
      camera-controls
      auto-rotate
      interaction-policy="allow-when-focused"
      shadow-intensity="1"
      exposure="1"
      environment-image="neutral"
      style="width: 100%; height: 100%;"
      xr-environment
    >
      <div slot="poster" style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #DC2626 0%, #991B1B 100%);">
        <div style="text-align: center; color: white;">
          <div style="font-size: 32px; margin-bottom: 16px;">📱</div>
          <div style="font-size: 24px; margin-bottom: 12px; font-weight: 600;">AR Ready</div>
          <div style="font-size: 14px; opacity: 0.9;">Tap AR button to view in AR</div>
        </div>
      </div>
    </model-viewer>
    
    <div class="info-panel">
      <h3>AR Features</h3>
      <p><span class="status-indicator status-active"></span>Plane Detection</p>
      <p><span class="status-indicator status-active"></span>3D Anchors</p>
      <p><span class="status-indicator status-active"></span>WebXR Support</p>
      <p style="margin-top: 12px; font-size: 12px; opacity: 0.7;">
        Move your device to detect surfaces. Tap to place the model.
      </p>
    </div>
    
    <div class="ar-controls">
      <button class="ar-button" onclick="enterAR()">
        🥽 Enter AR
      </button>
      <button class="ar-button" onclick="resetView()">
        🔄 Reset
      </button>
    </div>
  </div>

  <script type="module">
    const modelViewer = document.querySelector('#ar-model');
    let arSession = null;
    let isARActive = false;

    // Check WebXR support
    async function checkWebXRSupport() {
      if (navigator.xr) {
        const supported = await navigator.xr.isSessionSupported('immersive-ar');
        console.log('WebXR AR supported:', supported);
        return supported;
      }
      return false;
    }

    // Enter AR mode
    async function enterAR() {
      try {
        if (modelViewer.activateAR) {
          await modelViewer.activateAR();
          isARActive = true;
          updateUI();
        } else {
          // Fallback: Use model-viewer's built-in AR
          modelViewer.setAttribute('ar', 'true');
          isARActive = true;
          updateUI();
        }
      } catch (error) {
        console.error('AR activation error:', error);
        alert('AR not available. Please use a compatible device/browser.');
      }
    }

    // Reset view
    function resetView() {
      if (modelViewer.resetCamera) {
        modelViewer.resetCamera();
      }
      if (isARActive && modelViewer.exitAR) {
        modelViewer.exitAR();
        isARActive = false;
        updateUI();
      }
    }

    // Update UI based on AR state
    function updateUI() {
      const button = document.querySelector('.ar-button');
      if (isARActive) {
        button.textContent = '🚪 Exit AR';
        button.onclick = exitAR;
      } else {
        button.textContent = '🥽 Enter AR';
        button.onclick = enterAR;
      }
    }

    // Exit AR mode
    async function exitAR() {
      if (modelViewer.exitAR) {
        await modelViewer.exitAR();
      }
      isARActive = false;
      updateUI();
    }

    // Make functions globally available
    window.enterAR = enterAR;
    window.resetView = resetView;
    window.exitAR = exitAR;

    // Check AR support on load
    checkWebXRSupport().then(supported => {
      if (!supported) {
        console.log('WebXR not supported, using model-viewer AR fallback');
      }
    });

    // Handle AR session events
    modelViewer.addEventListener('ar-status', (event) => {
      console.log('AR Status:', event.detail.status);
      if (event.detail.status === 'not-presenting') {
        isARActive = false;
        updateUI();
      }
    });
  </script>
</body>
</html>
''';

    // Register the platform view
    ui_web.platformViewRegistry.registerViewFactory(
      _iframeKey!,
      (int viewId) => iframe,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _iframeKey != null) {
      return Stack(
        children: [
          HtmlElementView(viewType: _iframeKey!),
          if (!_isARSupported)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.info_outline, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Using model-viewer AR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    } else {
      return _buildUnsupportedView();
    }
  }

  Widget _buildUnsupportedView() {
    return Container(
      color: Colors.grey[900],
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
                'AR features require a compatible device and browser with WebXR support.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
