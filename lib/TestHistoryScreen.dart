import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Screen showing the current student's past test results.
class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late AnimationController _noResultsController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _noResultsFadeAnimation;
  late Animation<double> _noResultsScaleAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardFadeAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;
  bool _isLoading = false;

  // Gradient colors for cards, matching FeedbackListPage
  final List<List<Color>> cardGradients = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    [const Color(0xFF10B981), const Color(0xFF38EF7D)],
    [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
    [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _cardControllers = [];
    _cardFadeAnimations = [];
    _cardSlideAnimations = [];
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _noResultsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuad),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    _noResultsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _noResultsController, curve: Curves.easeOutQuad),
    );
    _noResultsScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _noResultsController, curve: Curves.easeOutBack),
    );

    _headerController.forward();
    _pulseController.repeat(reverse: true);
    _noResultsController.forward();
  }

  void _initializeCardAnimations(int itemCount) {
    if (_cardControllers.length == itemCount) return;
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    _cardControllers.clear();
    _cardFadeAnimations.clear();
    _cardSlideAnimations.clear();

    for (int i = 0; i < itemCount; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutQuad),
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );

      _cardControllers.add(controller);
      _cardFadeAnimations.add(fadeAnimation);
      _cardSlideAnimations.add(slideAnimation);

      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _pulseController.dispose();
    _noResultsController.dispose();
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
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 1200,
                        minHeight: MediaQuery.of(context).size.height,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: FadeTransition(
                          opacity: _noResultsFadeAnimation,
                          child: ScaleTransition(
                            scale: _noResultsScaleAnimation,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person_off_rounded,
                                  size: 80,
                                  color: const Color(0xFF94A3B8).withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Not Logged In',
                                  style: GoogleFonts.inter(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please log in to view your test history',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                      maxWidth: 1200,
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header
                          AnimatedBuilder(
                            animation: _headerController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _headerFadeAnimation,
                                child: Transform.scale(
                                  scale: _headerScaleAnimation.value + (_pulseController.value * 0.03),
                                  child: Container(
                                    width: 1000,
                                    padding: const EdgeInsets.all(24),
                                    margin: const EdgeInsets.only(bottom: 24),
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
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF334155).withOpacity(0.5),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.2),
                                            ),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.arrow_back_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                            onPressed: () => Navigator.pop(context),
                                            tooltip: 'Back',
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Test History',
                                                style: GoogleFonts.inter(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: -0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'View your past test results',
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
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
                                ),
                              );
                            },
                          ),
                          // Test Results
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('test_results')
                                  .where('studentId', isEqualTo: user.uid)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error: ${snapshot.error}',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        color: const Color(0xFFE53E3E),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF667EEA),
                                      strokeWidth: 4,
                                    ),
                                  );
                                }

                                final results = snapshot.data!.docs.toList()
                                  ..sort((a, b) {
                                    final tsA = (a['timestamp'] as Timestamp?)?.toDate();
                                    final tsB = (b['timestamp'] as Timestamp?)?.toDate();
                                    if (tsA == null && tsB == null) return 0;
                                    if (tsA == null) return 1;
                                    if (tsB == null) return -1;
                                    return tsB.compareTo(tsA);
                                  });

                                if (results.isEmpty) {
                                  return FadeTransition(
                                    opacity: _noResultsFadeAnimation,
                                    child: ScaleTransition(
                                      scale: _noResultsScaleAnimation,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.history_rounded,
                                            size: 80,
                                            color: const Color(0xFF94A3B8).withOpacity(0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No Test Results',
                                            style: GoogleFonts.inter(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'You haven\'t taken any tests yet',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                _initializeCardAnimations(results.length);

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(0),
                                  itemCount: results.length,
                                  itemBuilder: (context, index) {
                                    final data = results[index].data() as Map<String, dynamic>;
                                    final subject = data['subjectName'] ?? 'Subject';
                                    final score = (data['score'] as num?)?.toInt() ?? 0;
                                    final total = (data['total'] as num?)?.toInt() ?? 0;
                                    final ts = (data['timestamp'] as Timestamp?)?.toDate();
                                    final dateStr = ts != null
                                        ? '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                                        : 'Unknown';
                                    final gradient = cardGradients[index % cardGradients.length];
                                    final percentage = total > 0 ? (score / total * 100).round() : 0;

                                    return TestResultCard(
                                      data: data,
                                      index: index,
                                      gradient: gradient,
                                      subject: subject,
                                      score: score,
                                      total: total,
                                      dateStr: dateStr,
                                      percentage: percentage,
                                      fadeAnimation: _cardFadeAnimations[index],
                                      slideAnimation: _cardSlideAnimations[index],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Footer
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'Developed By Brolytics Technologies',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
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
}

class TestResultCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;
  final List<Color> gradient;
  final String subject;
  final int score;
  final int total;
  final String dateStr;
  final int percentage;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;

  const TestResultCard({
    Key? key,
    required this.data,
    required this.index,
    required this.gradient,
    required this.subject,
    required this.score,
    required this.total,
    required this.dateStr,
    required this.percentage,
    required this.fadeAnimation,
    required this.slideAnimation,
  }) : super(key: key);

  @override
  _TestResultCardState createState() => _TestResultCardState();
}

class _TestResultCardState extends State<TestResultCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
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
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: SlideTransition(
        position: widget.slideAnimation,
        child: MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _hoverAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF475569).withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradient.first.withOpacity(_isHovered ? 0.4 : 0.2),
                        blurRadius: _isHovered ? 25 : 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon/Avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradient.first.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AnimatedScale(
                          scale: _isHovered ? 1.08 : 1.0,
                          duration: const Duration(milliseconds: 250),
                          child: Center(
                            child: Icon(
                              Icons.quiz_rounded,
                              size: 32,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.subject,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Score: ${widget.score} / ${widget.total} (${widget.percentage}%)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.dateStr,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Percentage Indicator
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.gradient.first.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.percentage}%',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.percentage >= 80
                                ? Colors.green
                                : widget.percentage >= 60
                                ? Colors.orange
                                : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}