import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class LogService {
  static final LogService _instance = LogService._internal();

  factory LogService() {
    return _instance;
  }

  LogService._internal();

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return File('$path/log_$date.txt');
  }

  Future<void> logToFile(String message) async {
    if (!kDebugMode) return; // Optional: Disable in release mode if desired

    try {
      final file = await _localFile;
      final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      await file.writeAsString('[$timestamp] $message\n', mode: FileMode.append);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to write log to file: $e');
      }
    }
  }

  Future<void> cleanOldLogs() async {
    try {
      final path = await _localPath;
      final dir = Directory(path);
      final List<FileSystemEntity> entities = await dir.list().toList();

      final now = DateTime.now();
      final retentionPeriod = Duration(days: 7);

      for (var entity in entities) {
        if (entity is File && entity.path.contains('log_')) {
          final stat = await entity.stat();
          if (now.difference(stat.modified) > retentionPeriod) {
            await entity.delete();
            if (kDebugMode) {
              print('Deleted old log file: ${entity.path}');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clean old logs: $e');
      }
    }
  }
}
