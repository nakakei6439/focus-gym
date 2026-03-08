import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'app/app.dart';
import 'core/models/training_session.dart';
import 'core/notification/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  Hive.registerAdapter(TrainingTypeAdapter());
  Hive.registerAdapter(TrainingSessionAdapter());

  try {
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  runApp(const FocusGymApp());
}
