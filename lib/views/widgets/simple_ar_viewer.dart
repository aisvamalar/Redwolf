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
    .control-button {
      position: absolute;
      background: rgba(128, 128, 128, 0.8);
      color: white;
      border: none;
      width: 44px;
      height: 44px;
      border-radius: 50%;
      font-size: 20px;
      cursor: pointer;
      display: none;
      align-items: center;
      justify-content: center;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
      z-index: 100;
      backdrop-filter: blur(10px);
      transition: all 0.2s ease;
    }
    .control-button:hover {
      background: rgba(128, 128, 128, 1);
      transform: scale(1.1);
    }
    .control-button:active {
      transform: scale(0.95);
    }
    .control-button.visible {
      display: flex;
    }
    .info-button {
      top: 20px;
      left: 20px;
    }
    .close-button {
      top: 20px;
      right: 20px;
    }
    .zoom-in-button {
      top: 80px;
      right: 20px;
    }
    .zoom-controls {
      position: absolute;
      top: 130px;
      right: 20px;
      display: none;
      flex-direction: column;
      align-items: center;
      z-index: 100;
    }
    .zoom-controls.visible {
      display: flex;
    }
    .zoom-slider {
      width: 4px;
      height: 120px;
      background: rgba(255, 255, 255, 0.3);
      border-radius: 2px;
      position: relative;
      margin: 8px 0;
    }
    .zoom-slider-track {
      width: 100%;
      height: 100%;
      position: relative;
    }
    .zoom-slider-handle {
      position: absolute;
      width: 20px;
      height: 20px;
      background: white;
      border-radius: 50%;
      left: 50%;
      transform: translateX(-50%);
      cursor: grab;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
      top: 50%;
      margin-top: -10px;
    }
    .zoom-slider-handle:active {
      cursor: grabbing;
    }
    .zoom-label {
      color: white;
      font-size: 16px;
      font-weight: bold;
      margin: 4px 0;
    }
    .bottom-controls {
      position: absolute;
      bottom: 20px;
      left: 50%;
      transform: translateX(-50%);
      display: none;
      flex-direction: column;
      align-items: center;
      gap: 12px;
      z-index: 100;
    }
    .bottom-controls.visible {
      display: flex;
    }
    .rotate-slider-container {
      display: flex;
      align-items: center;
      gap: 12px;
      background: rgba(0, 0, 0, 0.6);
      padding: 8px 16px;
      border-radius: 20px;
      backdrop-filter: blur(10px);
    }
    .rotate-label {
      color: white;
      font-size: 14px;
      min-width: 50px;
      text-align: center;
    }
    .rotate-slider {
      width: 200px;
      height: 4px;
      background: rgba(255, 255, 255, 0.3);
      border-radius: 2px;
      position: relative;
      cursor: pointer;
    }
    .rotate-slider-handle {
      position: absolute;
      width: 16px;
      height: 16px;
      background: white;
      border-radius: 50%;
      top: 50%;
      transform: translateY(-50%);
      cursor: grab;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
      left: 50%;
    }
    .rotate-slider-handle:active {
      cursor: grabbing;
    }
    .camera-button {
      width: 64px;
      height: 64px;
      background: white;
      border: none;
      border-radius: 50%;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
      transition: all 0.2s ease;
    }
    .camera-button:hover {
      transform: scale(1.1);
    }
    .camera-button:active {
      transform: scale(0.95);
    }
    .reset-view-button {
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 4px;
      background: transparent;
      border: none;
      cursor: pointer;
    }
    .reset-view-icon {
      width: 44px;
      height: 44px;
      background: rgba(128, 128, 128, 0.8);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      backdrop-filter: blur(10px);
      transition: all 0.2s ease;
    }
    .reset-view-icon:hover {
      background: rgba(128, 128, 128, 1);
      transform: scale(1.1);
    }
    .reset-view-label {
      color: white;
      font-size: 12px;
      text-align: center;
    }
    .drag-indicator {
      position: absolute;
      bottom: 120px;
      left: 50%;
      transform: translateX(-50%);
      background: rgba(0, 0, 0, 0.8);
      color: white;
      padding: 8px 16px;
      border-radius: 20px;
      font-size: 14px;
      display: none;
      align-items: center;
      gap: 8px;
      z-index: 100;
      backdrop-filter: blur(10px);
    }
    .drag-indicator.visible {
      display: flex;
    }
    .drag-icon {
      width: 20px;
      height: 20px;
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
      ar-scale="0.1"
      scale="0.1"
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
    
    <!-- Top Controls -->
    <button class="control-button info-button" id="info-button" onclick="showInfo()" title="Information">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"></circle>
        <line x1="12" y1="16" x2="12" y2="12"></line>
        <line x1="12" y1="8" x2="12.01" y2="8"></line>
      </svg>
    </button>
    <button class="control-button close-button" id="close-button" onclick="goBack()" title="Close">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <line x1="18" y1="6" x2="6" y2="18"></line>
        <line x1="6" y1="6" x2="18" y2="18"></line>
      </svg>
    </button>
    
    <!-- Right Side Controls -->
    <button class="control-button zoom-in-button" id="zoom-in-button" onclick="zoomIn()" title="Zoom In">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="11" cy="11" r="8"></circle>
        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
        <line x1="11" y1="8" x2="11" y2="14"></line>
        <line x1="8" y1="11" x2="14" y2="11"></line>
      </svg>
    </button>
    <div class="zoom-controls" id="zoom-controls">
      <div class="zoom-label">+</div>
      <div class="zoom-slider">
        <div class="zoom-slider-track">
          <div class="zoom-slider-handle" id="zoom-handle"></div>
        </div>
      </div>
      <div class="zoom-label">−</div>
    </div>
    
    <!-- Bottom Controls -->
    <div class="bottom-controls" id="bottom-controls">
      <div class="rotate-slider-container">
        <span class="rotate-label" id="rotate-label">0°</span>
        <div class="rotate-slider" id="rotate-slider">
          <div class="rotate-slider-handle" id="rotate-handle"></div>
        </div>
        <span class="rotate-label">360°</span>
      </div>
      <button class="camera-button" id="camera-button" onclick="takeScreenshot()" title="Take Screenshot">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="2">
          <rect x="2" y="7" width="20" height="14" rx="2" ry="2"></rect>
          <circle cx="12" cy="14" r="3"></circle>
          <line x1="8" y1="7" x2="8" y2="5"></line>
          <line x1="16" y1="7" x2="16" y2="5"></line>
        </svg>
      </button>
      <button class="reset-view-button" id="reset-view-button" onclick="resetModel()" title="Reset View">
        <div class="reset-view-icon">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8"></path>
            <path d="M21 3v5h-5"></path>
            <path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16"></path>
            <path d="M3 21v-5h5"></path>
          </svg>
        </div>
        <span class="reset-view-label">Reset view</span>
      </button>
    </div>
    
    <!-- Drag Indicator -->
    <div class="drag-indicator" id="drag-indicator">
      <svg class="drag-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <line x1="8" y1="12" x2="16" y2="12"></line>
        <path d="M12 8l4 4-4 4"></path>
        <path d="M12 16l-4-4 4-4"></path>
      </svg>
      <span>Drag to move</span>
    </div>
    
    <div class="info-text" id="info-text">
      Opening AR view...
    </div>
  </div>

  <script type="module">
    const modelViewer = document.querySelector('#ar-model');
    const infoText = document.getElementById('info-text');
    const infoButton = document.getElementById('info-button');
    const closeButton = document.getElementById('close-button');
    const zoomInButton = document.getElementById('zoom-in-button');
    const zoomControls = document.getElementById('zoom-controls');
    const zoomHandle = document.getElementById('zoom-handle');
    const bottomControls = document.getElementById('bottom-controls');
    const rotateSlider = document.getElementById('rotate-slider');
    const rotateHandle = document.getElementById('rotate-handle');
    const rotateLabel = document.getElementById('rotate-label');
    const cameraButton = document.getElementById('camera-button');
    const resetViewButton = document.getElementById('reset-view-button');
    const dragIndicator = document.getElementById('drag-indicator');
    
    let arAutoTriggered = false;
    let modelLoaded = false;
    let modelLoadError = false;
    let currentScale = 0.1;
    let currentRotation = 0;
    let isDraggingZoom = false;
    let isDraggingRotate = false;

    // Log initial model URL for debugging
    console.log('Model Viewer initialized');
    console.log('Model URL:', modelViewer.src);
    console.log('Model URL attribute:', modelViewer.getAttribute('src'));
    
    // Verify model URL is set
    if (!modelViewer.src || modelViewer.src.trim() === '') {
      console.error('ERROR: Model URL is empty or not set!');
      infoText.textContent = 'Error: Model URL is not set. Please check the configuration.';
      infoText.style.background = 'rgba(239, 68, 68, 0.95)';
      modelLoadError = true;
    }

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

    // Track model loading start
    modelViewer.addEventListener('loadstart', () => {
      console.log('Model loading started...');
      console.log('Loading URL:', modelViewer.src);
      infoText.textContent = 'Loading 3D model...';
      infoText.style.background = 'rgba(0, 0, 0, 0.8)';
    });

    // Track model load progress
    modelViewer.addEventListener('progress', (event) => {
      const progress = event.detail.totalProgress;
      console.log('Model loading progress:', (progress * 100).toFixed(1) + '%');
      if (progress < 1) {
        infoText.textContent = 'Loading model... ' + (progress * 100).toFixed(0) + '%';
      }
    });

    // Track model load success
    modelViewer.addEventListener('load', () => {
      modelLoaded = true;
      modelLoadError = false;
      console.log('Model loaded successfully');
      console.log('Model bounds:', modelViewer.getBoundingBox());
    });

    // Auto-trigger AR when model loads - only on mobile devices
    modelViewer.addEventListener('load', async () => {
      if (arAutoTriggered || modelLoadError) return;
      
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
      
      // Wait a bit to ensure model is fully loaded and check for errors
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Don't activate AR if model failed to load
      if (modelLoadError || !modelLoaded) {
        console.error('Cannot activate AR: Model failed to load');
        return;
      }
      
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
          
          // Hide info text and show all controls after AR activates
          setTimeout(() => {
            infoText.style.display = 'none';
            infoButton.classList.add('visible');
            closeButton.classList.add('visible');
            zoomInButton.classList.add('visible');
            zoomControls.classList.add('visible');
            bottomControls.classList.add('visible');
            dragIndicator.classList.add('visible');
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
        // Show all controls when AR session starts
        infoButton.classList.add('visible');
        closeButton.classList.add('visible');
        zoomInButton.classList.add('visible');
        zoomControls.classList.add('visible');
        bottomControls.classList.add('visible');
        dragIndicator.classList.add('visible');
      } else if (event.detail.status === 'session-ended' || event.detail.status === 'not-presenting') {
        // Hide all controls when AR session ends
        infoButton.classList.remove('visible');
        closeButton.classList.remove('visible');
        zoomInButton.classList.remove('visible');
        zoomControls.classList.remove('visible');
        bottomControls.classList.remove('visible');
        dragIndicator.classList.remove('visible');
        // When AR session ends, go back
        goBack();
      }
    });

    // Reset function to remove/reset the model
    function resetModel() {
      try {
        // Reset scale and rotation
        currentScale = 0.1;
        currentRotation = 0;
        updateScale();
        updateRotation();
        
        // Reset camera orbit
        if (modelViewer.cameraOrbit) {
          modelViewer.cameraOrbit = '0deg 75deg 2.5m';
        }
        
        // Try to reset the model by reloading it
        const currentSrc = modelViewer.src;
        modelViewer.src = '';
        
        // Small delay then reload
        setTimeout(() => {
          modelViewer.src = currentSrc;
          console.log('Model reset');
        }, 100);
      } catch (error) {
        console.error('Error resetting model:', error);
      }
    }

    // Handle model load errors
    modelViewer.addEventListener('error', (event) => {
      console.error('Model load error:', event);
      console.error('Error detail:', event.detail);
      console.error('Error target:', event.target);
      console.error('Model URL:', modelViewer.src);
      
      modelLoadError = true;
      modelLoaded = false;
      
      const errorDetail = event.detail || {};
      const errorType = errorDetail.type || 'unknown';
      const errorSource = errorDetail.sourceError || null;
      
      console.error('Error type:', errorType);
      console.error('Source error:', errorSource);
      
      let errorMessage = 'Error loading 3D model. ';
      
      if (errorType === 'fetchfailure' || errorSource?.message?.includes('CORS') || errorSource?.message?.includes('Failed to fetch')) {
        errorMessage += 'Unable to load the model file. This is likely a CORS (Cross-Origin) issue. ';
        errorMessage += 'Please check: 1) The file URL is correct, 2) CORS is enabled on Supabase storage, 3) The file is publicly accessible. ';
        errorMessage += 'Model URL: ' + modelViewer.src;
        
        // Try to test if URL is accessible
        fetch(modelViewer.src, { method: 'HEAD', mode: 'no-cors' })
          .then(() => {
            console.log('URL appears accessible (no-cors mode)');
          })
          .catch((fetchError) => {
            console.error('URL fetch test failed:', fetchError);
          });
      } else if (errorType === 'parsingfailure' || errorSource?.message?.includes('parse') || errorSource?.message?.includes('format')) {
        errorMessage += 'The model file format is invalid or corrupted. Please check the GLB/GLTF file.';
      } else if (errorSource?.status === 403 || errorSource?.status === 404) {
        errorMessage += 'File not found or access denied (HTTP ' + errorSource.status + '). Please check the file URL.';
      } else if (errorSource?.status) {
        errorMessage += 'HTTP Error ' + errorSource.status + ': Unable to load the model file.';
      } else {
        errorMessage += 'Please check if the file is accessible and the URL is correct. ';
        errorMessage += 'Error details: ' + (errorSource?.message || errorType || 'Unknown error');
      }
      
      infoText.textContent = errorMessage;
      infoText.style.background = 'rgba(239, 68, 68, 0.95)';
      infoText.style.display = 'block';
      
      // Don't try to activate AR if model failed to load
      arAutoTriggered = true; // Prevent AR activation attempts
    });

    // Zoom functions
    function zoomIn() {
      currentScale = Math.min(1.0, currentScale + 0.05);
      updateScale();
    }
    
    function zoomOut() {
      currentScale = Math.max(0.1, currentScale - 0.05);
      updateScale();
    }
    
    // Zoom button: click to zoom in, long press or shift+click to zoom out
    let zoomButtonPressTimer;
    zoomInButton.addEventListener('mousedown', () => {
      zoomButtonPressTimer = setTimeout(() => {
        zoomOut();
      }, 500);
    });
    
    zoomInButton.addEventListener('mouseup', () => {
      clearTimeout(zoomButtonPressTimer);
    });
    
    zoomInButton.addEventListener('click', (e) => {
      if (!e.shiftKey) {
        zoomIn();
      } else {
        zoomOut();
      }
    });
    
    // Touch support for zoom button
    zoomInButton.addEventListener('touchstart', () => {
      zoomButtonPressTimer = setTimeout(() => {
        zoomOut();
      }, 500);
    });
    
    zoomInButton.addEventListener('touchend', () => {
      clearTimeout(zoomButtonPressTimer);
    });
    
    function updateScale() {
      try {
        modelViewer.scale = currentScale.toString();
        modelViewer.arScale = currentScale.toString();
        // Update zoom slider position (0% = bottom, 100% = top)
        const zoomPercent = ((currentScale - 0.1) / 0.9) * 100;
        zoomHandle.style.top = (100 - zoomPercent) + '%';
      } catch (e) {
        console.error('Error updating scale:', e);
      }
    }
    
    // Zoom slider interaction
    zoomHandle.addEventListener('mousedown', (e) => {
      isDraggingZoom = true;
      e.preventDefault();
    });
    
    document.addEventListener('mousemove', (e) => {
      if (isDraggingZoom) {
        const slider = zoomHandle.parentElement.parentElement;
        const rect = slider.getBoundingClientRect();
        const y = e.clientY - rect.top;
        const percent = Math.max(0, Math.min(100, 100 - (y / rect.height * 100)));
        currentScale = 0.1 + (percent / 100) * 0.9;
        updateScale();
      }
    });
    
    document.addEventListener('mouseup', () => {
      isDraggingZoom = false;
    });
    
    // Touch support for zoom slider
    zoomHandle.addEventListener('touchstart', (e) => {
      isDraggingZoom = true;
      e.preventDefault();
    });
    
    document.addEventListener('touchmove', (e) => {
      if (isDraggingZoom && e.touches.length > 0) {
        const slider = zoomHandle.parentElement.parentElement;
        const rect = slider.getBoundingClientRect();
        const y = e.touches[0].clientY - rect.top;
        const percent = Math.max(0, Math.min(100, 100 - (y / rect.height * 100)));
        currentScale = 0.1 + (percent / 100) * 0.9;
        updateScale();
      }
    });
    
    document.addEventListener('touchend', () => {
      isDraggingZoom = false;
    });
    
    // Rotate functions
    function updateRotation() {
      try {
        const radians = (currentRotation * Math.PI) / 180;
        modelViewer.cameraOrbit = currentRotation + 'deg 75deg 2.5m';
        rotateLabel.textContent = Math.round(currentRotation) + '°';
        // Update rotate slider position
        const percent = (currentRotation / 360) * 100;
        rotateHandle.style.left = percent + '%';
      } catch (e) {
        console.error('Error updating rotation:', e);
      }
    }
    
    // Rotate slider interaction
    rotateSlider.addEventListener('click', (e) => {
      const rect = rotateSlider.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const percent = Math.max(0, Math.min(100, (x / rect.width) * 100));
      currentRotation = (percent / 100) * 360;
      updateRotation();
    });
    
    rotateHandle.addEventListener('mousedown', (e) => {
      isDraggingRotate = true;
      e.preventDefault();
    });
    
    document.addEventListener('mousemove', (e) => {
      if (isDraggingRotate) {
        const rect = rotateSlider.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const percent = Math.max(0, Math.min(100, (x / rect.width) * 100));
        currentRotation = (percent / 100) * 360;
        updateRotation();
      }
    });
    
    document.addEventListener('mouseup', () => {
      isDraggingRotate = false;
    });
    
    // Touch support for rotate slider
    rotateHandle.addEventListener('touchstart', (e) => {
      isDraggingRotate = true;
      e.preventDefault();
    });
    
    document.addEventListener('touchmove', (e) => {
      if (isDraggingRotate && e.touches.length > 0) {
        const rect = rotateSlider.getBoundingClientRect();
        const x = e.touches[0].clientX - rect.left;
        const percent = Math.max(0, Math.min(100, (x / rect.width) * 100));
        currentRotation = (percent / 100) * 360;
        updateRotation();
      }
    });
    
    document.addEventListener('touchend', () => {
      isDraggingRotate = false;
    });
    
    // Camera/Screenshot function
    function takeScreenshot() {
      try {
        // Use html2canvas or similar library, or model-viewer's built-in method
        if (modelViewer.toDataURL) {
          const dataUrl = modelViewer.toDataURL();
          const link = document.createElement('a');
          link.download = 'ar-screenshot.png';
          link.href = dataUrl;
          link.click();
        } else {
          // Fallback: Use canvas to capture
          const canvas = document.createElement('canvas');
          canvas.width = window.innerWidth;
          canvas.height = window.innerHeight;
          const ctx = canvas.getContext('2d');
          // Note: This is a simplified version. For full AR capture, you'd need WebXR API
          alert('Screenshot feature requires WebXR support. Please use your device\'s screenshot function.');
        }
      } catch (error) {
        console.error('Error taking screenshot:', error);
        alert('Unable to take screenshot. Please use your device\'s screenshot function.');
      }
    }
    
    // Info function
    function showInfo() {
      const productName = '${widget.productName ?? '3D Model'}';
      alert('Product: ' + productName + '\\n\\nUse the controls to adjust the model:\\n- Zoom: Use the slider or zoom button\\n- Rotate: Use the rotation slider\\n- Reset: Click reset to restore default view\\n- Drag: Move the model in AR view');
    }
    
    // Initialize zoom slider position
    updateScale();
    updateRotation();
    
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
