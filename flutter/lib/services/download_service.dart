import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_taggy/flutter_taggy.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:permission_handler/permission_handler.dart';

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
      await _readTags(savePath, label: 'До записи');

      // Если есть теги — записываем
      if (title != null || artist != null) {
        await _setTags(savePath, title, artist);
      }

      // Читать теги после записи
      await _readTags(savePath, label: 'После записи');

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

    await Taggy.writePrimary(
      path: filePath,
      tag: tag,
      keepOthers: true,
    );

    print('Теги успешно записаны.');
  }

  /// Прочитать теги с помощью flutter_media_metadata
  static Future<void> _readTags(String filePath, {String? label}) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('Файл не найден для чтения тегов: $filePath');
      return;
    }

    final metadataRetriever = MetadataRetriever();
    final metadata = await MetadataRetriever.fromFile(file);

    print('Теги $label:');
    print('  Название: ${metadata.trackName}');
    print('  Артист:   ${metadata.trackArtistNames?.join(", ")}');
    print('  Альбом:   ${metadata.albumName}');
    print('  Год:      ${metadata.year}');
  }

  /// Проверка и запрос разрешений
  static Future<void> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        final result = await Permission.manageExternalStorage.request();
        if (!result.isGranted) {
          throw Exception('Разрешение MANAGE_EXTERNAL_STORAGE не получено');
        }
      }
    }
  }
}
