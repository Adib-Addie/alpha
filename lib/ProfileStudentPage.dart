import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animations/animations.dart';
import 'dart:math' as Math;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ProfileStudentPage extends StatefulWidget {
  const ProfileStudentPage({super.key});

  @override
  State<ProfileStudentPage> createState() => _ProfileStudentPageState();
}

class _ProfileStudentPageState extends State<ProfileStudentPage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardFadeAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;
  String? _profileImageUrl;
  bool _isHovered = false;
  bool _isInitialized = false; // Flag to track initialization

  final List<Color> profileGradient = [const Color(0xFF667EEA), const Color(0xFF764BA2)];

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );
    _cardControllers = [];
    _cardFadeAnimations = [];
    _cardSlideAnimations = [];

    _fetchProfileImage();
    _headerController.forward();
    _pulseController.repeat(reverse: true);
    _particleController.repeat();
    _isInitialized = true; // Set flag after initialization
  }

  void _initializeCardAnimations(int itemCount) {
    if (_cardControllers.length != itemCount) {
      for (var controller in _cardControllers) {
        controller.dispose();
      }
      _cardControllers.clear();
      _cardFadeAnimations.clear();
      _cardSlideAnimations.clear();

      for (int i = 0; i < itemCount; i++) {
        final controller = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1000),
        );
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.3, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        );

        _cardControllers.add(controller);
        _cardFadeAnimations.add(fadeAnimation);
        _cardSlideAnimations.add(slideAnimation);

        Future.delayed(Duration(milliseconds: 200 + (i * 100)), () {
          if (mounted) controller.forward();
        });
      }
    }
  }

  Future<void> _fetchProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('profile_pictures/${user.uid}.jpg');
        final url = await ref.getDownloadURL();
        setState(() {
          _profileImageUrl = url;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileImageUrl = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                Color(0xFF0F172A),
                Color(0xFF1E293B),
                Color(0xFF334155),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Text(
                'Not logged in',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 2.5,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
              Color(0xFF475569),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background particles
            if (_isInitialized)
              AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ParticlePainter(_particleController.value),
                    size: Size.infinite,
                  );
                },
              ),
            SafeArea(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53E3E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE53E3E).withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Color(0xFFE53E3E)),
                            const SizedBox(height: 16),
                            Text(
                              'Error Loading Profile',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                color: const Color(0xFFE53E3E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Error: ${snapshot.error}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 60,
                              height: 60,
                              child: CircularProgressIndicator(
                                color: profileGradient.first,
                                strokeWidth: 4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Loading Profile...',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_off_outlined,
                                size: 64,
                                color: Colors.white54,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Profile Not Found',
                              style: GoogleFonts.inter(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No profile data available for this account',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unknown';
                  final email = data['email'] ?? 'N/A';
                  final courseName = data['courseName'] ?? 'N/A';
                  final fatherName = data['fatherName'] ?? 'N/A';
                  final address = data['address'] ?? 'N/A';

                  _initializeCardAnimations(4);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Panel - Navigation & Profile Card
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              // Header with back button
                              AnimatedBuilder(
                                animation: _headerController,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: _headerFadeAnimation,
                                    child: Transform.scale(
                                      scale: _headerScaleAnimation.value,
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        margin: const EdgeInsets.only(bottom: 32),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: profileGradient.first.withOpacity(0.2),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: profileGradient),
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: profileGradient.first.withOpacity(0.4),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius.circular(16),
                                                  onTap: () => Navigator.pop(context),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(12),
                                                    child: Icon(
                                                      Icons.arrow_back_rounded,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Student Profile',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 28,
                                                      fontWeight: FontWeight.w800,
                                                      color: Colors.white,
                                                      letterSpacing: -0.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Manage your personal information',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      color: Colors.white.withOpacity(0.8),
                                                      fontWeight: FontWeight.w500,
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
                              // Enhanced Profile Card
                              Expanded(
                                child: ModernProfileCard(
                                  student: data,
                                  gradient: profileGradient,
                                  pulseController: _pulseController,
                                  profileImageUrl: _profileImageUrl,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Right Panel - Details Grid
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 100), // Align with left panel
                              Text(
                                'Personal Details',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your account information and course details',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Expanded(
                                child: GridView.count(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.8,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  children: [
                                    FadeTransition(
                                      opacity: _cardFadeAnimations[0],
                                      child: SlideTransition(
                                        position: _cardSlideAnimations[0],
                                        child: ModernDetailCard(
                                          label: 'Email Address',
                                          value: email,
                                          icon: Icons.mail_outline_rounded,
                                          gradient: profileGradient,
                                          delay: 0,
                                        ),
                                      ),
                                    ),
                                    FadeTransition(
                                      opacity: _cardFadeAnimations[1],
                                      child: SlideTransition(
                                        position: _cardSlideAnimations[1],
                                        child: ModernDetailCard(
                                          label: 'Course Enrolled',
                                          value: courseName,
                                          icon: Icons.school_outlined,
                                          gradient: profileGradient,
                                          delay: 100,
                                        ),
                                      ),
                                    ),
                                    FadeTransition(
                                      opacity: _cardFadeAnimations[2],
                                      child: SlideTransition(
                                        position: _cardSlideAnimations[2],
                                        child: ModernDetailCard(
                                          label: "Father's Name",
                                          value: fatherName,
                                          icon: Icons.person_outline_rounded,
                                          gradient: profileGradient,
                                          delay: 200,
                                        ),
                                      ),
                                    ),
                                    FadeTransition(
                                      opacity: _cardFadeAnimations[3],
                                      child: SlideTransition(
                                        position: _cardSlideAnimations[3],
                                        child: ModernDetailCard(
                                          label: 'Address',
                                          value: address,
                                          icon: Icons.location_on_outlined,
                                          gradient: profileGradient,
                                          delay: 300,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: Text(
                                    'Developed By Brolytics Technologies',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ModernProfileCard extends StatefulWidget {
  final Map<String, dynamic> student;
  final List<Color> gradient;
  final AnimationController pulseController;
  final String? profileImageUrl;

  const ModernProfileCard({
    Key? key,
    required this.student,
    required this.gradient,
    required this.pulseController,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  _ModernProfileCardState createState() => _ModernProfileCardState();
}

class _ModernProfileCardState extends State<ModernProfileCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (!mounted) return;
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student['name'] ?? 'Unknown';
    final courseName = widget.student['courseName'] ?? 'N/A';

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_hoverAnimation, widget.pulseController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(_isHovered ? 0.4 : 0.2),
                    blurRadius: _isHovered ? 30 : 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Profile Image with enhanced styling
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.first.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: ClipOval(
                        child: widget.profileImageUrl != null
                            ? Image.network(
                          widget.profileImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: widget.gradient.first,
                                strokeWidth: 3,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: widget.gradient),
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: GoogleFonts.inter(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                            : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: widget.gradient),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Name
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.gradient.first.withOpacity(0.3),
                          widget.gradient.last.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.gradient.first.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Active Student',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Course Name
                  Text(
                    courseName,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ModernDetailCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final int delay;

  const ModernDetailCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.delay = 0,
  }) : super(key: key);

  @override
  _ModernDetailCardState createState() => _ModernDetailCardState();
}

class _ModernDetailCardState extends State<ModernDetailCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (!mounted) return;
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(_isHovered ? 0.15 : 0.1),
                    Colors.white.withOpacity(_isHovered ? 0.1 : 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(0.1 + (_elevationAnimation.value * 0.2)),
                    blurRadius: 15 + (_elevationAnimation.value * 10),
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon with gradient background
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.first.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Label
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Value
                  Expanded(
                    child: Text(
                      widget.value,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Custom painter for animated background particles
class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF667EEA).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Create floating particles
    for (int i = 0; i < 20; i++) {
      final double x = (size.width * 0.1 * i) % size.width;
      final double y = (size.height * 0.3 +
          50 * Math.sin(animationValue * 2 * Math.pi + i)) % size.height;
      final double radius = 2 + Math.sin(animationValue * Math.pi + i) * 1;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Create gradient orbs
    final gradientPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF667EEA).withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.3), radius: 100));

    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.3),
        100 + 20 * Math.sin(animationValue * Math.pi),
        gradientPaint
    );

    final gradientPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF764BA2).withOpacity(0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * 0.8, size.height * 0.7), radius: 80));

    canvas.drawCircle(
        Offset(size.width * 0.8, size.height * 0.7),
        80 + 15 * Math.cos(animationValue * Math.pi * 1.5),
        gradientPaint2
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}