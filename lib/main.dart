import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'app.dart';

const String env = String.fromEnvironment('ENV', defaultValue: 'development');

Future<void> main() async {
  const devEnv =  'test';
  const prodEnv = 'production';

  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://8fa0fd6fc32dc7c0098df761d8e2aff3@o4509480427126784.ingest.de.sentry.io/4509480495218768';
      options.sendDefaultPii = true;
      options.environment = env;
    },
    appRunner: () => runApp(
      SentryWidget(
        child: ProviderScope(
          child: DonatelloLabApp(),
        ),
      ),
    ),
  );
}

// void main() {
//   runApp(
//     const ProviderScope(
//       child: DonatelloLabApp(),
//     ),
//   );
// }