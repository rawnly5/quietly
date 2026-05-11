import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart' as pp;

class ErrorLogger {
  static final Logger _log = Logger(printer: PrettyPrinter(methodCount: 2));

  static void log(String where, Object e, StackTrace st) {
    _log.e('[$where]', error: e, stackTrace: st);
    _appendFile(where, e, st);
  }

  static Future<void> _appendFile(String where, Object e, StackTrace st) async {
    try {
      final Directory dir = await pp.getApplicationSupportDirectory();
      final File f = File('${dir.path}/quietly_errors.log');
      await f.writeAsString(
        '${DateTime.now().toIso8601String()} [$where] $e\n$st\n---\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }
}
