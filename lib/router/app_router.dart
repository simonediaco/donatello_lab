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
      pageBuilder: (context, state) => NoTransitionPage(
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/recipients',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const RecipientsListScreen(),
      ),
    ),
    // GoRoute(
    //   path: '/recipients/add',
    //   pageBuilder: (context, state) => NoTransitionPage(
    //     child: const AddRecipientScreen(),
    //   ),
    // ),
    GoRoute(
      path: '/generate',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const GiftWizardScreen(),
      ),
    ),
    GoRoute(
      path: '/results',
      pageBuilder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;
        return NoTransitionPage(
          child: GiftResultsScreen(
            recipientName: extras?['recipientName'] ?? '',
            recipientAge: extras?['recipientAge'],
            gifts: extras?['gifts'] ?? [],
          ),
        );
      },
    ),
    GoRoute(
      path: '/saved-gifts',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const SavedGiftsScreen(),
      ),
    ),
  ],
);