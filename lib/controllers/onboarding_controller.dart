import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:onboarding_overlay/onboarding_overlay.dart';

class OnboardingController extends GetxController{
  GlobalKey<OnboardingState>? onboardingKey;


@override
void onInit(){
  super.onInit();
  onboardingKey =  GlobalKey<OnboardingState>();

}
  
  List<FocusNode> getFocusNodes(){
    return [
      FocusNode(),
      FocusNode(),
      FocusNode(),
      FocusNode(),
      FocusNode(),

    ];
  }
}