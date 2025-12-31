import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
        // Logo
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

        // Contact Us Button
        Container(
          constraints: BoxConstraints(
            minWidth: isMobile ? 100.0 : 130.0,
          ),
          width: isMobile ? null : 130.0,
          height: isMobile ? null : 40.0,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ElevatedButton.icon(
            onPressed: () async {
              const whatsappUrl = 'https://wa.me/916369869996';
              try {
                final uri = Uri.parse(whatsappUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not open WhatsApp. Please install WhatsApp or try again.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening WhatsApp: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: FaIcon(
              FontAwesomeIcons.whatsapp,
              size: isMobile ? 12.0 : 18.0,
              color: Colors.white,
            ),
            label: Text(
              'Contact Us',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 10.0 : 14.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,

              // ✅ INCREASED MOBILE PADDING
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 18.0 : 16.0,
                vertical: isMobile ? 12.0 : 8.0,
                    ),

              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
