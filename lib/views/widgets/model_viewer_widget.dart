import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'model_viewer_web_stub.dart'
    if (dart.library.html) 'model_viewer_web.dart' as web_utils;

/// Platform-aware 3D model viewer widget
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
      _viewerKey = 'model-viewer-${widget.modelUrl.hashCode}';
      _registerViewer();
    }
  }

  void _registerViewer() {
    if (!kIsWeb || _viewerKey == null) return;

    final iframe = web_utils.WebUtils.createIFrameElement();
    if (iframe == null) return;
    
    iframe.id = _viewerKey!;
    iframe.style.border = 'none';
    iframe.style.width = '100%';
    iframe.style.height = '100%';
    iframe.style.margin = '0';
    iframe.style.padding = '0';
    iframe.style.overflow = 'hidden';
    iframe.style.pointerEvents = 'auto';
    iframe.srcdoc = _createViewerHtml();

    web_utils.WebUtils.registerViewFactory(
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
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
    }
    model-viewer {
      width: 100%;
      height: 100%;
      display: block;
      cursor: grab;
    }
    model-viewer:active {
      cursor: grabbing;
    }
  </style>
</head>
<body>
  <model-viewer
    src="${widget.modelUrl}"
    alt="${widget.altText ?? '3D Model'}"
    camera-controls
    auto-rotate
    auto-rotate-delay="3000"
    rotation-per-second="10deg"
    interaction-policy="always-allow"
    shadow-intensity="1.5"
    exposure="1.2"
    environment-image="neutral"
    camera-orbit="0deg 75deg 2.2m"
    min-camera-orbit="auto auto 1.5m"
    max-camera-orbit="auto auto 4m"
    field-of-view="30deg"
    style="width: 100%; height: 100%; display: block; background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);"
    touch-action="none"
    reveal="auto"
    loading="auto"
    bounds="tight"
    scale="0.8 0.8 0.8"
    disable-zoom="false"
    disable-pan="false"
    disable-tap="false"
  >
    <div slot="poster" style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #DC2626 0%, #991B1B 100%); position: absolute; top: 0; left: 0; z-index: 1;">
      <div style="text-align: center; color: white;">
        <div style="font-size: 48px; margin-bottom: 16px;"></div>
        <div style="font-size: 24px; margin-bottom: 12px; font-weight: 600;">Loading 3D Model...</div>
        <div style="font-size: 14px; opacity: 0.9; margin-bottom: 8px;">${widget.altText ?? '3D Model'}</div>
      </div>
    </div>
  </model-viewer>
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
