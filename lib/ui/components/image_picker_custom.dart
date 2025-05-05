import 'dart:io';

import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/services/device_properties.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final MediaController mc;
  final TextEditingController imagePath;

  const ImagePickerWidget(
      {required this.mc, required this.imagePath, super.key});

  @override
  _ImagePickerWidgetState createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  XFile? _image;

  Future<void> _pickImage() async {
    final image = await widget.mc.pickImage();
    if (image != null) {
      setState(() {
        _image = image;
        widget.imagePath.text = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _image == null
              ? IconButton(
                  icon: Icon(Icons.add_photo_alternate, color: blueSecondary),
                  onPressed: _pickImage,
                )
              : Image.file(
                  File(_image!.path),
                  width: DeviceProperties().getWidth(context) / 2,
                  height: DeviceProperties().getHeight(context) / 2,
                  fit: BoxFit.cover,
                ),
        ],
      ),
    );
  }
}




class ImagePickerCamera extends StatefulWidget {
  final MediaController mc;
  final TextEditingController imagePath;

  const ImagePickerCamera(
      {required this.mc, required this.imagePath, super.key});

  @override
  _ImagePickerCameraState createState() => _ImagePickerCameraState();
}

class _ImagePickerCameraState extends State<ImagePickerCamera> {
  XFile? _image;

  Future<void> _pickImage() async {
    final image = await widget.mc.takeImageFromCamera();
    if (image != null) {
      setState(() {
        _image = image;
        widget.imagePath.text = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _image == null
              ? IconButton(
                  icon: Icon(Icons.add_photo_alternate, color: blueSecondary),
                  onPressed: _pickImage,
                )
              : Image.file(
                  File(_image!.path),
                  width: DeviceProperties().getWidth(context) / 2,
                  height: DeviceProperties().getHeight(context) / 2,
                  fit: BoxFit.cover,
                ),
        ],
      ),
    );
  }
}
