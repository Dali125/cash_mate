import 'package:get/get.dart';

class PaymentController extends GetxController {
  double calculateChange(double total, double amountPaid) {
    double change = amountPaid - total;
    if (change < 0) {
      return 0.0;
    }
    return change.toDouble();
  }
}
