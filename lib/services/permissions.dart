import 'package:hive_flutter/adapters.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> getPermissions() async {
  try {
    final status = await Permission.storage.request();
    if (status.isGranted) {

    } else {
      // Permission denied, handle accordingly
    }
  } catch (e) {
    // Handle any errors that may occur during permission request
  }
}
