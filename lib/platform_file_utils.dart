import 'platform_file_utils_io.dart'
    if (dart.library.html) 'platform_file_utils_web.dart';

Future<bool> pathExists(String path) {
  return platformPathExists(path);
}
