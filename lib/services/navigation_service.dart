import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'analytics_service.dart';
import '../models/recipient.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  static GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
  static BuildContext? get currentContext => _navigatorKey.currentContext;

  // Metodo interno per navigare con tracking automatico
  static void _navigateWithTracking(String path, [Object? extra]) {
    if (currentContext == null) return;
    
    // Usa il path direttamente, gestendo solo il caso speciale della home
    String screenName = path == '/' ? 'Home' : path;
    Analytics.navigatedTo(screenName);
    
    if (extra != null) {
      GoRouter.of(currentContext!).go(path, extra: extra);
    } else {
      GoRouter.of(currentContext!).go(path);
    }
  }

  // Metodi di navigazione semplificati
  static void goToHome() => _navigateWithTracking('/home');
  static void goToLogin() => _navigateWithTracking('/login');
  static void goToRegister() => _navigateWithTracking('/register');
  static void goToOnboarding() => _navigateWithTracking('/onboarding');
  static void goToRecipients() => _navigateWithTracking('/recipients');
  static void goToAddRecipient() => _navigateWithTracking('/recipients/add');

  static void goToRecipientDetail(int recipientId) {
    if (currentContext == null) return;
    String path = '/recipients/$recipientId';
    Analytics.navigatedTo(path);
    GoRouter.of(currentContext!).go(path);
  }

  static void goToEditRecipient(int recipientId) {
    if (currentContext == null) return;
    String path = '/recipients/$recipientId/edit';
    Analytics.navigatedTo(path);
    GoRouter.of(currentContext!).go(path);
  }

  static void goToGiftGeneration() => _navigateWithTracking('/generate-gifts');
  static void goToSelectRecipient() => _navigateWithTracking('/select-recipient');
  static void goToGiftWizard() => _navigateWithTracking('/gift-wizard');

  static void goToGiftWizardWithRecipient(Recipient recipient) {
    _navigateWithTracking('/gift-wizard-recipient', recipient);
  }

  static void goToGiftResults({
    required String recipientName,
    int? recipientAge,
    required List<dynamic> gifts,
    Recipient? existingRecipient,
    Map<String, dynamic>? wizardData,
  }) {
    _navigateWithTracking('/results', {
      'recipientName': recipientName,
      'recipientAge': recipientAge,
      'gifts': gifts,
      'existingRecipient': existingRecipient,
      'wizardData': wizardData,
    });
  }

  static void goToSavedGifts() => _navigateWithTracking('/saved-gifts');
  static void goToProfile() => _navigateWithTracking('/profile');

  // Navigation with context (for cases where we need to pass context)
  static void pushToLogin(BuildContext context) {
    Analytics.navigatedTo('/login');
    context.go('/login');
  }

  static void pushToRegister(BuildContext context) {
    Analytics.navigatedTo('/register');
    context.go('/register');
  }

  static void pushToForgotPassword(BuildContext context) {
    Analytics.navigatedTo('/forgot-password');
    context.go('/forgot-password');
  }

  // Utility methods
  static void goBack() {
    if (currentContext != null) {
      GoRouter.of(currentContext!).pop();
    }
  }

  static bool canGoBack() {
    return currentContext != null && GoRouter.of(currentContext!).canPop();
  }

  static void goBackToHome() => goToHome();

  // Replace current route
  static void replaceWithHome() => goToHome();
  static void replaceWithLogin() => goToLogin();
}