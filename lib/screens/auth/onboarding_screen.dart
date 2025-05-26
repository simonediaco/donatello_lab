import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_button.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Immagine rinascimentale
              Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage('assets/images/auth/onboarding.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                'Welcome to Donatello Lab',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              Text(
                "Let's craft the perfect gift together. Share a few details, and our AI will generate unique ideas tailored to your recipient.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.subtitleColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),
              
              CustomButton(
                text: 'Start',
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}