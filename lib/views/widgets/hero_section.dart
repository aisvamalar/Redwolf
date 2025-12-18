import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../services/device_detection_service.dart';
import 'hero_section_web_stub.dart'
    if (dart.library.html) 'hero_section_web.dart'
    as web_utils;

class HeroSection extends StatelessWidget {
  final VoidCallback? onExplorePressed;

  const HeroSection({super.key, this.onExplorePressed});

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;

    return isWeb
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 55, child: _buildTextContent(context)),
              const SizedBox(width: 48), // Reduced spacing
              Expanded(
                flex: 38,
                child: SizedBox(
                  height: 264,
                  child: _buildImageContent(context),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextContent(context),
              const SizedBox(height: 24),
              _buildImageContent(context),
            ],
          );
  }

  Widget _buildTextContent(BuildContext context) {
    final isMobile = DeviceDetectionService.isMobile(context);
    final isTablet = DeviceDetectionService.isTablet(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: isMobile ? 16 : 24,
      children: [
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: isMobile ? 12 : 16,
            children: [
              Text(
                'Experience Our Product in AR',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isMobile ? 28 : (isTablet ? 34 : 40),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Bridge the gap between digital and physical retail with interactive AR billboards that deliver unique product demos in high-traffic areas.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: isMobile ? 13 : 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.71,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 24,
            vertical: isMobile ? 12 : 10,
          ),
          decoration: ShapeDecoration(
            color: const Color(0xFFED1F24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: InkWell(
            onTap: onExplorePressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 10,
              children: [
                Text(
                  'Explore products',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 14 : 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.50,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (kIsWeb) {
      return SizedBox(
        width: 312,
        height: 264,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              Positioned(
                left: -3.44, // Adjusted to center the wider video
                top: -106.29,
                child: SizedBox(
                  width: 318.88,
                  height: 475.32,
                  child: _VideoPlayerWidget(),
                ),
              ),
              Positioned(
                left: 133.20,
                top: 104.84,
                child: SizedBox(
                  width: 52.49,
                  height: 52.49,
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
                    children: [
                      Container(
                        width: 52.49,
                        height: 52.49,
                        decoration: ShapeDecoration(
                          color: const Color(0xFFD9D9D9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(45.27),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 13.12,
                        top: 13.12,
                        child: SizedBox(
                          width: 26.25,
                          height: 26.25,
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.black54,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Fallback for non-web platforms
      return Container(
        width: double.infinity,
        height: 264,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(21),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_filled, size: 80, color: Colors.grey),
        ),
      );
    }
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  String? _viewId;
  bool _isPlaying = false;
  dynamic _videoElement;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _viewId = 'video-player-${DateTime.now().millisecondsSinceEpoch}';
      _registerVideoPlayer();
    }
  }

  void _registerVideoPlayer() {
    if (!kIsWeb || _viewId == null) return;

    // Get the base URL for assets
    final baseUrl = web_utils.WebUtils.getBaseUrl();
    _videoElement = web_utils.WebUtils.createVideoElement();
    if (_videoElement == null) return;

    // Try multiple video sources for better compatibility
    _videoElement.src = '$baseUrl/assets/img/demo.mp4';
    _videoElement.autoplay = false;
    _videoElement.loop = true;
    _videoElement.muted = true; // Start muted for better autoplay support
    _videoElement.setAttribute('playsinline', 'true');
    _videoElement.setAttribute('webkit-playsinline', 'true');
    _videoElement.controls = false;
    _videoElement.style.width = '100%';
    _videoElement.style.height = '100%';
    _videoElement.style.objectFit = 'cover';
    _videoElement.style.backgroundColor = '#000000';

    // Preload the video
    _videoElement.setAttribute('preload', 'metadata');

    // Add event listeners separately to avoid scope issues
    _videoElement.onError.listen((event) {
      print('Video loading error: ${event.toString()}');
      print('Video src: ${_videoElement.src}');
    });

    _videoElement.onLoadedData.listen((event) {
      print('Video loaded successfully');
      print('Video duration: ${_videoElement.duration}');
      print(
        'Video dimensions: ${_videoElement.videoWidth}x${_videoElement.videoHeight}',
      );
    });

    _videoElement.onLoadedMetadata.listen((event) {
      print('Video metadata loaded');
    });

    _videoElement.onCanPlay.listen((event) {
      print('Video can start playing');
    });

    _videoElement.onPlay.listen((event) {
      print('Video started playing');
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    });

    _videoElement.onPause.listen((event) {
      print('Video paused');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    _videoElement.onEnded.listen((event) {
      print('Video ended');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    web_utils.WebUtils.registerViewFactory(
      _viewId!,
      (int viewId) => _videoElement,
    );
  }

  void _playVideo() {
    if (_videoElement != null && !_isPlaying) {
      // Unmute when user interacts (required for user-initiated playback)
      _videoElement!.muted = false;
      _videoElement!.play().catchError((error) {
        print('Error playing video: $error');
        // Fallback: try playing muted
        _videoElement!.muted = true;
        return _videoElement!.play();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || _viewId == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _playVideo,
      child: ClipRect(
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            Positioned.fill(child: HtmlElementView(viewType: _viewId!)),
            if (!_isPlaying)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 50,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
