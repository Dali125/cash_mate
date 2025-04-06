import 'package:cash_app/services/device_properties.dart';
import 'package:flutter/material.dart';

class Button extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final String text;
  final VoidCallback onPressed;
  const Button(
      {super.key,
      required this.width,
      required this.height,
      required this.color,
      required this.text,
      required this.onPressed});

  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: height,
          width: DeviceProperties().getWidth(context),
          color: color,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
