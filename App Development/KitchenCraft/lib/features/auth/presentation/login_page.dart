// lib/features/auth/presentation/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:KitchenCraft/widgets/custom_scaffold.dart';
import 'package:KitchenCraft/services/recipe_init_service.dart';
import 'dart:async';
import 'package:KitchenCraft/features/home/presentation/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  final PageController _pageController = PageController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _showSetPasswordDialog(User user) async {
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Set Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set a password for ${user.email}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm password';
                    if (v != passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    // Link password credential to the Google account
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: passwordCtrl.text,
                    );
                    await user.linkWithCredential(credential);
                    Navigator.pop(context, true);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password set successfully! You can now login with email and password.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    Navigator.pop(context, false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to set password: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Set Password'),
            ),
          ],
        ),
      ),
    );

    passwordCtrl.dispose();
    confirmCtrl.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      debugPrint('Login attempt - Firebase Auth initialization check');
      debugPrint('Current user before login: ${FirebaseAuth.instance.currentUser}');
      debugPrint('Attempting to login with email: ${_emailCtrl.text.trim()}');
      debugPrint('Password length: ${_pwdCtrl.text.length}');
      
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text,
      );
      
      debugPrint('Login successful');
      debugPrint('Current user after login: ${userCredential.user?.uid}');
      
      if (userCredential.user != null) {
        await RecipeInitService.ensureUserHasRecipes(userCredential.user!.uid);
      }
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      debugPrint('FirebaseAuthException during login: ${e.code} - ${e.message}');
      
      if (e.code == 'user-not-found') {
        message = 'No user found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password. If you signed up with Google and haven\'t set a password yet, please use the "Continue with Google" button.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is not valid';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials. If you signed up with Google, please use the "Continue with Google" button.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Check your internet connection.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('General error during login: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // Google Sign-In - Fixed version supporting both Web and Mobile
  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    
    try {
      UserCredential? userCredential;

      if (kIsWeb) {
        // WEB: Use popup method
        debugPrint('Using Web Google Sign-In');
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // MOBILE: Use google_sign_in package
        debugPrint('Using Mobile Google Sign-In');
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email'],
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          // User canceled the sign-in
          debugPrint('User canceled Google Sign-In');
          if (mounted) {
            setState(() => _loading = false);
          }
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      
      debugPrint('Google Sign-In successful');
      debugPrint('User: ${userCredential.user?.displayName}');
      debugPrint('Email: ${userCredential.user?.email}');
      debugPrint('UID: ${userCredential.user?.uid}');

      // Ensure user has popular recipes
      if (userCredential.user != null) {
        await RecipeInitService.ensureUserHasRecipes(userCredential.user!.uid);
      }

      if (!mounted) return;

      // Check if this is a new account (check if they have password login enabled)
      try {
        final providers = userCredential.user!.providerData;
        final hasPassword = providers.any((info) => info.providerId == 'password');

        if (!hasPassword) {
          // Offer to set a password for future email/password login
          final shouldSetPassword = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Set a Password'),
              content: const Text(
                'Would you like to set a password? This will allow you to login with email and password in the future.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Skip'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Set Password'),
                ),
              ],
            ),
          );

          if (shouldSetPassword == true && mounted) {
            await _showSetPasswordDialog(userCredential.user!);
          }
        }
      } catch (e) {
        debugPrint('Error checking password provider: $e');
      }
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, ${userCredential.user?.displayName ?? 'User'}!'),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      
    } on FirebaseAuthException catch (e) {
      String message = 'Google sign-in failed';
      debugPrint('FirebaseAuthException during Google sign-in: ${e.code} - ${e.message}');
      
      if (e.code == 'account-exists-with-different-credential') {
        message = 'An account already exists with the same email address';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid credentials. Please try again.';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Google sign-in is not enabled. Please contact support.';
      } else if (e.code == 'user-disabled') {
        message = 'This account has been disabled';
      } else if (e.code == 'network-request-failed') {
        message = 'Network error. Check your internet connection.';
      } else if (e.code == 'popup-closed-by-user') {
        message = 'Sign-in popup was closed. Please try again.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error during Google sign-in: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = const SizedBox(height: 12);

    return CustomScaffold(
      body: Stack(
        children: [
          // Rotating background images with PageView
          PageView(
            controller: _pageController,
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Unsplash.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/bg-1.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/kitchen_tablet.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          // Gradient overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFF8B0000),
                  Colors.transparent,
                ],
                stops: [0.0, 0.6],
              ),
            ),
          ),
          // Main content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      const SizedBox(height: 24),
                      const Icon(
                        Icons.kitchen,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'KitchenCraft',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Organize your kitchen. Simplify your life.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: Color.fromARGB(179, 7, 7, 7),
                          shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailCtrl,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'you@example.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          filled: true,
                          fillColor: Colors.white.withAlpha((0.9 * 255).round()),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      spacing,
                      TextFormField(
                        controller: _pwdCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white.withAlpha((0.9 * 255).round()),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Show password' : 'Hide password',
                            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _loading ? null : _handleLogin,
                        icon: _loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.login),
                        label: const Text('Login'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      spacing,
                      Row(
                        children: [
                          const Expanded(child: Divider(color: Colors.white54, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: Colors.white54, thickness: 1)),
                        ],
                      ),
                      spacing,
                      ElevatedButton(
                        onPressed: _loading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                    height: 24,
                                    width: 24,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.login, color: Colors.red, size: 24);
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      spacing,
                      TextButton(
                        onPressed: _loading ? null : () => Navigator.pushNamed(context, '/family'),
                        child: const Text('Join a Family Group', style: TextStyle(color: Colors.white70)),
                      ),
                      TextButton(
                        onPressed: _loading ? null : () => Navigator.pushNamed(context, '/signup'),
                        child: const Text("Don't have an account? Sign up", style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('AI Assistant'),
                    content: const Text('Powered by Gemini AI. Ask for recipe ideas, tips, or substitutes once signed in!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[600],
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}