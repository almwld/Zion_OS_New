import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static Future<String> getAppDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  static Future<String> getCacheDirectory() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  static Future<String> readFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  }

  static Future<void> writeFile(String path, String content) async {
    final file = File(path);
    await file.writeAsString(content);
  }

  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
