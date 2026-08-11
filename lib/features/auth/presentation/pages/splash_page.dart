import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled3/app/router/route_names.dart';
import 'package:untitled3/app/theme/app_colors.dart';
import 'package:untitled3/features/auth/presentation/providers/auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    final minSplash = Future.delayed(const Duration(seconds: 2));
    final authRepository = ref.read(authRepositoryProvider);
    final user = authRepository.currentUser;

    String destination;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
      destination = seenOnboarding ? RouteNames.login : RouteNames.onboarding;
    } else {
      final appUser = await authRepository.getUserDoc(user.uid);
      if (appUser == null) {
        // Auth account exists without a Firestore profile (e.g. interrupted signup).
        await authRepository.signOut();
        destination = RouteNames.login;
      } else if (appUser.role == 'admin') {
        destination = RouteNames.adminDashboard;
      } else {
        destination = appUser.isSeller ? RouteNames.sellerDashboard : RouteNames.home;
      }
    }

    await minSplash;
    if (!mounted || _navigated) return;
    _navigated = true;
    context.go(destination);
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
