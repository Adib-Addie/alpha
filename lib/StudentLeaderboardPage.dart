import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentLeaderboardPage extends StatefulWidget {
  const StudentLeaderboardPage({Key? key}) : super(key: key);

  @override
  _StudentLeaderboardPageState createState() => _StudentLeaderboardPageState();
}

class _StudentLeaderboardPageState extends State<StudentLeaderboardPage> {
  String? _selectedBatch;

  final List<List<Color>> cardGradients = [
    [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
    [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [const Color(0xFF0A0020), const Color(0xFF150040), const Color(0xFF200060)],
    [const Color(0xFF12002F), const Color(0xFF1C0050), const Color(0xFF2D0080)],
    [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
    [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [const Color(0xFF0A0020), const Color(0xFF150040), const Color(0xFF200060)],
    [const Color(0xFF12002F), const Color(0xFF1C0050), const Color(0xFF2D0080)],
    [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
  ];

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
                child: const Icon(Icons.error_outline, color: AppTheme.textPrimary, size: 20),
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
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Failed to fetch batches: $e',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textPrimary.withOpacity(0.9),
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
                child: const Icon(Icons.error_outline, color: AppTheme.textPrimary, size: 20),
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
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Failed to fetch leaderboard: $e',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textPrimary.withOpacity(0.9),
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
              AppTheme.backgroundStart,
              AppTheme.backgroundMid,
              AppTheme.backgroundEnd,
              AppTheme.border,
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
                      const Color(0xFF7B2FBE).withOpacity(0.1),
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
                      AppTheme.backgroundEnd.withOpacity(0.08),
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
                        Container(
                          width: 1000,
                          padding: const EdgeInsets.all(28),
                          margin: const EdgeInsets.only(bottom: 32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.backgroundMid.withOpacity(0.95),
                                AppTheme.backgroundEnd.withOpacity(0.9),
                                AppTheme.divider.withOpacity(0.85),
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
                                color: const Color(0xFF7B2FBE).withOpacity(0.1),
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
                                    colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7B2FBE).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: AppTheme.textPrimary,
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
                                                const Color(0xFF7B2FBE).withOpacity(0.2),
                                                AppTheme.backgroundEnd.withOpacity(0.2),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: const Color(0xFF7B2FBE).withOpacity(0.3),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.leaderboard_rounded,
                                            color: Color(0xFF7B2FBE),
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
                                              color: AppTheme.textPrimary,
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
                                      color: AppTheme.textPrimary,
                                      size: 28,
                                    ),
                                    onPressed: () => setState(() {}),
                                    tooltip: 'Refresh',
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: _selectedBatch == null
                              ? FutureBuilder<List<String>>(
                            future: _fetchBatches(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FBE)));
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
                                  return ModernBatchCard(
                                    batch: batch,
                                    gradient: gradient,
                                    onTap: () => setState(() => _selectedBatch = batch),
                                    index: index,
                                  );
                                },
                              );
                            },
                          )
                              : FutureBuilder<List<Map<String, dynamic>>>(
                            future: _fetchLeaderboardData(_selectedBatch!),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FBE)));
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
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: leaderboard.length,
                                itemBuilder: (context, index) {
                                  final student = leaderboard[index];
                                  final gradient = _getRankGradient(index + 1);
                                  return ModernLeaderboardCard(
                                    student: student,
                                    rank: index + 1,
                                    gradient: gradient,
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
                                    colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.code_rounded,
                                  color: AppTheme.textPrimary,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Developed by Brolytics Technologies',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
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
                      : [AppTheme.textSecondary, AppTheme.textMuted],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isError ? const Color(0xFFE53E3E) : AppTheme.textSecondary)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
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
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case 2:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B4513)];
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

class _ModernBatchCardState extends State<ModernBatchCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
                        color: AppTheme.textPrimary,
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
                    color: AppTheme.textPrimary,
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
                      color: AppTheme.textPrimary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'View Rankings',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
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
                    color: AppTheme.textPrimary.withOpacity(0.9),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _ModernLeaderboardCardState extends State<ModernLeaderboardCard> {
  bool _isHovered = false;

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
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundMid.withOpacity(0.95),
              AppTheme.backgroundEnd.withOpacity(0.9),
              AppTheme.divider.withOpacity(0.85),
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
                        color: AppTheme.textPrimary,
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
                    color: AppTheme.textPrimary,
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
                      color: AppTheme.textPrimary,
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
                              color: AppTheme.textPrimary.withOpacity(0.9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$percentage%',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
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
                          color: AppTheme.textPrimary.withOpacity(0.8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$testsCompleted tests completed',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary.withOpacity(0.8),
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
  }
}
