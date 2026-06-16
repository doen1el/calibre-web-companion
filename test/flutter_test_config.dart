import 'dart:async';

import 'package:logger/logger.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Logger.level = Level.off;
  await testMain();
}
