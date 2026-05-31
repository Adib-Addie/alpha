import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animations/animations.dart';

class StudentLeaderboardPage extends StatefulWidget {
  const StudentLeaderboardPage({Key? key}) : super(key: key);

  @override
  _StudentLeaderboardPageState createState() => _StudentLeaderboardPageState();
}

class _StudentLeaderboardPageState extends State<StudentLeaderboardPage> with TickerProviderStateMixin {
  String? _selectedBatch;
  late AnimationController _headerController;
  AnimationController? _loaderController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  Animation<double>? _loaderRotationAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardFadeAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;

  final List<List<Color>> cardGradients = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    [const Color(0xFF10B981), const Color(0xFF38EF7D)],
    [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
    [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
    [const Color(0xFFFF6B6B), const Color(0xFF4ECDC4)],
    [const Color(0xFF845EC2), const Color(0xFFD65DB1)],
    [const Color(0xFF4E54C8), const Color(0xFF8F94FB)],
    [const Color(0xFFFF9A8B), const Color(0xFFA8E6CF)],
    [const Color(0xFF00C9FF), const Color(0xFF92FE9D)],
    [const Color(0xFFFC00FF), const Color(0xFF00DBDE)],
    [const Color(0xFFFFCC70), const Color(0xFFC850C0)],
    [const Color(0xFF4481EB), const Color(0xFF04BEFE)],
  ];

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuart),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );

    _headerController.forward();

    _cardControllers = [];
    _cardFadeAnimations = [];
    _cardSlideAnimations = [];
  }

  @override
  void dispose() {
    _headerController.dispose();
    _loaderController?.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
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
          CurvedAnimation(parent: controller, curve: Curves.easeOutQuart),
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: controller, curve: Curves.elasticOut),
        );

        _cardControllers.add(controller);
        _cardFadeAnimations.add(fadeAnimation);
        _cardSlideAnimations.add(slideAnimation);

        Future.delayed(Duration(milliseconds: i * 100), () {
          if (mounted) controller.forward();
        });
      }
    }
  }

  Widget _buildCustomLoader({String text = 'Loading...'}) {
    // Initialize loader controller only when needed
    if (_loaderController == null) {
      _loaderController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      )..repeat();

      _loaderRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _loaderController!, curve: Curves.linear),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _loaderRotationAnimation!,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _loaderRotationAnimation!.value * 2 * 3.14159,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const Icon(
                  Icons.leaderboard_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 150,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: AnimatedBuilder(
              animation: _loaderController!,
              builder: (context, child) {
                return Stack(
                  children: [
                    Container(
                      width: 150 * (_loaderController!.value),
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _fetchBatches() async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance.collection('students').get();
      final batches = studentsSnapshot.docs
          .map((doc) => doc['batch'] as String?)
          .where((batch) => batch != null && batch.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();
      batches.sort();
      return batches;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error Occurred',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Failed to fetch batches: $e',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLeaderboardData(String batch) async {
    try {
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('batch', isEqualTo: batch)
          .get();

      final studentScores = <String, Map<String, dynamic>>{};
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

        final resultsSnapshot = await FirebaseFirestore.instance
            .collection('test_results')
            .where('studentId', isEqualTo: studentId)
            .get();

        for (var doc in resultsSnapshot.docs) {
          final data = doc.data();
          final score = (data['score'] as num?)?.toDouble() ?? 0.0;
          final totalQuestions = (data['total'] as num?)?.toDouble() ?? 0.0;
          studentScores[studentId]!['score'] += score;
          studentScores[studentId]!['totalQuestions'] += totalQuestions;
          studentScores[studentId]!['testsCompleted']++;
        }
      }

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
      return leaderboard;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.error_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error Occurred',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Failed to fetch leaderboard: $e',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      return [];
    }
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
              Color(0xFF475569),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF667EEA).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF764BA2).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Main content
            Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 1200,
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _headerController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _headerFadeAnimation,
                              child: Transform.scale(
                                scale: _headerScaleAnimation.value,
                                child: Container(
                                  width: 1000,
                                  padding: const EdgeInsets.all(28),
                                  margin: const EdgeInsets.only(bottom: 32),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF1E293B).withOpacity(0.95),
                                        const Color(0xFF334155).withOpacity(0.9),
                                        const Color(0xFF475569).withOpacity(0.85),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF000000).withOpacity(0.3),
                                        blurRadius: 30,
                                        offset: const Offset(0, 12),
                                        spreadRadius: 0,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF667EEA).withOpacity(0.1),
                                        blurRadius: 40,
                                        offset: const Offset(0, 0),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF667EEA).withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back_rounded,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          onPressed: () {
                                            if (_selectedBatch != null) {
                                              setState(() => _selectedBatch = null);
                                            } else {
                                              Navigator.pop(context);
                                            }
                                          },
                                          tooltip: _selectedBatch != null ? 'Back to Batches' : 'Back',
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        const Color(0xFF667EEA).withOpacity(0.2),
                                                        const Color(0xFF764BA2).withOpacity(0.2),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(14),
                                                    border: Border.all(
                                                      color: const Color(0xFF667EEA).withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.leaderboard_rounded,
                                                    color: Color(0xFF667EEA),
                                                    size: 32,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Text(
                                                    _selectedBatch ?? 'Student Leaderboard',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 38,
                                                      fontWeight: FontWeight.w900,
                                                      color: Colors.white,
                                                      letterSpacing: -0.8,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.white.withOpacity(0.2),
                                                ),
                                              ),
                                              child: Text(
                                                _selectedBatch != null
                                                    ? 'Rankings based on test performance'
                                                    : 'Select a batch to view student rankings',
                                                style: GoogleFonts.inter(
                                                  fontSize: 16,
                                                  color: Colors.white.withOpacity(0.95),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_selectedBatch == null)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.white.withOpacity(0.1),
                                                Colors.white.withOpacity(0.05),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.2),
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.refresh_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                            onPressed: () => setState(() {}),
                                            tooltip: 'Refresh',
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: _selectedBatch == null
                              ? FutureBuilder<List<String>>(
                            future: _fetchBatches(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildCustomLoader(text: 'Loading Batches...');
                              }
                              if (snapshot.hasError) {
                                return _buildErrorWidget(
                                  icon: Icons.error_outline_rounded,
                                  title: 'Error Loading Batches',
                                  subtitle: 'Please try again later',
                                );
                              }
                              final batches = snapshot.data ?? [];
                              if (batches.isEmpty) {
                                return _buildErrorWidget(
                                  icon: Icons.group_rounded,
                                  title: 'No Batches Available',
                                  subtitle: 'Students need to be added to view batches',
                                  isError: false,
                                );
                              }
                              _initializeCardAnimations(batches.length);
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 380,
                                  childAspectRatio: 1.3,
                                  crossAxisSpacing: 20,
                                  mainAxisSpacing: 20,
                                ),
                                itemCount: batches.length,
                                itemBuilder: (context, index) {
                                  final batch = batches[index];
                                  final gradient = cardGradients[index % cardGradients.length];
                                  return FadeTransition(
                                    opacity: _cardFadeAnimations[index],
                                    child: SlideTransition(
                                      position: _cardSlideAnimations[index],
                                      child: ModernBatchCard(
                                        batch: batch,
                                        gradient: gradient,
                                        onTap: () => setState(() => _selectedBatch = batch),
                                        index: index,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                              : FutureBuilder<List<Map<String, dynamic>>>(
                            future: _fetchLeaderboardData(_selectedBatch!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return _buildCustomLoader(text: 'Loading Leaderboard...');
                              }
                              if (snapshot.hasError) {
                                return _buildErrorWidget(
                                  icon: Icons.error_outline_rounded,
                                  title: 'Error Loading Leaderboard',
                                  subtitle: 'Please try again later',
                                );
                              }
                              final leaderboard = snapshot.data ?? [];
                              if (leaderboard.isEmpty) {
                                return _buildErrorWidget(
                                  icon: Icons.emoji_events_rounded,
                                  title: 'No Test Results Available',
                                  subtitle: 'Students need to complete tests to appear on the leaderboard',
                                  isError: false,
                                );
                              }
                              _initializeCardAnimations(leaderboard.length);
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: leaderboard.length,
                                itemBuilder: (context, index) {
                                  final student = leaderboard[index];
                                  final gradient = _getRankGradient(index + 1);
                                  return FadeTransition(
                                    opacity: _cardFadeAnimations[index],
                                    child: SlideTransition(
                                      position: _cardSlideAnimations[index],
                                      child: ModernLeaderboardCard(
                                        student: student,
                                        rank: index + 1,
                                        gradient: gradient,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.code_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Developed By Brolytics Technologies',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isError = true,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isError
                      ? [const Color(0xFFE53E3E), const Color(0xFFFC8181)]
                      : [const Color(0xFF94A3B8), const Color(0xFF64748B)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isError ? const Color(0xFFE53E3E) : const Color(0xFF94A3B8))
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
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

  List<Color> _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)]; // Gold
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)]; // Silver
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)]; // Bronze
      default:
        return cardGradients[(rank - 1) % cardGradients.length];
    }
  }
}

class ModernBatchCard extends StatefulWidget {
  final String batch;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int index;

  const ModernBatchCard({
    Key? key,
    required this.batch,
    required this.gradient,
    required this.onTap,
    required this.index,
  }) : super(key: key);

  @override
  _ModernBatchCardState createState() => _ModernBatchCardState();
}

class _ModernBatchCardState extends State<ModernBatchCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _glowController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
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
        animation: Listenable.merge([_hoverAnimation, _glowAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(_isHovered ? 0.4 : 0.2),
                    width: _isHovered ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.first.withOpacity(_isHovered ? 0.6 : 0.3),
                      blurRadius: _isHovered ? 35 : 25,
                      offset: const Offset(0, 12),
                      spreadRadius: _isHovered ? 3 : 0,
                    ),
                    BoxShadow(
                      color: widget.gradient.last.withOpacity(_glowAnimation.value * 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 0),
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedScale(
                            scale: _isHovered ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(
                              Icons.group_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                          if (_isHovered)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: Text(
                        widget.batch,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.leaderboard_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View Rankings',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedRotation(
                      turns: _isHovered ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(_isHovered ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ModernLeaderboardCard extends StatefulWidget {
  final Map<String, dynamic> student;
  final int rank;
  final List<Color> gradient;

  const ModernLeaderboardCard({
    Key? key,
    required this.student,
    required this.rank,
    required this.gradient,
  }) : super(key: key);

  @override
  _ModernLeaderboardCardState createState() => _ModernLeaderboardCardState();
}

class _ModernLeaderboardCardState extends State<ModernLeaderboardCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _shimmerController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _shimmerAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    if (widget.rank <= 3) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  Widget _buildRankBadge() {
    IconData icon;
    List<Color> badgeGradient;
    Color textColor;

    switch (widget.rank) {
      case 1:
        icon = Icons.emoji_events_rounded;
        badgeGradient = [const Color(0xFFFFD700), const Color(0xFFFFA500)];
        textColor = const Color(0xFF8B4513);
        break;
      case 2:
        icon = Icons.workspace_premium_rounded;
        badgeGradient = [const Color(0xFFC0C0C0), const Color(0xFF9CA3AF)];
        textColor = const Color(0xFF374151);
        break;
      case 3:
        icon = Icons.military_tech_rounded;
        badgeGradient = [const Color(0xFFCD7F32), const Color(0xFFA0522D)];
        textColor = Colors.white;
        break;
      default:
        icon = Icons.star_rounded;
        badgeGradient = widget.gradient;
        textColor = Colors.white;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: badgeGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeGradient.first.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.rank <= 3)
            AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      begin: Alignment(-1.0 + _shimmerAnimation.value, -1.0),
                      end: Alignment(1.0 + _shimmerAnimation.value, 1.0),
                    ),
                  ),
                );
              },
            ),
          Icon(
            icon,
            color: textColor,
            size: 24,
          ),
          Positioned(
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.rank}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.student['name'] ?? 'Unknown';
    final profilePictureUrl = widget.student['profilePictureUrl'] as String?;
    final score = widget.student['score']?.toInt() ?? 0;
    final totalQuestions = widget.student['totalQuestions']?.toInt() ?? 0;
    final percentage = widget.student['percentage'] ?? '0.0';
    final testsCompleted = widget.student['testsCompleted'] ?? 0;

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.95),
                    const Color(0xFF334155).withOpacity(0.9),
                    const Color(0xFF475569).withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.gradient.first.withOpacity(_isHovered ? 0.8 : 0.4),
                  width: _isHovered ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(_isHovered ? 0.5 : 0.3),
                    blurRadius: _isHovered ? 30 : 20,
                    offset: const Offset(0, 8),
                    spreadRadius: _isHovered ? 3 : 0,
                  ),
                  BoxShadow(
                    color: const Color(0xFF000000).withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.first.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: profilePictureUrl != null
                        ? ClipOval(
                      child: Image.network(
                        profilePictureUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                        : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    widget.gradient.first.withOpacity(0.3),
                                    widget.gradient.last.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: widget.gradient.first.withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.quiz_rounded,
                                    size: 16,
                                    color: widget.gradient.first,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$score/$totalQuestions',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: widget.gradient.first,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.percent_rounded,
                                    size: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$percentage%',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.assignment_turned_in_rounded,
                                size: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$testsCompleted tests completed',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  AnimatedScale(
                    scale: _isHovered ? 1.15 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildRankBadge(),
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