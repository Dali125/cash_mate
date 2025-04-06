import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';

Widget buildTextField({
  required TextEditingController controller,
  required String hintText,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: blueSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: blueSecondary),
        ),
      ),
    ),
  );
}
