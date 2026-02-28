import 'dart:io';

import 'package:cash_app/controllers/media_controller.dart';
import 'package:cash_app/utils/color.dart';
import 'package:flutter/material.dart';

Widget imageSelector(TextEditingController imagePath, StateSetter setState,
    {required MediaController mc}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'hero-new-item-image',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 160,
              width: double.infinity,
              color: Colors.white,
              child: imagePath.text.isEmpty
                  ? Icon(Icons.image_outlined,
                      size: 64, color: Colors.grey.shade400)
                  : Image.file(
                      File(imagePath.text),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: Colors.redAccent),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                IconButton(
                  icon:
                      Icon(Icons.photo_library, color: blueSecondary, size: 32),
                  onPressed: () async {
                    final image = await mc.pickImage();
                    if (image != null) {
                      setState(() {
                        imagePath.text = image.path;
                      });
                    }
                  },
                ),
                Text('Gallery',
                    style: TextStyle(fontSize: 12, color: Colors.black)),
              ],
            ),
            const SizedBox(width: 32),
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.camera_alt, color: blueSecondary, size: 32),
                  onPressed: () async {
                    final image = await mc.takeImageFromCamera();
                    if (image != null) {
                      setState(() {
                        imagePath.text = image.path;
                      });
                    }
                  },
                ),
                Text('Camera',
                    style: TextStyle(fontSize: 12, color: Colors.black)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          imagePath.text.isEmpty
              ? 'Choose image from gallery or take a photo'
              : 'Image selected',
          style: TextStyle(
              fontSize: 12,
              color: imagePath.text.isEmpty ? Colors.black : Colors.green),
        ),
      ],
    ),
  );
}
