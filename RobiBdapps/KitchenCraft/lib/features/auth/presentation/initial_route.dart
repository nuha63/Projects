import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_wizard.dart';
import 'login_page.dart';
import '../../home/presentation/home_page.dart';

const String _baseUrl = 'https://www.flicksize.com/kitchencraft/';

class InitialRoute extends StatefulWidget {
  const InitialRoute({super.key});

  @override
  State<InitialRoute> createState() => _InitialRouteState();
}

class _InitialRouteState extends State<InitialRoute> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    // Wait a moment for splash effect
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final savedPhone = prefs.getString('userPhone')?.trim() ?? '';

    // SECOND-LOGIN FLOW: User is already logged in
    // Auto-verify subscription status
    if (isLoggedIn && savedPhone.isNotEmpty) {
      final isStillSubscribed = await _checkAlreadySubscribed(savedPhone);
      
      if (!isStillSubscribed) {
        // Subscription expired/invalid - clear session and go to login
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('userPhone');
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => isStillSubscribed ? const HomePage() : const LoginPage(),
        ),
      );
      return;
    }

    // FIRST-LOGIN FLOW: User is not logged in
    if (!mounted) return;

    if (onboardingCompleted) {
      // Onboarding done → show login screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      // Onboarding not done → show onboarding wizard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingWizard()),
      );
    }
  }

  Future<bool> _checkAlreadySubscribed(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse('${_baseUrl}check_subscription.php'),
            body: {'user_mobile': phone},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;

      final status =
          decoded['subscriptionStatus']?.toString().trim().toUpperCase() ?? '';
      return status == 'REGISTERED';
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Splash screen while checking
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange[700]!,
              Colors.orange[400]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'KitchenCraft',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
