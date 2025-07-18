import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_taggy/flutter_taggy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_path_provider/android_path_provider.dart';

class DownloadService {
  static final Dio _dio = Dio();

  static Future<void> downloadFile(
    String url,
    String folderPath,
    String fileName, {
    Function(int, int)? onProgress,
    String? title,
    String? artist,
  }) async {
    try {
      // Для Android 10+ используем SAF или стандартные папки
      if (Platform.isAndroid) {
        await _checkAndroidPermissions();
      }

      final savePath = p.join(folderPath, fileName);
      print('Скачивание началось: $url -> $savePath');

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onProgress,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      print('Файл успешно скачан.');

      // Записываем теги если они указаны
      if (title != null || artist != null) {
        await _setTags(savePath, title, artist);
      }
    } catch (e) {
      print('Ошибка при скачивании: $e');
      rethrow;
    }
  }

  static Future<void> _setTags(
    String filePath,
    String? title,
    String? artist,
  ) async {
    if (!File(filePath).existsSync()) return;

    final tag = Tag(
      tagType: TagType.FilePrimaryType,
      pictures: [],
      trackTitle: title,
      trackArtist: artist,
    );

    await Taggy.writePrimary(path: filePath, tag: tag, keepOthers: true);
  }

  static Future<void> _checkAndroidPermissions() async {
    if (await Permission.storage.isGranted) return;
    
    // Для Android 10+ (API 29+) используем manageExternalStorage
    if (await Permission.manageExternalStorage.isGranted) return;
    
    final status = await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      throw Exception('Требуется разрешение на управление внешним хранилищем');
    }
  }

  // Получение стандартных папок для Android
  static Future<String?> getDownloadsDirectory() async {
    if (!Platform.isAndroid) return null;
    return await AndroidPathProvider.downloadsPath;
  }

  static Future<String?> getMusicDirectory() async {
    if (!Platform.isAndroid) return null;
    return await AndroidPathProvider.musicPath;
  }
}
