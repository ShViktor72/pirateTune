import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_taggy/flutter_taggy.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DownloadService {
  static final Dio _dio = Dio();

  /// Скачать файл и записать теги (если указаны)
  static Future<void> downloadFile(
    String url,
    String folderPath,
    String fileName, {
    Function(int, int)? onProgress,
    String? title,
    String? artist,
  }) async {
    await _checkStoragePermission();
    final savePath = p.join(folderPath, fileName);

    try {
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

      // Читать теги перед записью
      // await _readTags(savePath, label: 'До записи');

      // Если есть теги — записываем
      if (title != null || artist != null) {
        await _setTags(savePath, title, artist);
      }

      // Читать теги после записи
      // await _readTags(savePath, label: 'После записи');
    } catch (e) {
      print('Ошибка при скачивании: $e');
      rethrow;
    }
  }

  /// Записать теги в файл
  static Future<void> _setTags(
    String filePath,
    String? title,
    String? artist,
  ) async {
    if (!File(filePath).existsSync()) {
      print('Файл не найден для записи тегов: $filePath');
      return;
    }

    final tag = Tag(
      tagType: TagType.FilePrimaryType,
      pictures: [],
      trackTitle: title,
      trackArtist: artist,
    );

    print('Запись тегов: title="$title", artist="$artist"');

    await Taggy.writePrimary(path: filePath, tag: tag, keepOthers: true);

    print('Теги успешно записаны.');
  }

  /// Проверка и запрос разрешений
  static Future<void> _checkStoragePermission() async {
    if (!Platform.isAndroid) return;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      // Android 13+: используем доступ к медиафайлам
      final status = await Permission.audio.request();
      if (!status.isGranted) {
        throw Exception(
          'Нет разрешения на доступ к аудиофайлам (READ_MEDIA_AUDIO)',
        );
      }
    } else {
      // Android 12 и ниже: обычный доступ к хранилищу
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception(
          'Нет разрешения на доступ к хранилищу (READ/WRITE_EXTERNAL_STORAGE)',
        );
      }
    }
  }
}
