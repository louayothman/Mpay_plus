import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mpay_app/screens/auth/register_screen.dart';
import 'package:mpay_app/screens/auth/pin_screen.dart';
import 'package:mpay_app/screens/auth/forgot_password_screen.dart';
import 'package:mpay_app/screens/auth/two_factor_auth_screen.dart';
import 'package:mpay_app/screens/home/home_screen.dart';
import 'package:mpay_app/utils/security_utils.dart';
import 'package:mpay_app/utils/connectivity_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';
  int _loginAttempts = 0;
  DateTime? _lastLoginAttempt;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadLoginAttempts();
  }

  Future<void> _checkConnectivity() async {
    bool isConnected = await ConnectivityUtils.isConnected();
    setState(() {
      _isConnected = isConnected;
    });
  }

  Future<void> _loadLoginAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loginAttempts = prefs.getInt('login_attempts') ?? 0;
      final lastAttemptMillis = prefs.getInt('last_login_attempt');
      _lastLoginAttempt = lastAttemptMillis != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastAttemptMillis) 
          : null;
    });
  }

  Future<void> _saveLoginAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('login_attempts', _loginAttempts);
    if (_lastLoginAttempt != null) {
      await prefs.setInt('last_login_attempt', _lastLoginAttempt!.millisecondsSinceEpoch);
    }
  }

  bool _isLoginBlocked() {
    if (_loginAttempts >= 5 && _lastLoginAttempt != null) {
      final difference = DateTime.now().difference(_lastLoginAttempt!);
      if (difference.inMinutes < 15) {
        return true;
      } else {
        // Reset attempts after 15 minutes
        _loginAttempts = 0;
        _saveLoginAttempts();
        return false;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (!_isConnected) {
      setState(() {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
      });
      return;
    }

    if (_isLoginBlocked()) {
      final difference = DateTime.now().difference(_lastLoginAttempt!);
      final remainingMinutes = 15 - difference.inMinutes;
      setState(() {
        _errorMessage = 'تم حظر تسجيل الدخول مؤقتًا بسبب محاولات متكررة. يرجى المحاولة مرة أخرى بعد $remainingMinutes دقيقة.';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // Increment login attempts
        _loginAttempts++;
        _lastLoginAttempt = DateTime.now();
        await _saveLoginAttempts();

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (!mounted) return;
        
        // Reset login attempts on successful login
        _loginAttempts = 0;
        await _saveLoginAttempts();

        // Check if 2FA is enabled for this user
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final isTwoFactorEnabled = await SecurityUtils.isTwoFactorEnabled(user.uid);
          
          if (isTwoFactorEnabled) {
            // Navigate to 2FA verification screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TwoFactorAuthScreen(
                  onVerificationComplete: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinScreen(isVerification: true),
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            // Navigate to PIN screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PinScreen(isVerification: true),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            _errorMessage = 'لم يتم العثور على مستخدم بهذا البريد الإلكتروني';
          } else if (e.code == 'wrong-password') {
            _errorMessage = 'كلمة المرور غير صحيحة';
          } else if (e.code == 'too-many-requests') {
            _errorMessage = 'تم حظر الوصول مؤقتًا بسبب نشاط غير عادي. يرجى المحاولة لاحقًا.';
          } else if (e.code == 'user-disabled') {
            _errorMessage = 'تم تعطيل هذا الحساب. يرجى التواصل مع الدعم الفني.';
          } else {
            _errorMessage = 'حدث خطأ في تسجيل الدخول: ${e.message}';
          }
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_isConnected) {
      setState(() {
        _errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
      });
      return;
    }

    if (_isLoginBlocked()) {
      final difference = DateTime.now().difference(_lastLoginAttempt!);
      final remainingMinutes = 15 - difference.inMinutes;
      setState(() {
        _errorMessage = 'تم حظر تسجيل الدخول مؤقتًا بسبب محاولات متكررة. يرجى المحاولة مرة أخرى بعد $remainingMinutes دقيقة.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Increment login attempts
      _loginAttempts++;
      _lastLoginAttempt = DateTime.now();
      await _saveLoginAttempts();

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (!mounted) return;
      
      // Reset login attempts on successful login
      _loginAttempts = 0;
      await _saveLoginAttempts();

      // Check if this is a new user
      final User? user = FirebaseAuth.instance.currentUser;
      final metadata = user?.metadata;
      
      if (metadata != null && 
          metadata.creationTime != null && 
          metadata.lastSignInTime != null &&
          metadata.creationTime!.isAtSameMomentAs(metadata.lastSignInTime!)) {
        // New user, navigate to PIN creation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PinScreen(isVerification: false),
          ),
        );
      } else {
        // Check if 2FA is enabled for this user
        if (user != null) {
          final isTwoFactorEnabled = await SecurityUtils.isTwoFactorEnabled(user.uid);
          
          if (isTwoFactorEnabled) {
            // Navigate to 2FA verification screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => TwoFactorAuthScreen(
                  onVerificationComplete: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinScreen(isVerification: true),
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            // Existing user, navigate to PIN verification
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const PinScreen(isVerification: true),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ في تسجيل الدخول باستخدام Google: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    height: 120,
                    width: 120,
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  const Text(
                    'تسجيل الدخول',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Connectivity warning
                  if (!_isConnected)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.wifi_off, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'لا يوجد اتصال بالإنترنت. بعض الميزات قد لا تعمل بشكل صحيح.',
                              style: TextStyle(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_isConnected) const SizedBox(height: 16),
                  
                  // Error message
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_errorMessage.isNotEmpty) const SizedBox(height: 16),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال البريد الإلكتروني';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'الرجاء إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  
                  // Forgot password
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text('نسيت كلمة المرور؟'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading || _isLoginBlocked() ? null : _signInWithEmailAndPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Google sign in
                  OutlinedButton.icon(
                    onPressed: _isLoading || _isLoginBlocked() ? null : _signInWithGoogle,
                    icon: Image.asset(
                      'assets/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    label: const Text('تسجيل الدخول باستخدام Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Register link
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'ليس لديك حساب؟ ',
                      style: TextStyle(color: Colors.grey.shade700),
                      children: [
                        TextSpan(
                          text: 'إنشاء حساب جديد',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
