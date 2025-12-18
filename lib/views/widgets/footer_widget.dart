import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'footer_widget_stub.dart'
    if (dart.library.html) 'footer_widget_web.dart' as web_utils;

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  void _openRuditechWebsite() {
    if (kIsWeb) {
      web_utils.openRuditechWebsite();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openRuditechWebsite,
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Built by',
                style: TextStyle(
                  color: Color(0xFFBABABA),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const TextSpan(
                text: ' ',
                style: TextStyle(
                  color: Color(0xFF5D8BFF),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
              const TextSpan(
                text: 'Ruditech',
                style: TextStyle(
                  color: Color(0xFF5D8BFF),
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

