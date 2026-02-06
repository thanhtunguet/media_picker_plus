import 'dart:typed_data';

Future<Uint8List> loadImageBytesFromPath(String imagePath) {
  return Future.error(
    UnsupportedError('Web image loading supports data URLs only.'),
  );
}
