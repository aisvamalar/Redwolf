import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../widgets/simple_ar_viewer.dart';
import '../../services/device_detection_service.dart';
import '../../services/ar_analytics_service.dart';
import '../../services/analytics_service.dart';
import 'ar_view_for_3d_objects.dart';

/// Full-screen AR view screen that shows native AR on mobile and web AR on web
class ARViewScreen extends StatefulWidget {
  final Product product;
  final String modelUrl;

  const ARViewScreen({Key? key, required this.product, required this.modelUrl})
    : super(key: key);

  @override
  State<ARViewScreen> createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _trackARSessionStart();
  }

  @override
  void dispose() {
    _trackARSessionEnd();
    super.dispose();
  }

  Future<void> _trackARSessionStart() async {
    if (widget.product.id == null) return;
    
    // Track AR view in analytics
    final analyticsService = AnalyticsService();
    await analyticsService.trackARView(widget.product.id!);
    
    // Also track in AR analytics service
    await ARAnalyticsService.trackARInteraction(
      eventType: AREventTypes.sessionStart,
      productId: widget.product.id!,
      eventData: {
        'product_name': widget.product.name,
        'model_url': widget.modelUrl,
        'platform': kIsWeb ? 'web' : 'mobile',
      },
    );
  }

  Future<void> _trackARSessionEnd() async {
    if (_sessionStartTime == null || widget.product.id == null) return;
    final duration = DateTime.now().difference(_sessionStartTime!);
    await ARAnalyticsService.trackARInteraction(
      eventType: AREventTypes.sessionEnd,
      productId: widget.product.id!,
      eventData: {
        'session_duration_ms': duration.inMilliseconds,
        'product_name': widget.product.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use native AR for mobile/tablet (iOS/Android)
    if (!kIsWeb) {
      return ArViewFor3dObjects(
        name: widget.product.name,
        model3dUrl: widget.modelUrl,
      );
    }

    // Web platform - use web-based AR viewer
    // Check if device is desktop - if so, show message and go back
    if (DeviceDetectionService.isDesktop(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AR is only available on mobile and tablet devices. Please open this website on your mobile or tablet to experience AR.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFFED1F24),
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });

      // Show loading/error message while navigating back
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFED1F24)),
        ),
      );
    }

    // Web mobile/tablet - use web AR viewer
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // AR Viewer takes full screen
            Positioned.fill(
              child: SimpleARViewer(
                modelUrl: widget.modelUrl,
                altText: widget.product.name,
                productName: widget.product.name,
                onBackPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
