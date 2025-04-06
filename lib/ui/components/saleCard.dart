import 'package:flutter/material.dart';

import '../../services/device_properties.dart';
import '../../utils/color.dart';

/// **Reusable Function for Sales Cards**
Widget buildSalesCard(
  BuildContext context, {
  required String title,
  required String data,
  required double fontSize,
  required Widget trailing,
  double heightFactor = 7, // Default height factor
  Color backgroundColor = Colors.white, // Default background color
}) {
  return Material(
    color: backgroundColor,
    borderOnForeground: true,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      height: DeviceProperties().getHeight(context) / heightFactor,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: ColorScheme.fromSeed(seedColor: bluePrimary)
                .onPrimaryFixedVariant),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ColorScheme.fromSeed(seedColor: bluePrimary)
                  .onPrimaryContainer),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              data,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
