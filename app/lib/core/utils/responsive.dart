import 'package:flutter/widgets.dart';
import 'package:mindflow/core/constants/app_constants.dart';

/// Classifies screen width into device classes. Deliberately width-based
/// (never `Platform.isX`) so Windows/Web desktop widths automatically get
/// correct layouts once those targets are added, with zero extra code.
enum DeviceClass { phone, tablet, desktop }

class Responsive {
  Responsive._();

  static DeviceClass classify(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppConstants.desktopBreakpoint) return DeviceClass.desktop;
    if (width >= AppConstants.tabletBreakpoint) return DeviceClass.tablet;
    return DeviceClass.phone;
  }

  static bool isPhone(BuildContext context) => classify(context) == DeviceClass.phone;
  static bool isTablet(BuildContext context) => classify(context) == DeviceClass.tablet;
  static bool isDesktop(BuildContext context) => classify(context) == DeviceClass.desktop;

  static T value<T>(BuildContext context, {required T phone, T? tablet, T? desktop}) {
    switch (classify(context)) {
      case DeviceClass.desktop:
        return desktop ?? tablet ?? phone;
      case DeviceClass.tablet:
        return tablet ?? phone;
      case DeviceClass.phone:
        return phone;
    }
  }
}
