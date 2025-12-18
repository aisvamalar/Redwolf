import 'package:flutter/material.dart';
import '../../services/device_detection_service.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = DeviceDetectionService.isMobile(context);
    final logoWidth = isMobile ? 120.0 : 160.0;
    final logoHeight = isMobile ? 40.0 : 52.21;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: logoWidth,
          height: logoHeight,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(),
          child: Image.asset(
            'img/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: logoWidth,
                height: logoHeight,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
