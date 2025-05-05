import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
              fontSize: 30, color: bluePrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Material(
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        // Handle Language click
                      },
                      child: ListTile(
                        leading: Icon(Icons.language),
                        title: Text("Language"),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Handle Privacy Policy click
                      },
                      child: ListTile(
                        leading: Icon(Icons.privacy_tip),
                        title: Text("Privacy Policy"),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Handle Terms of Service click
                      },
                      child: ListTile(
                        leading: Icon(Icons.description),
                        title: Text("Terms of Service"),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Handle About App click
                      },
                      child: ListTile(
                        leading: Icon(Icons.info),
                        title: Text("About App"),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Material(
              borderRadius: BorderRadius.circular(12),
              elevation: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        // Handle Rate Us click
                      },
                      child: ListTile(
                        leading: Icon(Icons.star_rate),
                        title: Text("Rate Us"),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Handle Share with Friends click
                      },
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text("Share with Friends"),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // Handle More Apps click
                      },
                      child: ListTile(
                        leading: Icon(Icons.apps),
                        title: Text("More Apps"),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}