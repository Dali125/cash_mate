import 'package:flutter/material.dart';

class DeviceProperties {
  double getHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  double getWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 891;
  }

  bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width > 1200;
  }
}
