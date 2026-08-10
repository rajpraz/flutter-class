import 'package:flutter/material.dart';

class AppColors {
  // Core palette pulled from the new Pooja Pasal design
  static const Color primary = Color(0xFF7A1E1E); // deep maroon (headings, nav)
  static const Color primaryDark = Color(0xFF5C1414);
  static const Color accent = Color(0xFFE8590C); // vivid saffron-orange (CTAs)
  static const Color accentDark = Color(0xFFC24A0A);
  static const Color accentLight = Color(0xFFFF8A3D);
  static const Color background = Color(0xFFFDF6EE); // warm cream
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFF3E0); // soft peach card
  static const Color text = Color(0xFF2B1B12);
  static const Color muted = Color(0xFF8C6E5D);
  static const Color border = Color(0xFFF0DFC5);
  static const Color success = Color(0xFF2E9E44); // eSewa green
  static const Color error = Color(0xFFC0392B); // brick-red, warm-palette friendly
  static const Color khaltiPurple = Color(0xFF5C2D91);
  static const Color fonepayBlue = Color(0xFF1565C0);

  // Festival collection accent colors (homepage + festivalCollectionPage)
  static const Color festivalShivaratri = Color(0xFF3B3B58);
  static const Color festivalTeej = Color(0xFFB23A6B);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Poppins',
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.text,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.primary),
      titleTextStyle: TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent,
        side: const BorderSide(color: AppColors.accent),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 2,
      surfaceTintColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.muted,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.text),
      bodyMedium: TextStyle(color: AppColors.text),
      bodySmall: TextStyle(color: AppColors.text),
    ),
  );
}

/// Shared bottom navigation used across the buyer-facing pages
/// (Home / Categories / Cart / Wishlist / Profile).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    Widget cartIcon = const Icon(Icons.shopping_cart_outlined);
    if (cartCount > 0) {
      cartIcon = Badge(
        label: Text('$cartCount'),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.shopping_cart_outlined),
      );
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined), label: 'Home'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined), label: 'Categories'),
        BottomNavigationBarItem(icon: cartIcon, label: 'Cart'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border), label: 'Wishlist'),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}