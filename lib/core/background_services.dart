import 'package:flutter_background/flutter_background.dart';

Future<void> enableBackgroundMode() async {
  const androidConfig = FlutterBackgroundAndroidConfig(
    notificationTitle: "Grabando audio",
    notificationText: "Tu grabación está en curso.",
    notificationImportance: AndroidNotificationImportance.normal,
  );

  bool success = await FlutterBackground.initialize(
    androidConfig: androidConfig,
  );
  if (success) {
    FlutterBackground.enableBackgroundExecution();
  }
}
