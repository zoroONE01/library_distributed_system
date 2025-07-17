import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:library_distributed_app/app.dart';
import 'package:library_distributed_app/core/utils/logger.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      runApp(const ProviderScope(child: App()));
    },
    (error, stack) {
      logger.e("___App error!!", error: error, stackTrace: stack);
    },
  );
}
