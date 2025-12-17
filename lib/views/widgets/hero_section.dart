import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 24,
      children: [
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              const Text(
                'Experience Our Product in AR',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 40,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Bridge the gap between digital and physical retail with interactive AR billboards that deliver unique product demos in high-traffic areas.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.71,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: ShapeDecoration(
            color: const Color(0xFFED1F24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: InkWell(
            onTap: onExplorePressed,
            child: const Row(
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
                    fontSize: 16,
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
  html.VideoElement? _videoElement;

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
    final baseUrl = html.window.location.origin;
    _videoElement = html.VideoElement()
      ..src = '$baseUrl/assets/img/demo.mp4'
      ..autoplay = false
      ..loop = true
      ..muted = false
      ..setAttribute('playsinline', 'true')
      ..controls = false
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    // Add event listeners separately to avoid scope issues
    _videoElement!.onError.listen((event) {
      print('Video loading error');
    });
    _videoElement!.onLoadedData.listen((event) {
      print('Video loaded successfully');
    });
    _videoElement!.onPlay.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
    });
    _videoElement!.onPause.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
    _videoElement!.onEnded.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId!,
      (int viewId) => _videoElement!,
    );
  }

  void _playVideo() {
    if (_videoElement != null && !_isPlaying) {
      _videoElement!.play();
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
