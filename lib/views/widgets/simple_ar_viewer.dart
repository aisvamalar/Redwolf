import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'simple_ar_viewer_web_stub.dart'
    if (dart.library.html) 'simple_ar_viewer_web.dart'
    as web_utils;

/// Interactive AR Viewer - Working version from this morning
/// Supports camera AR, tap-to-place, drag, and screenshot capture
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
        // Call callback if provided, otherwise pop navigation
        if (widget.onBackPressed != null) {
          widget.onBackPressed!();
        } else {
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
    iframe.allow = 'camera; microphone; xr-spatial-tracking';
    iframe.srcdoc = _createArHtml();

    web_utils.WebUtils.registerViewFactory(_iframeKey!, (int viewId) => iframe);
  }

  String _createArHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <title>Interactive AR Viewer</title>
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
    }
    model-viewer {
      width: 100%;
      height: 100%;
      background-color: transparent;
    }
    
    #ar-models-container {
      overflow: visible !important;
    }
    
    #ar-models-container > div {
      pointer-events: auto !important;
    }
    
    #ar-models-container model-viewer {
      display: block !important;
      visibility: visible !important;
      opacity: 1 !important;
    }
    .controls-panel {
      position: absolute;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      display: flex;
      gap: 12px;
      z-index: 100;
      flex-wrap: wrap;
      justify-content: center;
    }
    .control-button {
      background: rgba(220, 38, 38, 0.95);
      color: white;
      border: none;
      padding: 14px 20px;
      border-radius: 30px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      backdrop-filter: blur(10px);
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      transition: all 0.3s ease;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .control-button:hover {
      background: rgba(220, 38, 38, 1);
      transform: translateY(-2px);
      box-shadow: 0 6px 16px rgba(0,0,0,0.4);
    }
    .control-button:active {
      transform: translateY(0);
    }
    .control-button.secondary {
      background: rgba(0, 0, 0, 0.7);
    }
    .control-button.secondary:hover {
      background: rgba(0, 0, 0, 0.9);
    }
    .info-panel {
      position: absolute;
      top: 20px;
      left: 20px;
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 16px 20px;
      border-radius: 12px;
      backdrop-filter: blur(10px);
      z-index: 100;
      max-width: 320px;
      font-size: 13px;
      line-height: 1.6;
    }
    .info-panel h3 {
      margin-bottom: 10px;
      font-size: 16px;
      color: #DC2626;
    }
    .info-panel p {
      margin: 6px 0;
      opacity: 0.9;
    }
    .gesture-hint {
      display: flex;
      align-items: center;
      gap: 8px;
      margin: 4px 0;
    }
    .gesture-icon {
      font-size: 18px;
    }
  </style>
</head>
<body>
  <div id="ar-container">
    <!-- Camera feed container -->
    <video id="camera-feed" autoplay playsinline style="width: 100%; height: 100%; object-fit: cover; display: none;"></video>
    
    <!-- Canvas for AR overlay (crosshair only) -->
    <canvas id="ar-canvas" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; display: none; z-index: 5; pointer-events: auto;"></canvas>
    
    <!-- Container for placed 3D models -->
    <div id="ar-models-container" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 20; display: none;"></div>
    
    <!-- Model viewer (shown in 3D view, hidden during AR) -->
    <model-viewer
      id="ar-model"
      src="${widget.modelUrl}"
      alt="${widget.altText ?? widget.productName ?? 'Digital Standee 4.5 feet'}"
      ar
      ar-modes="webxr scene-viewer quick-look"
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
      style="width: 100%; height: 100%; display: block; background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);"
      xr-environment
      touch-action="pan-y"
      ar-tap-to-place
      reveal="auto"
      loading="auto"
    >
      <!-- Poster is kept in DOM but hidden by default so we skip the
           "Loading 3D Model" splash and go straight into AR view. -->
      <div
        slot="poster"
        id="model-poster"
        style="display: none; width: 100%; height: 100%;"
      ></div>
    </model-viewer>
    
    <!-- AR Mode Controls (shown during camera AR) -->
    <div id="ar-mode-controls" style="display: none;">
      <!-- Top Left Controls -->
      <div style="position: absolute; top: 20px; left: 20px; z-index: 100; display: flex; gap: 12px;">
        <!-- Info Button styled like the circular back arrow -->
        <button onclick="toggleInfo()" id="info-btn" style="
          background: rgba(0, 0, 0, 0.7);
          color: white;
          border: 3px solid rgba(255, 255, 255, 0.8);
          width: 56px;
          height: 56px;
          border-radius: 50%;
          font-size: 22px;
          font-weight: 700;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
          backdrop-filter: blur(10px);
        ">
          i
        </button>
      </div>
      
      <!-- Top Right Controls -->
      <div style="position: absolute; top: 20px; right: 20px; z-index: 100; display: flex; flex-direction: column; gap: 12px;">
        <!-- Close Button -->
        <button onclick="goBack()" style="
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
        ">
          ×
        </button>
        
        <!-- Zoom In Button -->
        <button onclick="zoomIn()" style="
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
        ">
          +
        </button>
        
        <!-- Zoom Out Button -->
        <button onclick="zoomOut()" style="
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
        ">
          −
        </button>
      </div>
      
      
      <!-- Bottom Rotation Control -->
      <div style="
        position: absolute;
        bottom: 120px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(0, 0, 0, 0.8);
        padding: 16px 24px;
        border-radius: 20px;
        z-index: 30;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 12px;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
        backdrop-filter: blur(10px);
      ">
        <span style="color: white; font-size: 14px; font-weight: 500;">Rotate</span>
        <div style="display: flex; align-items: center; gap: 12px;">
          <span style="color: white; font-size: 12px;">0°</span>
          <input type="range" id="rotation-slider" min="0" max="360" value="0" 
                 onInput="rotateModel(this.value)"
                 style="
                   width: 200px;
                   height: 6px;
                   background: rgba(255, 255, 255, 0.3);
                   border-radius: 3px;
                   outline: none;
                   -webkit-appearance: none;
                 ">
          <span style="color: white; font-size: 12px;">360°</span>
        </div>
      </div>
      
      <!-- Bottom Controls -->
      <div style="
        position: absolute;
        bottom: 30px;
        left: 50%;
        transform: translateX(-50%);
        display: flex;
        gap: 24px;
        z-index: 30;
        align-items: center;
      ">
        <!-- Camera Button -->
        <button onclick="captureScreenshot()" style="
          background: white;
          border: 4px solid rgba(128, 128, 128, 0.8);
          width: 64px;
          height: 64px;
          border-radius: 50%;
          cursor: pointer;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
          position: relative;
        ">
          <div style="
            width: 24px;
            height: 24px;
            background: rgba(128, 128, 128, 0.8);
            border-radius: 3px;
            position: relative;
          ">
            <div style="
              position: absolute;
              top: -4px;
              left: 50%;
              transform: translateX(-50%);
              width: 8px;
              height: 4px;
              background: rgba(128, 128, 128, 0.8);
              border-radius: 2px 2px 0 0;
            "></div>
          </div>
        </button>
        
        <!-- Reset View Button -->
        <button onclick="resetView()" style="
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
        ">
          <span style="font-size: 18px;">↻</span>
          <span>Reset view</span>
        </button>
      </div>
      
      <!-- Info Panel (hidden by default) -->
      <div id="info-panel" style="
        position: absolute;
        top: 80px;
        left: 20px;
        background: rgba(0, 0, 0, 0.9);
        color: white;
        padding: 16px;
        border-radius: 12px;
        max-width: 280px;
        z-index: 90;
        display: none;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
        backdrop-filter: blur(10px);
      ">
        <h3 style="margin: 0 0 12px 0; font-size: 16px; font-weight: 600;">${widget.productName ?? 'AR Product View'}</h3>
        <div style="font-size: 14px; line-height: 1.4; opacity: 0.9;">
          <p style="margin: 0 0 8px 0;">• Tap on surface to place the model</p>
          <p style="margin: 0 0 8px 0;">• Model stays locked to world position when camera moves</p>
          <p style="margin: 0 0 8px 0;">• Drag model to reposition it</p>
          <p style="margin: 0 0 8px 0;">• Use rotation slider to rotate</p>
          <p style="margin: 0 0 8px 0;">• Zoom in/out with +/- buttons</p>
          <p style="margin: 0;">• Capture screenshots with camera button</p>
        </div>
      </div>
    </div>

    <!-- Default Controls (previous 3D loading UI) are now hidden so we
         navigate directly into the AR camera experience. -->
    <div class="controls-panel" id="default-controls" style="display: none;"></div>
    
    <style>
      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
      
      /* Rotation Slider Styling */
      #rotation-slider {
        -webkit-appearance: none;
        appearance: none;
        background: rgba(255, 255, 255, 0.3);
        border-radius: 3px;
        height: 6px;
        outline: none;
      }
      
      #rotation-slider::-webkit-slider-thumb {
        -webkit-appearance: none;
        appearance: none;
        width: 20px;
        height: 20px;
        background: white;
        border-radius: 50%;
        cursor: pointer;
        box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
      }
      
      #rotation-slider::-moz-range-thumb {
        width: 20px;
        height: 20px;
        background: white;
        border-radius: 50%;
        cursor: pointer;
        border: none;
        box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
      }
      
      /* AR Control Buttons Hover Effects */
      button:hover {
        transform: scale(1.05);
        transition: transform 0.2s ease;
      }
      
      button:active {
        transform: scale(0.95);
      }
    </style>
  </div>

  <script type="module">
    const modelViewer = document.querySelector('#ar-model');
    const cameraFeed = document.querySelector('#camera-feed');
    const arCanvas = document.querySelector('#ar-canvas');
    let isARActive = false;
    let arSession = null;
    let cameraStream = null;
    let modelScale = 1;
    let modelRotation = { x: 0, y: 0, z: 0 };
    let modelPosition = { x: 0, y: 0, z: 0 };
    let placedModels = [];
    let isDraggingModel = false; // Track if any model is being dragged
    
    // World-locking variables
    let deviceOrientation = { alpha: 0, beta: 0, gamma: 0 };
    let initialOrientation = null;
    let orientationTrackingActive = false;
    let lastCameraPosition = { x: 0, y: 0 };
    let worldLockedModels = new Map(); // Map of modelId to world position
    
    // Analytics tracking variables
    let arSessionStartTime = Date.now();
    let screenshotCount = 0;
    let actionCount = 0;

    // Start camera feed
    async function startCameraFeed() {
      try {
        // Check if camera is available
        if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
          throw new Error('Camera API not supported');
        }
        
        showNotification('Requesting camera access...');
        
        cameraStream = await navigator.mediaDevices.getUserMedia({ 
          video: { 
            facingMode: 'environment',
            width: { ideal: 1280 },
            height: { ideal: 720 }
          } 
        });
        
        cameraFeed.srcObject = cameraStream;
        
        // Wait for video to be ready
        return new Promise((resolve) => {
          cameraFeed.onloadedmetadata = () => {
            cameraFeed.style.display = 'block';
            modelViewer.style.display = 'none';
            arCanvas.style.display = 'block';
            
            console.log('Camera feed started');
            showNotification('Camera ready! Tap on surfaces to place the 3D model');
            resolve(true);
          };
          
          cameraFeed.onerror = () => {
            console.error('Video element error');
            showNotification('Failed to initialize camera feed');
            resolve(false);
          };
        });
        
      } catch (error) {
        console.error('Camera access denied:', error);
        
        let errorMessage = 'Camera access is required for AR';
        if (error.name === 'NotAllowedError') {
          errorMessage = 'Camera permission denied. Please allow camera access and refresh.';
        } else if (error.name === 'NotFoundError') {
          errorMessage = 'No camera found. Please ensure your device has a camera.';
        } else if (error.name === 'NotSupportedError') {
          errorMessage = 'Camera not supported on this device/browser.';
        }
        
        showNotification(errorMessage);
        return false;
      }
    }

    // Stop camera feed
    function stopCameraFeed() {
      if (cameraStream) {
        cameraStream.getTracks().forEach(track => track.stop());
        cameraStream = null;
      }
      cameraFeed.style.display = 'none';
      arCanvas.style.display = 'none';
      modelViewer.style.display = 'block';
      
      // Hide models container
      const modelsContainer = document.getElementById('ar-models-container');
      if (modelsContainer) {
        modelsContainer.style.display = 'none';
      }
      
      // Clear placed models
      placedModels.forEach(model => {
        if (model.element && model.element.parentNode) {
          model.element.parentNode.removeChild(model.element);
        }
      });
      placedModels = [];
      const ctx = arCanvas.getContext('2d');
      if (ctx) {
        ctx.clearRect(0, 0, arCanvas.width, arCanvas.height);
      }
    }
    
    // Setup AR canvas
    function setupARCanvas() {
      arCanvas.width = window.innerWidth;
      arCanvas.height = window.innerHeight;
      const ctx = arCanvas.getContext('2d');
      ctx.clearRect(0, 0, arCanvas.width, arCanvas.height);
      drawCrosshair(ctx);
    }
    
    // Draw crosshair
    function drawCrosshair(ctx) {
      const centerX = arCanvas.width / 2;
      const centerY = arCanvas.height / 2;
      
      ctx.strokeStyle = '#DC2626';
      ctx.lineWidth = 3;
      ctx.shadowColor = 'rgba(0,0,0,0.5)';
      ctx.shadowBlur = 5;
      ctx.beginPath();
      
      ctx.moveTo(centerX - 25, centerY);
      ctx.lineTo(centerX + 25, centerY);
      ctx.moveTo(centerX, centerY - 25);
      ctx.lineTo(centerX, centerY + 25);
      ctx.arc(centerX, centerY, 4, 0, 2 * Math.PI);
      
      ctx.stroke();
      ctx.shadowBlur = 0;
    }
    
    // Setup tap to place
    function setupTapToPlace() {
      console.log('Setting up tap to place handler');
      
      // Remove existing listener if any
      arCanvas.removeEventListener('click', handleCanvasClick);
      
      // Add click handler
      arCanvas.addEventListener('click', handleCanvasClick);
      
      function handleCanvasClick(event) {
        // Don't place model if we just finished dragging
        if (isDraggingModel) {
          console.log('Drag just ended, ignoring canvas click');
          return;
        }
        
        console.log('Canvas clicked at:', event.clientX, event.clientY);
        
        // Check if click is on an existing model
        const modelsContainer = document.getElementById('ar-models-container');
        if (modelsContainer) {
          const elementsBelow = document.elementsFromPoint(event.clientX, event.clientY);
          const clickedOnModel = elementsBelow.some(el => 
            el.closest && el.closest('#ar-models-container > div')
          );
          if (clickedOnModel) {
            console.log('Clicked on existing model, skipping placement');
            return; // Don't place new model if clicking on existing one
          }
        }
        
        const rect = arCanvas.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;
        console.log('Placing model at canvas coordinates:', x, y);
        placeModelAt(x, y);
      }
    }
    
    // Place GLB model at coordinates
    function placeModelAt(x, y) {
      const ctx = arCanvas.getContext('2d');
      drawCrosshair(ctx);
      
      // Get the models container
      let modelsContainer = document.getElementById('ar-models-container');
      if (!modelsContainer) {
        modelsContainer = document.createElement('div');
        modelsContainer.id = 'ar-models-container';
        modelsContainer.style.cssText = 'position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 20;';
        document.body.appendChild(modelsContainer);
      }
      
      // Create a new model-viewer element for the GLB model
      const modelId = 'ar-model-' + Date.now();
      const modelContainer = document.createElement('div');
      modelContainer.id = modelId;
      modelContainer.style.cssText = \`
        position: absolute;
        left: \${x}px;
        top: \${y}px;
        width: 250px;
        height: 400px;
        transform: translate(-50%, -50%);
        pointer-events: auto;
        z-index: 21;
      \`;
      
      // Create model-viewer element
      const modelViewerElement = document.createElement('model-viewer');
      modelViewerElement.setAttribute('src', '${widget.modelUrl}');
      modelViewerElement.setAttribute('alt', '${widget.altText ?? widget.productName ?? '3D Model'}');
      // Disable camera controls and interaction to allow dragging
      modelViewerElement.setAttribute('interaction-policy', 'none');
      modelViewerElement.setAttribute('shadow-intensity', '1');
      modelViewerElement.setAttribute('exposure', '1');
      modelViewerElement.setAttribute('environment-image', 'neutral');
      // Auto-rotate removed - placed models should stay fixed in position
      modelViewerElement.setAttribute('ar', '');
      // Disable pointer events on model-viewer so container handles drag
      modelViewerElement.style.cssText = 'width: 100%; height: 100%; background: transparent; position: absolute; top: 0; left: 0; pointer-events: none;';
      
      // Add label
      const label = document.createElement('div');
      label.textContent = '${widget.productName ?? widget.altText ?? '3D Model'}';
      label.style.cssText = \`
        position: absolute;
        bottom: -30px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(0, 0, 0, 0.9);
        color: white;
        padding: 6px 16px;
        border-radius: 16px;
        font-size: 13px;
        font-weight: 600;
        white-space: nowrap;
        pointer-events: none;
        z-index: 22;
        box-shadow: 0 2px 8px rgba(0,0,0,0.3);
      \`;
      
      modelContainer.appendChild(modelViewerElement);
      modelContainer.appendChild(label);
      modelsContainer.appendChild(modelContainer);
      
      console.log('Model container created and added to DOM');
      
      // Wait for model-viewer to be ready, then make draggable
      setTimeout(() => {
        makeModelDraggable(modelContainer, modelId);
        
        // Handle model load
        modelViewerElement.addEventListener('load', () => {
          console.log('3D Model loaded:', modelId);
          showNotification('3D Model loaded! Drag to move');
        });
        
        // Handle errors
        modelViewerElement.addEventListener('error', (e) => {
          console.error('Model load error:', e.detail);
          showNotification('Failed to load model');
        });
        
        console.log('Placing model at:', x, y, 'URL:', '${widget.modelUrl}');
      }, 100);
      
      placedModels.push({ 
        id: modelId, 
        element: modelContainer, 
        modelViewer: modelViewerElement,
        x: x, 
        y: y, 
        scale: modelScale 
      });
      
      showNotification('Placing 3D Model...');
      
      // Store world position for this model
      // Use the placement coordinates as the world anchor point
      worldLockedModels.set(modelId, {
        worldX: x,
        worldY: y,
        placedAt: Date.now()
      });
      
      // Initialize orientation tracking if not already done
      if (!initialOrientation && deviceOrientation.alpha !== undefined) {
        initialOrientation = { ...deviceOrientation };
      }
    }
    
    // Start world-locking: Track device movement to keep models in world position
    function startWorldLocking() {
      if (orientationTrackingActive) return;
      orientationTrackingActive = true;
      
      // Request device orientation permission (iOS 13+)
      if (typeof DeviceOrientationEvent !== 'undefined' && 
          typeof DeviceOrientationEvent.requestPermission === 'function') {
        DeviceOrientationEvent.requestPermission()
          .then(response => {
            if (response === 'granted') {
              setupOrientationTracking();
            }
          })
          .catch(console.error);
      } else {
        setupOrientationTracking();
      }
      
      // Also track device motion for better accuracy
      if (typeof DeviceMotionEvent !== 'undefined' && 
          typeof DeviceMotionEvent.requestPermission === 'function') {
        DeviceMotionEvent.requestPermission()
          .then(response => {
            if (response === 'granted') {
              setupMotionTracking();
            }
          })
          .catch(console.error);
      } else {
        setupMotionTracking();
      }
    }
    
    function setupOrientationTracking() {
      window.addEventListener('deviceorientation', handleOrientationChange);
      
      // Store initial orientation
      if (!initialOrientation) {
        initialOrientation = { alpha: 0, beta: 0, gamma: 0 };
      }
    }
    
    function setupMotionTracking() {
      window.addEventListener('devicemotion', handleMotionChange);
    }
    
    function handleOrientationChange(event) {
      if (!isARActive) return;
      
      // Store initial orientation on first reading
      if (!initialOrientation) {
        initialOrientation = {
          alpha: event.alpha || 0,
          beta: event.beta || 0,
          gamma: event.gamma || 0
        };
      }
      
      deviceOrientation = {
        alpha: event.alpha || 0, // Z-axis rotation (compass)
        beta: event.beta || 0,   // X-axis rotation (front-back tilt)
        gamma: event.gamma || 0  // Y-axis rotation (left-right tilt)
      };
      
      // Update model positions based on orientation change
      updateWorldLockedModels();
    }
    
    function handleMotionChange(event) {
      if (!isARActive) return;
      
      // Use acceleration to detect camera movement
      if (event.accelerationIncludingGravity) {
        const accel = event.accelerationIncludingGravity;
        // Calculate movement delta
        const deltaX = accel.x ? accel.x * 0.1 : 0;
        const deltaY = accel.y ? accel.y * 0.1 : 0;
        
        // Update camera position estimate
        lastCameraPosition.x += deltaX;
        lastCameraPosition.y += deltaY;
        
        // Update model positions
        updateWorldLockedModels();
      }
    }
    
    function updateWorldLockedModels() {
      if (worldLockedModels.size === 0 || !isARActive) return;
      
      // Use requestAnimationFrame for smooth updates
      requestAnimationFrame(() => {
        if (!isARActive) return;
        
        // Calculate transform based on device orientation
        const betaRad = (deviceOrientation.beta || 0) * Math.PI / 180;
        const gammaRad = (deviceOrientation.gamma || 0) * Math.PI / 180;
        
        // Calculate offset based on orientation change from initial
        let offsetX = 0;
        let offsetY = 0;
        
        if (initialOrientation) {
          const deltaBeta = (deviceOrientation.beta || 0) - (initialOrientation.beta || 0);
          const deltaGamma = (deviceOrientation.gamma || 0) - (initialOrientation.gamma || 0);
          
          // Convert orientation change to screen offset
          // Sensitivity multipliers - adjust these to fine-tune tracking
          const sensitivity = 3.0; // Higher = more responsive to movement
          offsetX = deltaGamma * sensitivity; // Left-right movement
          offsetY = deltaBeta * sensitivity;  // Front-back movement
        }
        
        // Also account for camera position changes
        offsetX -= lastCameraPosition.x * 0.5;
        offsetY -= lastCameraPosition.y * 0.5;
        
        // Update each world-locked model
        worldLockedModels.forEach((worldData, modelId) => {
          const model = placedModels.find(m => m.id === modelId);
          if (!model || !model.element) return;
          
          // Calculate new position to maintain world position
          // Invert the camera movement to keep model in same world spot
          const newX = worldData.worldX - offsetX;
          const newY = worldData.worldY - offsetY;
          
          // Constrain to screen bounds
          const maxX = window.innerWidth - model.element.offsetWidth / 2;
          const maxY = window.innerHeight - model.element.offsetHeight / 2;
          const minX = model.element.offsetWidth / 2;
          const minY = model.element.offsetHeight / 2;
          
          const constrainedX = Math.max(minX, Math.min(maxX, newX));
          const constrainedY = Math.max(minY, Math.min(maxY, newY));
          
          // Only update if not currently being dragged
          if (!isDraggingModel) {
            model.element.style.left = constrainedX + 'px';
            model.element.style.top = constrainedY + 'px';
            
            // Update stored position
            model.x = constrainedX;
            model.y = constrainedY;
          }
        });
      });
    }
    
    // Stop world-locking when exiting AR
    function stopWorldLocking() {
      orientationTrackingActive = false;
      window.removeEventListener('deviceorientation', handleOrientationChange);
      window.removeEventListener('devicemotion', handleMotionChange);
      worldLockedModels.clear();
      initialOrientation = null;
    }
    
    // Make model draggable (supports both mouse and touch)
    function makeModelDraggable(element, modelId) {
      let isDragging = false;
      let startX, startY, initialX, initialY;
      
      function startDrag(e) {
        // Don't start drag if clicking on canvas (for placing new models)
        if (e.target === arCanvas || e.target.closest('#ar-canvas')) {
          return;
        }
        
        isDragging = true;
        isDraggingModel = true; // Set global flag
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;
        startX = clientX;
        startY = clientY;
        const rect = element.getBoundingClientRect();
        initialX = rect.left + rect.width / 2;
        initialY = rect.top + rect.height / 2;
        element.style.cursor = 'grabbing';
        element.style.touchAction = 'none';
        // Make sure element is on top when dragging
        element.style.zIndex = '22';
        e.preventDefault();
        e.stopPropagation();
      }
      
      function drag(e) {
        if (!isDragging) return;
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;
        const deltaX = clientX - startX;
        const deltaY = clientY - startY;
        
        // Only move if there's significant movement (prevents accidental drags)
        if (Math.abs(deltaX) < 5 && Math.abs(deltaY) < 5) {
          return;
        }
        
        const newX = initialX + deltaX;
        const newY = initialY + deltaY;
        
        // Constrain to screen bounds
        const maxX = window.innerWidth - element.offsetWidth / 2;
        const maxY = window.innerHeight - element.offsetHeight / 2;
        const minX = element.offsetWidth / 2;
        const minY = element.offsetHeight / 2;
        
        const constrainedX = Math.max(minX, Math.min(maxX, newX));
        const constrainedY = Math.max(minY, Math.min(maxY, newY));
        
        element.style.left = constrainedX + 'px';
        element.style.top = constrainedY + 'px';
        
        e.preventDefault();
        e.stopPropagation();
      }
      
      function endDrag(e) {
        if (isDragging) {
          isDragging = false;
          element.style.cursor = 'grab';
          element.style.touchAction = 'auto';
          element.style.zIndex = '21';
          
          // Update stored position
          const model = placedModels.find(m => m.id === modelId);
          if (model) {
            const rect = element.getBoundingClientRect();
            const newX = rect.left + rect.width / 2;
            const newY = rect.top + rect.height / 2;
            model.x = newX;
            model.y = newY;
            
            // Update world-locked position anchor to new location
            if (worldLockedModels.has(modelId)) {
              worldLockedModels.set(modelId, {
                worldX: newX,
                worldY: newY,
                placedAt: Date.now()
              });
            }
          }
          
          // Provide haptic feedback on mobile
          if (navigator.vibrate) {
            navigator.vibrate(50);
          }
          
          if (e) {
            e.preventDefault();
            e.stopPropagation();
          }
          
          // Reset global drag flag after a short delay to prevent canvas click
          setTimeout(() => {
            isDraggingModel = false;
          }, 100);
        }
      }
      
      // Mouse events
      element.addEventListener('mousedown', startDrag, { passive: false });
      document.addEventListener('mousemove', drag, { passive: false });
      document.addEventListener('mouseup', endDrag);
      
      // Touch events
      element.addEventListener('touchstart', startDrag, { passive: false });
      document.addEventListener('touchmove', drag, { passive: false });
      document.addEventListener('touchend', endDrag);
      
      // Prevent context menu on long press
      element.addEventListener('contextmenu', (e) => e.preventDefault());
      
      element.style.cursor = 'grab';
      element.style.userSelect = 'none';
      element.style.webkitUserSelect = 'none';
    }

    // Enter AR mode with camera
    async function enterAR() {
      try {
        // Track AR session start
        arSessionStartTime = Date.now();
        trackARAction('session_start', { timestamp: arSessionStartTime });
        
        // Update button to show attempting
        const arButton = document.getElementById('ar-button');
        if (arButton) {
          arButton.innerHTML = '<span style="display: inline-block; width: 16px; height: 16px; border: 2px solid white; border-top: 2px solid transparent; border-radius: 50%; animation: spin 1s linear infinite; margin-right: 8px;"></span>Requesting Camera...';
        }
        
        const success = await startCameraFeed();
        if (success) {
          isARActive = true;
          setupARCanvas();
          setupTapToPlace();
          startWorldLocking(); // Start tracking device movement for world-locking
          
          // Hide model-viewer, show camera feed
          modelViewer.style.display = 'none';
          
          // Show AR controls, hide any fallback controls or info splash if present
          const arModeControls = document.getElementById('ar-mode-controls');
          if (arModeControls) {
            arModeControls.style.display = 'block';
          }
          const defaultControls = document.getElementById('default-controls');
          if (defaultControls) {
            defaultControls.style.display = 'none';
          }
          const prepPanel = document.querySelector('.info-panel');
          if (prepPanel) {
            prepPanel.style.display = 'none';
          }
          
          // Show models container
          const modelsContainer = document.getElementById('ar-models-container');
          if (modelsContainer) {
            modelsContainer.style.display = 'block';
          }
          
          
          updateARButton();
          
          // Track successful AR start
          trackARAction('camera_permission_granted', { success: true });
        } else {
          // Camera access failed - show fallback options
          if (arButton) {
            arButton.innerHTML = 'Camera Access Denied';
            arButton.style.background = 'rgba(150, 150, 150, 0.8)';
          }
          
          // Track camera permission denied
          trackARAction('camera_permission_denied', { success: false });
          
          // Update info panel to show error
          const infoPanel = document.querySelector('.info-panel');
          if (infoPanel) {
            infoPanel.innerHTML = '<h3 style="color: #ff6b6b;">Camera Access Required</h3><p>Please allow camera access and refresh the page to use AR features.</p><button onclick="window.location.reload()" style="margin-top: 12px; padding: 8px 16px; background: #DC2626; color: white; border: none; border-radius: 4px; cursor: pointer;">Refresh Page</button>';
          }
        }
      } catch (error) {
        console.error('AR activation error:', error);
        showNotification('AR not available. Please use a compatible device/browser.');
        
        // Track error
        trackARAction('error_occurred', { error: error.message });
        
        // Update button to show error
        const arButton = document.getElementById('ar-button');
        if (arButton) {
          arButton.innerHTML = 'AR Not Available';
          arButton.style.background = 'rgba(150, 150, 150, 0.8)';
        }
      }
    }

    // Go back navigation
    function goBack() {
      // Send message to Flutter to pop navigation
      if (window.parent) {
        window.parent.postMessage({ type: 'ar_back' }, '*');
      }
    }

    // Exit AR mode with analytics
    async function exitAR() {
      // Calculate session metrics
      const sessionDuration = Date.now() - arSessionStartTime;
      const modelsPlaced = placedModels.length;
      
      // Track session end
      trackARAction('session_end', {
        session_duration_ms: sessionDuration,
        models_placed: modelsPlaced,
        screenshots_taken: screenshotCount || 0
      });
      
      // Send comprehensive session analytics
      await sendARAnalytics('ar_session_complete', {
        product_id: '${widget.productName ?? 'unknown'}',
        session_duration_ms: sessionDuration,
        models_placed: modelsPlaced,
        screenshots_taken: screenshotCount || 0,
        actions_performed: actionCount || 0,
        engagement_score: calculateEngagementScore(sessionDuration, modelsPlaced, screenshotCount || 0, actionCount || 0)
      });
      
      stopCameraFeed();
      stopWorldLocking(); // Stop world-locking tracking
      
      if (arSession) {
        await arSession.end();
        arSession = null;
      }
      
      if (modelViewer.exitAR) {
        await modelViewer.exitAR();
      }
      
      // Show model-viewer again
      modelViewer.style.display = 'block';
      
      // Show default controls, hide AR controls (if they exist).
      const arModeControls = document.getElementById('ar-mode-controls');
      if (arModeControls) {
        arModeControls.style.display = 'none';
      }
      const defaultControls = document.getElementById('default-controls');
      if (defaultControls) {
        defaultControls.style.display = 'flex';
      }
      const prepPanel = document.querySelector('.info-panel');
      if (prepPanel) {
        prepPanel.style.display = 'block';
      }
      
      isARActive = false;
      updateARButton();
      showNotification('AR Session Complete - Thank you!');
      
      // Reset counters
      screenshotCount = 0;
      actionCount = 0;
    }

    // Reset model to original position/scale
    function resetModel() {
      if (isARActive) {
        // Remove all placed model elements
        placedModels.forEach(model => {
          if (model.element && model.element.parentNode) {
            model.element.parentNode.removeChild(model.element);
          }
        });
        placedModels = [];
        worldLockedModels.clear(); // Clear world-locked positions
        const ctx = arCanvas.getContext('2d');
        if (ctx) {
          ctx.clearRect(0, 0, arCanvas.width, arCanvas.height);
          drawCrosshair(ctx);
        }
        showNotification('All models cleared');
      } else {
        if (modelViewer.resetCamera) {
          modelViewer.resetCamera();
        }
        showNotification('Camera reset');
      }
      
      modelScale = 1;
      modelRotation = { x: 0, y: 0, z: 0 };
      modelPosition = { x: 0, y: 0, z: 0 };
    }

    // Capture screenshot with all placed models
    async function captureScreenshot() {
      try {
        if (isARActive) {
          showNotification('Capturing screenshot with models...');
          
          // Create main canvas
          const canvas = document.createElement('canvas');
          const ctx = canvas.getContext('2d');
          canvas.width = window.innerWidth;
          canvas.height = window.innerHeight;
          
          // Step 1: Draw camera feed as background
          if (cameraFeed && cameraFeed.videoWidth > 0) {
            ctx.drawImage(cameraFeed, 0, 0, canvas.width, canvas.height);
          } else {
            // Black background if no camera
            ctx.fillStyle = '#000000';
            ctx.fillRect(0, 0, canvas.width, canvas.height);
          }
          
          // Step 2: Draw crosshair (optional - can be removed if not needed)
          // ctx.drawImage(arCanvas, 0, 0);
          
          // Step 3: Capture each placed model and composite them
          if (placedModels.length > 0) {
            const modelPromises = placedModels.map(async (model) => {
              if (model.modelViewer && model.element) {
                try {
                  // Get screenshot from model-viewer
                  const blob = await model.modelViewer.toBlob({ 
                    idealAspectRatio: 1,
                    mimeType: 'image/png'
                  });
                  
                  if (blob) {
                    return new Promise((resolve) => {
                      const img = new Image();
                      img.onload = () => {
                        const rect = model.element.getBoundingClientRect();
                        // Draw the model at its current position
                        ctx.drawImage(
                          img, 
                          rect.left, 
                          rect.top, 
                          rect.width, 
                          rect.height
                        );
                        resolve();
                      };
                      img.onerror = () => resolve(); // Continue even if one fails
                      img.src = URL.createObjectURL(blob);
                    });
                  }
                } catch (error) {
                  console.error('Error capturing model:', error);
                  return Promise.resolve(); // Continue with other models
                }
              }
              return Promise.resolve();
            });
            
            // Wait for all models to be captured
            await Promise.all(modelPromises);
          }
          
          // Step 4: Save the composite image
          canvas.toBlob((blob) => {
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'ar-${widget.productName ?? 'screenshot'}-' + Date.now() + '.png';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
            showNotification('Screenshot saved with all models!');
          }, 'image/png');
          
        } else {
          // 3D view mode - use model-viewer's built-in screenshot
          if (modelViewer.toBlob) {
            modelViewer.toBlob({ idealAspectRatio: 1 }).then((blob) => {
              const url = URL.createObjectURL(blob);
              const a = document.createElement('a');
              a.href = url;
              a.download = '3d-${widget.productName ?? 'screenshot'}-' + Date.now() + '.png';
              document.body.appendChild(a);
              a.click();
              document.body.removeChild(a);
              URL.revokeObjectURL(url);
              showNotification('3D Screenshot saved!');
            });
          }
        }
      } catch (error) {
        console.error('Screenshot error:', error);
        showNotification('Failed to capture screenshot: ' + error.message);
      }
    }

    // Show notification
    function showNotification(message) {
      const notification = document.createElement('div');
      notification.style.cssText = \`
        position: fixed;
        top: 20px;
        right: 20px;
        background: rgba(220, 38, 38, 0.95);
        color: white;
        padding: 16px 24px;
        border-radius: 8px;
        z-index: 10000;
        font-weight: 600;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      \`;
      notification.textContent = message;
      document.body.appendChild(notification);
      
      setTimeout(() => {
        notification.style.opacity = '0';
        notification.style.transition = 'opacity 0.3s';
        setTimeout(() => notification.remove(), 300);
      }, 2000);
    }

    // Update AR button text
    function updateARButton() {
      const button = document.getElementById('ar-button');
      if (button) {
        if (isARActive) {
          button.textContent = 'Exit AR';
          button.onclick = exitAR;
        } else {
          button.textContent = 'Open Camera & AR';
          button.onclick = enterAR;
        }
      }
    }

    // New AR Control Functions
    function toggleInfo() {
      const infoPanel = document.getElementById('info-panel');
      const infoBtn = document.getElementById('info-btn');
      
      if (infoPanel.style.display === 'none' || !infoPanel.style.display) {
        infoPanel.style.display = 'block';
        infoBtn.style.background = 'rgba(220, 38, 38, 0.8)';
        // Auto-hide after 5 seconds
        setTimeout(() => {
          infoPanel.style.display = 'none';
          infoBtn.style.background = 'rgba(128, 128, 128, 0.8)';
        }, 5000);
      } else {
        infoPanel.style.display = 'none';
        infoBtn.style.background = 'rgba(128, 128, 128, 0.8)';
      }
    }
    
    function zoomIn() {
      placedModels.forEach(model => {
        if (model.element) {
          const currentScale = model.scale || 1;
          const newScale = Math.min(currentScale * 1.2, 3); // Max 3x zoom
          model.scale = newScale;
          model.element.style.transform = model.element.style.transform.replace(/scale\([^)]*\)/, '') + \` scale(\${newScale})\`;
        }
      });
      showNotification('Zoomed in');
      
      // Track zoom action
      trackARAction('zoom_in', { scale: placedModels[0]?.scale || 1 });
    }
    
    function zoomOut() {
      placedModels.forEach(model => {
        if (model.element) {
          const currentScale = model.scale || 1;
          const newScale = Math.max(currentScale * 0.8, 0.3); // Min 0.3x zoom
          model.scale = newScale;
          model.element.style.transform = model.element.style.transform.replace(/scale\([^)]*\)/, '') + \` scale(\${newScale})\`;
        }
      });
      showNotification('Zoomed out');
      
      // Track zoom action
      trackARAction('zoom_out', { scale: placedModels[0]?.scale || 1 });
    }
    
    function rotateModel(degrees) {
      const rotation = parseFloat(degrees);
      placedModels.forEach(model => {
        if (model.modelViewer) {
          model.modelViewer.setAttribute('camera-orbit', \`\${rotation}deg 75deg 2.5m\`);
          model.rotation = rotation;
        }
      });
      
      // Update slider label
      const slider = document.getElementById('rotation-slider');
      if (slider) {
        slider.setAttribute('title', \`\${Math.round(rotation)}°\`);
      }
      
      // Track rotation
      trackARAction('rotate', { rotation: rotation });
    }
    
    // Reset button: clear ALL placed models from the surface
    function resetView() {
      // Re-use resetModel logic so we don't duplicate behaviour
      resetModel();

      // Also reset the rotation slider UI
      const slider = document.getElementById('rotation-slider');
      if (slider) {
        slider.value = 0;
        slider.setAttribute('title', '0°');
      }

      // Track reset action explicitly for analytics
      trackARAction('reset_view', {
        models_after_reset: placedModels.length
      });
    }
    
    // Enhanced screenshot function with backend integration
    async function captureScreenshotEnhanced() {
      try {
        showNotification('Capturing AR screenshot...');
        
        const success = await captureScreenshot();
        
        if (success) {
          screenshotCount++;
          
          // Track screenshot capture
          trackARAction('screenshot_captured', {
            models_count: placedModels.length,
            screenshot_number: screenshotCount,
            timestamp: new Date().toISOString()
          });
          
          // Send analytics to backend
          await sendARAnalytics('screenshot', {
            product_id: '${widget.productName ?? 'unknown'}',
            session_duration: Date.now() - arSessionStartTime,
            models_placed: placedModels.length,
            screenshot_count: screenshotCount
          });
          
          showNotification(\`Screenshot \${screenshotCount} saved!\`);
        }
      } catch (error) {
        console.error('Screenshot capture failed:', error);
        showNotification('Failed to capture screenshot');
      }
    }
    
    // AR Analytics and Backend Integration
    function trackARAction(action, data) {
      actionCount++;
      
      const eventData = {
        action: action,
        timestamp: new Date().toISOString(),
        session_id: arSessionStartTime,
        product_name: '${widget.productName ?? 'unknown'}',
        action_count: actionCount,
        ...data
      };
      
      console.log('AR Action:', eventData);
      
      // Send to backend analytics
      sendARAnalytics(action, eventData).catch(err => {
        console.warn('Failed to send AR analytics:', err);
      });
    }
    
    function calculateEngagementScore(sessionDuration, modelsPlaced, screenshotsTaken, totalActions) {
      // Simple engagement scoring algorithm (0-100)
      let score = 0;
      
      // Session duration score (max 40 points)
      const durationMinutes = sessionDuration / (1000 * 60);
      score += Math.min(durationMinutes * 10, 40);
      
      // Models placed score (max 30 points)
      score += Math.min(modelsPlaced * 15, 30);
      
      // Screenshots taken score (max 20 points)
      score += Math.min(screenshotsTaken * 10, 20);
      
      // Actions performed score (max 10 points)
      score += Math.min(totalActions * 2, 10);
      
      return Math.round(score);
    }
    
    async function sendARAnalytics(event, data) {
      try {
        // In production, this would send to your analytics endpoint
        const analyticsData = {
          event_type: 'ar_interaction',
          event_name: event,
          properties: data,
          user_agent: navigator.userAgent,
          timestamp: new Date().toISOString(),
          url: window.location.href
        };
        
        // For now, log to console (replace with actual API call)
        console.log('Analytics Event:', analyticsData);
        
        // Example API call (uncomment and modify for production):
        /*
        await fetch('/api/analytics/ar', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(analyticsData)
        });
        */
        
        return true;
      } catch (error) {
        console.error('Analytics error:', error);
        return false;
      }
    }

    // Make functions globally available
    window.enterAR = enterAR;
    window.exitAR = exitAR;
    window.resetModel = resetModel;
    window.captureScreenshot = captureScreenshotEnhanced;
    window.goBack = goBack;
    window.toggleInfo = toggleInfo;
    window.zoomIn = zoomIn;
    window.zoomOut = zoomOut;
    window.rotateModel = rotateModel;
    window.resetView = resetView;
    window.trackARAction = trackARAction;

    // Handle AR session events
    modelViewer.addEventListener('ar-status', (event) => {
      console.log('AR Status:', event.detail.status);
      if (event.detail.status === 'not-presenting') {
        isARActive = false;
        updateARButton();
      }
    });

    // Handle model load - hide poster and show model
    modelViewer.addEventListener('load', () => {
      console.log('3D Model loaded successfully');
      console.log('Model URL:', '${widget.modelUrl}');
      const poster = document.getElementById('model-poster');
      if (poster) {
        poster.style.display = 'none';
        poster.style.opacity = '0';
        poster.style.transition = 'opacity 0.5s';
      }
      modelViewer.style.display = 'block';
      modelViewer.style.opacity = '1';
      showNotification('3D Model loaded! Drag to rotate');
    });

    // Handle model progress
    modelViewer.addEventListener('progress', (event) => {
      const progress = event.detail.totalProgress;
      console.log('Model loading progress:', Math.round(progress * 100) + '%');
      if (progress >= 1.0) {
        const poster = document.getElementById('model-poster');
        if (poster) {
          poster.style.display = 'none';
        }
      }
    });

    // Handle errors
    modelViewer.addEventListener('error', (event) => {
      console.error('Model loading error:', event.detail);
      console.error('Failed URL:', '${widget.modelUrl}');
      showNotification('Failed to load 3D model. Check console for details.');
      const poster = document.getElementById('model-poster');
      if (poster) {
        poster.innerHTML = '<div style="text-align: center; color: white;"><div style="font-size: 16px; margin-top: 12px;">Failed to load model</div><div style="font-size: 12px; margin-top: 8px; opacity: 0.8;">Check console for details</div></div>';
      }
    });
    
    // Ensure model-viewer is visible on initial load and auto-enter AR
    window.addEventListener('load', () => {
      modelViewer.style.display = 'block';
      console.log('🚀 Model viewer initialized');
      console.log('Model URL:', '${widget.modelUrl}');
      console.log('📝 Product Name:', '${widget.productName ?? 'N/A'}');
      
      // Force poster to hide after a delay if model loads
      setTimeout(() => {
        if (modelViewer.loaded) {
          const poster = document.getElementById('model-poster');
          if (poster) {
            poster.style.display = 'none';
          }
        }
      }, 2000);
      
      // Auto-enter AR camera mode after a short delay
      setTimeout(() => {
        console.log('Auto-entering AR camera mode...');
        enterAR();
      }, 1500);
    });
    
    // Also check when model-viewer is ready
    modelViewer.addEventListener('model-loaded', () => {
      console.log('🎉 Model fully loaded and ready');
      const poster = document.getElementById('model-poster');
      if (poster) {
        poster.style.display = 'none';
      }
    });
  </script>
</body>
</html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _iframeKey != null) {
      return SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: HtmlElementView(viewType: _iframeKey!),
      );
    } else {
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
}
