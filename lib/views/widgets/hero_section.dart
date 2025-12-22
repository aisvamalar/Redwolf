import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../utils/responsive_helper.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback? onExplorePressed;

  const HeroSection({super.key, this.onExplorePressed});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 55, child: _buildTextContent(context)),
              SizedBox(width: isTablet ? 32 : 48),
              Expanded(
                flex: 38,
                child: SizedBox(
                  height: isTablet ? 220 : 264,
                  child: _buildImageContent(context),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextContent(context),
              SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(
                  context,
                  mobile: 20,
                  tablet: 24,
                  desktop: 24,
                ),
              ),
              _buildImageContent(context),
            ],
          );
  }

  Widget _buildTextContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
              ),
              Text(
                'Experience Our Product in AR',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 28,
                    tablet: 34,
                    desktop: 40,
                  ),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(
                height: ResponsiveHelper.getResponsiveSpacing(
                  context,
                  mobile: 12,
                  tablet: 14,
                  desktop: 16,
                ),
              ),
              Text(
                'Bridge the gap between digital and physical retail with interactive AR billboards that deliver unique product demos in high-traffic areas.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(
                    context,
                    mobile: 13,
                    tablet: 14,
                    desktop: 14,
                  ),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.71,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: ResponsiveHelper.getResponsiveSpacing(
            context,
            mobile: 16,
            tablet: 20,
            desktop: 24,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 20,
              tablet: 22,
              desktop: 24,
            ),
            vertical: ResponsiveHelper.getResponsiveSpacing(
              context,
              mobile: 12,
              tablet: 10,
              desktop: 10,
            ),
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
              children: [
                Text(
                  'Explore products',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.getResponsiveFontSize(
                      context,
                      mobile: 14,
                      tablet: 15,
                      desktop: 16,
                    ),
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
    final isDesktop = ResponsiveHelper.isDesktop(context);

    // Only show image for desktop/web view, hide for mobile and tablet
    if (kIsWeb && isDesktop) {
      final width = 312.0;
      final height = 264.0;

      return SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(21),
          child: Image.asset(
            'img/demo.png',
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Hide for mobile and tablet - return empty container
      return const SizedBox.shrink();
    }
  }
}

