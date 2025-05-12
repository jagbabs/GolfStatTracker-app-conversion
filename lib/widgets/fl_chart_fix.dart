import 'package:flutter/material.dart';

// This is a patch to fix the MediaQuery.boldTextOverride issue in fl_chart
// The fl_chart package uses this method which doesn't exist in our Flutter version
class FlChartFix {
  static bool isBoldTextOverride(BuildContext context) {
    // Just return false since we don't need bold text override
    return false;
  }
}