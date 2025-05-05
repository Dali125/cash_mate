import 'package:cash_app/controllers/page_controller.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/ui/components/button.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TabletRoot extends StatefulWidget {
  const TabletRoot({super.key});

  @override
  State<TabletRoot> createState() => _TabletRootState();
}

class _TabletRootState extends State<TabletRoot> {
  @override
  Widget build(BuildContext context) {
    final pc = Get.find<PageControllers>();
    return Scaffold(
      body: Container(
        
        height: DeviceProperties().getHeight(context),
        width: DeviceProperties().getWidth(context),
        child: Row(
          children: [
            Container(height: DeviceProperties().getHeight(context),
            width: DeviceProperties().getWidth(context) -  DeviceProperties().getWidth(context) /4,

              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Material(
                        elevation: 10,

                        child: Container(height: 70, width: DeviceProperties().getWidth(context ), color: Colors.pink,)),
                  )


                ],
              ),
            ),
            Material(
              elevation: 10,
              child: Container(
                width: DeviceProperties().getWidth(context) /4,
                height: DeviceProperties().getHeight(context),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(

                    children: [
                      Text("Sales Cart", style: TextStyle(color: bluePrimary, fontSize: 36, fontWeight: FontWeight.bold),),

                      Positioned(
                        bottom: 0,

                          child: Material(
                            elevation: 10,
                            shadowColor: bluePrimary,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              decoration: BoxDecoration(
                              
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all()
                                
                              ),
                              height: 150,
                              width: DeviceProperties().getWidth(context) /4.3,
                                                   
                            
                            
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("Total", style: TextStyle(fontSize: 20, ),),
                                  Text("data", style: TextStyle(color: Colors.black87, fontSize: 40, fontWeight: FontWeight.bold),
                                    
                            
                                  )
                                ],
                              )
                            
                            
                            ),
                          ))



                    ],
                  ),
                ),
              
              ),
            ),


          ],
        ),



      )

    );
  }
}
