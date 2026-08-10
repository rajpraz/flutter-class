import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:untitled3/const/style.dart';
import 'package:untitled3/services/auth_service.dart';
import 'package:untitled3/ui/homepage.dart';
import 'package:untitled3/ui/signUp.dart';
import 'package:untitled3/ui/seller_dashboard.dart';
import 'package:untitled3/ui/forgetpassword.dart';

class LoginPage extends StatefulWidget {
  final String role;
  const LoginPage({super.key, this.role = 'buyer'});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obsecure = true;
  bool _isloading = false;
  late String currentRole;

  @override
  void initState() {
    super.initState();
    currentRole = widget.role;
  }

  void _signUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => signUp(role: currentRole)),
    );
  }

  void _forgetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const forgetPassword()),
    );
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isloading = true);
    try {
      await AuthService.signInWithGoogle(role: currentRole);
      if (!mounted) return;
      final user = AuthService.currentUser;
      final appUser = user == null ? null : await AuthService.getUserDoc(user.uid);
      if (!mounted) return;
      _routeAfterLogin(appUser?.role ?? currentRole);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Google sign-in failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isloading = false);
    }
  }

  void _routeAfterLogin(String role) {
    if (role == 'seller') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => const SellerDashboard()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePage()));
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: 'Please enter your email and password');
      return;
    }

    setState(() => _isloading = true);

    try {
      await AuthService.signIn(email: email, password: password);
      final user = AuthService.currentUser;
      final appUser = user == null ? null : await AuthService.getUserDoc(user.uid);

      if (!mounted) return;
      if (appUser == null) {
        Fluttertoast.showToast(msg: 'Account profile not found. Please sign up again.');
        return;
      }
      _routeAfterLogin(appUser.role);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? 'Login failed. Please try again.');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _isloading
            ? const Center(
                child: SpinKitCircle(color: AppColors.accent, size: 60))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text('Welcome Back!',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                    const SizedBox(height: 6),
                    const Text('Login to continue',
                        style: TextStyle(fontSize: 15, color: AppColors.muted)),
                    const SizedBox(height: 20),

                    // Buyer / seller selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _roleTab('Buyer', 'buyer'),
                          ),
                          Expanded(
                            child: _roleTab('Seller', 'seller'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Email',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.text)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'Email address',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Password',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.text)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obsecure,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obsecure = !_obsecure),
                          child: Icon(_obsecure
                              ? Icons.remove_red_eye
                              : Icons.remove_red_eye_outlined),
                        ),
                        hintText: 'Enter your password',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgetPassword,
                        child: const Text('Forgot password?',
                            style: TextStyle(color: AppColors.accent)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('OR', style: TextStyle(color: AppColors.muted)),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _continueWithGoogle,
                        icon: const Icon(Icons.g_mobiledata,
                            size: 28, color: AppColors.text),
                        label: const Text('Continue with Google',
                            style: TextStyle(color: AppColors.text)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          foregroundColor: AppColors.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('New here? '),
                        GestureDetector(
                          onTap: _signUp,
                          child: Text(
                            'Create ${currentRole == 'seller' ? 'seller' : 'a buyer'} account',
                            style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _roleTab(String label, String role) {
    final bool selected = currentRole == role;
    return GestureDetector(
      onTap: () => setState(() => currentRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
