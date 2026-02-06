import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> loadImageBytesFromPath(String imagePath) async {
  final file = File(imagePath);
  return file.readAsBytes();
}
