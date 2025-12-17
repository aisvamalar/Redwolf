import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ModelViewerWidget extends StatefulWidget {
  final String modelUrl;
  final String? altText;

  const ModelViewerWidget({super.key, required this.modelUrl, this.altText});

  @override
  State<ModelViewerWidget> createState() => _ModelViewerWidgetState();
}

class _ModelViewerWidgetState extends State<ModelViewerWidget> {
  String? _viewerKey;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _viewerKey = 'model-viewer-${DateTime.now().millisecondsSinceEpoch}';
      _registerView();
    }
  }

  void _registerView() {
    final iframe = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..srcdoc = _createViewerHtml();

    ui.platformViewRegistry.registerViewFactory(
      _viewerKey!,
      (int viewId) => iframe,
    );
  }

  String _createViewerHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
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
      background: #ffffff;
      margin: 0;
      padding: 0;
    }
    model-viewer {
      width: 100%;
      height: 100%;
      display: block;
      cursor: grab;
      touch-action: pan-y pinch-zoom;
      -webkit-touch-callout: none;
      -webkit-user-select: none;
      user-select: none;
    }
    model-viewer:active {
      cursor: grabbing;
    }
    @media (max-width: 768px) {
      model-viewer {
        cursor: default;
      }
    }
    .zoom-controls {
      position: absolute;
      right: 16px;
      top: 50%;
      transform: translateY(-50%);
      display: flex;
      flex-direction: column;
      gap: 8px;
      z-index: 100;
    }
    .zoom-button {
      width: 40px;
      height: 40px;
      border-radius: 50%;
      background: rgba(255, 255, 255, 0.9);
      border: 1px solid rgba(0, 0, 0, 0.1);
      color: #333;
      font-size: 20px;
      font-weight: bold;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
      transition: all 0.2s ease;
      user-select: none;
    }
    .zoom-button:hover {
      background: rgba(255, 255, 255, 1);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
      transform: scale(1.05);
    }
    .zoom-button:active {
      transform: scale(0.95);
    }
  </style>
</head>
<body>
  <div style="position: relative; width: 100%; height: 100%;">
  <model-viewer
    src="${widget.modelUrl}"
    alt="${widget.altText ?? '3D Model'}"
    camera-controls
    interaction-policy="always-allow"
    shadow-intensity="1.5"
    exposure="1.2"
    environment-image="neutral"
    camera-orbit="0deg 75deg auto"
    field-of-view="25deg"
    style="width: 100%; height: 100%; display: block; background: #ffffff;"
    touch-action="none"
    reveal="auto"
    loading="auto"
    bounds="tight"
    disable-zoom="false"
    disable-pan="false"
    disable-tap="false"
  >
    <div slot="poster" style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background: #ffffff; position: absolute; top: 0; left: 0; z-index: 1;">
      <div style="text-align: center; color: #666;">
        <div style="font-size: 48px; margin-bottom: 16px;">📦</div>
        <div style="font-size: 18px; margin-bottom: 8px; font-weight: 600; color: #333;">Loading 3D Model...</div>
        <div style="font-size: 14px; opacity: 0.7; color: #666;">${widget.altText ?? '3D Model'}</div>
      </div>
    </div>
  </model-viewer>
  
  <!-- Zoom Controls -->
  <div class="zoom-controls">
    <button class="zoom-button" onclick="zoomIn()" title="Zoom In">+</button>
    <button class="zoom-button" onclick="zoomOut()" title="Zoom Out">−</button>
    <button class="zoom-button" onclick="resetZoom()" title="Reset View">⟲</button>
  </div>
  </div>
  <script>
    const modelViewer = document.querySelector('model-viewer');
    let currentZoomLevel = 1.0;
    
    // Simple zoom functions using field of view (more reliable than distance)
    function zoomIn() {
      currentZoomLevel = Math.min(currentZoomLevel * 1.3, 4.0);
      updateZoom();
    }
    
    function zoomOut() {
      currentZoomLevel = Math.max(currentZoomLevel / 1.3, 0.2);
      updateZoom();
    }
    
    function resetZoom() {
      currentZoomLevel = 1.0;
      modelViewer.cameraOrbit = '0deg 75deg auto';
      modelViewer.fieldOfView = '25deg';
      // Let model-viewer handle automatic framing
      if (modelViewer.updateFraming) {
        modelViewer.updateFraming();
      }
    }
    
    function updateZoom() {
      // Use field of view for zooming - more reliable than camera distance
      const baseFOV = 25; // degrees - narrower for better initial framing
      const newFOV = baseFOV / currentZoomLevel;
      const clampedFOV = Math.max(5, Math.min(120, newFOV));
      modelViewer.fieldOfView = clampedFOV + 'deg';
    }
    
    // Initialize with proper framing
    function initializeViewer() {
      // Reset to default state and let model-viewer auto-frame
      modelViewer.cameraOrbit = '0deg 75deg auto';
      modelViewer.fieldOfView = '25deg'; // Narrower FOV for better initial framing
      
      // Use model-viewer's built-in framing
      if (modelViewer.updateFraming) {
        modelViewer.updateFraming();
      }
      
      currentZoomLevel = 1.0;
    }
    
    // Initialize on both events
    modelViewer.addEventListener('load', () => {
      setTimeout(initializeViewer, 100);
    });
    
    modelViewer.addEventListener('model-loaded', () => {
      setTimeout(initializeViewer, 50);
    });
    
    // Make functions globally available
    window.zoomIn = zoomIn;
    window.zoomOut = zoomOut;
    window.resetZoom = resetZoom;
  </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _viewerKey != null
          ? SizedBox.expand(
              child: HtmlElementView(
                viewType: _viewerKey!,
                onPlatformViewCreated: (int viewId) {},
              ),
            )
          : const Center(child: CircularProgressIndicator());
    } else {
      return _ModelViewerMobile(
        modelUrl: widget.modelUrl,
        altText: widget.altText,
      );
    }
  }
}

/// Mobile-specific implementation
class _ModelViewerMobile extends StatelessWidget {
  final String modelUrl;
  final String? altText;

  const _ModelViewerMobile({required this.modelUrl, this.altText});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.view_in_ar, size: 64, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            const Text(
              '3D Model Viewer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Use AR button for 3D experience',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
