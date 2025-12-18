import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// AR plugin imports (mobile only - will fail on web, but code checks kIsWeb first)
import 'package:ar_flutter_plugin_engine/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_engine/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_engine/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin_engine/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_engine/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_engine/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_engine/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_engine/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vectorMath64;
import 'package:permission_handler/permission_handler.dart';

class ArViewFor3dObjects extends StatefulWidget {
  final String name;
  final String model3dUrl;

  const ArViewFor3dObjects({
    super.key,
    required this.name,
    required this.model3dUrl,
  });

  @override
  State<ArViewFor3dObjects> createState() => _ArViewFor3dObjectsState();
}

class _ArViewFor3dObjectsState extends State<ArViewFor3dObjects> {
  ARSessionManager? sessionManagerAR;
  ARObjectManager? objectManagerAR;
  ARAnchorManager? anchorManagerAR;
  List<ARNode> allNodesList = [];
  List<ARAnchor> allAnchors = [];
  bool isLoading = true;
  bool hasPlacedObject = false;
  bool arInitializationFailed = false;
  String? arErrorMessage;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool isDownloading = false;
  double currentScale = 0.62;
  double currentRotation = 0.0;
  double zoomLevel = 0.5;

  createARView(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager locationManagerAR,
  ) {
    try {
      sessionManagerAR = arSessionManager;
      objectManagerAR = arObjectManager;
      anchorManagerAR = arAnchorManager;

      sessionManagerAR!.onInitialize(
        handleRotation: true,
        handlePans: true,
        showWorldOrigin: true,
        showFeaturePoints: false,
        showPlanes: true,
      );

      objectManagerAR!.onInitialize();
      sessionManagerAR!.onPlaneOrPointTap = detectPlaneAndLetUserTap;
      objectManagerAR!.onPanStart = duringOnPanStarted;
      objectManagerAR!.onPanChange = duringOnPanChanged;
      objectManagerAR!.onPanEnd = duringOnPanEnded;
      objectManagerAR!.onRotationStart = duringOnRotationStarted;
      objectManagerAR!.onRotationChange = duringOnRotationChanged;
      objectManagerAR!.onRotationEnd = duringOnRotationEnded;

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !arInitializationFailed) {
          setState(() {
            isLoading = false;
          });
        }
      });
    } catch (e) {
      print("AR Initialization Error: $e");
      if (mounted) {
        setState(() {
          arInitializationFailed = true;
          arErrorMessage = "Failed to initialize AR: $e";
          isLoading = false;
        });
      }
    }
  }

  duringOnPanStarted(String object3DNodeName) {
    print("Panning Node Started = $object3DNodeName");
  }

  duringOnPanChanged(String object3DNodeName) {
    print("Panning Node Continued = $object3DNodeName");
  }

  duringOnPanEnded(String object3DNodeName, Matrix4 transformMatrix4) {
    print("Panning Node Ended = $object3DNodeName");
  }

  duringOnRotationStarted(String object3DNodeName) {
    print("Rotating Node Started = $object3DNodeName");
  }

  duringOnRotationChanged(String object3DNodeName) {
    print("Rotating Node Changed = $object3DNodeName");
  }

  duringOnRotationEnded(String object3DNodeName, Matrix4 transformMatrix4) {
    print("Rotating Node Ended = $object3DNodeName");
  }

  Future<void> detectPlaneAndLetUserTap(
    List<ARHitTestResult> hitTapResultsList,
  ) async {
    try {
      var userHitTapResultsList = hitTapResultsList.firstWhere(
        (ARHitTestResult userHitPoint) =>
            userHitPoint.type == ARHitTestResultType.plane,
      );

      setState(() {
        hasPlacedObject = true;
      });

      var planeARAnchor = ARPlaneAnchor(
        transformation: userHitTapResultsList.worldTransform,
      );

      bool? anchorAdded = await anchorManagerAR!.addAnchor(planeARAnchor);

      if (anchorAdded == true) {
        allAnchors.add(planeARAnchor);

        var object3DNewNode = ARNode(
          type: NodeType.webGLB,
          uri: widget.model3dUrl,
          scale: vectorMath64.Vector3(currentScale, currentScale, currentScale),
          position: vectorMath64.Vector3(0, 0, 0),
          rotation: vectorMath64.Vector4(1, 0, 0, 0),
        );

        bool? addARNodeToAnchor = await objectManagerAR!.addNode(
          object3DNewNode,
          planeAnchor: planeARAnchor,
        );

        if (addARNodeToAnchor == true) {
          allNodesList.add(object3DNewNode);
          _showSuccessSnackbar();
        } else {
          sessionManagerAR!.onError("Node to Anchor attachment Failed");
          _showErrorSnackbar("Failed to attach 3D model");
        }
      } else {
        sessionManagerAR!.onError(" Failed. Anchor can not be added");
        _showErrorSnackbar("Failed to add anchor");
      }
    } catch (e) {
      print("Error in hit test: $e");
      _showErrorSnackbar("Please scan the area and try again");
    }
  }

  void _showSuccessSnackbar([String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? "${widget.name} placed successfully!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> removeEvery3DObjects() async {
    setState(() {
      hasPlacedObject = false;
    });

    allAnchors.forEach((each3dObject) {
      anchorManagerAR!.removeAnchor(each3dObject);
    });
    allAnchors = [];
    allNodesList = [];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("All objects removed"),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    if (!kIsWeb && sessionManagerAR != null) {
      sessionManagerAR!.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print platform info
    print("AR View - kIsWeb: $kIsWeb, Platform: ${Platform.operatingSystem}");

    // Web platform fallback
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.name,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.view_in_ar, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 24),
                const Text(
                  'AR View Not Available on Web',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Augmented Reality functionality requires native device capabilities and is only available on mobile devices (iOS and Android).',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Please use the mobile app to view products in AR',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Mobile platform - AR view
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 24,
            ),
          ),
          onPressed: () {
            _showHelpDialog();
          },
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 24),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: Stack(
          children: [
            // AR View or Error Message
            if (!arInitializationFailed)
              ARView(
                planeDetectionConfig:
                    PlaneDetectionConfig.horizontalAndVertical,
                onARViewCreated: createARView,
              )
            else
              Container(
                color: Colors.black,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'AR Not Available',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          arErrorMessage ??
                              'AR requires a physical device with camera and motion sensors. Emulators do not support AR functionality.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[300],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Loading indicator
            if (isLoading && !arInitializationFailed)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        "Initializing AR...",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // Instructions overlay when AR is ready but no object placed
            if (!isLoading && !hasPlacedObject)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, color: Colors.white, size: 32),
                      SizedBox(height: 8),
                      Text(
                        "Tap on a surface to place object",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            // Zoom controls on the right side
            if (hasPlacedObject)
              Positioned(
                right: 16,
                top: MediaQuery.of(context).size.height * 0.25,
                child: Column(
                  children: [
                    // Zoom in button
                    GestureDetector(
                      onTap: () => _zoomIn(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Plus button
                    GestureDetector(
                      onTap: () => _increaseScale(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Zoom slider
                    Container(
                      height: 150,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 20,
                            ),
                          ),
                          child: Slider(
                            value: zoomLevel,
                            min: 0.0,
                            max: 1.0,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white.withOpacity(0.3),
                            onChanged: (value) {
                              setState(() {
                                zoomLevel = value;
                                _updateObjectScale(0.3 + (value * 1.2));
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Minus button
                    GestureDetector(
                      onTap: () => _decreaseScale(),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Drag to move instruction
            if (hasPlacedObject && !isLoading)
              Positioned(
                bottom: 200,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_with, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Drag to move",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Rotation control at the bottom
            if (hasPlacedObject)
              Positioned(
                bottom: 120,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    const Text(
                      "Rotate",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 3.0,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          "0°",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 24,
                              ),
                            ),
                            child: Slider(
                              value: currentRotation,
                              min: 0,
                              max: 360,
                              divisions: 72,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withOpacity(0.3),
                              onChanged: (value) {
                                setState(() {
                                  currentRotation = value;
                                });
                                _updateObjectRotation(value);
                              },
                            ),
                          ),
                        ),
                        const Text(
                          "360°",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Bottom control buttons
            if (hasPlacedObject)
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Camera button
                    GestureDetector(
                      onTap: isDownloading ? null : _downloadScreenshot,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade400,
                            width: 3,
                          ),
                        ),
                        child: isDownloading
                            ? const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: Colors.grey,
                                size: 28,
                              ),
                      ),
                    ),
                    // Reset view button
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _resetView,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Reset view",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("AR View Help"),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• Move your phone to scan the environment"),
              SizedBox(height: 8),
              Text("• Tap on a detected surface to place the object"),
              SizedBox(height: 8),
              Text("• Use zoom slider to resize the object"),
              SizedBox(height: 8),
              Text("• Drag to move the object"),
              SizedBox(height: 8),
              Text("• Use rotation slider to rotate 360°"),
              SizedBox(height: 8),
              Text("• Press camera button to capture screenshot"),
              SizedBox(height: 8),
              Text("• Press 'Reset view' to reset controls"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Got it"),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Future<void> _downloadScreenshot() async {
    if (!hasPlacedObject) {
      _showErrorSnackbar("Please place an object first");
      return;
    }

    setState(() {
      isDownloading = true;
    });

    try {
      // Request storage permission
      PermissionStatus status;
      if (Platform.isAndroid) {
        if (await Permission.photos.isGranted ||
            await Permission.storage.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.photos.request();
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        }
      } else {
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        setState(() {
          isDownloading = false;
        });
        _showErrorSnackbar("Storage permission is required to save images");
        return;
      }

      // Capture screenshot using RepaintBoundary
      final RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        setState(() {
          isDownloading = false;
        });
        _showErrorSnackbar("Failed to capture screenshot");
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'AR_${widget.name.replaceAll(' ', '_')}_$timestamp.png';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      setState(() {
        isDownloading = false;
      });

      _showSuccessSnackbar("Screenshot saved successfully!");

      // Show dialog with file location
      _showSaveLocationDialog(filePath);
    } catch (e) {
      setState(() {
        isDownloading = false;
      });
      print("Error saving screenshot: $e");
      _showErrorSnackbar("Error saving image: ${e.toString()}");
    }
  }

  void _showSaveLocationDialog(String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Image Saved Successfully!"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Your AR screenshot has been saved to:"),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  filePath,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "You can find this file in your device's file manager under the app's documents folder.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  void _zoomIn() {
    setState(() {
      zoomLevel = (zoomLevel + 0.1).clamp(0.0, 1.0);
      _updateObjectScale(0.3 + (zoomLevel * 1.2));
    });
  }

  void _increaseScale() {
    setState(() {
      currentScale = (currentScale + 0.1).clamp(0.1, 2.0);
      _updateObjectScale(currentScale);
    });
  }

  void _decreaseScale() {
    setState(() {
      currentScale = (currentScale - 0.1).clamp(0.1, 2.0);
      _updateObjectScale(currentScale);
    });
  }

  void _updateObjectScale(double newScale) {
    if (allNodesList.isNotEmpty) {
      setState(() {
        currentScale = newScale;
      });
      for (var node in allNodesList) {
        // Update node scale by modifying the node's scale property
        node.scale = vectorMath64.Vector3(newScale, newScale, newScale);
      }
    }
  }

  void _updateObjectRotation(double degrees) {
    if (allNodesList.isNotEmpty) {
      double radians = degrees * (3.14159 / 180.0);
      for (var node in allNodesList) {
        // Create a rotation matrix for Y-axis rotation
        final rotationMatrix = vectorMath64.Matrix3.rotationY(radians);
        // Update the node's rotation property
        node.rotation = rotationMatrix;
      }
    }
  }

  void _resetView() {
    setState(() {
      currentRotation = 0.0;
      zoomLevel = 0.5;
      currentScale = 0.62;
    });
    _updateObjectRotation(0.0);
    _updateObjectScale(0.62);
    _showSuccessSnackbar("View reset to default");
  }
}
