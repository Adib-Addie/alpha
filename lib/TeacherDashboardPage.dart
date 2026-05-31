import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:intl/intl.dart';

import 'LoginPage.dart';
import 'SubjectsPage.dart';
import 'RegisterStudentPage.dart';
import 'ViewStudentsPage.dart';
import 'ShareAnnouncementPage.dart';
import 'FeedbackListPage.dart';
import 'AboutUsScreen.dart';
import 'ShareStudyMaterialPage.dart';
import 'StudentLeaderboardPage.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({Key? key}) : super(key: key);

  @override
  _TeacherDashboardPageState createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage>
    with TickerProviderStateMixin {
  // Animation controllers - reduced complexity
  late AnimationController _primaryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Data state
  StreamSubscription<QuerySnapshot>? _feedbackSubscription;
  int _unreadFeedbackCount = 0;
  final Map<String, int> _counts = {
    'students': 0,
    'questions': 0,
    'feedback': 0,
    'subjects': 0,
  };
  bool _isInitialized = false;

  // Cache user for performance
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;

    if (_currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      });
      return;
    }

    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _primaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _primaryController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _primaryController, curve: Curves.easeOutBack),
    );

    _primaryController.forward();
  }

  Future<void> _initializeData() async {
    if (_currentUser == null) return;

    try {
      // Setup feedback listener (synchronous operation)
      _setupFeedbackListener();

      // Fetch counts (async operation)
      await _fetchAllCounts();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Show UI even if data fetch fails
        });
      }
    }
  }

  void _setupFeedbackListener() {
    if (_currentUser == null) return;

    _feedbackSubscription = FirebaseFirestore.instance
        .collection('feedback')
        .where('read', isEqualTo: false)
        .limit(50) // Limit for better performance
        .snapshots()
        .listen(
          (snapshot) {
        if (mounted) {
          setState(() {
            _unreadFeedbackCount = snapshot.docs.length;
          });
        }
      },
      onError: (error) {
        debugPrint('Feedback listener error: $error');
        if (mounted) {
          setState(() {
            _unreadFeedbackCount = 0;
          });
        }
      },
    );
  }

  Future<void> _fetchAllCounts() async {
    if (_currentUser == null) return;

    try {
      // Use Future.wait for parallel execution with timeout
      final results = await Future.wait([
        _getCollectionCount('students'),
        _getCollectionCount('questions'),
        _getCollectionCount('feedback'),
        _getCollectionCount('subjects'),
      ], eagerError: false).timeout(
        const Duration(seconds: 10), // 10 second timeout
        onTimeout: () => [0, 0, 0, 0], // Default values on timeout
      );

      if (mounted) {
        setState(() {
          _counts['students'] = results[0];
          _counts['questions'] = results[1];
          _counts['feedback'] = results[2];
          _counts['subjects'] = results[3];
        });
      }
    } catch (e) {
      debugPrint('Error fetching counts: $e');
      // Set default values on error
      if (mounted) {
        setState(() {
          _counts['students'] = 0;
          _counts['questions'] = 0;
          _counts['feedback'] = 0;
          _counts['subjects'] = 0;
        });
      }
    }
  }

  Future<int> _getCollectionCount(String collection) async {
    try {
      // Try cache first for immediate response
      final cachedSnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .limit(1000) // Reasonable limit to avoid large queries
          .get(const GetOptions(source: Source.cache))
          .timeout(const Duration(seconds: 2));
      return cachedSnapshot.docs.length;
    } catch (e) {
      // Fallback to server with timeout
      try {
        final serverSnapshot = await FirebaseFirestore.instance
            .collection(collection)
            .limit(1000) // Same limit for consistency
            .get(const GetOptions(source: Source.server))
            .timeout(const Duration(seconds: 5));
        return serverSnapshot.docs.length;
      } catch (e) {
        debugPrint('Error fetching $collection count: $e');
        return 0;
      }
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _feedbackSubscription?.cancel();
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
        _showErrorSnackBar('Error in logout! Please try again.');
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
    );
  }

  Widget _buildSidebar() {
    return SlideTransition(
      position: _slideAnimation,
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
            _buildSidebarHeader(),
            const Divider(
              color: Color(0xFF475569),
              thickness: 0.5,
              height: 1,
            ),
            Expanded(
              child: _buildNavigationItems(),
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

  Widget _buildSidebarHeader() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.school,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Teacher Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItems() {
    final navItems = [
      _NavItem('Add Questions', Icons.quiz_rounded, 0),
      _NavItem('View Students', Icons.groups_rounded, 1),
      _NavItem('Register Student', Icons.person_add_rounded, 2),
      _NavItem('Announcements', Icons.campaign_rounded, 3),
      _NavItem('Feedback', Icons.feedback_rounded, 4),
      _NavItem('Share Study Material', Icons.library_books_rounded, 5),
      _NavItem('Student Leaderboard', Icons.leaderboard_rounded, 6),
      _NavItem('About Us', Icons.info_rounded, 7),
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: navItems.length,
      itemBuilder: (context, index) {
        final item = navItems[index];
        return _buildNavItemWidget(item, index);
      },
    );
  }

  Widget _buildNavItemWidget(_NavItem item, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 50)),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToPage(item.index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF475569).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: const Color(0xFF667EEA),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE53E3E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE53E3E).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                color: Color(0xFFE53E3E),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 24),
          if (_isInitialized) _buildStatsRow() else _buildLoadingStats(),
          const SizedBox(height: 24),
          _buildQuickActionsGrid(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
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
            color: const Color(0xFF334155).withOpacity(0.4),
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
                  'Welcome!',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your classroom with ease and efficiency',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildNotificationBadge(),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: const Icon(
            Icons.notifications_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        if (_unreadFeedbackCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE53E3E),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              child: Text(
                '$_unreadFeedbackCount',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingStats() {
    return Row(
      children: List.generate(4, (index) =>
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 16 : 0),
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF475569).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: _buildCustomLoader(size: 32),
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildCustomLoader({double size = 40}) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1200),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 6.28, // 2π radians for full rotation
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                  Color(0xFF667EEA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_rounded,
                size: size * 0.4,
                color: const Color(0xFF667EEA),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      _StatData('Total Students', _counts['students']!, Icons.people_rounded, const Color(0xFF10B981)),
      _StatData('Questions Added', _counts['questions']!, Icons.quiz_rounded, const Color(0xFF3B82F6)),
      _StatData('Feedback', _counts['feedback']!, Icons.feedback_rounded, const Color(0xFFF59E0B)),
      _StatData('Total Subjects', _counts['subjects']!, Icons.book_rounded, const Color(0xFF8B5CF6)),
    ];

    return Row(
      children: stats.map((stat) =>
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: stat != stats.last ? 16 : 0),
              child: _buildStatCard(stat),
            ),
          ),
      ).toList(),
    );
  }

  Widget _buildStatCard(_StatData stat) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: animationValue,
          child: Container(
            padding: const EdgeInsets.all(20),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: stat.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        stat.icon,
                        color: stat.color,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF10B981),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${stat.value}',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
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
      _ActionItem('Add Questions', 'Create new quiz questions', Icons.quiz_rounded, [const Color(0xFF667EEA), const Color(0xFF764BA2)], 0),
      _ActionItem('View Students', 'See all registered students', Icons.groups_rounded, [const Color(0xFF10B981), const Color(0xFF38EF7D)], 1),
      _ActionItem('Register Student', 'Add new student to class', Icons.person_add_rounded, [const Color(0xFFFC466B), const Color(0xFF3F5EFB)], 2),
      _ActionItem('Share Announcement', 'Notify students via WhatsApp', Icons.campaign_rounded, [const Color(0xFF7E5EF1), const Color(0xFF5E60CE)], 3),
      _ActionItem('Student Feedback', 'View feedback from students', Icons.feedback_rounded, [const Color(0xFFF59E0B), const Color(0xFFEAB308)], 4),
      _ActionItem('Share Study Material', 'Share resources with students', Icons.library_books_rounded, [const Color(0xFFEC4899), const Color(0xFFD946EF)], 5),
      _ActionItem('Student Leaderboard', 'View student rankings', Icons.leaderboard_rounded, [const Color(0xFF14B8A6), const Color(0xFF06B6D4)], 6),
      _ActionItem('About Us', 'Learn about our company', Icons.info_rounded, [const Color(0xFF6B73FF), const Color(0xFF667EEA)], 7),
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
        return _OptimizedActionCard(
          action: action,
          onPressed: () => _navigateToPage(action.index),
          delay: index * 50,
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
        page = const SubjectsPage();
        break;
      case 1:
        page = const ViewStudentsPage();
        break;
      case 2:
        page = const RegisterStudentPage();
        break;
      case 3:
        page = const ShareAnnouncementPage();
        break;
      case 4:
        page = const FeedbackListPage();
        break;
      case 5:
        page = const ShareStudyMaterialPage();
        break;
      case 6:
        page = const StudentLeaderboardPage();
        break;
      case 7:
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

// Helper classes for better code organization
class _NavItem {
  final String title;
  final IconData icon;
  final int index;

  _NavItem(this.title, this.icon, this.index);
}

class _StatData {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  _StatData(this.title, this.value, this.icon, this.color);
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final int index;

  _ActionItem(this.title, this.subtitle, this.icon, this.gradient, this.index);
}

// Optimized action card with reduced animations for better performance
class _OptimizedActionCard extends StatefulWidget {
  final _ActionItem action;
  final VoidCallback onPressed;
  final int delay;

  const _OptimizedActionCard({
    required this.action,
    required this.onPressed,
    required this.delay,
  });

  @override
  _OptimizedActionCardState createState() => _OptimizedActionCardState();
}

class _OptimizedActionCardState extends State<_OptimizedActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + widget.delay),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: MouseRegion(
              onEnter: (_) => _setHovered(true),
              onExit: (_) => _setHovered(false),
              child: AnimatedScale(
                scale: _isHovered ? 1.02 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: widget.onPressed,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF475569).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.action.gradient.first.withOpacity(_isHovered ? 0.2 : 0.1),
                          blurRadius: _isHovered ? 15 : 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.action.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: widget.action.gradient.first.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.action.icon,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.action.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.action.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
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
              ),
            ),
          ),
        );
      },
    );
  }

  void _setHovered(bool hovered) {
    if (_isHovered != hovered) {
      setState(() => _isHovered = hovered);
    }
  }
}