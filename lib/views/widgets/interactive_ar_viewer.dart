import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Interactive AR Viewer inspired by ArApp repository
/// Supports drag, rotate, resize, and screenshot capture
class InteractiveARViewer extends StatefulWidget {
  final String modelUrl;
  final String? altText;
  final String? productName;

  const InteractiveARViewer({
    super.key,
    required this.modelUrl,
    this.altText,
    this.productName,
  });

  @override
  State<InteractiveARViewer> createState() => _InteractiveARViewerState();
}

class _InteractiveARViewerState extends State<InteractiveARViewer> {
  String? _iframeKey;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _iframeKey = 'interactive-ar-${widget.modelUrl.hashCode}';
      _registerARViewer();
    }
  }

  void _registerARViewer() {
    if (!kIsWeb || _iframeKey == null) return;

    final iframe = html.IFrameElement()
      ..id = _iframeKey!
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'camera; microphone; xr-spatial-tracking'
      ..srcdoc =
          '''
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
    
    <!-- Model viewer (hidden during AR) -->
    <model-viewer
      id="ar-model"
      src="${widget.modelUrl}"
      alt="${widget.altText ?? '3D Model'}"
      ar
      ar-modes="webxr scene-viewer quick-look"
      ar-scale="auto"
      ar-placement="floor"
      camera-controls
      interaction-policy="allow-when-focused"
      shadow-intensity="1"
      exposure="1"
      environment-image="neutral"
      style="width: 100%; height: 100%;"
      xr-environment
      touch-action="none"
      ar-tap-to-place
    >
      <div slot="poster" style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #DC2626 0%, #991B1B 100%);">
        <div style="text-align: center; color: white;">
          <div style="font-size: 48px; margin-bottom: 16px;">📷</div>
          <div style="font-size: 24px; margin-bottom: 12px; font-weight: 600;">Camera AR Ready</div>
          <div style="font-size: 14px; opacity: 0.9; margin-bottom: 8px;">${widget.productName ?? 'Tap AR button to open camera'}</div>
          <div style="font-size: 12px; opacity: 0.8;">Camera will open when you tap "Enter AR"</div>
        </div>
      </div>
    </model-viewer>
    
    <div class="info-panel">
      <h3>📷 Camera AR</h3>
      <div class="gesture-hint">
        <span class="gesture-icon">📷</span>
        <p>Camera opens automatically</p>
      </div>
      <div class="gesture-hint">
        <span class="gesture-icon">👆</span>
        <p>Tap surfaces to place model</p>
      </div>
      <div class="gesture-hint">
        <span class="gesture-icon">🔄</span>
        <p>Move device to detect planes</p>
      </div>
      <p style="margin-top: 12px; font-size: 12px; opacity: 0.7; border-top: 1px solid rgba(255,255,255,0.2); padding-top: 8px;">
        Point camera at flat surfaces. Tap detected surfaces to place the 3D model.
      </p>
    </div>
    
    <!-- AR Mode Controls (shown during camera AR) -->
    <div id="ar-mode-controls" style="display: none;">
      <!-- Product Label -->
      <div id="product-label" style="
        position: absolute;
        bottom: 180px;
        left: 50%;
        transform: translateX(-50%);
        background: rgba(0, 0, 0, 0.9);
        color: white;
        padding: 8px 20px;
        border-radius: 20px;
        font-size: 16px;
        font-weight: 600;
        z-index: 25;
        box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
      ">
        ${widget.productName ?? widget.altText ?? 'Digital standee 4.5 feet'}
      </div>
      
      <!-- Screenshot Button -->
      <div style="
        position: absolute;
        bottom: 100px;
        left: 50%;
        transform: translateX(-50%);
        z-index: 30;
      ">
        <button onclick="captureScreenshot()" style="
          background: rgba(0, 0, 0, 0.8);
          color: white;
          border: none;
          padding: 12px 24px;
          border-radius: 25px;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
          display: flex;
          align-items: center;
          gap: 8px;
        ">
          📷 Screenshot
        </button>
      </div>
      
      <!-- Main Control Buttons -->
      <div style="
        position: absolute;
        bottom: 30px;
        left: 50%;
        transform: translateX(-50%);
        display: flex;
        gap: 15px;
        z-index: 30;
        align-items: center;
      ">
        <button onclick="exitAR()" style="
          background: linear-gradient(135deg, #DC2626 0%, #991B1B 100%);
          color: white;
          border: none;
          padding: 12px 24px;
          border-radius: 25px;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          box-shadow: 0 4px 15px rgba(220, 38, 38, 0.4);
          display: flex;
          align-items: center;
          gap: 8px;
        ">
          📱 Exit Camera AR
        </button>
        
        <button onclick="showInfo()" style="
          background: rgba(0, 0, 0, 0.8);
          color: white;
          border: none;
          padding: 12px 20px;
          border-radius: 25px;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
          display: flex;
          align-items: center;
          gap: 8px;
        ">
          ℹ️ Info
        </button>
        
        <button onclick="resetModel()" style="
          background: rgba(0, 0, 0, 0.8);
          color: white;
          border: none;
          padding: 12px 20px;
          border-radius: 25px;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.4);
          display: flex;
          align-items: center;
          gap: 8px;
        ">
          🔄 Reset
        </button>
      </div>
    </div>

    <!-- Default Controls (shown in 3D view) -->
    <div class="controls-panel" id="default-controls">
      <button class="control-button" onclick="enterAR()" id="ar-button">
        📷 Open Camera & AR
      </button>
      <button class="control-button secondary" onclick="resetModel()">
        🔄 Reset
      </button>
      <button class="control-button secondary" onclick="captureScreenshot()">
        📸 Screenshot
      </button>
    </div>
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

    // Start camera feed
    async function startCameraFeed() {
      try {
        cameraStream = await navigator.mediaDevices.getUserMedia({ 
          video: { 
            facingMode: 'environment',
            width: { ideal: 1280 },
            height: { ideal: 720 }
          } 
        });
        
        cameraFeed.srcObject = cameraStream;
        cameraFeed.style.display = 'block';
        modelViewer.style.display = 'none';
        arCanvas.style.display = 'block';
        
        console.log('Camera feed started');
        showNotification('Camera opened! Tap on surfaces to place the 3D model');
        return true;
      } catch (error) {
        console.error('Camera access denied:', error);
        showNotification('Camera access is required for AR');
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
    
    // Place GLB model at coordinates (exact copy from working browser version)
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
        background: rgba(255, 0, 0, 0.2);
        border: 2px dashed #FF0000;
        border-radius: 8px;
      \`;
      
      // Create a highly visible placeholder first (immediate feedback)
      const placeholder = document.createElement('div');
      placeholder.style.cssText = \`
        width: 100%;
        height: 100%;
        background: linear-gradient(135deg, #FF0000 0%, #CC0000 100%);
        border-radius: 12px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        color: white;
        font-size: 48px;
        box-shadow: 0 8px 25px rgba(255,0,0,0.5);
        border: 4px solid #FFFFFF;
        animation: pulse 2s infinite;
        z-index: 100;
      \`;
      placeholder.innerHTML = \`
        <div style="font-size: 64px; margin-bottom: 10px;">📦</div>
        <div style="font-size: 16px; font-weight: bold;">3D MODEL</div>
        <div style="font-size: 12px; opacity: 0.9; margin-top: 5px;">TAP TO PLACE</div>
      \`;
      
      // Add pulsing animation
      const style = document.createElement('style');
      style.textContent = \`
        @keyframes pulse {
          0% { transform: scale(1); }
          50% { transform: scale(1.05); }
          100% { transform: scale(1); }
        }
      \`;
      document.head.appendChild(style);
      
      // Create model-viewer element
      const modelViewerElement = document.createElement('model-viewer');
      modelViewerElement.setAttribute('src', '${widget.modelUrl}');
      modelViewerElement.setAttribute('alt', '${widget.altText ?? widget.productName ?? '3D Model'}');
      modelViewerElement.setAttribute('camera-controls', '');
      modelViewerElement.setAttribute('interaction-policy', 'allow-when-focused');
      modelViewerElement.setAttribute('shadow-intensity', '1');
      modelViewerElement.setAttribute('exposure', '1');
      modelViewerElement.setAttribute('environment-image', 'neutral');
      modelViewerElement.setAttribute('auto-rotate', '');
      modelViewerElement.setAttribute('auto-rotate-delay', '0');
      modelViewerElement.setAttribute('ar', '');
      modelViewerElement.style.cssText = 'width: 100%; height: 100%; background: transparent; position: absolute; top: 0; left: 0;';
      
      // Add loading poster
      const poster = document.createElement('div');
      poster.setAttribute('slot', 'poster');
      poster.style.cssText = 'width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background: rgba(220, 38, 38, 0.8);';
      poster.innerHTML = '<div style="text-align: center; color: white;"><div style="font-size: 32px;">📦</div><div style="font-size: 14px; margin-top: 8px;">Loading 3D Model...</div></div>';
      modelViewerElement.appendChild(poster);
      
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
      
      // Add placeholder first (visible immediately)
      modelContainer.appendChild(placeholder);
      // Add model-viewer on top
      modelContainer.appendChild(modelViewerElement);
      modelContainer.appendChild(label);
      modelsContainer.appendChild(modelContainer);
      
      console.log('✅ Model container created and added to DOM');
      
      // Wait for model-viewer to be ready, then make draggable
      setTimeout(() => {
        makeModelDraggable(modelContainer, modelId);
        
        // Handle model load
        modelViewerElement.addEventListener('load', () => {
          console.log('3D Model loaded:', modelId);
          showNotification('✅ 3D Model loaded! Drag to move');
          // Hide placeholder when model loads
          placeholder.style.display = 'none';
        });
        
        // Handle errors
        modelViewerElement.addEventListener('error', (e) => {
          console.error('Model load error:', e.detail);
          showNotification('❌ Failed to load model');
          // Show error on placeholder
          placeholder.innerHTML = '❌';
          placeholder.style.background = 'linear-gradient(135deg, #DC2626 0%, #991B1B 100%)';
        });
        
        // Log model URL for debugging
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
      
      showNotification('✅ Placing 3D Model...');
    }
    
    // Make model draggable (supports both mouse and touch)
    function makeModelDraggable(element, modelId) {
      let isDragging = false;
      let startX, startY, initialX, initialY;
      
      function startDrag(e) {
        isDragging = true;
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;
        startX = clientX;
        startY = clientY;
        const rect = element.getBoundingClientRect();
        initialX = rect.left + rect.width / 2;
        initialY = rect.top + rect.height / 2;
        element.style.cursor = 'grabbing';
        element.style.touchAction = 'none';
        e.preventDefault();
      }
      
      function drag(e) {
        if (!isDragging) return;
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;
        const deltaX = clientX - startX;
        const deltaY = clientY - startY;
        const newX = initialX + deltaX;
        const newY = initialY + deltaY;
        element.style.left = newX + 'px';
        element.style.top = newY + 'px';
        e.preventDefault();
      }
      
      function endDrag() {
        if (isDragging) {
          isDragging = false;
          element.style.cursor = 'grab';
          element.style.touchAction = 'auto';
          // Update stored position
          const model = placedModels.find(m => m.id === modelId);
          if (model) {
            const rect = element.getBoundingClientRect();
            model.x = rect.left + rect.width / 2;
            model.y = rect.top + rect.height / 2;
          }
        }
      }
      
      // Mouse events
      element.addEventListener('mousedown', startDrag);
      document.addEventListener('mousemove', drag);
      document.addEventListener('mouseup', endDrag);
      
      // Touch events
      element.addEventListener('touchstart', startDrag);
      document.addEventListener('touchmove', drag);
      document.addEventListener('touchend', endDrag);
      
      element.style.cursor = 'grab';
    }

    // Enter AR mode with camera
    async function enterAR() {
      try {
        // Start camera feed for AR
        const success = await startCameraFeed();
        if (success) {
          isARActive = true;
          
          // Show AR controls, hide default controls
          document.getElementById('ar-mode-controls').style.display = 'block';
          document.getElementById('default-controls').style.display = 'none';
          document.querySelector('.info-panel').style.display = 'none';
          
          updateARButton();
        }
      } catch (error) {
        console.error('AR activation error:', error);
        showNotification('AR not available. Please use a compatible device/browser.');
      }
    }

    // Start WebXR AR session
    async function startWebXRAR() {
      try {
        const session = await navigator.xr.requestSession('immersive-ar', {
          requiredFeatures: ['local-floor', 'hit-test'],
          optionalFeatures: ['dom-overlay', 'light-estimation']
        });

        arSession = session;
        isARActive = true;
        updateARButton();
        showNotification('WebXR AR activated! Tap surfaces to place model.');

        // Handle session end
        session.addEventListener('end', () => {
          isARActive = false;
          updateARButton();
        });
      } catch (error) {
        console.error('WebXR AR error:', error);
        showNotification('WebXR not available. Using fallback AR.');
        // Fallback to model-viewer AR
        if (modelViewer.activateAR) {
          await modelViewer.activateAR();
          isARActive = true;
          updateARButton();
        }
      }
    }

    // Exit AR mode
    async function exitAR() {
      // Stop camera feed
      stopCameraFeed();
      
      // Stop WebXR session if active
      if (arSession) {
        await arSession.end();
        arSession = null;
      }
      
      if (modelViewer.exitAR) {
        await modelViewer.exitAR();
      }
      
      // Show default controls, hide AR controls
      document.getElementById('ar-mode-controls').style.display = 'none';
      document.getElementById('default-controls').style.display = 'flex';
      document.querySelector('.info-panel').style.display = 'block';
      
      isARActive = false;
      updateARButton();
      showNotification('📱 Switched to 3D View');
    }
    
    // Show info (placeholder function)
    function showInfo() {
      showNotification('ℹ️ Tap on surfaces to place 3D models');
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
        const ctx = arCanvas.getContext('2d');
        if (ctx) {
          ctx.clearRect(0, 0, arCanvas.width, arCanvas.height);
          drawCrosshair(ctx);
        }
        showNotification('🔄 All models cleared');
      } else {
        // Reset 3D viewer
        if (modelViewer.resetCamera) {
          modelViewer.resetCamera();
        }
        showNotification('🔄 Camera reset');
      }
      
      modelScale = 1;
      modelRotation = { x: 0, y: 0, z: 0 };
      modelPosition = { x: 0, y: 0, z: 0 };
    }

    // Capture screenshot
    function captureScreenshot() {
      try {
        if (isARActive) {
          // Capture AR view (camera + overlay)
          const canvas = document.createElement('canvas');
          const ctx = canvas.getContext('2d');
          canvas.width = arCanvas.width;
          canvas.height = arCanvas.height;
          
          // Draw camera feed
          ctx.drawImage(cameraFeed, 0, 0, canvas.width, canvas.height);
          
          // Draw AR overlay
          ctx.drawImage(arCanvas, 0, 0);
          
          // Convert to blob and download
          canvas.toBlob((blob) => {
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'ar-${widget.productName ?? 'screenshot'}-' + Date.now() + '.png';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
            showNotification('AR Screenshot saved! 📸');
          });
        } else {
          // Regular 3D model screenshot
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
              showNotification('3D Screenshot saved! 📸');
            });
          }
        }
      } catch (error) {
        console.error('Screenshot error:', error);
        showNotification('Failed to capture screenshot');
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
          button.textContent = '🚪 Exit AR';
          button.onclick = exitAR;
        } else {
          button.textContent = '📷 Open Camera & AR';
          button.onclick = enterAR;
        }
      }
    }

    // Make functions globally available
    window.enterAR = enterAR;
    window.exitAR = exitAR;
    window.resetModel = resetModel;
    window.captureScreenshot = captureScreenshot;

    // Handle AR session events
    modelViewer.addEventListener('ar-status', (event) => {
      console.log('AR Status:', event.detail.status);
      if (event.detail.status === 'not-presenting') {
        isARActive = false;
        updateARButton();
      }
    });

    // Handle model load
    modelViewer.addEventListener('load', () => {
      console.log('3D Model loaded successfully');
    });

    // Handle errors
    modelViewer.addEventListener('error', (event) => {
      console.error('Model loading error:', event.detail);
      showNotification('Failed to load 3D model');
    });
  </script>
</body>
</html>
''';

    ui_web.platformViewRegistry.registerViewFactory(
      _iframeKey!,
      (int viewId) => iframe,
    );
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
