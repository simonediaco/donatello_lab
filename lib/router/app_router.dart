import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/recipients/recipients_list_screen.dart';
import '../screens/recipients/add_recipient_screen.dart';
import '../screens/gift_generation/gift_wizard_screen.dart';
import '../screens/gift_generation/gift_results_screen.dart';
import '../screens/saved_gifts/saved_gifts_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/recipients',
      builder: (context, state) => const RecipientsListScreen(),
    ),
    // GoRoute(
    //   path: '/recipients/add',
    //   builder: (context, state) => const AddRecipientScreen(),
    // ),
    GoRoute(
      path: '/generate',
      builder: (context, state) => const GiftWizardScreen(),
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        return GiftResultsScreen(
          recipientName: extras?['recipientName'] ?? '',
          recipientAge: extras?['recipientAge'],
          gifts: extras?['gifts'] ?? [],
        );
      },
    ),
    GoRoute(
      path: '/saved-gifts',
      builder: (context, state) => const SavedGiftsScreen(),
    ),
  ],
);