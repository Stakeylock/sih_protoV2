import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This splash screen is now a stateless widget. Its only job is to display
    // the UI while the AppState provider and AuthGate are initializing.
    // All navigation logic has been removed and is correctly handled by AuthGate.

    return Scaffold(
      backgroundColor: const Color(0xFF1a202c), // Consistent with your app's dark theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // A more visually appealing logo representation
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withOpacity(0.1),
                border: Border.all(
                  color: Colors.blueAccent.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.security_rounded,
                size: 80,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Suraksha Setu',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
             const SizedBox(height: 8),
            Text(
              'Your Safety, Our Priority.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 64),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

