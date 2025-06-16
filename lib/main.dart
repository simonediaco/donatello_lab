import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WebView platform based on platform
  if (WebViewPlatform.instance is! AndroidWebViewPlatform &&
      WebViewPlatform.instance is! WebKitWebViewPlatform) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }

  // Temporarily disable Sentry to avoid conflicts
  // await SentryFlutter.init(
  //   (options) {
  //     options.dsn = 'https://8fa0fd6fc32dc7c0098df761d8e2aff3@o4509480427126784.ingest.de.sentry.io/4509480495218768';
  //     options.sendDefaultPii = true;
  //     options.environment = env;
  //     // Disable automatic initialization to prevent zone conflicts
  //     options.autoInitializeNativeSdk = false;
  //   },
  // );

  // Run the app directly without Sentry wrapper
  runApp(
    ProviderScope(
      child: DonatelloLabApp(),
    ),
  );
}