import 'package:get/get.dart';

class PaymentController extends GetxController{




  double calculateChange(double total, double amountPaid){

    return amountPaid - total;

  }


}