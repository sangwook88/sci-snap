import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/supabase/supabase.dart';

String? parseDateFormatYM(DateTime? date) {
  if (date == null) {
    return '날짜 없음';
  }

  final localDate = date.toLocal();

  final DateFormat formatter = DateFormat('yyyy년 M월 d일', 'ko_KR');
  return formatter.format(localDate);
}

String? parseDateFormatHM(DateTime? date) {
  if (date == null) {
    return '날짜 없음';
  }

  final localTime = date.toLocal();

  final DateFormat formatter = DateFormat('a h:mm', 'ko_KR');

  return formatter.format(localTime);
}
