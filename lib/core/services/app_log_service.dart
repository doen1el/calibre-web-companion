import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class AppLogService {
  AppLogService({this.maxEntries = 1000});

  final int maxEntries;
  final ListQueue<String> _entries = ListQueue<String>();
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void add(String message) {
    if (message.trim().isEmpty) return;

    final timestamp = DateTime.now().toIso8601String();
    _entries.addLast('[$timestamp] $message');

    while (_entries.length > maxEntries) {
      _entries.removeFirst();
    }

    revision.value++;
  }

  void addLines(List<String> lines) {
    for (final line in lines) {
      add(line);
    }
  }

  String exportText() {
    return _entries.join('\n');
  }

  bool get isEmpty => _entries.isEmpty;

  void clear() {
    _entries.clear();
    revision.value++;
  }
}

class AppLogOutput extends LogOutput {
  AppLogOutput(this._appLogService);

  final AppLogService _appLogService;

  @override
  void output(OutputEvent event) {
    _appLogService.addLines(event.lines);
  }
}
