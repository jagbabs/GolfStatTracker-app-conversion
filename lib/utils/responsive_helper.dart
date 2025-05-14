import 'package:flutter/material.dart';

/// A utility class to help with responsive design across different screen sizes.
/// This class provides methods to determine the current device type and size,
/// as well as helper methods for calculating appropriate dimensions.
class ResponsiveHelper {
  /// Device screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Returns true if the screen width is below [mobileBreakpoint]
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Returns true if the screen width is between [mobileBreakpoint] and [tabletBreakpoint]
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Returns true if the screen width is between [tabletBreakpoint] and [desktopBreakpoint]
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Returns true if the screen width is greater than or equal to [desktopBreakpoint]
  static bool isWideDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Returns a value based on the current screen size
  /// 
  /// For example:
  /// ```dart
  /// final padding = ResponsiveHelper.value(
  ///   context,
  ///   mobile: 8.0,
  ///   tablet: 16.0,
  ///   desktop: 24.0,
  /// );
  /// ```
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? wideDesktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else {
      return wideDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Returns a font size based on the current screen size.
  /// This helps maintain readability across different device sizes.
  static double fontSize(
    BuildContext context, {
    required double baseFontSize,
    double? tabletFontSizeIncrease,
    double? desktopFontSizeIncrease,
    double? wideFontSizeIncrease,
  }) {
    if (isMobile(context)) {
      return baseFontSize;
    } else if (isTablet(context)) {
      return baseFontSize + (tabletFontSizeIncrease ?? 2.0);
    } else if (isDesktop(context)) {
      return baseFontSize + (desktopFontSizeIncrease ?? 4.0);
    } else {
      return baseFontSize + (wideFontSizeIncrease ?? 6.0);
    }
  }

  /// Calculates a responsive padding for the current device size
  static EdgeInsets responsivePadding(BuildContext context) {
    return value<EdgeInsets>(
      context,
      mobile: const EdgeInsets.all(8.0),
      tablet: const EdgeInsets.all(16.0),
      desktop: const EdgeInsets.all(24.0),
    );
  }

  /// Returns a responsive width based on the container width
  /// For example, to make a widget take 80% width on mobile,
  /// 60% on tablet, and 40% on desktop:
  /// ```dart
  /// width: ResponsiveHelper.relativeWidth(
  ///   context, 
  ///   mobilePercent: 0.8,
  ///   tabletPercent: 0.6,
  ///   desktopPercent: 0.4,
  /// ),
  /// ```
  static double relativeWidth(
    BuildContext context, {
    required double mobilePercent,
    double? tabletPercent,
    double? desktopPercent,
    double? wideDesktopPercent,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    final percent = value<double>(
      context,
      mobile: mobilePercent,
      tablet: tabletPercent ?? mobilePercent * 0.75,
      desktop: desktopPercent ?? (tabletPercent ?? mobilePercent * 0.75) * 0.75,
      wideDesktop: wideDesktopPercent ?? 
          (desktopPercent ?? 
              (tabletPercent ?? mobilePercent * 0.75) * 0.75) * 0.75,
    );
    
    return screenWidth * percent;
  }

  /// Returns a responsive height based on the screen height
  static double relativeHeight(
    BuildContext context, {
    required double mobilePercent,
    double? tabletPercent,
    double? desktopPercent,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    final percent = value<double>(
      context,
      mobile: mobilePercent,
      tablet: tabletPercent ?? mobilePercent,
      desktop: desktopPercent ?? tabletPercent ?? mobilePercent,
    );
    
    return screenHeight * percent;
  }
}