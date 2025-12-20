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
    .reset-button {
      position: absolute;
      bottom: 20px;
      left: 20px;
      background: rgba(0, 0, 0, 0.7);
      color: white;
      border: 2px solid rgba(255, 255, 255, 0.8);
      width: 56px;
      height: 56px;
      border-radius: 50%;
      font-size: 24px;
      cursor: pointer;
      display: none;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
      z-index: 100;
      backdrop-filter: blur(10px);
      transition: all 0.2s ease;
    }
    .reset-button:hover {
      background: rgba(0, 0, 0, 0.9);
      transform: scale(1.1);
    }
    .reset-button:active {
      transform: scale(0.95);
    }
    .reset-button.visible {
      display: flex;
    }
  </style>
</head>
<body>
  <div id="ar-container">
    <model-viewer
      id="ar-model"
      src="${widget.modelUrl}"
      alt="${widget.productName ?? '3D Model'}"
      ar
      ar-modes="scene-viewer webxr quick-look"
      ar-scale="0.25"
      scale="0.25"
      ar-placement="floor"
      camera-controls
      shadow-intensity="1.5"
      exposure="1.2"
      environment-image="neutral"
      reveal="auto"
      loading="auto"
      interaction-policy="allow-when-focused"
      style="width: 100%; height: 100%;"
    >
    </model-viewer>
    <button class="reset-button" id="reset-button" onclick="resetModel()" title="Reset/Remove Model">
      <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"></path>
        <path d="M21 3v5h-5"></path>
        <path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"></path>
        <path d="M3 21v-5h5"></path>
      </svg>
    </button>
    <div class="info-text" id="info-text">
      Opening AR view...
    </div>
  </div>

  <script type="module">
    const modelViewer = document.querySelector('#ar-model');
    const infoText = document.getElementById('info-text');
    const resetButton = document.getElementById('reset-button');
    let arAutoTriggered = false;

    // Check if device is mobile/tablet (AR capable)
    function isMobileDevice() {
      return /android|webos|iphone|ipad|ipod|blackberry|iemobile|opera mini/i.test(navigator.userAgent) ||
             (window.innerWidth <= 768 && 'ontouchstart' in window);
    }

    // Check if AR is available
    async function checkARAvailability() {
      if (!modelViewer.canActivateAR) {
        return false;
      }
      
      try {
        // Check if any AR mode is available
        const arModes = modelViewer.arModes;
        return arModes && arModes.length > 0;
      } catch (e) {
        return false;
      }
    }

    // Auto-trigger AR when model loads - only on mobile devices
    modelViewer.addEventListener('load', async () => {
      if (arAutoTriggered) return;
      
      // Check if device is mobile before attempting AR
      const isMobile = isMobileDevice();
      
      if (!isMobile) {
        infoText.textContent = 'AR is only available on mobile and tablet devices. Please open this on your mobile device to view in AR.';
        infoText.style.background = 'rgba(239, 68, 68, 0.95)';
        // Hide after 5 seconds
        setTimeout(() => {
          infoText.style.display = 'none';
        }, 5000);
        return;
      }
      
      // Small delay to ensure model is fully loaded
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Check AR availability
      const arAvailable = await checkARAvailability();
      
      if (!arAvailable) {
        infoText.textContent = 'AR is not available on this device. Please ensure Google ARCore is installed (Android) or use a compatible device.';
        infoText.style.background = 'rgba(239, 68, 68, 0.95)';
        return;
      }
      
      try {
        if (modelViewer.activateAR) {
          arAutoTriggered = true;
          infoText.textContent = 'Opening AR view...';
          
          // Activate AR - model-viewer will handle Scene Viewer with proper CORS
          await modelViewer.activateAR();
          
          // Hide info text and show reset button after AR activates
          setTimeout(() => {
            infoText.style.display = 'none';
            resetButton.classList.add('visible');
          }, 1000);
        } else {
          infoText.textContent = 'AR is not supported on this device/browser.';
          infoText.style.background = 'rgba(239, 68, 68, 0.95)';
        }
      } catch (error) {
        console.error('AR activation error:', error);
        infoText.textContent = 'Failed to open AR. Please ensure the model file is accessible and try again.';
        infoText.style.background = 'rgba(239, 68, 68, 0.95)';
      }
    });

    // Handle AR status changes
    modelViewer.addEventListener('ar-status', (event) => {
      console.log('AR status:', event.detail.status);
      
      if (event.detail.status === 'session-started') {
        infoText.style.display = 'none';
        // Show reset button when AR session starts
        resetButton.classList.add('visible');
      } else if (event.detail.status === 'session-ended' || event.detail.status === 'not-presenting') {
        // Hide reset button when AR session ends
        resetButton.classList.remove('visible');
        // When AR session ends, go back
        goBack();
      }
    });

    // Reset function to remove/reset the model
    function resetModel() {
      try {
        // Try to reset the model by reloading it
        const currentSrc = modelViewer.src;
        modelViewer.src = '';
        
        // Small delay then reload
        setTimeout(() => {
          modelViewer.src = currentSrc;
          console.log('Model reset');
        }, 100);
        
        // Alternative: Try to reset camera and model position
        if (modelViewer.cameraOrbit) {
          modelViewer.cameraOrbit = '0deg 75deg 2.5m';
        }
        if (modelViewer.scale) {
          modelViewer.scale = '0.25';
        }
        
        // In Scene Viewer, the reset might need to be handled differently
        // This will at least reset the preview/model-viewer state
      } catch (error) {
        console.error('Error resetting model:', error);
      }
    }

    // Handle model load errors
    modelViewer.addEventListener('error', (event) => {
      console.error('Model load error:', event);
      infoText.textContent = 'Error loading model. Please check if the file is accessible.';
      infoText.style.background = 'rgba(239, 68, 68, 0.95)';
    });

    // Go back navigation
    function goBack() {
      if (window.parent) {
        window.parent.postMessage({ type: 'ar_back' }, '*');
      } else {
        window.history.back();
      }
    }
  </script>
</body>
</html>
''';
  }
}
