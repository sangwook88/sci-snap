// Automatic FlutterFlow imports
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/custom_code/actions/index.dart'; // Imports custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

class NotificationListener extends StatefulWidget {
  const NotificationListener({
    Key? key,
    this.width,
    this.height,
    required this.isTriggered,
    required this.onTriggered,
  }) : super(key: key);

  final double? width;
  final double? height;
  final bool isTriggered;
  final Future<dynamic> Function() onTriggered;

  @override
  _NotificationListenerState createState() => _NotificationListenerState();
}

class _NotificationListenerState extends State<NotificationListener> {
  @override
  void didUpdateWidget(NotificationListener oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isTriggered == false && widget.isTriggered == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTriggered();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
