import 'package:donatello_lab/screens/gift_generation/generate_screen.dart';
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
import '../screens/recipients/recipient_detail_screen.dart'; // Import the detail screen
import '../screens/recipients/edit_recipient_screen.dart'; // Import the edit screen
import '../screens/gift_generation/gift_intro_screen.dart';

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
      routes: [
        GoRoute(
          path: 'add',
          pageBuilder: (context, state) => NoTransitionPage(
            child: const AddRecipientScreen(),
          ),
        ),
        GoRoute(
          path: ':id',
          pageBuilder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return NoTransitionPage(child: RecipientDetailScreen(recipientId: id));
          },
          routes: [
            GoRoute(
              path: 'edit',
              pageBuilder: (context, state) {
                final id = int.parse(state.pathParameters['id']!);
                return NoTransitionPage(child: EditRecipientScreen(recipientId: id));
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/generate-gifts',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const GenerateScreen(),
      ),
    ),
    GoRoute(
      path: '/gift-wizard',
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