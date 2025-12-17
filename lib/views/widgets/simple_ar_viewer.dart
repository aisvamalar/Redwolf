import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Interactive AR Viewer - Working version from this morning
/// Supports camera AR, tap-to-place, drag, and screenshot capture
class SimpleARViewer extends StatefulWidget {
  final String modelUrl;
  final String? altText;
  final String? productName;
  final VoidCallback? onBackPressed;
  final bool autoStartAR;

  const SimpleARViewer({
    super.key,
    required this.modelUrl,
    this.altText,
    this.productName,
    this.onBackPressed,
    this.autoStartAR = false,
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

    html.window.onMessage.listen((event) {
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

    final iframe = html.IFrameElement()
      ..id = _iframeKey!
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'camera; microphone; xr-spatial-tracking'
      ..srcdoc = _createArHtml();

    ui_web.platformViewRegistry.registerViewFactory(
      _iframeKey!,
      (int viewId) => iframe,
    );
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
    .icon-button {
      width: 44px;
      height: 44px;
      border-radius: 50%;
      background: rgba(128, 128, 128, 0.8);
      border: none;
      color: white;
      font-size: 20px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      backdrop-filter: blur(10px);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
      transition: all 0.2s ease;
    }
    .icon-button:hover {
      background: rgba(128, 128, 128, 1);
      transform: scale(1.05);
    }
    .zoom-controls {
      position: absolute;
      right: 20px;
      top: 50%;
      transform: translateY(-50%);
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 12px;
      z-index: 100;
    }
    .zoom-icon {
      width: 44px;
      height: 44px;
      border-radius: 50%;
      background: rgba(128, 128, 128, 0.8);
      border: none;
      color: white;
      font-size: 20px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      backdrop-filter: blur(10px);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
    }
    .zoom-slider {
      width: 4px;
      height: 200px;
      background: rgba(128, 128, 128, 0.5);
      border-radius: 2px;
      position: relative;
      cursor: pointer;
    }
    .zoom-slider-handle {
      width: 20px;
      height: 20px;
      background: white;
      border-radius: 50%;
      position: absolute;
      left: 50%;
      transform: translateX(-50%);
      cursor: grab;
      box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
    }
    .zoom-slider-handle:active {
      cursor: grabbing;
    }
    .zoom-button {
      width: 36px;
      height: 36px;
      border-radius: 50%;
      background: rgba(128, 128, 128, 0.8);
      border: none;
      color: white;
      font-size: 18px;
      font-weight: bold;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      backdrop-filter: blur(10px);
      box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
    }
    .rotation-controls {
      position: absolute;
      bottom: 100px;
      left: 50%;
      transform: translateX(-50%);
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      z-index: 100;
    }
    .rotation-label {
      color: white;
      font-size: 14px;
      font-weight: 500;
      text-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
    }
    .rotation-slider {
      width: 300px;
      height: 6px;
      background: rgba(128, 128, 128, 0.5);
      border-radius: 3px;
      position: relative;
      cursor: pointer;
    }
    .rotation-slider-handle {
      width: 24px;
      height: 24px;
      background: white;
      border-radius: 50%;
      position: absolute;
      top: 50%;
      transform: translateY(-50%);
      cursor: grab;
      box-shadow: 0 2px 6px rgba(0, 0, 0, 0.3);
    }
    .rotation-slider-handle:active {
      cursor: grabbing;
    }
    .rotation-values {
      display: flex;
      justify-content: space-between;
      width: 300px;
      color: white;
      font-size: 12px;
      text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
    }
    .camera-button {
      position: absolute;
      bottom: 30px;
      left: 30px;
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: white;
      border: none;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
      z-index: 100;
      transition: all 0.2s ease;
    }
    .camera-button:hover {
      transform: scale(1.05);
      box-shadow: 0 6px 16px rgba(0, 0, 0, 0.4);
    }
    .camera-icon {
      width: 32px;
      height: 32px;
      background: black;
      border-radius: 4px;
      position: relative;
    }
    .camera-icon::after {
      content: '';
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      width: 20px;
      height: 20px;
      border: 2px solid white;
      border-radius: 50%;
    }
    .reset-button {
      position: absolute;
      bottom: 30px;
      right: 30px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 8px;
      z-index: 100;
    }
    .reset-icon-button {
      width: 64px;
      height: 64px;
      border-radius: 50%;
      background: rgba(128, 128, 128, 0.8);
      border: none;
      color: white;
      font-size: 24px;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      backdrop-filter: blur(10px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
      transition: all 0.2s ease;
    }
    .reset-icon-button:hover {
      background: rgba(128, 128, 128, 1);
      transform: scale(1.05);
    }
    .reset-label {
      color: white;
      font-size: 12px;
      text-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
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
      auto-rotate-delay="2000"
      rotation-per-second="15deg"
      interaction-policy="always-allow"
      shadow-intensity="2"
      exposure="1.5"
      environment-image="neutral"
      skybox-image="neutral"
      camera-orbit="0deg 75deg 5m"
      min-camera-orbit="auto auto 2m"
      max-camera-orbit="auto auto 10m"
      field-of-view="55deg"
      bounds="auto"
      scale="0.9 0.9 0.9"
      disable-zoom="false"
      disable-pan="false"
      disable-tap="false"
      style="width: 100%; height: 100%; display: block; background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);"
      xr-environment
      touch-action="none"
      ar-tap-to-place
      reveal="auto"
      loading="auto"
    >
      <div slot="poster" id="model-poster" style="width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #DC2626 0%, #991B1B 100%); position: absolute; top: 0; left: 0; z-index: 1;">
        <div style="text-align: center; color: white;">
          <div style="font-size: 48px; margin-bottom: 16px;"></div>
          <div style="font-size: 24px; margin-bottom: 12px; font-weight: 600;">Loading 3D Model...</div>
          <div style="font-size: 14px; opacity: 0.9; margin-bottom: 8px;">${widget.productName ?? 'Digital Standee 4.5 feet'}</div>
          <div style="font-size: 12px; opacity: 0.8;">Tap "Open Camera & AR" for AR mode</div>
        </div>
      </div>
    </model-viewer>
    
    <!-- AR Mode Controls (shown during camera AR) -->
    <div id="ar-mode-controls" style="display: none;">
      <!-- Info Button (Top Left) -->
      <button onclick="showInfo()" class="icon-button" style="position: absolute; top: 20px; left: 20px; z-index: 100;">
        i
      </button>
      
      <!-- Close Button (Top Right) -->
      <button onclick="goBack()" class="icon-button" style="position: absolute; top: 20px; right: 20px; z-index: 100;">
        ×
      </button>
      
      <!-- Zoom Controls (Right Side) -->
      <div class="zoom-controls">
        <button onclick="zoomIn()" class="zoom-icon">🔍</button>
        <div class="zoom-slider" id="zoom-slider">
          <div class="zoom-slider-handle" id="zoom-handle"></div>
        </div>
        <button onclick="zoomIn()" class="zoom-button">+</button>
        <button onclick="zoomOut()" class="zoom-button">-</button>
      </div>
      
      <!-- Rotation Controls (Bottom Center) -->
      <div class="rotation-controls">
        <div class="rotation-label">Rotate</div>
        <div class="rotation-slider" id="rotation-slider">
          <div class="rotation-slider-handle" id="rotation-handle"></div>
        </div>
        <div class="rotation-values">
          <span>0°</span>
          <span>360°</span>
        </div>
      </div>
      
      <!-- Camera Button (Bottom Left) -->
      <button onclick="captureScreenshot()" class="camera-button">
        <div class="camera-icon"></div>
      </button>
      
      <!-- Reset View Button (Bottom Right) -->
      <div class="reset-button">
        <button onclick="resetModel()" class="reset-icon-button">↻</button>
        <div class="reset-label">Reset view</div>
      </div>
    </div>

    <!-- Default Controls (shown in 3D view) -->
    <div class="controls-panel" id="default-controls">
      <button class="control-button" onclick="enterAR()" id="ar-button">
        Open Camera & AR
      </button>
      <button class="control-button secondary" onclick="resetModel()">
        Reset
      </button>
      <button class="control-button secondary" onclick="captureScreenshot()">
        Screenshot
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
    let currentZoom = 1;
    let currentRotation = 0;
    const minZoom = 0.5;
    const maxZoom = 3;
    const autoStartAR = ${widget.autoStartAR};

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
      const baseWidth = 250;
      const baseHeight = 400;
      const modelContainer = document.createElement('div');
      modelContainer.id = modelId;
      modelContainer.style.cssText = \`
        position: absolute;
        left: \${x}px;
        top: \${y}px;
        width: \${baseWidth * currentZoom}px;
        height: \${baseHeight * currentZoom}px;
        transform: translate(-50%, -50%) rotate(\${currentRotation}deg);
        pointer-events: auto;
        z-index: 21;
      \`;
      
      // Create model-viewer element
      const modelViewerElement = document.createElement('model-viewer');
      modelViewerElement.setAttribute('src', '${widget.modelUrl}');
      modelViewerElement.setAttribute('alt', '${widget.altText ?? widget.productName ?? '3D Model'}');
      modelViewerElement.setAttribute('camera-controls', '');
      modelViewerElement.setAttribute('interaction-policy', 'always-allow');
      modelViewerElement.setAttribute('shadow-intensity', '2');
      modelViewerElement.setAttribute('exposure', '1.5');
      modelViewerElement.setAttribute('environment-image', 'neutral');
      modelViewerElement.setAttribute('skybox-image', 'neutral');
      modelViewerElement.setAttribute('auto-rotate', '');
      modelViewerElement.setAttribute('auto-rotate-delay', '1000');
      modelViewerElement.setAttribute('rotation-per-second', '15deg');
      modelViewerElement.setAttribute('camera-orbit', '0deg 75deg 5m');
      modelViewerElement.setAttribute('field-of-view', '55deg');
      modelViewerElement.setAttribute('bounds', 'auto');
      modelViewerElement.setAttribute('scale', '0.9 0.9 0.9');
      modelViewerElement.setAttribute('ar', '');
      modelViewerElement.style.cssText = 'width: 100%; height: 100%; background: transparent; position: absolute; top: 0; left: 0;';
      
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
    }
    
    // Make model draggable
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
          const model = placedModels.find(m => m.id === modelId);
          if (model) {
            const rect = element.getBoundingClientRect();
            model.x = rect.left + rect.width / 2;
            model.y = rect.top + rect.height / 2;
          }
        }
      }
      
      element.addEventListener('mousedown', startDrag);
      document.addEventListener('mousemove', drag);
      document.addEventListener('mouseup', endDrag);
      element.addEventListener('touchstart', startDrag);
      document.addEventListener('touchmove', drag);
      document.addEventListener('touchend', endDrag);
      
      element.style.cursor = 'grab';
    }

    // Enter AR mode with camera
    async function enterAR() {
      try {
        const success = await startCameraFeed();
        if (success) {
          isARActive = true;
          setupARCanvas();
          setupTapToPlace();
          setupZoomSlider();
          setupRotationSlider();
          
          // Hide model-viewer, show camera feed
          modelViewer.style.display = 'none';
          
          // Show AR controls, hide default controls
          document.getElementById('ar-mode-controls').style.display = 'block';
          document.getElementById('default-controls').style.display = 'none';
          const infoPanel = document.querySelector('.info-panel');
          if (infoPanel) {
            infoPanel.style.display = 'none';
          }
          
          // Show models container
          const modelsContainer = document.getElementById('ar-models-container');
          if (modelsContainer) {
            modelsContainer.style.display = 'block';
          }
          
          updateARButton();
        }
      } catch (error) {
        console.error('AR activation error:', error);
        showNotification('AR not available. Please use a compatible device/browser.');
      }
    }

    // Go back navigation
    function goBack() {
      // Send message to Flutter to pop navigation
      if (window.parent) {
        window.parent.postMessage({ type: 'ar_back' }, '*');
      }
    }

    // Exit AR mode
    async function exitAR() {
      stopCameraFeed();
      
      if (arSession) {
        await arSession.end();
        arSession = null;
      }
      
      if (modelViewer.exitAR) {
        await modelViewer.exitAR();
      }
      
      // Show model-viewer again
      modelViewer.style.display = 'block';
      
      // Show default controls, hide AR controls
      document.getElementById('ar-mode-controls').style.display = 'none';
      document.getElementById('default-controls').style.display = 'flex';
      document.querySelector('.info-panel').style.display = 'block';
      
      isARActive = false;
      updateARButton();
      showNotification('Switched to 3D View');
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
        // Reset zoom and rotation
        currentZoom = 1;
        currentRotation = 0;
        updateZoom();
        updateRotation(0);
        showNotification('All models cleared');
      } else {
        // Reset camera to optimal viewing position
        if (modelViewer.cameraOrbit) {
          modelViewer.cameraOrbit = '0deg 75deg 5m';
        }
        if (modelViewer.fieldOfView) {
          modelViewer.fieldOfView = '55deg';
        }
        if (modelViewer.scale) {
          modelViewer.scale = '0.9 0.9 0.9';
        }
        if (modelViewer.resetCamera) {
          modelViewer.resetCamera();
        }
        showNotification('Camera reset to optimal view');
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

    // Zoom controls
    function zoomIn() {
      currentZoom = Math.min(currentZoom + 0.1, maxZoom);
      updateZoom();
      applyZoomToModels();
    }
    
    function zoomOut() {
      currentZoom = Math.max(currentZoom - 0.1, minZoom);
      updateZoom();
      applyZoomToModels();
    }
    
    function updateZoom() {
      const zoomSlider = document.getElementById('zoom-slider');
      const zoomHandle = document.getElementById('zoom-handle');
      if (zoomSlider && zoomHandle) {
        const percentage = ((currentZoom - minZoom) / (maxZoom - minZoom)) * 100;
        zoomHandle.style.top = (100 - percentage) + '%';
      }
    }
    
    function applyZoomToModels() {
      placedModels.forEach(model => {
        if (model.element) {
          const baseWidth = 250;
          const baseHeight = 400;
          model.element.style.width = (baseWidth * currentZoom) + 'px';
          model.element.style.height = (baseHeight * currentZoom) + 'px';
        }
      });
    }
    
    // Setup zoom slider drag
    function setupZoomSlider() {
      const zoomSlider = document.getElementById('zoom-slider');
      const zoomHandle = document.getElementById('zoom-handle');
      if (!zoomSlider || !zoomHandle) return;
      
      let isDragging = false;
      
      function startDrag(e) {
        isDragging = true;
        e.preventDefault();
      }
      
      function drag(e) {
        if (!isDragging) return;
        const rect = zoomSlider.getBoundingClientRect();
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;
        const y = clientY - rect.top;
        const percentage = Math.max(0, Math.min(100, (rect.height - y) / rect.height * 100));
        zoomHandle.style.top = (100 - percentage) + '%';
        currentZoom = minZoom + (percentage / 100) * (maxZoom - minZoom);
        applyZoomToModels();
        e.preventDefault();
      }
      
      function endDrag() {
        isDragging = false;
      }
      
      zoomSlider.addEventListener('mousedown', startDrag);
      zoomHandle.addEventListener('mousedown', startDrag);
      document.addEventListener('mousemove', drag);
      document.addEventListener('mouseup', endDrag);
      zoomSlider.addEventListener('touchstart', startDrag);
      zoomHandle.addEventListener('touchstart', startDrag);
      document.addEventListener('touchmove', drag);
      document.addEventListener('touchend', endDrag);
      
      updateZoom();
    }
    
    // Rotation controls
    function updateRotation(degrees) {
      currentRotation = degrees;
      const rotationHandle = document.getElementById('rotation-handle');
      if (rotationHandle) {
        const percentage = (degrees / 360) * 100;
        rotationHandle.style.left = percentage + '%';
      }
      applyRotationToModels();
    }
    
    function applyRotationToModels() {
      placedModels.forEach(model => {
        if (model.element) {
          model.element.style.transform = 'translate(-50%, -50%) rotate(' + currentRotation + 'deg)';
        }
      });
    }
    
    // Setup rotation slider drag
    function setupRotationSlider() {
      const rotationSlider = document.getElementById('rotation-slider');
      const rotationHandle = document.getElementById('rotation-handle');
      if (!rotationSlider || !rotationHandle) return;
      
      let isDragging = false;
      
      function startDrag(e) {
        isDragging = true;
        e.preventDefault();
      }
      
      function drag(e) {
        if (!isDragging) return;
        const rect = rotationSlider.getBoundingClientRect();
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const x = clientX - rect.left;
        const percentage = Math.max(0, Math.min(100, (x / rect.width) * 100));
        rotationHandle.style.left = percentage + '%';
        const degrees = (percentage / 100) * 360;
        updateRotation(degrees);
        e.preventDefault();
      }
      
      function endDrag() {
        isDragging = false;
      }
      
      rotationSlider.addEventListener('mousedown', startDrag);
      rotationHandle.addEventListener('mousedown', startDrag);
      document.addEventListener('mousemove', drag);
      document.addEventListener('mouseup', endDrag);
      rotationSlider.addEventListener('touchstart', startDrag);
      rotationHandle.addEventListener('touchstart', startDrag);
      document.addEventListener('touchmove', drag);
      document.addEventListener('touchend', endDrag);
      
      updateRotation(0);
    }
    
    // Show info
    function showInfo() {
      showNotification('Tap on surfaces to place the 3D model. Drag to move, use controls to zoom and rotate.');
    }

    // Make functions globally available
    window.enterAR = enterAR;
    window.exitAR = exitAR;
    window.resetModel = resetModel;
    window.captureScreenshot = captureScreenshot;
    window.goBack = goBack;
    window.zoomIn = zoomIn;
    window.zoomOut = zoomOut;
    window.showInfo = showInfo;

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
      
      // Ensure optimal camera position on load
      setTimeout(() => {
        if (modelViewer.cameraOrbit) {
          modelViewer.cameraOrbit = '0deg 75deg 5m';
        }
        if (modelViewer.fieldOfView) {
          modelViewer.fieldOfView = '55deg';
        }
        if (modelViewer.scale) {
          modelViewer.scale = '0.9 0.9 0.9';
        }
      }, 100);
      
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
    
    // Ensure model-viewer is visible on initial load
    window.addEventListener('load', () => {
      modelViewer.style.display = 'block';
      console.log('🚀 Model viewer initialized');
      console.log('Model URL:', '${widget.modelUrl}');
      console.log('📝 Product Name:', '${widget.productName ?? 'N/A'}');
      
      // Auto-start AR if enabled
      if (autoStartAR) {
        setTimeout(() => { enterAR(); }, 500);
      }
      
      // Force poster to hide after a delay if model loads
      setTimeout(() => {
        if (modelViewer.loaded) {
          const poster = document.getElementById('model-poster');
          if (poster) {
            poster.style.display = 'none';
          }
        }
      }, 2000);
    });
    
    // Also check when model-viewer is ready
    modelViewer.addEventListener('model-loaded', () => {
      console.log('🎉 Model fully loaded and ready');
      const poster = document.getElementById('model-poster');
      if (poster) {
        poster.style.display = 'none';
      }
      // Auto-start AR after model loads if enabled
      if (autoStartAR && !isARActive) {
        setTimeout(() => { enterAR(); }, 300);
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
      return HtmlElementView(viewType: _iframeKey!);
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
