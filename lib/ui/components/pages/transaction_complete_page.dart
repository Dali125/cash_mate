import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TransactionCompletePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Transaction Complete',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 16,
              ),
              Text(
                'Transaction recorded Successfully.',
                style: TextStyle(
                    fontSize: 18, decorationStyle: TextDecorationStyle.double),
              ),
              SizedBox(
                height: 24,
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(Colors.blue),
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                ),
                onPressed: () {
                  Get.offAllNamed('/');
                },
                child: Text('Go to Menu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
