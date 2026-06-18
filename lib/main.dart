import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'domain/state/wardrobe_state.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/main_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WardrobeAIApp());
}

class WardrobeAIApp extends StatelessWidget {
  const WardrobeAIApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WardrobeState(),
      child: Consumer<WardrobeState>(
        builder: (context, wardrobeState, _) {
          return MaterialApp(
            title: 'Wardrobe AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark, // Premium Obsidian Gold by default
            home: wardrobeState.isLoading
                ? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : (wardrobeState.isOnboarded
                    ? const MainNavigation()
                    : const OnboardingScreen()),
          );
        },
      ),
    );
  }
}
