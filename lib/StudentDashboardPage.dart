import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

import 'LoginPage.dart';
import 'StudentDashLeaderboardPage.dart';
import 'SubjectListScreen.dart';
import 'TestHistoryScreen.dart';
import 'ProfileStudentPage.dart';
import 'FeedbackScreen.dart';
import 'AboutUsScreen.dart';
import 'StudentLeaderboardPage.dart';
import 'StudyMaterialPage.dart';

/// A modern student dashboard optimized for Windows Desktop, matching TeacherDashboardPage design
class StudentDashboardPage extends StatefulWidget {
  final String studentName;
  const StudentDashboardPage({Key? key, required this.studentName}) : super(key: key);

  @override
  _StudentDashboardPageState createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _welcomeController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  StreamSubscription<QuerySnapshot>? _testResultsSubscription;
  StreamSubscription<DocumentSnapshot>? _studentSubscription;
  int _testCount = 0;
  int _highestScore = 0;
  String _studentLevel = 'Beginner';
  String _admissionNumber = 'N/A';
  String? _studentBatch;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupFirestoreListeners();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOutBack),
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _mainAnimationController.forward();
    _welcomeController.repeat(reverse: true);
    _backgroundController.repeat();
  }

  void _setupFirestoreListeners() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _studentSubscription = FirebaseFirestore.instance
        .collection('students')
        .doc(userId)
        .snapshots()
        .listen(
          (snapshot) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              if (snapshot.exists) {
                final data = snapshot.data() as Map<String, dynamic>;
                _admissionNumber = data['admissionNumber'] ?? 'N/A';
                _studentBatch = data['batch'] as String?;
              } else {
                _admissionNumber = 'N/A';
                _studentBatch = null;
              }
            });
          });
        }
      },
      onError: (error) {
        debugPrint('Firestore student listener error: $error');
        if (mounted) {
          setState(() {
            _admissionNumber = 'N/A';
            _studentBatch = null;
          });
        }
      },
    );

    _testResultsSubscription = FirebaseFirestore.instance
        .collection('test_results')
        .where('studentId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _testCount = snapshot.docs.length;
              if (_testCount > 0) {
                _highestScore = snapshot.docs
                    .map((doc) => (doc['score'] as num?)?.toInt() ?? 0)
                    .reduce((a, b) => a > b ? a : b);
                _studentLevel = _highestScore >= 80
                    ? 'Advanced'
                    : _highestScore >= 50
                    ? 'Intermediate'
                    : 'Beginner';
              } else {
                _highestScore = 0;
                _studentLevel = 'Beginner';
              }
            });
          });
        }
      },
      onError: (error) {
        debugPrint('Firestore test results listener error: $error');
        if (mounted) {
          setState(() {
            _testCount = 0;
            _highestScore = 0;
            _studentLevel = 'Beginner';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _welcomeController.dispose();
    _backgroundController.dispose();
    _testResultsSubscription?.cancel();
    _studentSubscription?.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Error in logout! Please try again.'),
              ],
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
              const Color(0xFF334155),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F172A).withOpacity(0.9),
                    const Color(0xFF1E293B).withOpacity(0.8),
                    const Color(0xFF334155).withOpacity(0.9),
                  ],
                  stops: [
                    0.0,
                    0.5 + (_backgroundAnimation.value * 0.2),
                    1.0,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      _buildSidebar(),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildMainContent(),
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
    );
  }

  Widget _buildSidebar() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
          width: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF475569).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            SizedBox(
            height: 240,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _welcomeController,
                          builder: (context, child) {
                            return Container(
                              width: 110 + (_welcomeController.value * 10),
                              height: 110 + (_welcomeController.value * 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF667EEA).withOpacity(0.3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667EEA).withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        AnimatedBuilder(
                          animation: _welcomeController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_welcomeController.value * 0.1),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF667EEA),
                                      Color(0xFF764BA2),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667EEA).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/logoimg.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Student',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      'Dashboard',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
            const Divider(
              color: Color(0xFF475569),
              thickness: 0.5,
              height: 1,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNavItem('MCQ Test Series', Icons.quiz_rounded, 0),
                    _buildNavItem('Test Results', Icons.assessment_rounded, 1),
                    _buildNavItem('Leaderboard', Icons.leaderboard_rounded, 2),
                    _buildNavItem('Study Material', Icons.library_books_rounded, 3),
                    _buildNavItem('Profile', Icons.person_rounded, 4),
                    _buildNavItem('Feedback / Doubts', Icons.feedback_rounded, 5),
                    _buildNavItem('About Us', Icons.info_rounded, 6),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: _buildLogoutButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToPage(index),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF475569).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: const Color(0xFF667EEA),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE53E3E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE53E3E).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: const Color(0xFFE53E3E),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFE53E3E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeHeader(),
        const SizedBox(height: 24),
        _buildStatsRow(),
        const SizedBox(height: 24),
        _buildQuickActionsGrid(),
        const SizedBox(height: 24),
        _buildFooter(),
      ],
    );
  }

  Widget _buildWelcomeHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF334155).withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome To Alpha Graphic!',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your progress and excel in your tests',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Admission Number', _admissionNumber, Icons.confirmation_number_rounded, const Color(0xFFF59E0B)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Tests Given', '$_testCount', Icons.quiz_rounded, const Color(0xFF10B981)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Highest Score', '$_highestScore', Icons.star_rounded, const Color(0xFF3B82F6)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard('Student Level', _studentLevel, Icons.trending_up_rounded, const Color(0xFF8B5CF6)),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF475569).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.trending_up_rounded,
                      color: const Color(0xFF10B981),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      ActionItem('MCQ Test Series', 'Start practice tests', Icons.quiz_rounded,
          [const Color(0xFF667EEA), const Color(0xFF764BA2)], 0),
      ActionItem('Test Results', 'View your scores', Icons.assessment_rounded,
          [const Color(0xFF10B981), const Color(0xFF38EF7D)], 1),
      ActionItem('Leaderboard', 'View batch rankings', Icons.leaderboard_rounded,
          [const Color(0xFF14B8A6), const Color(0xFF10B981)], 2),
      ActionItem('Study Material', 'Download study resources', Icons.library_books_rounded,
          [const Color(0xFFEC4899), const Color(0xFFF472B6)], 3),
      ActionItem('Profile', 'View your info', Icons.person_rounded,
          [const Color(0xFFFC466B), const Color(0xFF3F5EFB)], 4),
      ActionItem('Feedback / Doubts', 'Send feedback to teacher', Icons.feedback_rounded,
          [const Color(0xFFF59E0B), const Color(0xFFEAB308)], 5),
      ActionItem('About Us', 'Learn about our company', Icons.info_rounded,
          [const Color(0xFF6B73FF), const Color(0xFF667EEA)], 6),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return ModernActionCard(
          action: action,
          onPressed: () => _navigateToPage(action.index),
          delay: index * 100,
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'Developed By Brolytics Technologies',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _navigateToPage(int index) {
    Widget page;
    switch (index) {
      case 0:
        page = const SubjectListScreen();
        break;
      case 1:
        page = const TestHistoryScreen();
        break;
      case 2:
        page = StudentDashLeaderboardPage(initialBatch: _studentBatch);
        break;
      case 3:
        page = const StudyMaterialPage();
        break;
      case 4:
        page = const ProfileStudentPage();
        break;
      case 5:
        page = const FeedbackScreen();
        break;
      case 6:
        page = const AboutUsScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.scaled,
              child: child,
            ),
      ),
    );
  }
}

class ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final int index;

  ActionItem(this.title, this.subtitle, this.icon, this.gradient, this.index);
}

class ModernActionCard extends StatefulWidget {
  final ActionItem action;
  final VoidCallback onPressed;
  final int delay;

  const ModernActionCard({
    Key? key,
    required this.action,
    required this.onPressed,
    required this.delay,
  }) : super(key: key);

  @override
  _ModernActionCardState createState() => _ModernActionCardState();
}

class _ModernActionCardState extends State<ModernActionCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _hoverController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: GestureDetector(
                  onTap: widget.onPressed,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF475569).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.action.gradient.first.withOpacity(_isHovered ? 0.3 : 0.1),
                          blurRadius: _isHovered ? 20 : 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.action.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: widget.action.gradient.first.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: AnimatedScale(
                            scale: _isHovered ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              widget.action.icon,
                              size: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.action.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.action.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _setHovered(bool hovered) {
    setState(() => _isHovered = hovered);
    if (hovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }
}