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
      background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
    }
    .ar-button {
      position: absolute;
      bottom: 40px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(220, 38, 38, 0.95);
      color: white;
      border: none;
      padding: 16px 32px;
      border-radius: 30px;
      font-size: 16px;
      font-weight: 600;
      cursor: pointer;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
      z-index: 100;
      display: flex;
      align-items: center;
      gap: 8px;
      transition: transform 0.2s, box-shadow 0.2s;
    }
    .ar-button:hover {
      transform: translateX(-50%) scale(1.05);
      box-shadow: 0 6px 20px rgba(0, 0, 0, 0.5);
    }
    .ar-button:active {
      transform: translateX(-50%) scale(0.95);
    }
    .ar-button:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
    .back-button {
      position: absolute;
      top: 20px;
      left: 20px;
      background: rgba(0, 0, 0, 0.7);
      color: white;
      border: 2px solid rgba(255, 255, 255, 0.8);
      width: 48px;
      height: 48px;
      border-radius: 50%;
      font-size: 24px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
      z-index: 100;
      backdrop-filter: blur(10px);
    }
    .back-button:hover {
      background: rgba(0, 0, 0, 0.9);
    }
    .info-text {
      position: absolute;
      top: 80px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 12px 20px;
      border-radius: 20px;
      font-size: 14px;
      z-index: 100;
      text-align: center;
      max-width: 90%;
      backdrop-filter: blur(10px);
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
      ar-scale="auto"
      ar-placement="floor"
      camera-controls
      auto-rotate
      auto-rotate-delay="1000"
      rotation-per-second="20deg"
      interaction-policy="allow-when-focused"
      shadow-intensity="1.5"
      exposure="1.2"
      environment-image="neutral"
      camera-orbit="0deg 75deg 2.5m"
      min-camera-orbit="auto auto 1m"
      max-camera-orbit="auto auto 8m"
      field-of-view="45deg"
      reveal="auto"
      loading="auto"
    >
      <div slot="poster" style="width: 100%; height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);">
        <div style="text-align: center; color: white; padding: 20px;">
          <div style="font-size: 64px; margin-bottom: 20px;">📱</div>
          <div style="font-size: 24px; font-weight: 600; margin-bottom: 12px;">${widget.productName ?? '3D Model'}</div>
          <div style="font-size: 14px; opacity: 0.8; margin-bottom: 24px;">Tap the button below to view in AR</div>
        </div>
      </div>
    </model-viewer>
    
    <button class="back-button" onclick="goBack()" title="Go back">×</button>
    
    <div class="info-text" id="info-text" style="display: none;">
      AR is opening... Please wait
    </div>
    
    <button class="ar-button" id="ar-button" onclick="enterAR()">
      <span>📱</span>
      <span>View in AR</span>
    </button>
  </div>

  <script type="module">
    const modelViewer = document.querySelector('#ar-model');
    const arButton = document.getElementById('ar-button');
    const infoText = document.getElementById('info-text');
    let isARActive = false;

    // Enter AR mode using Scene Viewer
    async function enterAR() {
      try {
        if (!modelViewer.activateAR) {
          showError('AR is not supported on this device/browser.');
          return;
        }

        // Update UI
        arButton.disabled = true;
        arButton.innerHTML = '<span style="display: inline-block; width: 16px; height: 16px; border: 2px solid white; border-top: 2px solid transparent; border-radius: 50%; animation: spin 1s linear infinite; margin-right: 8px;"></span><span>Opening AR...</span>';
        infoText.style.display = 'block';
        infoText.textContent = 'Opening AR view...';

        // Activate AR - Scene Viewer will handle everything
        await modelViewer.activateAR();
        
        isARActive = true;
        arButton.style.display = 'none';
        infoText.style.display = 'none';
        
      } catch (error) {
        console.error('AR activation error:', error);
        showError('Failed to open AR. Please try again or use a compatible device.');
        arButton.disabled = false;
        arButton.innerHTML = '<span>📱</span><span>View in AR</span>';
        infoText.style.display = 'none';
      }
    }

    // Handle AR status changes
    modelViewer.addEventListener('ar-status', (event) => {
      console.log('AR status:', event.detail.status);
      
      if (event.detail.status === 'session-started') {
        isARActive = true;
        arButton.style.display = 'none';
        infoText.style.display = 'none';
      } else if (event.detail.status === 'session-ended') {
        isARActive = false;
        arButton.style.display = 'flex';
        arButton.disabled = false;
        arButton.innerHTML = '<span>📱</span><span>View in AR</span>';
      } else if (event.detail.status === 'not-presenting') {
        isARActive = false;
        arButton.style.display = 'flex';
        arButton.disabled = false;
        arButton.innerHTML = '<span>📱</span><span>View in AR</span>';
      }
    });

    // Go back navigation
    function goBack() {
      if (window.parent) {
        window.parent.postMessage({ type: 'ar_back' }, '*');
      }
    }

    // Show error message
    function showError(message) {
      infoText.style.display = 'block';
      infoText.textContent = message;
      infoText.style.background = 'rgba(239, 68, 68, 0.95)';
      
      setTimeout(() => {
        infoText.style.display = 'none';
        infoText.style.background = 'rgba(0, 0, 0, 0.8)';
      }, 5000);
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
