import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

void GetShowcaseConfig(List<GlobalKey<State<StatefulWidget>>> showcaseList) {
  ShowcaseView.register(
      globalFloatingActionWidget: (context) => FloatingActionWidget(
            left: 20,
            top: 30,
            child: ElevatedButton(
              onPressed: () => ShowcaseView.get().dismiss(),
              style: ElevatedButton.styleFrom(backgroundColor: bluePrimary),
              child: const Text('End', style: TextStyle(color: Colors.white)),
            ),
          ));
  WidgetsBinding.instance.addPostFrameCallback(
      (_) => ShowcaseView.get().startShowCase(showcaseList));
}
