import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: DonatelloLabApp(),
    ),
  );
}