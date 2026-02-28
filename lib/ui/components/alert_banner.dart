import 'package:flutter/material.dart';

Widget alertBanner(String message, Color borderColor, Color backgroundColor,
    double borderRadius, double alertHeight, double alertWidth, IconData icon) {
  return Container(
    width: alertWidth,
    decoration: BoxDecoration(
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(borderRadius),
      color: backgroundColor,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: borderColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
