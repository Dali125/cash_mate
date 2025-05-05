import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class MediaController extends GetxController {
  Future<XFile?> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      // Pick an image.
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      return image;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return null;
    }
  }

  Future<XFile?> takeImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      // Pick an image.
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      return image;
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return null;
    }
  }
}
