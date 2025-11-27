import 'package:flutter/material.dart';

class AppStyles {
  // Spacing
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s48 = 48.0;
  static const double s64 = 64.0;

  // Radius
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r24 = 24.0;
  static const double rFull = 999.0;

  // Shadows
  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppPadding {
  static const EdgeInsets p4 = EdgeInsets.all(4);
  static const EdgeInsets p8 = EdgeInsets.all(8);
  static const EdgeInsets p12 = EdgeInsets.all(12);
  static const EdgeInsets p16 = EdgeInsets.all(16);
  static const EdgeInsets p24 = EdgeInsets.all(24);
  static const EdgeInsets h16 = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets v16 = EdgeInsets.symmetric(vertical: 16);
}

class AppRadius {
  static const Radius r8 = Radius.circular(8);
  static const Radius r12 = Radius.circular(12);
  static const Radius r16 = Radius.circular(16);
  static const Radius r24 = Radius.circular(24);
  static const BorderRadius br16 = BorderRadius.all(r16);
}

class Gap {
  static const Widget w4 = SizedBox(width: 4);
  static const Widget w8 = SizedBox(width: 8);
  static const Widget w12 = SizedBox(width: 12);
  static const Widget w16 = SizedBox(width: 16);
  static const Widget w24 = SizedBox(width: 24);

  static const Widget h4 = SizedBox(height: 4);
  static const Widget h8 = SizedBox(height: 8);
  static const Widget h12 = SizedBox(height: 12);
  static const Widget h16 = SizedBox(height: 16);
  static const Widget h24 = SizedBox(height: 24);
  static const Widget h32 = SizedBox(height: 32);
  static const Widget h48 = SizedBox(height: 48);
}
