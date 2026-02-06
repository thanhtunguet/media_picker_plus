import 'package:flutter/widgets.dart';

import 'thumbnail_image_io.dart'
    if (dart.library.html) 'thumbnail_image_web.dart';

/// Cross-platform thumbnail image widget.
///
/// Uses [Image.file] with `cacheWidth` on IO platforms for memory efficiency,
/// and [Image.network] on web for data/blob URL support.
Widget buildThumbnail(String path, {BoxFit fit = BoxFit.cover}) {
  return buildThumbnailImage(path, fit: fit);
}
