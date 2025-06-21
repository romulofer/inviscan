import 'package:flutter/material.dart';

class LogUtils {
  static Color getLogColor(String log) {
    if (log.startsWith('[+]')) return Colors.green.shade700;
    if (log.startsWith('[*]')) return Colors.blue.shade700;
    if (log.startsWith('[!]')) return Colors.orange.shade800;
    if (log.startsWith('[-]')) return Colors.red.shade700;
    return Colors.black;
  }
}
