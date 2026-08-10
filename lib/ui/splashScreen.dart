import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/login.dart' as login_page;
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/ui/onboardingPage.dart';
import 'package:untitled3/ui/homepage.dart';
import 'package:untitled3/ui/seller_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    final minSplash = Future.delayed(const Duration(seconds: 2));
    final user = AuthService.currentUser;

    Widget destination;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      destination = seenOnboarding ? const login_page.LoginPage() : const OnboardingPage();
    } else {
      final appUser = await AuthService.getUserDoc(user.uid);
      if (appUser == null) {
        // Auth account exists without a Firestore profile (e.g. interrupted signup).
        await AuthService.signOut();
        destination = const login_page.LoginPage();
      } else {
        destination = appUser.isSeller ? const SellerDashboard() : const HomePage();
      }
    }

    await minSplash;
    if (!mounted || _navigated) return;
    _navigated = true;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              AppColors.accentLight,
              AppColors.accent,
            ],
            stops: [0.0, 0.55, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.local_florist,
                      size: 90, color: Colors.white.withValues(alpha: 0.9)),
                ],
              ),
              const SizedBox(height: 8),
              Icon(Icons.temple_hindu,
                  size: 110, color: Colors.white.withValues(alpha: 0.95)),
              const SizedBox(height: 20),
              const Text('Pooja Pasal',
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
              const SizedBox(height: 10),
              const Text('Everything for your',
                  style: TextStyle(fontSize: 15, color: Colors.white)),
              const Text('Puja, delivered with devotion',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const Spacer(flex: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.local_fire_department,
                        size: 18, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
