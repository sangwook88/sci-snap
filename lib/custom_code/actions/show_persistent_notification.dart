// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

Future showPersistentNotification() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await _notifications.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      FFAppState().update(() {
        FFAppState().isFromNotification = true;
      });
    },
  );

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'scisnap_persistent_channel',
    'Sci-Snap 상주 알림',
    channelDescription: '앱 빠른 실행을 위해 알림창에 고정됩니다.',
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
    showWhen: false,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );

  await _notifications.show(
    id: 888,
    title: 'Sci-Snap 탐사 모드 가동 중',
    body: '탭하여 즉시 관찰을 시작하세요.',
    notificationDetails: platformDetails,
  );
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
