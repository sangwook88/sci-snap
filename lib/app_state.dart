import 'package:flutter/material.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _objectLabel = '';
  String get objectLabel => _objectLabel;
  set objectLabel(String value) {
    _objectLabel = value;
  }

  bool _isFromNotification = false;
  bool get isFromNotification => _isFromNotification;
  set isFromNotification(bool value) {
    _isFromNotification = value;
  }

  DateTime? _chatCreatedTimeUser;
  DateTime? get chatCreatedTimeUser => _chatCreatedTimeUser;
  set chatCreatedTimeUser(DateTime? value) {
    _chatCreatedTimeUser = value;
  }

  DateTime? _chatCreatedTimeSystem;
  DateTime? get chatCreatedTimeSystem => _chatCreatedTimeSystem;
  set chatCreatedTimeSystem(DateTime? value) {
    _chatCreatedTimeSystem = value;
  }
}
