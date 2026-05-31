import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'StudentDashboardPage.dart';
import 'TeacherDashboardPage.dart';

/// Windows/desktop Firebase sign-in can hang without a timeout.
const Duration _loginTimeout = Duration(seconds: 30);

const String _teacherEmail = 'razah5367@gmail.com'; // Static teacher email

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showForgotPassword = false;

  @override
  void initState() {
    super.initState();
    // Add listener to email controller to toggle Forgot Password visibility
    _emailController.addListener(() {
      setState(() {
        _showForgotPassword = _emailController.text.trim() == _teacherEmail;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    super.dispose();
  }

  Future<void> _login(String role) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter both email and password');
      return;
    }

    setState(() => _isLoading = true);

    final stopwatch = Stopwatch()..start();
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
          .timeout(
            _loginTimeout,
            onTimeout: () => throw TimeoutException(
              'Login timed out. Internet ya Windows Firewall check karein.',
            ),
          );
      debugPrint('Firebase signIn took ${stopwatch.elapsedMilliseconds}ms');

      if (userCredential.user != null) {
        final email = (userCredential.user!.email ?? '').trim().toLowerCase();
        final isTeacherEmail = email == _teacherEmail.toLowerCase();
        if (isTeacherEmail && role == 'teacher') {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const TeacherDashboardPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    fillColor: Colors.transparent,
                    child: child,
                  ),
            ),
          );
        } else if (!isTeacherEmail && role == 'student') {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const StudentDashboardPage(studentName: ''),
              transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                  SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    fillColor: Colors.transparent,
                    child: child,
                  ),
            ),
          );
        } else {
          await FirebaseAuth.instance.signOut();
          if (isTeacherEmail) {
            _showErrorSnackBar(
              'Teacher account hai — "Teacher Login" button use karein, Student Login nahi.',
            );
          } else {
            _showErrorSnackBar(
              'Student account hai — "Student Login" button use karein, Teacher Login nahi.',
            );
          }
        }
      } else {
        _showErrorSnackBar('Login failed: No user data received');
      }
    } on TimeoutException catch (e) {
      debugPrint('Login timeout: $e');
      _showErrorSnackBar(e.message ?? 'Login timed out. Dobara try karein.');
    } on FirebaseAuthException catch (e) {
      debugPrint('Login FirebaseAuthException: ${e.code} — ${e.message}');
      String errorMessage = 'Login failed. Please try again.';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Is email par koi account nahi mila. Firebase mein user banaya hai?';
          break;
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-login-credentials':
          errorMessage = 'Galat password. Sahi password ya Forgot Password try karein.';
          break;
        case 'invalid-email':
          errorMessage = 'Email format galat hai.';
          break;
        case 'user-disabled':
          errorMessage = 'Ye account disable hai.';
          break;
        case 'too-many-requests':
          errorMessage = 'Bahut zyada tries. Thodi der baad try karein.';
          break;
        case 'network-request-failed':
          errorMessage = 'Internet / network issue. Connection check karein.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email login Firebase par enable nahi hai (Authentication settings).';
          break;
        default:
          errorMessage = 'Login failed (${e.code}). ${e.message ?? ''}';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_resetEmailController.text.isEmpty) {
      _showErrorSnackBar('Please enter your email address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _resetEmailController.text.trim(),
      );
      _resetEmailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Password reset email sent successfully!',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to send reset email.';
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        transitionDuration: Duration(milliseconds: 300),
        reverseTransitionDuration: Duration(milliseconds: 200),
      ),
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppTheme.backgroundStart,
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 32,
                      color: AppTheme.textPrimary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reset Password',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ModernTextField(
                      controller: _resetEmailController,
                      label: 'Email Address',
                      icon: Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ModernButton(
                            text: 'Cancel',
                            gradient: const [AppTheme.textMuted, AppTheme.border],
                            icon: Icons.close_rounded,
                            onPressed: () {
                              _resetEmailController.clear();
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ModernButton(
                            text: 'Send Link',
                            gradient: const [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                            icon: Icons.send_rounded,
                            onPressed: _resetPassword,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _useDesktopLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width > 900) return true;
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux) &&
        size.width > 700;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final isDesktop = _useDesktopLayout(context);
    final isTablet = !isDesktop && screenSize.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.backgroundStart,
              AppTheme.backgroundEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7B2FBE),
                      strokeWidth: 4,
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: isDesktop
                  ? _buildDesktopShell(screenSize, padding)
                  : Center(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isTablet ? 800 : double.infinity,
                            minHeight: screenSize.height - padding.vertical - 32,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildMobileLayout(),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopShell(Size screenSize, EdgeInsets padding) {
    final availableHeight = screenSize.height - padding.top - padding.bottom;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: SizedBox(
            height: availableHeight.clamp(400.0, screenSize.height),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: _buildDesktopWelcomeColumn(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundMid.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.border.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.backgroundMid.withOpacity(0.8),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: _buildLoginForm(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopWelcomeColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/logoimg.jpg'),
              fit: BoxFit.cover,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2FBE).withOpacity(0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Welcome to',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          'Alpha Graphics',
          style: GoogleFonts.inter(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your gateway to interactive learning and creative excellence with our Test Series App. Sign in to access your personalized dashboard, practice with tailored test series, track your progress, and explore endless possibilities for academic and competitive success.',
          style: GoogleFonts.inter(
            fontSize: 18,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w400,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.backgroundMid.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.border.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.security_rounded,
                color: Color(0xFF7B2FBE),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your data is secured with enterprise-grade encryption',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppTheme.backgroundMid.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.border.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.backgroundMid.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage('assets/logoimg.jpg'),
                    fit: BoxFit.cover,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B2FBE).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Alpha Graphics',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back! Sign in to continue',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textPrimary.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.backgroundMid.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.border.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.backgroundMid.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: _buildLoginForm(),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '© 2024 Alpha Graphics. All rights reserved.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Developed by Brolytics Technologies',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sign In',
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Access your account to continue',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 32),
        ModernTextField(
          controller: _emailController,
          label: 'Email Address',
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        ModernTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_rounded,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: Visibility(
            visible: _showForgotPassword,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF7B2FBE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF7B2FBE),
              strokeWidth: 3,
            ),
          )
        else
          Column(
            children: [
              ModernButton(
                text: 'Teacher Login',
                onPressed: () => _login('teacher'),
                gradient: const [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              ModernButton(
                text: 'Student Login',
                onPressed: () => _login('student'),
                gradient: const [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
                icon: Icons.school_rounded,
              ),
            ],
          ),
      ],
    );
  }
}

class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const ModernTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
  }) : super(key: key);

  @override
  _ModernTextFieldState createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      onTap: () {
        if (!_isFocused) {
          setState(() => _isFocused = true);
        }
      },
      onTapOutside: (_) {
        if (_isFocused) {
          setState(() => _isFocused = false);
        }
      },
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: GoogleFonts.inter(
          color: _isFocused ? const Color(0xFF7B2FBE) : AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          widget.icon,
          color: _isFocused ? const Color(0xFF7B2FBE) : AppTheme.textSecondary,
        ),
        suffixIcon: widget.suffixIcon,
        filled: true,
        fillColor: _isFocused
            ? const Color(0xFF7B2FBE).withOpacity(0.1)
            : AppTheme.backgroundMid,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _isFocused ? const Color(0xFF7B2FBE) : AppTheme.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7B2FBE), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> gradient;
  final IconData icon;

  const ModernButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.gradient,
    required this.icon,
  }) : super(key: key);

  @override
  _ModernButtonState createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withOpacity(_isHovered ? 0.4 : 0.3),
                blurRadius: _isHovered ? 20 : 15,
                offset: Offset(0, _isHovered ? 10 : 8),
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
            border: _isHovered
                ? Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                widget.text,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
