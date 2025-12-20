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
    <!-- Camera feed for fallback AR -->
    <video id="camera-feed" autoplay playsinline style="width: 100%; height: 100%; object-fit: cover; display: none; position: absolute; top: 0; left: 0; z-index: 1;"></video>
    
    <!-- Canvas for AR overlay -->
    <canvas id="ar-canvas" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; display: none; z-index: 2; pointer-events: auto;"></canvas>
    
    <!-- Container for placed 3D models -->
    <div id="ar-models-container" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; pointer-events: none; z-index: 3; display: none;"></div>
    
    <model-viewer
      id="ar-model"
      src="${widget.modelUrl}"
      alt="${widget.altText ?? widget.productName ?? '3D Model'}"
      ar
      ar-modes="webxr scene-viewer quick-look"
      quick-look-browsers="safari"
      ar-scale="0.5"
      ar-placement="floor"
      scale="0.5 0.5 0.5"
      ar-tap-to-place
      camera-controls
      interaction-policy="allow-when-focused"
      shadow-intensity="1.5"
      exposure="1.2"
      environment-image="neutral"
      reveal="auto"
      loading="auto"
      style="--ar-button-display: none; position: relative; z-index: 0;"
    >
      <div slot="poster" id="model-poster" style="width: 100%; height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; background: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);">
        <div style="text-align: center; color: white; padding: 20px;">
          <div style="font-size: 64px; margin-bottom: 20px;">📱</div>
          <div style="font-size: 24px; font-weight: 600; margin-bottom: 12px;">${widget.productName ?? '3D Model'}</div>
          <div style="font-size: 14px; opacity: 0.8; margin-bottom: 24px;">Tap the button below to view in AR</div>
        </div>
      </div>
    </model-viewer>
    
    <!-- Top Left Controls -->
    <div class="top-controls">
      <button class="control-btn info-btn" id="info-btn" title="Info">i</button>
      <button class="control-btn" id="close-btn" title="Close">×</button>
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
             orient="vertical">
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
                 value="0">
          <span class="rotate-value">360°</span>
        </div>
      </div>
      
      <!-- Action Buttons -->
      <div class="action-buttons">
        <button class="camera-btn" id="camera-btn" title="Take Screenshot">
          <div class="camera-icon"></div>
        </button>
        <button class="reset-btn" id="reset-btn" title="Reset View">
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
    const rotateValue = rotateSlider ? rotateSlider.previousElementSibling : null;
    const cameraFeed = document.getElementById('camera-feed');
    const arCanvas = document.getElementById('ar-canvas');
    const modelsContainer = document.getElementById('ar-models-container');
    const infoBtn = document.getElementById('info-btn');
    const closeBtn = document.getElementById('close-btn');
    const cameraBtn = document.getElementById('camera-btn');
    const resetBtn = document.getElementById('reset-btn');
    
    let isARActive = false;
    let currentScale = 0.5; // Start at 50% size to prevent model being too big
    let currentRotation = 0;
    let arSession = null;
    let cameraStream = null;
    let useCameraFallback = false;
    let placedModels = [];
    
    // Wait for model-viewer to be ready
    if (modelViewer) {
      // Ensure model-viewer is visible from the start
      modelViewer.style.display = 'block';
      modelViewer.style.visibility = 'visible';
      modelViewer.style.opacity = '1';
      
      // Log model URL
      const modelUrl = modelViewer.getAttribute('src');
      console.log('Model URL:', modelUrl);
      
      if (!modelUrl || modelUrl.trim() === '') {
        console.error('Model URL is empty!');
        showError('Model URL is missing. Please check the product configuration.');
      }
      
      modelViewer.addEventListener('load', () => {
        console.log('Model loaded, AR ready');
        console.log('Model dimensions:', {
          width: modelViewer.model?.dimensions?.x,
          height: modelViewer.model?.dimensions?.y,
          depth: modelViewer.model?.dimensions?.z
        });
        
        // Ensure model is visible after loading
        modelViewer.style.display = 'block';
        modelViewer.style.visibility = 'visible';
        modelViewer.style.opacity = '1';
      });
      
      // Handle model loading errors
      modelViewer.addEventListener('error', (event) => {
        console.error('Model loading error:', event.detail);
        const errorMessage = event.detail?.message || 'Unknown error';
        console.error('Error details:', errorMessage);
        showError('Failed to load 3D model: ' + errorMessage + '. Please check the model URL: ' + modelUrl);
      });
      
      // Check AR availability on load
      modelViewer.addEventListener('ar-status', (event) => {
        console.log('AR status event:', event.detail.status);
      });
      
      // Log when model starts loading
      modelViewer.addEventListener('progress', (event) => {
        const progress = event.detail.totalProgress;
        console.log('Model loading progress:', (progress * 100).toFixed(0) + '%');
      });
      
      // Check if model is already loaded
      if (modelViewer.loaded) {
        console.log('Model already loaded');
        modelViewer.style.display = 'block';
        modelViewer.style.visibility = 'visible';
        modelViewer.style.opacity = '1';
      }
    }
    
    // Note: Event listeners for buttons and sliders are attached at the end of the script

    // Enter AR mode - Direct navigation to AR view
    async function enterAR() {
      try {
        // Hide preview/poster immediately
        const poster = modelViewer.querySelector('[slot="poster"]');
        if (poster) {
          poster.style.display = 'none';
        }
        
        // Hide button immediately
        arButton.style.display = 'none';
        
        // Show loading state
        const loadingDiv = document.createElement('div');
        loadingDiv.id = 'ar-loading';
        loadingDiv.style.cssText = \`
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: rgba(0, 0, 0, 0.9);
          z-index: 10000;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          color: white;
        \`;
        loadingDiv.innerHTML = \`
          <div style="width: 50px; height: 50px; border: 4px solid rgba(255,255,255,0.3); border-top-color: white; border-radius: 50%; animation: spin 1s linear infinite; margin-bottom: 20px;"></div>
          <div style="font-size: 16px;">Opening AR view...</div>
        \`;
        document.body.appendChild(loadingDiv);
        
        // Set initial scale BEFORE activating AR to prevent model being too big
        updateScale(0.5);
        
        // Ensure model is placed on floor, not above camera
        if (modelViewer) {
          modelViewer.setAttribute('ar-placement', 'floor');
          modelViewer.setAttribute('ar-scale', '0.5');
          modelViewer.setAttribute('scale', '0.5 0.5 0.5');
        }
        
        // Ensure model-viewer is visible before activating AR
        if (modelViewer) {
          modelViewer.style.display = 'block';
          modelViewer.style.visibility = 'visible';
          modelViewer.style.opacity = '1';
          modelViewer.style.width = '100%';
          modelViewer.style.height = '100%';
        }
        
        // Try WebXR/Scene Viewer first
        let arActivated = false;
        
        if (modelViewer.activateAR) {
          try {
            console.log('Attempting to activate AR via model-viewer...');
            console.log('Model URL:', modelViewer.getAttribute('src'));
            console.log('Model loaded:', modelViewer.loaded);
            
            // Wait for model to load if not already loaded
            if (!modelViewer.loaded) {
              console.log('Waiting for model to load...');
              await new Promise((resolve) => {
                const timeout = setTimeout(() => {
                  console.warn('Model load timeout');
                  resolve();
                }, 5000);
                
                modelViewer.addEventListener('load', () => {
                  clearTimeout(timeout);
                  console.log('Model loaded successfully');
                  resolve();
                }, { once: true });
              });
            }
            
            await modelViewer.activateAR();
            console.log('activateAR() completed');
            arActivated = true;
            
            // Wait a moment for AR session to initialize
            await new Promise(resolve => setTimeout(resolve, 1000));
            
            // Check if AR session actually started
            if (modelViewer.arSession) {
              console.log('WebXR/Scene Viewer AR activated successfully');
              arSession = modelViewer.arSession;
              
              // Ensure model-viewer remains visible in AR mode
              modelViewer.style.display = 'block';
              modelViewer.style.visibility = 'visible';
              modelViewer.style.opacity = '1';
            }
          } catch (arError) {
            console.warn('model-viewer activateAR failed:', arError);
            // Will fall back to camera feed
          }
        }
        
        // Fallback to camera feed AR if WebXR/Scene Viewer didn't work
        if (!arActivated || !modelViewer.arSession) {
          console.log('Falling back to camera feed AR...');
          useCameraFallback = true;
          
          // Start camera feed
          try {
            cameraStream = await navigator.mediaDevices.getUserMedia({ 
              video: { 
                facingMode: 'environment',
                width: { ideal: 1280 },
                height: { ideal: 720 }
              } 
            });
            
            cameraFeed.srcObject = cameraStream;
            
            // Wait for video to be ready
            await new Promise((resolve) => {
              cameraFeed.onloadedmetadata = () => {
                cameraFeed.style.display = 'block';
                modelViewer.style.display = 'none';
                arCanvas.style.display = 'block';
                modelsContainer.style.display = 'block';
                
                // Setup canvas
                setupARCanvas();
                setupTapToPlace();
                
                console.log('Camera feed AR started');
                resolve();
              };
            });
            
            arActivated = true;
          } catch (cameraError) {
            console.error('Camera feed failed:', cameraError);
            throw new Error('Camera access is required for AR. Please allow camera permission.');
          }
        }
        
        // Remove loading
        if (loadingDiv.parentNode) {
          loadingDiv.parentNode.removeChild(loadingDiv);
        }
        
        if (arActivated) {
          isARActive = true;
          container.classList.add('ar-active');
          
          // Show controls immediately
          scaleControl.style.display = 'flex';
          bottomControls.style.display = 'flex';
          
          // Setup drag after AR starts
          setupDrag();
          
          // Hide drag hint after 3 seconds
          setTimeout(() => {
            if (dragHint) dragHint.style.display = 'none';
          }, 3000);
          
          showNotification('AR view active! Tap surfaces to place model.');
        } else {
          throw new Error('Failed to activate AR');
        }
        
      } catch (error) {
        console.error('AR activation error:', error);
        
        // Remove loading if still present
        const loadingDiv = document.getElementById('ar-loading');
        if (loadingDiv && loadingDiv.parentNode) {
          loadingDiv.parentNode.removeChild(loadingDiv);
        }
        
        // Show error and restore button
        showError('Failed to open AR. ' + (error.message || 'Please try again or use a compatible device.'));
        arButton.style.display = 'flex';
        arButton.disabled = false;
        arButton.innerHTML = '<span>📱</span><span>View in AR</span>';
        
        // Restore poster
        const poster = modelViewer.querySelector('[slot="poster"]');
        if (poster) {
          poster.style.display = 'flex';
        }
      }
    }

    // Update model scale
    function updateScale(value) {
      currentScale = parseFloat(value);
      
      // Ensure slider value is synced
      if (scaleSlider) {
        scaleSlider.value = currentScale;
      }
      
      // Update main model-viewer
      if (modelViewer) {
        const scaleString = currentScale + ' ' + currentScale + ' ' + currentScale;
        
        // Update both scale and ar-scale attributes
        modelViewer.setAttribute('scale', scaleString);
        modelViewer.setAttribute('ar-scale', currentScale.toString());
        
        // Try to update the model's transform directly if in AR mode
        if (isARActive && !useCameraFallback) {
          // For WebXR mode, try to access the model directly
          if (modelViewer.arSession && modelViewer.model) {
            try {
              // Access the model's scene graph and update scale
              const scene = modelViewer.scene || modelViewer.model;
              if (scene && scene.scene) {
                scene.scene.scale.set(currentScale, currentScale, currentScale);
              }
            } catch (e) {
              console.log('Direct scale update not available, using attribute update');
            }
          }
          
          // Force a refresh by dispatching a custom event
          modelViewer.dispatchEvent(new CustomEvent('scale-changed', { 
            detail: { scale: currentScale } 
          }));
          
          // Also try updating the model source as a fallback
          setTimeout(() => {
            const currentSrc = modelViewer.getAttribute('src');
            if (currentSrc) {
              modelViewer.removeAttribute('src');
              requestAnimationFrame(() => {
                modelViewer.setAttribute('src', currentSrc);
              });
            }
          }, 50);
        }
      }
      
      // Update all placed models (for camera feed AR)
      placedModels.forEach(model => {
        if (model.modelViewer) {
          const scaleString = currentScale + ' ' + currentScale + ' ' + currentScale;
          model.modelViewer.setAttribute('scale', scaleString);
          
          // Also update the container size for visual feedback
          if (model.element) {
            const baseSize = 250;
            const newWidth = baseSize * currentScale;
            const newHeight = 400 * currentScale;
            model.element.style.width = newWidth + 'px';
            model.element.style.height = newHeight + 'px';
          }
        }
      });
      
      console.log('Scale updated to:', currentScale, '(', (currentScale * 100).toFixed(0) + '%)');
    }

    // Update model rotation
    function updateRotation(value) {
      currentRotation = parseInt(value);
      if (rotateValue) {
        rotateValue.textContent = currentRotation + '°';
      }
      
      // Update main model-viewer rotation
      if (modelViewer) {
        const rotationString = \`0 \${currentRotation} 0\`;
        modelViewer.setAttribute('rotation', rotationString);
      }
      
      // Update all placed models (for camera feed AR)
      placedModels.forEach(model => {
        if (model.modelViewer) {
          const rotationString = \`0 \${currentRotation} 0\`;
          model.modelViewer.setAttribute('rotation', rotationString);
        }
      });
      
      console.log('Rotation updated to:', currentRotation + '°');
    }

    // Setup AR canvas
    function setupARCanvas() {
      if (!arCanvas) return;
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
    
    // Setup tap to place for camera feed AR
    function setupTapToPlace() {
      if (!arCanvas) return;
      
      arCanvas.addEventListener('click', (event) => {
        if (!isARActive || useCameraFallback) {
          const rect = arCanvas.getBoundingClientRect();
          const x = event.clientX - rect.left;
          const y = event.clientY - rect.top;
          placeModelAt(x, y);
        }
      });
    }
    
    // Place model at coordinates (for camera feed AR)
    function placeModelAt(x, y) {
      if (!modelsContainer) return;
      
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
      
      const modelViewerElement = document.createElement('model-viewer');
      modelViewerElement.setAttribute('src', '${widget.modelUrl}');
      modelViewerElement.setAttribute('alt', '${widget.altText ?? widget.productName ?? '3D Model'}');
      modelViewerElement.setAttribute('interaction-policy', 'none');
      modelViewerElement.setAttribute('shadow-intensity', '1');
      modelViewerElement.setAttribute('exposure', '1');
      modelViewerElement.setAttribute('environment-image', 'neutral');
      modelViewerElement.setAttribute('scale', currentScale + ' ' + currentScale + ' ' + currentScale);
      modelViewerElement.setAttribute('rotation', \`0 \${currentRotation} 0\`);
      modelViewerElement.style.cssText = 'width: 100%; height: 100%; background: transparent; pointer-events: none;';
      
      modelContainer.appendChild(modelViewerElement);
      modelsContainer.appendChild(modelContainer);
      
      placedModels.push({ 
        id: modelId, 
        element: modelContainer, 
        modelViewer: modelViewerElement,
        x: x, 
        y: y 
      });
      
      // Make draggable
      makeModelDraggable(modelContainer, modelId);
      
      showNotification('Model placed! Drag to move.');
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
    
    // Setup drag functionality for AR model (WebXR mode)
    function setupDrag() {
      if (useCameraFallback) {
        // Drag is handled by makeModelDraggable for camera feed
        return;
      }
      
      if (!modelViewer) return;
      
      // In WebXR, dragging is handled by model-viewer's built-in interaction
      modelViewer.setAttribute('interaction-policy', 'allow-when-focused');
      modelViewer.style.cursor = 'grab';
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
        
        // Hide poster/preview
        const poster = document.getElementById('model-poster');
        if (poster) {
          poster.style.display = 'none';
        }
        
        // Remove loading if present
        const loadingDiv = document.getElementById('ar-loading');
        if (loadingDiv && loadingDiv.parentNode) {
          loadingDiv.parentNode.removeChild(loadingDiv);
        }
        
        // Ensure model-viewer is visible and properly sized
        if (modelViewer && !useCameraFallback) {
          modelViewer.style.display = 'block';
          modelViewer.style.visibility = 'visible';
          modelViewer.style.opacity = '1';
          modelViewer.style.width = '100%';
          modelViewer.style.height = '100%';
          modelViewer.style.position = 'relative';
          modelViewer.style.zIndex = '0';
        }
        
        // Show controls
        scaleControl.style.display = 'flex';
        bottomControls.style.display = 'flex';
        
        // Apply initial scale and rotation when AR starts
        setTimeout(() => {
          updateScale(currentScale);
          updateRotation(currentRotation);
          
          // Force model to render
          if (modelViewer && modelViewer.model) {
            console.log('Model is loaded and ready');
          } else {
            console.warn('Model not loaded yet, waiting...');
            modelViewer.addEventListener('load', () => {
              console.log('Model loaded in AR mode');
              updateScale(currentScale);
              updateRotation(currentRotation);
            }, { once: true });
          }
        }, 500);
        
        setupDrag();
        
        // Store AR session
        arSession = modelViewer.arSession;
        
      } else if (event.detail.status === 'session-ended' || event.detail.status === 'not-presenting') {
        isARActive = false;
        container.classList.remove('ar-active');
        
        // Show poster again
        const poster = document.getElementById('model-poster');
        if (poster) {
          poster.style.display = 'flex';
        }
        
        arButton.style.display = 'flex';
        arButton.disabled = false;
        arButton.innerHTML = '<span>📱</span><span>View in AR</span>';
        scaleControl.style.display = 'none';
        bottomControls.style.display = 'none';
        arSession = null;
      }
    });
    
    // Auto-hide poster when model loads (optional - for faster AR entry)
    modelViewer.addEventListener('load', () => {
      console.log('Model loaded, ready for AR');
      // Don't auto-hide, let user click button
    });

    // Go back navigation
    function goBack() {
      // Stop camera feed if active
      if (useCameraFallback && cameraStream) {
        cameraStream.getTracks().forEach(track => track.stop());
        cameraStream = null;
        cameraFeed.style.display = 'none';
        arCanvas.style.display = 'none';
        modelsContainer.style.display = 'none';
        modelViewer.style.display = 'block';
      }
      
      // Exit AR session if active
      if (isARActive) {
        if (modelViewer && modelViewer.exitAR) {
          modelViewer.exitAR();
        }
        if (arSession) {
          arSession.end();
          arSession = null;
        }
        isARActive = false;
        useCameraFallback = false;
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
    
    // Attach event listeners after all functions are defined
    if (arButton) {
      arButton.addEventListener('click', enterAR);
    }
    if (infoBtn) {
      infoBtn.addEventListener('click', toggleInfo);
    }
    if (closeBtn) {
      closeBtn.addEventListener('click', goBack);
    }
    if (cameraBtn) {
      cameraBtn.addEventListener('click', captureScreenshot);
    }
    if (resetBtn) {
      resetBtn.addEventListener('click', resetView);
    }
    if (scaleSlider) {
      scaleSlider.addEventListener('input', (e) => updateScale(e.target.value));
    }
    if (rotateSlider) {
      rotateSlider.addEventListener('input', (e) => updateRotation(e.target.value));
    }
  </script>
</body>
</html>
''';
  }
}
