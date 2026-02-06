import 'dart:io';

import 'package:flutter/widgets.dart';

/// IO implementation: loads thumbnail from a file path using [Image.file]
/// with `cacheWidth` for memory efficiency.
Widget buildThumbnailImage(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.file(
    File(path),
    fit: fit,
    cacheWidth: 200,
    errorBuilder: (context, error, stackTrace) {
      return const Center(
          child: Icon(IconData(0xe237, fontFamily: 'MaterialIcons')));
    },
  );
}
