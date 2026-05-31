import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'StudentDashboardPage.dart';
import 'TeacherDashboardPage.dart';

const String _teacherEmail = 'razah5367@gmail.com'; // Static teacher email

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmailController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isInitialized = false; // Flag to track initialization
  bool _showForgotPassword = false; // Flag to control Forgot Password visibility

  late AnimationController _headerController;
  late AnimationController _pulseController;
  late AnimationController _formController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Set up animations
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuad),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    _formFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutQuad),
    );
    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutBack),
    );

    // Add listener to email controller to toggle Forgot Password visibility
    _emailController.addListener(() {
      setState(() {
        _showForgotPassword = _emailController.text.trim() == _teacherEmail;
      });
    });

    // Start animations
    _headerController.forward();
    _pulseController.repeat(reverse: true);

    // Delay form animation and mark initialization complete
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _formController.forward();
        setState(() => _isInitialized = true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
    _headerController.dispose();
    _pulseController.dispose();
    _formController.dispose();
    super.dispose();
  }

  Future<void> _login(String role) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter both email and password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential.user != null) {
        final isTeacherEmail = userCredential.user!.email == _teacherEmail;
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
          _showErrorSnackBar('Access denied: ${isTeacherEmail ? 'Use Teacher login for this account' : 'Not a teacher account'}');
        }
      } else {
        _showErrorSnackBar('Login failed: No user data received');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed. Please try again.';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
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
          backgroundColor: const Color(0xFF1E293B),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Reset Password',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
                        color: const Color(0xFF94A3B8),
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
                            gradient: const [Color(0xFF64748B), Color(0xFF475569)],
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
                            gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;
    final isTablet = screenSize.width > 600 && screenSize.width <= 900;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
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
                      color: Color(0xFF667EEA),
                      strokeWidth: 4,
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1200 : (isTablet ? 800 : double.infinity),
                      minHeight: screenSize.height - 200,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isDesktop ? 32.0 : 16.0),
                      child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
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

  Widget _buildDesktopLayout() {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF667EEA)));
    }
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: AnimatedBuilder(
            animation: _headerController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _headerFadeAnimation,
                child: Transform.scale(
                  scale: _headerScaleAnimation.value + (_pulseController.value * 0.02),
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    child: Column(
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
                                color: const Color(0xFF667EEA).withOpacity(0.4),
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
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        Text(
                          'Alpha Graphics',
                          style: GoogleFonts.inter(
                            fontSize: 48,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your gateway to interactive learning and creative excellence with our Test Series App. Sign in to access your personalized dashboard, practice with tailored test series, track your progress, and explore endless possibilities for academic and competitive success.',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF475569).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                            const Icon(
                            Icons.security_rounded,
                            color: Color(0xFF667EEA),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your data is secured with enterprise-grade encryption',
                              style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
              ),
              );
            },
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          flex: 4,
          child: FadeTransition(
            opacity: _formFadeAnimation,
            child: SlideTransition(
              position: _formSlideAnimation,
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF475569).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF334155).withOpacity(0.5),
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
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF667EEA)));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _headerController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _headerFadeAnimation,
              child: Transform.scale(
                scale: _headerScaleAnimation.value + (_pulseController.value * 0.02),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF475569).withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF334155).withOpacity(0.5),
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
                              color: const Color(0xFF667EEA).withOpacity(0.4),
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
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Welcome back! Sign in to continue',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        FadeTransition(
          opacity: _formFadeAnimation,
          child: SlideTransition(
            position: _formSlideAnimation,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF475569).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF334155).withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _buildLoginForm(),
            ),
          ),
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
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Developed By Brolytics Technologies',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Color(0xFF64748B),
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
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Access your account to continue',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Color(0xFF94A3B8),
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
              color: const Color(0xFF94A3B8),
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
                  color: const Color(0xFF667EEA),
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
              color: Color(0xFF667EEA),
              strokeWidth: 3,
            ),
          )
        else
          Column(
            children: [
              ModernButton(
                text: 'Teacher Login',
                onPressed: () => _login('teacher'),
                gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              ModernButton(
                text: 'Student Login',
                onPressed: () => _login('student'),
                gradient: const [Color(0xFF10B981), Color(0xFF38EF7D)],
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

class _ModernTextFieldState extends State<ModernTextField> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _borderAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _borderAnimation = ColorTween(
      begin: const Color(0xFF475569),
      end: const Color(0xFF667EEA),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _borderAnimation,
      builder: (context, child) {
        return TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          onTap: () {
            if (!_isFocused) {
              setState(() => _isFocused = true);
              _controller.forward();
            }
          },
          onTapOutside: (_) {
            if (_isFocused) {
              setState(() => _isFocused = false);
              _controller.reverse();
            }
          },
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: GoogleFonts.inter(
              color: _isFocused ? const Color(0xFF667EEA) : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused ? const Color(0xFF667EEA) : const Color(0xFF94A3B8),
            ),
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: _isFocused
                ? const Color(0xFF667EEA).withOpacity(0.1)
                : const Color(0xFF0F172A).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _borderAnimation.value!, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF475569), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        );
      },
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

class _ModernButtonState extends State<ModernButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onPressed();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
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
                      blurRadius: _isPressed ? 8 : (_isHovered ? 20 : 15),
                      offset: Offset(0, _isPressed ? 2 : (_isHovered ? 10 : 8)),
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
            );
          },
        ),
      ),
    );
  }
}