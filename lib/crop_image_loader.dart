import 'dart:convert';
import 'dart:typed_data';

import 'crop_image_loader_io.dart'
    if (dart.library.html) 'crop_image_loader_web.dart';

Future<Uint8List> loadImageBytes(String imagePath) async {
  if (imagePath.isEmpty) {
    throw ArgumentError('imagePath is empty');
  }

  if (imagePath.startsWith('data:image')) {
    final base64Data = imagePath.split(',').last;
    return base64Decode(base64Data);
  }

  return loadImageBytesFromPath(imagePath);
}
