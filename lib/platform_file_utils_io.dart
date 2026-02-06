import 'dart:io';

Future<bool> platformPathExists(String path) async {
  if (path.isEmpty) return false;
  if (path.startsWith('data:') || path.startsWith('blob:')) return true;
  return File(path).exists();
}
