import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class CrossPlatformImage extends StatelessWidget {
  final File? imageFile;
  final Uint8List? webImage;
  final double height;
  final double width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const CrossPlatformImage({
    super.key,
    this.imageFile,
    this.webImage,
    this.height = 200,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      if (webImage != null) {
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(10),
          child: Image.memory(
            webImage!,
            height: height,
            width: width,
            fit: fit,
          ),
        );
      }
    } else {
      if (imageFile != null) {
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(10),
          child: Image.file(imageFile!, height: height, width: width, fit: fit),
        );
      }
    }

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius ?? BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.add_photo_alternate,
        size: 50,
        color: Colors.grey,
      ),
    );
  }
}
