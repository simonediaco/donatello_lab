import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/recipients/recipients_list_screen.dart';
import '../screens/recipients/add_recipient_screen.dart';
import '../screens/recipients/edit_recipient_screen.dart';
import '../screens/recipients/recipient_detail_screen.dart';
import '../screens/gift_generation/gift_intro_screen.dart';
import '../screens/gift_generation/gift_wizard_screen.dart';
import '../screens/gift_generation/gift_wizard_recipient_screen.dart';
import '../screens/gift_generation/gift_recipient_selection_screen.dart';
import '../screens/gift_generation/gift_loading_screen.dart';
import '../screens/gift_generation/gift_results_screen.dart';
import '../screens/saved_gifts/saved_gifts_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../models/recipient.dart';
import '../models/gift.dart';

// Custom page transition builders
Page<T> _slideTransitionPage<T extends Object?>(
  GoRouterState state,
  Widget child, {
  Offset beginOffset = const Offset(1.0, 0.0),
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeInOutCubic;

      final slideAnimation = Tween<Offset>(
        begin: beginOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      ));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: const Interval(0.3, 1.0, curve: curve),
      ));

      final scaleAnimation = Tween<double>(
        begin: 0.95,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      ));

      // Exit animation for the previous page
      final exitSlideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.3, 0.0),
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: curve,
      ));

      final exitFadeAnimation = Tween<double>(
        begin: 1.0,
        end: 0.8,
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: curve,
      ));

      return Stack(
        children: [
          // Previous page (sliding out)
          if (secondaryAnimation.value > 0)
            SlideTransition(
              position: exitSlideAnimation,
              child: FadeTransition(
                opacity: exitFadeAnimation,
                child: child,
              ),
            ),
          // New page (sliding in)
          SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(
                scale: scaleAnimation,
                child: child,
              ),
            ),
          ),
        ],
      );
    },
  );
}

Page<T> _fadeTransitionPage<T extends Object?>(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeInOut;

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      ));

      final scaleAnimation = Tween<double>(
        begin: 0.9,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: curve,
      ));

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(
          scale: scaleAnimation,
          child: child,
        ),
      );
    },
  );
}

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
      name: 'login',
      pageBuilder: (context, state) => _fadeTransitionPage(
        state,
        const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      pageBuilder: (context, state) => _slideTransitionPage(
        state,
        const RegisterScreen(),
        beginOffset: const Offset(1.0, 0.0),
      ),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      pageBuilder: (context, state) => _slideTransitionPage(
        state,
        const ForgotPasswordScreen(),
        beginOffset: const Offset(0.0, 1.0),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      pageBuilder: (context, state) => _slideTransitionPage(
        state,
        const OnboardingScreen(),
        beginOffset: const Offset(1.0, 0.0),
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
        child: const GiftIntroScreen(),
      ),
    ),

    GoRoute(
      path: '/select-recipient',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const GiftRecipientSelectionScreen(),
      ),
    ),
    GoRoute(
      path: '/gift-wizard',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const GiftWizardScreen(),
      ),
    ),
    GoRoute(
      path: '/gift-wizard-recipient',
      pageBuilder: (context, state) {
        final recipient = state.extra as Recipient;
        return NoTransitionPage(child: GiftWizardRecipientScreen(recipient: recipient));
      },
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
            existingRecipient: extras?['existingRecipient'],
            wizardData: extras?['wizardData'],
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
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => NoTransitionPage(
        child: const ProfileScreen(),
      ),
    ),
  ],
);