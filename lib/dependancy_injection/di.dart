import 'package:cash_app/controllers/cart_controller.dart';
import 'package:cash_app/controllers/inventory_controller.dart';
import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/controllers/onboarding_controller.dart';
import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/db/config.dart';
import 'package:get/get.dart';

class DependanctInjection {
  init() {
    //All Dependancies to be enabled here

    //Controllers
    Get.put(PageControllers());
    Get.put(CartController());
    Get.put(OnboardingController());
    Get.put(Config());
    Get.put(MediaController());
    Get.put(InventoryController());

    //
  }
}
