import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsService {
  static const String _folderKey = 'download_folder';
  static const String _folderUriKey = 'download_folder_uri';

  static Future<void> saveFolderPath(String path, [String? uri]) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_folderKey, path);
    if (uri != null) {
      await prefs.setString(_folderUriKey, uri);
    }
  }

  static Future<String?> getFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_folderKey);
  }

  static Future<String?> getFolderUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_folderUriKey);
  }
}
