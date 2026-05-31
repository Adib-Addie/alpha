import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animations/animations.dart';

class StudentDashLeaderboardPage extends StatefulWidget {
  final String? initialBatch;
  const StudentDashLeaderboardPage({Key? key, this.initialBatch}) : super(key: key);

  @override
  _StudentDashLeaderboardPageState createState() => _StudentDashLeaderboardPageState();
}

class _StudentDashLeaderboardPageState extends State<StudentDashLeaderboardPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  String? _selectedBatch;
  late AnimationController _headerController;
  late AnimationController _loaderController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _loaderRotationAnimation;
  late Animation<double> _loaderPulseAnimation;

  // Cache for better performance
  List<String>? _cachedBatches;
  Map<String, List<Map<String, dynamic>>> _cachedLeaderboards = {};

  // Reduced animation controllers for better performance
  List<AnimationController> _cardControllers = [];
  List<Animation<double>> _cardFadeAnimations = [];
  List<Animation<Offset>> _cardSlideAnimations = [];

  static const List<List<Color>> cardGradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF10B981), Color(0xFF38EF7D)],
    [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    [Color(0xFFF59E0B), Color(0xFFEAB308)],
    [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
    [Color(0xFF845EC2), Color(0xFFD65DB1)],
    [Color(0xFF4E54C8), Color(0xFF8F94FB)],
    [Color(0xFFFF9A8B), Color(0xFFA8E6CF)],
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _selectedBatch = widget.initialBatch;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Reduced duration
    );
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuad),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    _headerController.forward();

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Reduced duration
    );
    _loaderRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.linear),
    );
    _loaderPulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _loaderController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeCardAnimations(int itemCount) {
    // Dispose existing controllers
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    _cardControllers.clear();
    _cardFadeAnimations.clear();
    _cardSlideAnimations.clear();

    // Limit animations for performance - only animate first 10 items
    final animationCount = itemCount > 10 ? 10 : itemCount;

    for (int i = 0; i < animationCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400), // Reduced duration
      );
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutQuad),
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.1), // Reduced slide distance
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );

      _cardControllers.add(controller);
      _cardFadeAnimations.add(fadeAnimation);
      _cardSlideAnimations.add(slideAnimation);

      // Reduced delay for faster loading
      Future.delayed(Duration(milliseconds: i * 50), () {
        if (mounted) controller.forward();
      });
    }
  }

  Widget _buildCustomLoader({String text = "Loading..."}) {
    if (!_loaderController.isAnimating) {
      _loaderController.repeat();
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _loaderController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loaderRotationAnimation.value * 2 * 3.14159,
                child: Transform.scale(
                  scale: _loaderPulseAnimation.value,
                  child: Container(
                    width: 60, // Reduced size for better performance
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.leaderboard_rounded,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _fetchBatches() async {
    if (_cachedBatches != null) {
      return _cachedBatches!;
    }

    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();

      final batches = studentsSnapshot.docs
          .map((doc) => doc['batch'] as String?)
          .where((batch) => batch != null && batch.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      batches.sort();
      _cachedBatches = batches; // Cache the result
      return batches;
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to fetch batches: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboardData(String batch) async {
    // Check cache first
    if (_cachedLeaderboards.containsKey(batch)) {
      return _cachedLeaderboards[batch]!;
    }

    try {
      // Optimized query with limit and indexing
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('batch', isEqualTo: batch)
          .limit(100) // Limit results for better performance
          .get();

      final studentScores = <String, Map<String, dynamic>>{};
      final futures = <Future>[];

      for (var studentDoc in studentsSnapshot.docs) {
        final studentId = studentDoc.id;
        final studentData = studentDoc.data();

        studentScores[studentId] = {
          'score': 0.0,
          'totalQuestions': 0.0,
          'name': studentData['name'] ?? 'Unknown',
          'profilePictureUrl': studentData['profilePictureUrl'] as String?,
          'testsCompleted': 0,
        };

        // Use batch processing for better performance
        futures.add(
            FirebaseFirestore.instance
                .collection('test_results')
                .where('studentId', isEqualTo: studentId)
                .get()
                .then((resultsSnapshot) {
              for (var doc in resultsSnapshot.docs) {
                final data = doc.data();
                final score = (data['score'] as num?)?.toDouble() ?? 0.0;
                final totalQuestions = (data['total'] as num?)?.toDouble() ?? 0.0;
                studentScores[studentId]!['score'] += score;
                studentScores[studentId]!['totalQuestions'] += totalQuestions;
                studentScores[studentId]!['testsCompleted']++;
              }
            })
        );
      }

      await Future.wait(futures);

      final leaderboard = studentScores.entries.map((entry) {
        final percentage = entry.value['totalQuestions'] > 0
            ? (entry.value['score'] / entry.value['totalQuestions'] * 100).toStringAsFixed(1)
            : '0.0';
        return {
          'studentId': entry.key,
          'name': entry.value['name'],
          'score': entry.value['score'],
          'totalQuestions': entry.value['totalQuestions'],
          'percentage': percentage,
          'profilePictureUrl': entry.value['profilePictureUrl'],
          'testsCompleted': entry.value['testsCompleted'],
        };
      }).toList();

      leaderboard.sort((a, b) => b['score'].compareTo(a['score']));

      // Cache the result
      _cachedLeaderboards[batch] = leaderboard;

      return leaderboard;
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to fetch leaderboard: $e');
      }
      return [];
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Color> _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
      default:
        return cardGradients[(rank - 1) % cardGradients.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

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
          child: CustomScrollView( // Using CustomScrollView for better performance
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildHeader(),
                ),
              ),
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: Transform.scale(
            scale: _headerScaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
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
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF334155).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildBackButton(),
                  const SizedBox(width: 12),
                  Expanded(child: _buildHeaderContent()),
                  if (_selectedBatch == null && widget.initialBatch == null)
                    _buildRefreshButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
        onPressed: () {
          if (widget.initialBatch != null) {
            Navigator.pop(context);
          } else if (_selectedBatch != null) {
            setState(() => _selectedBatch = null);
          } else {
            Navigator.pop(context);
          }
        },
        tooltip: widget.initialBatch != null
            ? 'Back'
            : (_selectedBatch != null ? 'Back to Batches' : 'Back'),
      ),
    );
  }

  Widget _buildHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                  Icons.leaderboard_rounded,
                  color: Color(0xFF667EEA),
                  size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedBatch != null
                    ? '$_selectedBatch Leaderboard'
                    : 'Student Leaderboard',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _selectedBatch != null
              ? 'Rankings based on test performance'
              : 'Select a batch to view student rankings',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
        onPressed: () {
          // Clear cache and refresh
          _cachedBatches = null;
          _cachedLeaderboards.clear();
          setState(() {});
        },
        tooltip: 'Refresh',
      ),
    );
  }

  Widget _buildContent() {
    if (_selectedBatch == null && widget.initialBatch == null) {
      return _buildBatchSelection();
    } else {
      return _buildLeaderboard();
    }
  }

  Widget _buildBatchSelection() {
    return FutureBuilder<List<String>>(
      future: _fetchBatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCustomLoader(text: "Loading batches...");
        }
        if (snapshot.hasError) {
          return _buildErrorView('Error Loading Batches', 'Please try again later');
        }

        final batches = snapshot.data ?? [];
        if (batches.isEmpty) {
          return _buildEmptyView(
            Icons.group_rounded,
            'No Batches Available',
            'Students need to be added to view batches',
          );
        }

        _initializeCardAnimations(batches.length);

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 300,
            childAspectRatio: 1.1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final batch = batches[index];
            final gradient = cardGradients[index % cardGradients.length];
            final shouldAnimate = index < _cardFadeAnimations.length;

            final card = EnhancedBatchCard(
              batch: batch,
              gradient: gradient,
              onTap: () => setState(() => _selectedBatch = batch),
            );

            if (shouldAnimate) {
              return FadeTransition(
                opacity: _cardFadeAnimations[index],
                child: SlideTransition(
                  position: _cardSlideAnimations[index],
                  child: card,
                ),
              );
            }
            return card;
          },
        );
      },
    );
  }

  Widget _buildLeaderboard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchLeaderboardData(_selectedBatch ?? widget.initialBatch!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCustomLoader(text: "Loading leaderboard...");
        }
        if (snapshot.hasError) {
          return _buildErrorView('Error Loading Leaderboard', 'Please try again later');
        }

        final leaderboard = snapshot.data ?? [];
        if (leaderboard.isEmpty) {
          return _buildEmptyView(
            Icons.emoji_events_rounded,
            'No Test Results Available',
            'Students need to complete tests to appear on the leaderboard',
          );
        }

        _initializeCardAnimations(leaderboard.length);

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: leaderboard.length,
          itemBuilder: (context, index) {
            final student = leaderboard[index];
            final gradient = _getRankGradient(index + 1);
            final shouldAnimate = index < _cardFadeAnimations.length;

            final card = EnhancedLeaderboardCard(
              student: student,
              rank: index + 1,
              gradient: gradient,
            );

            if (shouldAnimate) {
              return FadeTransition(
                opacity: _cardFadeAnimations[index],
                child: SlideTransition(
                  position: _cardSlideAnimations[index],
                  child: card,
                ),
              );
            }
            return card;
          },
        );
      },
    );
  }

  Widget _buildErrorView(String title, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 60,
            color: const Color(0xFFE53E3E).withOpacity(0.7),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(IconData icon, String title, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 60,
            color: const Color(0xFF94A3B8).withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Optimized Batch Card
class EnhancedBatchCard extends StatefulWidget {
  final String batch;
  final List<Color> gradient;
  final VoidCallback onTap;

  const EnhancedBatchCard({
    Key? key,
    required this.batch,
    required this.gradient,
    required this.onTap,
  }) : super(key: key);

  @override
  _EnhancedBatchCardState createState() => _EnhancedBatchCardState();
}

class _EnhancedBatchCardState extends State<EnhancedBatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _hoverController.forward(),
      onTapUp: (_) => _hoverController.reverse(),
      onTapCancel: () => _hoverController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.group_rounded,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.batch,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'View Rankings',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

// Optimized Leaderboard Card
class EnhancedLeaderboardCard extends StatefulWidget {
  final Map<String, dynamic> student;
  final int rank;
  final List<Color> gradient;

  const EnhancedLeaderboardCard({
    Key? key,
    required this.student,
    required this.rank,
    required this.gradient,
  }) : super(key: key);

  @override
  _EnhancedLeaderboardCardState createState() => _EnhancedLeaderboardCardState();
}

class _EnhancedLeaderboardCardState extends State<EnhancedLeaderboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.rank <= 3) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  IconData _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return Icons.emoji_events_rounded;
      case 2:
        return Icons.military_tech_rounded;
      case 3:
        return Icons.workspace_premium_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student['name'] ?? 'Unknown';
    final profilePictureUrl = widget.student['profilePictureUrl'] as String?;
    final testsCompleted = widget.student['testsCompleted'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B).withOpacity(0.8),
            const Color(0xFF334155).withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.gradient.first.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.gradient.first.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank Badge
          AnimatedBuilder(
            animation: widget.rank <= 3 ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              return Transform.scale(
                scale: widget.rank <= 3 ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getRankIcon(widget.rank),
                        size: widget.rank <= 3 ? 18 : 16,
                        color: Colors.white,
                      ),
                      Text(
                        '#${widget.rank}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Profile Picture
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: profilePictureUrl != null
                  ? Image.network(
                profilePictureUrl,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withOpacity(0.5),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
                  : Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Student Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.gradient.first.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.gradient.first.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${widget.student['percentage']}%',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: widget.gradient.first,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${widget.student['score'].toInt()}/${widget.student['totalQuestions'].toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white60,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.quiz_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$testsCompleted test${testsCompleted != 1 ? 's' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Achievement Badge for Top 3
          if (widget.rank <= 3)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.first.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.rank == 1
                          ? Icons.stars_rounded
                          : widget.rank == 2
                          ? Icons.star_rounded
                          : Icons.star_half_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}