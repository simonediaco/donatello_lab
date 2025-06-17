import 'package:firebase_analytics/firebase_analytics.dart';


class Analytics {
  static void appOpened() {
    FirebaseAnalytics.instance.logAppOpen();
  }

  static void navigatedTo(String screenName, [Map<String, Object?>? parameters]) {
    FirebaseAnalytics.instance.logScreenView(
      screenName: screenName,
      parameters: parameters,
    );
  }

  // Helper per pulire i path con parametri dinamici
  static String _cleanPath(String path) {
    // Sostituisce ID numerici con placeholder per raggruppare le analytics
    return path
        .replaceAll(RegExp(r'/\d+'), '/{id}')
        .replaceAll(RegExp(r'\?.*'), ''); // Rimuove query parameters
  }

}
