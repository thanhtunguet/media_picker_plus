import 'package:flutter/widgets.dart';

/// Web implementation: loads thumbnail from a data/blob URL using
/// [Image.network].
Widget buildThumbnailImage(String path, {BoxFit fit = BoxFit.cover}) {
  return Image.network(
    path,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      return const Center(
          child: Icon(IconData(0xe237, fontFamily: 'MaterialIcons')));
    },
  );
}
