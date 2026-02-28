import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';

class NkongolePage extends StatelessWidget {
  const NkongolePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nkongole',
          style: TextStyle(
              fontSize: 30, color: bluePrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Text(
          'Coming Soon..',
          style: TextStyle(fontSize: 24, color: bluePrimary),
        ),
      ),
    );
  }
}
