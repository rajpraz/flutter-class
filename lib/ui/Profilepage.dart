import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/login.dart' as login_page;
import 'package:untitled3/providers/providers.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/ui/Addressespage.dart';
import 'package:untitled3/ui/HelpSupportPage.dart';
import 'package:untitled3/ui/NotificationPage.dart';
import 'package:untitled3/ui/homepage.dart';
import 'package:untitled3/ui/categories.dart';
import 'package:untitled3/ui/cart.dart';
import 'package:untitled3/ui/wishlistPage.dart';
import 'package:untitled3/ui/orderHistoryPage.dart';
import 'package:untitled3/ui/editprofilepage.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  String language = 'English';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      language = prefs.getString('app_language') ?? 'English';
    });
  }

  void _editProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
  }

  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose language'),
        children: ['English', 'नेपाली'].map((lang) {
          return SimpleDialogOption(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('app_language', lang);
              if (!context.mounted) return;
              Navigator.pop(context);
              setState(() => language = lang);
            },
            child: Text(lang),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const login_page.LoginPage()),
      (route) => false,
    );
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const HomePage()));
        break;
      case 1:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const CategoriesPage()));
        break;
      case 2:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const cartPage()));
        break;
      case 3:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const WishlistPage()));
        break;
    }
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap,
      {String? trailingText}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.accent),
          title: Text(label, style: const TextStyle(color: AppColors.text)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(trailingText,
                      style: const TextStyle(color: AppColors.muted)),
                ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.muted),
            ],
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userDocAsync = ref.watch(currentUserDocProvider);
    final isLoadingProfile = userDocAsync.isLoading && !userDocAsync.hasValue;
    final userName = userDocAsync.value?.name ?? '';
    final userPhone = userDocAsync.value?.phone ?? '';
    final userPhotoUrl = userDocAsync.value?.photoUrl ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accentDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    backgroundImage:
                        userPhotoUrl.isNotEmpty ? NetworkImage(userPhotoUrl) : null,
                    child: userPhotoUrl.isEmpty
                        ? const Icon(Icons.person, size: 34, color: AppColors.accent)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profile',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12)),
                        const SizedBox(height: 4),
                        if (isLoadingProfile)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        else
                          Text(userName.isEmpty ? 'Your name' : userName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        const SizedBox(height: 2),
                        if (!isLoadingProfile)
                          Text(userPhone.isEmpty ? 'Add a phone number' : userPhone,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white),
                    tooltip: 'Edit profile',
                    onPressed: _editProfile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _tile(Icons.receipt_long_outlined, 'My Orders', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OrderHistoryPage()));
                  }),
                  _tile(Icons.favorite_border, 'Wishlist', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WishlistPage()));
                  }),
                  _tile(Icons.location_on_outlined, 'Addresses', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddressesPage()));
                  }),
                  _tile(Icons.notifications_none, 'Notifications', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsPage()));
                  }),
                  _tile(Icons.language_outlined, 'Language', _changeLanguage,
                      trailingText: language),
                  _tile(Icons.help_outline, 'Help & Support', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const HelpSupportPage()));
                  }),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.accent),
                    title: const Text('Logout',
                        style: TextStyle(color: AppColors.text)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 4,
        onTap: _onNavTap,
      ),
    );
  }
}
