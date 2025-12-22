import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/responsive_helper.dart';

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final logoWidth = isMobile ? 120.0 : (isTablet ? 140.0 : 160.0);
    final logoHeight = isMobile ? 40.0 : (isTablet ? 46.0 : 52.21);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        // Admin Panel Link - Navigate to login
        TextButton.icon(
          onPressed: () {
            context.push('/admin/login');
          },
          icon: const Icon(Icons.admin_panel_settings, size: 18),
          label: const Text('Admin'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }
}
