import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Roboto';

  // Generous base sizes for tablet readability at arm's length
  static const TextStyle displayLg = TextStyle(fontSize: 34, fontWeight: FontWeight.bold, height: 1.2);
  static const TextStyle displayMd = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2);

  static const TextStyle headingLg = TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle headingMd = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.3);
  static const TextStyle headingSm = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3);

  static const TextStyle bodyLg = TextStyle(fontSize: 17, fontWeight: FontWeight.normal, height: 1.5);
  static const TextStyle bodyMd = TextStyle(fontSize: 15, fontWeight: FontWeight.normal, height: 1.5);
  static const TextStyle bodySm = TextStyle(fontSize: 13, fontWeight: FontWeight.normal, height: 1.5);

  // Minimum readable size — never go below this on tablet UI
  static const double minFontSize = 13.0;

  static const TextStyle label = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);
  static const TextStyle caption = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.4);
  static const TextStyle buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.0);
}
