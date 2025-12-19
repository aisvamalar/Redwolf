import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'simple_ar_viewer_web_stub.dart'
    if (dart.library.html) 'simple_ar_viewer_web.dart'
    as web_utils;

/// AR Viewer with full controls - Scale, Rotate, Move, Reset
/// Uses WebXR for custom controls matching the reference image
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
      touch-action: none;
    }
    #ar-container {
      width: 100%;
      height: 100%;
      position: relative;
    }
    model-viewer {
      width: 100%;
      height: 100%;
      display: block;
      background: #000;
    }
    
    /* Top Controls */
    .top-controls {
      position: absolute;
      top: 20px;
      left: 20px;
      z-index: 100;
      display: flex;
      gap: 12px;
    }
    .control-btn {
      background: rgba(128, 128, 128, 0.8);
      color: white;
      border: none;
      width: 48px;
      height: 48px;
      border-radius: 50%;
      font-size: 24px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
      backdrop-filter: blur(10px);
      transition: transform 0.2s;
    }
    .control-btn:hover {
      transform: scale(1.1);
    }
    .control-btn:active {
      transform: scale(0.95);
    }
    .info-btn {
      background: rgba(0, 0, 0, 0.7);
      border: 2px solid rgba(255, 255, 255, 0.8);
      font-size: 18px;
      font-weight: bold;
    }
    
    /* Right Side Scale Control */
    .scale-control {
      position: absolute;
      right: 20px;
      top: 50%;
      transform: translateY(-50%);
      z-index: 100;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
    }
    .scale-icon {
      font-size: 20px;
      color: white;
      text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
    }
    .scale-slider {
      width: 60px;
      height: 200px;
      -webkit-appearance: slider-vertical;
      appearance: slider-vertical;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 30px;
      outline: none;
      cursor: pointer;
    }
    .scale-slider::-webkit-slider-thumb {
      -webkit-appearance: none;
      appearance: none;
      width: 24px;
      height: 24px;
      background: white;
      border-radius: 50%;
      cursor: pointer;
      box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
    }
    .scale-slider::-moz-range-thumb {
      width: 24px;
      height: 24px;
      background: white;
      border-radius: 50%;
      cursor: pointer;
      border: none;
      box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
    }
    .scale-labels {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
      color: white;
      font-size: 18px;
      font-weight: bold;
      text-shadow: 0 2px 4px rgba(0, 0, 0, 0.5);
    }
    
    /* Bottom Controls */
    .bottom-controls {
      position: absolute;
      bottom: 20px;
      left: 0;
      right: 0;
      z-index: 100;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 16px;
    }
    .drag-hint {
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 12px 20px;
      border-radius: 20px;
      font-size: 14px;
      display: flex;
      align-items: center;
      gap: 8px;
      backdrop-filter: blur(10px);
    }
    .rotate-control {
      background: rgba(0, 0, 0, 0.8);
      padding: 12px 24px;
      border-radius: 20px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      backdrop-filter: blur(10px);
    }
    .rotate-label {
      color: white;
      font-size: 14px;
      font-weight: 500;
    }
    .rotate-slider-container {
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .rotate-value {
      color: white;
      font-size: 12px;
      min-width: 40px;
      text-align: center;
    }
    .rotate-slider {
      width: 200px;
      height: 6px;
      background: rgba(255, 255, 255, 0.3);
      border-radius: 3px;
      outline: none;
      -webkit-appearance: none;
      appearance: none;
    }
    .rotate-slider::-webkit-slider-thumb {
      -webkit-appearance: none;
      appearance: none;
      width: 20px;
      height: 20px;
      background: white;
      border-radius: 50%;
      cursor: pointer;
      box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
    }
    .rotate-slider::-moz-range-thumb {
      width: 20px;
      height: 20px;
      background: white;
      border-radius: 50%;
      cursor: pointer;
      border: none;
      box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
    }
    .action-buttons {
      display: flex;
      gap: 16px;
      align-items: center;
    }
    .camera-btn {
      width: 64px;
      height: 64px;
      background: white;
      border: 4px solid rgba(128, 128, 128, 0.8);
      border-radius: 50%;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
      position: relative;
    }
    .camera-icon {
      width: 24px;
      height: 24px;
      background: rgba(128, 128, 128, 0.8);
      border-radius: 3px;
      position: relative;
    }
    .camera-icon::before {
      content: '';
      position: absolute;
      top: -4px;
      left: 50%;
      transform: translateX(-50%);
      width: 8px;
      height: 4px;
      background: rgba(128, 128, 128, 0.8);
      border-radius: 2px 2px 0 0;
    }
    .reset-btn {
      background: rgba(128, 128, 128, 0.8);
      color: white;
      border: none;
      padding: 12px 20px;
      border-radius: 20px;
      font-size: 14px;
      font-weight: 500;
      cursor: pointer;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
      backdrop-filter: blur(10px);
    }
    .reset-icon {
      font-size: 18px;
    }
    
    /* AR Button */
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
      transition: transform 0.2s;
    }
    .ar-button:hover {
      transform: translateX(-50%) scale(1.05);
    }
    .ar-button:active {
      transform: translateX(-50%) scale(0.95);
    }
    .ar-button:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
    
    /* Hidden when AR active */
    .ar-active .ar-button,
    .ar-active .drag-hint {
      display: none;
    }
  </style>
</head>
<body>
  <div id="ar-container" class="">
    <model-viewer
      id="ar-model"
      src="${widget.modelUrl}"
      alt="${widget.altText ?? widget.productName ?? '3D Model'}"
      ar
      ar-modes="webxr scene-viewer quick-look"
      ar-scale="0.5"
      ar-placement="floor"
      scale="0.5 0.5 0.5"
      camera-controls
      interaction-policy="allow-when-focused"
      shadow-intensity="1.5"
      exposure="1.2"
      environment-image="neutral"
      reveal="auto"
      loading="auto"
      style="--ar-button-display: none;"
    >
      <div slot="poster" style="width: 100%; height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);">
        <div style="text-align: center; color: white; padding: 20px;">
          <div style="font-size: 64px; margin-bottom: 20px;">📱</div>
          <div style="font-size: 24px; font-weight: 600; margin-bottom: 12px;">${widget.productName ?? '3D Model'}</div>
          <div style="font-size: 14px; opacity: 0.8; margin-bottom: 24px;">Tap the button below to view in AR</div>
        </div>
      </div>
    </model-viewer>
    
    <!-- Top Left Controls -->
    <div class="top-controls">
      <button class="control-btn info-btn" id="info-btn" onclick="toggleInfo()" title="Info">i</button>
      <button class="control-btn" id="close-btn" onclick="goBack()" title="Close">×</button>
    </div>
    
    <!-- Right Side Scale Control -->
    <div class="scale-control" id="scale-control" style="display: none;">
      <div class="scale-labels">
        <span>+</span>
      </div>
      <input type="range" 
             id="scale-slider" 
             class="scale-slider" 
             min="0.1" 
             max="2" 
             step="0.1" 
             value="0.5"
             orient="vertical"
             oninput="updateScale(this.value)">
      <div class="scale-labels">
        <span>-</span>
      </div>
    </div>
    
    <!-- Bottom Controls -->
    <div class="bottom-controls" id="bottom-controls" style="display: none;">
      <!-- Drag Hint -->
      <div class="drag-hint" id="drag-hint">
        <span>👆</span>
        <span>Drag to move</span>
        <span>↔</span>
      </div>
      
      <!-- Rotate Control -->
      <div class="rotate-control">
        <div class="rotate-label">Rotate</div>
        <div class="rotate-slider-container">
          <span class="rotate-value">0°</span>
          <input type="range" 
                 id="rotate-slider" 
                 class="rotate-slider" 
                 min="0" 
                 max="360" 
                 value="0"
                 oninput="updateRotation(this.value)">
          <span class="rotate-value">360°</span>
        </div>
      </div>
      
      <!-- Action Buttons -->
      <div class="action-buttons">
        <button class="camera-btn" id="camera-btn" onclick="captureScreenshot()" title="Take Screenshot">
          <div class="camera-icon"></div>
        </button>
        <button class="reset-btn" id="reset-btn" onclick="resetView()" title="Reset View">
          <span class="reset-icon">↻</span>
          <span>Reset view</span>
        </button>
      </div>
    </div>
    
    <!-- AR Button -->
    <button class="ar-button" id="ar-button" onclick="enterAR()">
      <span>📱</span>
      <span>View in AR</span>
    </button>
  </div>

  <script type="module">
    const modelViewer = document.querySelector('#ar-model');
    const arButton = document.getElementById('ar-button');
    const container = document.getElementById('ar-container');
    const scaleControl = document.getElementById('scale-control');
    const bottomControls = document.getElementById('bottom-controls');
    const dragHint = document.getElementById('drag-hint');
    const scaleSlider = document.getElementById('scale-slider');
    const rotateSlider = document.getElementById('rotate-slider');
    const rotateValue = rotateSlider.previousElementSibling;
    
    let isARActive = false;
    let currentScale = 0.5;
    let currentRotation = 0;
    let isDragging = false;
    let dragStartX = 0;
    let dragStartY = 0;
    let modelX = 0;
    let modelY = 0;

    // Enter AR mode
    async function enterAR() {
      try {
        if (!modelViewer.activateAR) {
          showError('AR is not supported on this device/browser.');
          return;
        }

        arButton.disabled = true;
        arButton.innerHTML = '<span style="display: inline-block; width: 16px; height: 16px; border: 2px solid white; border-top: 2px solid transparent; border-radius: 50%; animation: spin 1s linear infinite; margin-right: 8px;"></span><span>Opening AR...</span>';

        // Activate AR
        await modelViewer.activateAR();
        
        isARActive = true;
        container.classList.add('ar-active');
        arButton.style.display = 'none';
        
        // Show controls
        scaleControl.style.display = 'flex';
        bottomControls.style.display = 'flex';
        
        // Set initial scale to prevent model being too big
        updateScale(0.5);
        
        // Hide drag hint after 3 seconds
        setTimeout(() => {
          if (dragHint) dragHint.style.display = 'none';
        }, 3000);
        
      } catch (error) {
        console.error('AR activation error:', error);
        showError('Failed to open AR. Please try again.');
        arButton.disabled = false;
        arButton.innerHTML = '<span>📱</span><span>View in AR</span>';
      }
    }

    // Update model scale
    function updateScale(value) {
      currentScale = parseFloat(value);
      
      if (modelViewer) {
        // Update scale attribute (format: "x y z")
        const scaleString = currentScale + ' ' + currentScale + ' ' + currentScale;
        modelViewer.setAttribute('scale', scaleString);
        
        // Update ar-scale for AR mode
        modelViewer.setAttribute('ar-scale', currentScale.toString());
        
        // Force update if in AR mode
        if (isARActive && modelViewer.arSession) {
          // Trigger a refresh by updating the model
          const currentSrc = modelViewer.getAttribute('src');
          modelViewer.setAttribute('src', '');
          setTimeout(() => {
            modelViewer.setAttribute('src', currentSrc);
          }, 100);
        }
        
        console.log('Scale updated to:', currentScale, '(', (currentScale * 100).toFixed(0) + '%)');
      }
    }

    // Update model rotation
    function updateRotation(value) {
      currentRotation = parseInt(value);
      if (rotateValue) {
        rotateValue.textContent = currentRotation + '°';
      }
      
      // Update model-viewer rotation
      if (modelViewer) {
        // Convert degrees to radians for Y-axis rotation
        // model-viewer uses degrees in rotation attribute
        const rotationString = \`0 \${currentRotation} 0\`;
        modelViewer.setAttribute('rotation', rotationString);
        
        console.log('Rotation updated to:', currentRotation + '°');
      }
    }

    // Setup drag functionality for AR model
    function setupDrag() {
      if (!modelViewer) return;
      
      // Listen for AR model placement events
      modelViewer.addEventListener('ar-status', (event) => {
        if (event.detail.status === 'session-started') {
          // Model is placed, enable drag
          enableModelDrag();
        }
      });
    }

    function enableModelDrag() {
      // In WebXR, dragging is handled by model-viewer's built-in interaction
      // We can enhance it by listening to model interactions
      if (modelViewer) {
        // Enable interaction policy for dragging
        modelViewer.setAttribute('interaction-policy', 'allow-when-focused');
        
        // Add visual feedback
        modelViewer.style.cursor = 'grab';
        modelViewer.addEventListener('mousedown', () => {
          modelViewer.style.cursor = 'grabbing';
        });
        modelViewer.addEventListener('mouseup', () => {
          modelViewer.style.cursor = 'grab';
        });
      }
    }

    // Reset view
    function resetView() {
      currentScale = 0.5;
      currentRotation = 0;
      modelX = 0;
      modelY = 0;
      
      scaleSlider.value = currentScale;
      rotateSlider.value = currentRotation;
      rotateValue.textContent = '0°';
      
      updateScale(currentScale);
      updateRotation(currentRotation);
      
      if (modelViewer && modelViewer.resetCamera) {
        modelViewer.resetCamera();
      }
    }

    // Capture screenshot
    async function captureScreenshot() {
      try {
        if (modelViewer && modelViewer.toBlob) {
          const blob = await modelViewer.toBlob({ idealAspectRatio: 1 });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = 'ar-screenshot-' + Date.now() + '.png';
          document.body.appendChild(a);
          a.click();
          document.body.removeChild(a);
          URL.revokeObjectURL(url);
          showNotification('Screenshot saved!');
        }
      } catch (error) {
        console.error('Screenshot error:', error);
        showError('Failed to capture screenshot');
      }
    }

    // Toggle info
    function toggleInfo() {
      const infoDialog = document.createElement('div');
      infoDialog.style.cssText = \`
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.7);
        z-index: 10000;
        display: flex;
        align-items: center;
        justify-content: center;
      \`;
      
      infoDialog.innerHTML = \`
        <div style="
          background: white;
          border-radius: 16px;
          padding: 24px;
          max-width: 400px;
          width: 90%;
        ">
          <h2 style="margin: 0 0 16px 0; font-size: 20px; font-weight: bold;">AR Controls</h2>
          <div style="display: flex; flex-direction: column; gap: 12px; color: #333;">
            <div>• <strong>Drag</strong> the model to move it on the surface</div>
            <div>• Use the <strong>scale slider</strong> (right side) to resize the model</div>
            <div>• Use <strong>rotate slider</strong> (bottom) to rotate 0°-360°</div>
            <div>• Tap <strong>camera</strong> button to take a screenshot</div>
            <div>• Tap <strong>reset</strong> to restore default size and position</div>
            <div>• Model is placed on the floor automatically</div>
          </div>
          <button onclick="this.closest('div[style*=\\'position: fixed\\']').remove()" style="
            margin-top: 20px;
            background: rgba(220, 38, 38, 1);
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            width: 100%;
          ">Got it</button>
        </div>
      \`;
      
      document.body.appendChild(infoDialog);
      infoDialog.addEventListener('click', (e) => {
        if (e.target === infoDialog) {
          infoDialog.remove();
        }
      });
    }

    // Handle AR status changes
    modelViewer.addEventListener('ar-status', (event) => {
      console.log('AR status:', event.detail.status);
      
      if (event.detail.status === 'session-started') {
        isARActive = true;
        container.classList.add('ar-active');
        arButton.style.display = 'none';
        scaleControl.style.display = 'flex';
        bottomControls.style.display = 'flex';
        
        // Apply initial scale and rotation when AR starts
        setTimeout(() => {
          updateScale(currentScale);
          updateRotation(currentRotation);
        }, 500);
        
        setupDrag();
      } else if (event.detail.status === 'session-ended' || event.detail.status === 'not-presenting') {
        isARActive = false;
        container.classList.remove('ar-active');
        arButton.style.display = 'flex';
        arButton.disabled = false;
        arButton.innerHTML = '<span>📱</span><span>View in AR</span>';
        scaleControl.style.display = 'none';
        bottomControls.style.display = 'none';
      }
    });

    // Go back navigation
    function goBack() {
      if (isARActive && modelViewer.exitAR) {
        modelViewer.exitAR();
      }
      if (window.parent) {
        window.parent.postMessage({ type: 'ar_back' }, '*');
      }
    }

    // Show notification
    function showNotification(message) {
      const notification = document.createElement('div');
      notification.style.cssText = \`
        position: fixed;
        top: 20px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(34, 197, 94, 0.95);
        color: white;
        padding: 12px 24px;
        border-radius: 20px;
        font-size: 14px;
        z-index: 10000;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      \`;
      notification.textContent = message;
      document.body.appendChild(notification);
      setTimeout(() => notification.remove(), 2000);
    }

    // Show error
    function showError(message) {
      const error = document.createElement('div');
      error.style.cssText = \`
        position: fixed;
        top: 20px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(239, 68, 68, 0.95);
        color: white;
        padding: 12px 24px;
        border-radius: 20px;
        font-size: 14px;
        z-index: 10000;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      \`;
      error.textContent = message;
      document.body.appendChild(error);
      setTimeout(() => error.remove(), 5000);
    }

    // Add spin animation
    const style = document.createElement('style');
    style.textContent = \`
      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
    \`;
    document.head.appendChild(style);
  </script>
</body>
</html>
''';
  }
}
