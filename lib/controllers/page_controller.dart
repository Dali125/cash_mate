import 'package:get/get.dart';

class PageControllers extends GetxController {
  var currentPage = 0.obs;
  var isFabExpanded = false.obs;

  void changePage(int page) {
    currentPage.value = page;
  }

  void toggleFab() {
    isFabExpanded.value = !isFabExpanded.value;
  }
}
