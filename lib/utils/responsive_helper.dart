import 'package:flutter/material.dart';

/// Helper class for responsive design
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  /// Get adaptive padding based on screen width
  static EdgeInsets getAdaptivePadding(BuildContext context, {bool horizontal = true, bool vertical = true}) {
    final width = MediaQuery.of(context).size.width;
    
    // Base padding that adapts to screen width
    double horizontalPadding = 16.0;
    double verticalPadding = 12.0;
    
    if (width >= 650) {
      horizontalPadding = 24.0;
      verticalPadding = 16.0;
    }
    
    if (width >= 1100) {
      horizontalPadding = 32.0; 
      verticalPadding = 20.0;
    }
    
    return EdgeInsets.symmetric(
      horizontal: horizontal ? horizontalPadding : 0,
      vertical: vertical ? verticalPadding : 0,
    );
  }

  /// Get adaptive card elevation based on device type
  static double getAdaptiveElevation(BuildContext context) {
    if (isMobile(context)) return 2.0;
    if (isTablet(context)) return 3.0;
    return 4.0;
  }

  /// Get adaptive font size based on device type
  static double getAdaptiveFontSize(BuildContext context, double baseFontSize, {
    double mobileReduction = 0.9,
    double tabletIncrease = 1.1,
    double desktopIncrease = 1.2,
  }) {
    if (isMobile(context)) return baseFontSize * mobileReduction;
    if (isTablet(context)) return baseFontSize * tabletIncrease;
    return baseFontSize * desktopIncrease;
  }
}