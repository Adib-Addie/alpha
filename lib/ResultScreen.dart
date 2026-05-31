import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

import 'StudentDashboardPage.dart';

/// Enhanced ResultScreen with improved design and animations
class ResultScreen extends StatefulWidget {
  final String subjectName;
  final int score;
  final int total;
  final List<Map<String, dynamic>> incorrect;

  const ResultScreen({
    super.key,
    required this.subjectName,
    required this.score,
    required this.total,
    required this.incorrect,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late AnimationController _scoreController;
  late AnimationController _buttonController;
  late AnimationController _successController;
  late AnimationController _backgroundController;

  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _scoreFadeAnimation;
  late Animation<Offset> _scoreSlideAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _successFadeAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _backgroundAnimation;

  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardFadeAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;

  bool _isLoading = false;

  final List<List<Color>> cardGradients = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    [const Color(0xFF06FFA5), const Color(0xFF3D8BFF)],
    [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
    [const Color(0xFFFFCE00), const Color(0xFFFF6B35)],
    [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
    [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCardAnimations();
  }

  void _initializeAnimations() {
    // Main controllers
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    // Animations
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: const Interval(0.2, 1.0, curve: Curves.elasticOut)),
    );
    _scoreFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutCubic),
    );
    _scoreSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutBack),
    );
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutCubic),
    );
    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );
    _successFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.easeOutCubic),
    );
    _successScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    // Start animations
    _headerController.forward();
    _pulseController.repeat(reverse: true);
    _backgroundController.repeat();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _scoreController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _buttonController.forward();
    });
    if (widget.incorrect.isEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _successController.forward();
      });
    }
  }

  void _initializeCardAnimations() {
    _cardControllers = [];
    _cardFadeAnimations = [];
    _cardSlideAnimations = [];

    for (int i = 0; i < widget.incorrect.length; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );

      _cardControllers.add(controller);
      _cardFadeAnimations.add(fadeAnimation);
      _cardSlideAnimations.add(slideAnimation);

      Future.delayed(Duration(milliseconds: 600 + (i * 200)), () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _pulseController.dispose();
    _scoreController.dispose();
    _buttonController.dispose();
    _successController.dispose();
    _backgroundController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _backToDashboard() {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const StudentDashboardPage(studentName: ''),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.horizontal,
                  fillColor: Colors.transparent,
                  child: child,
                ),
          ),
          (route) => false,
        );
      }
    });
  }

  double get _scorePercentage => (widget.score / widget.total * 100);

  Color get _scoreColor {
    if (_scorePercentage >= 90) return const Color(0xFF10B981);
    if (_scorePercentage >= 70) return const Color(0xFF3B82F6);
    if (_scorePercentage >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1200;

    return Scaffold(
      body: Stack(
        children: [
          // Enhanced animated background
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0F0F23),
                      const Color(0xFF1a1a2e).withOpacity(0.9),
                      const Color(0xFF16213e),
                      const Color(0xFF0f3460),
                    ],
                    stops: [
                      0.0,
                      0.3 + (_backgroundAnimation.value * 0.1),
                      0.7 + (_backgroundAnimation.value * 0.1),
                      1.0,
                    ],
                  ),
                ),
                child: CustomPaint(
                  painter: GeometricBackgroundPainter(_backgroundAnimation.value),
                  size: Size.infinite,
                ),
              );
            },
          ),

          // Loading overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF667EEA),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Returning to Dashboard...',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1400 : double.infinity),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Enhanced Header
                      AnimatedBuilder(
                        animation: _headerController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _headerFadeAnimation,
                            child: Transform.scale(
                              scale: _headerScaleAnimation.value + (_pulseController.value * 0.02),
                              child: _buildEnhancedHeader(isDesktop),
                            ),
                          );
                        },
                      ),

                      SizedBox(height: isDesktop ? 48 : 32),

                      // Enhanced Score Section
                      FadeTransition(
                        opacity: _scoreFadeAnimation,
                        child: SlideTransition(
                          position: _scoreSlideAnimation,
                          child: _buildEnhancedScoreSection(isDesktop),
                        ),
                      ),

                      SizedBox(height: isDesktop ? 48 : 32),

                      // Content Section
                      if (widget.incorrect.isEmpty)
                        _buildSuccessSection()
                      else
                        _buildIncorrectQuestionsSection(isDesktop),

                      SizedBox(height: isDesktop ? 48 : 32),

                      // Enhanced Action Button
                      FadeTransition(
                        opacity: _buttonFadeAnimation,
                        child: ScaleTransition(
                          scale: _buttonScaleAnimation,
                          child: _buildEnhancedButton(),
                        ),
                      ),

                      SizedBox(height: isDesktop ? 32 : 24),

                      // Footer
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHeader(bool isDesktop) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
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
            color: const Color(0xFF667EEA).withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildBackButton(),
          SizedBox(width: isDesktop ? 24 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Results',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 42 : 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: cardGradients[0],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.subjectName,
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Review your performance and learn from mistakes',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 18 : 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
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
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 24,
        ),
        onPressed: () => Navigator.pop(context),
        tooltip: 'Go Back',
      ),
    );
  }

  Widget _buildEnhancedScoreSection(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _scoreColor.withOpacity(0.1),
            _scoreColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _scoreColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _scoreColor.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Score Icon
          Container(
            width: isDesktop ? 80 : 64,
            height: isDesktop ? 80 : 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_scoreColor, _scoreColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _scoreColor.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              _getScoreIcon(),
              color: Colors.white,
              size: isDesktop ? 40 : 32,
            ),
          ),

          SizedBox(width: isDesktop ? 24 : 16),

          // Score Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Score',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${widget.score}',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 48 : 36,
                        fontWeight: FontWeight.w900,
                        color: _scoreColor,
                        height: 1,
                      ),
                    ),
                    Text(
                      ' / ${widget.total}',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 32 : 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_scorePercentage.toStringAsFixed(1)}% • ${_getScoreLabel()}',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w500,
                    color: _scoreColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessSection() {
    return FadeTransition(
      opacity: _successFadeAnimation,
      child: ScaleTransition(
        scale: _successScaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.1),
                const Color(0xFF059669).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Perfect Score!',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Congratulations! You answered all questions correctly.',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncorrectQuestionsSection(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.quiz_outlined,
              color: Colors.white,
              size: isDesktop ? 32 : 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Review Incorrect Answers',
              style: GoogleFonts.inter(
                fontSize: isDesktop ? 28 : 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.incorrect.length,
          itemBuilder: (context, index) {
            if (index >= _cardFadeAnimations.length) return const SizedBox.shrink();

            final item = widget.incorrect[index];
            final options = (item['options'] as List?)?.cast<String>() ?? [];
            final selected = item['selected'] as int?;
            final correct = item['correct'] as int? ?? 0;

            return FadeTransition(
              opacity: _cardFadeAnimations[index],
              child: SlideTransition(
                position: _cardSlideAnimations[index],
                child: EnhancedIncorrectCard(
                  question: item['question']?.toString() ?? '',
                  options: options,
                  selected: selected,
                  correct: correct,
                  gradient: cardGradients[index % cardGradients.length],
                  index: index + 1,
                  isDesktop: isDesktop,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedButton() {
    return EnhancedModernButton(
      text: 'Back to Dashboard',
      gradient: cardGradients[0],
      icon: Icons.dashboard_rounded,
      onPressed: _backToDashboard,
      isLoading: _isLoading,
    );
  }

  Widget _buildFooter() {
    return Text(
      'Developed By Brolytics Technologies',
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.6),
      ),
      textAlign: TextAlign.center,
    );
  }

  IconData _getScoreIcon() {
    if (_scorePercentage >= 90) return Icons.emoji_events_rounded;
    if (_scorePercentage >= 70) return Icons.star_rounded;
    if (_scorePercentage >= 50) return Icons.thumb_up_rounded;
    return Icons.trending_up_rounded;
  }

  String _getScoreLabel() {
    if (_scorePercentage >= 90) return 'Excellent';
    if (_scorePercentage >= 70) return 'Good';
    if (_scorePercentage >= 50) return 'Average';
    return 'Needs Improvement';
  }
}

// Enhanced Modern Button
class EnhancedModernButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> gradient;
  final IconData icon;
  final bool isLoading;

  const EnhancedModernButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.gradient,
    required this.icon,
    this.isLoading = false,
  });

  @override
  State<EnhancedModernButton> createState() => _EnhancedModernButtonState();
}

class _EnhancedModernButtonState extends State<EnhancedModernButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          if (!widget.isLoading) widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 240,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.first.withOpacity(0.4 + (_glowAnimation.value * 0.2)),
                      blurRadius: 20 + (_glowAnimation.value * 10),
                      offset: const Offset(0, 8),
                      spreadRadius: _glowAnimation.value * 2,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: widget.isLoading ? null : widget.onPressed,
                    child: Center(
                      child: widget.isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.text,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Enhanced Incorrect Answer Card
class EnhancedIncorrectCard extends StatefulWidget {
  final String question;
  final List<String> options;
  final int? selected;
  final int correct;
  final List<Color> gradient;
  final int index;
  final bool isDesktop;

  const EnhancedIncorrectCard({
    super.key,
    required this.question,
    required this.options,
    required this.selected,
    required this.correct,
    required this.gradient,
    required this.index,
    this.isDesktop = false,
  });

  @override
  State<EnhancedIncorrectCard> createState() => _EnhancedIncorrectCardState();
}

class _EnhancedIncorrectCardState extends State<EnhancedIncorrectCard>
    with SingleTickerProviderStateMixin {
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
        animation: _hoverAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: widget.isDesktop ? 24 : 16),
              padding: EdgeInsets.all(widget.isDesktop ? 32 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.95),
                    const Color(0xFF334155).withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.gradient.first.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(_isHovered ? 0.4 : 0.2),
                    blurRadius: _isHovered ? 30 : 20,
                    offset: const Offset(0, 8),
                    spreadRadius: _isHovered ? 2 : 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Header
                  Row(
                    children: [
                      Container(
                        width: widget.isDesktop ? 48 : 40,
                        height: widget.isDesktop ? 48 : 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.gradient,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradient.first.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${widget.index}',
                            style: GoogleFonts.inter(
                              fontSize: widget.isDesktop ? 20 : 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Question ${widget.index}',
                          style: GoogleFonts.inter(
                            fontSize: widget.isDesktop ? 20 : 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: widget.isDesktop ? 24 : 20),

                  // Question Text
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(widget.isDesktop ? 20 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      widget.question,
                      style: GoogleFonts.inter(
                        fontSize: widget.isDesktop ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                  ),
                  SizedBox(height: widget.isDesktop ? 24 : 20),

                  // Options
                  Text(
                    'Answer Options:',
                    style: GoogleFonts.inter(
                      fontSize: widget.isDesktop ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...widget.options.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final option = entry.value;

                    Color backgroundColor;
                    Color textColor;
                    Color borderColor;
                    IconData? icon;
                    String label = String.fromCharCode(65 + idx); // A, B, C, D

                    if (idx == widget.correct) {
                      backgroundColor = const Color(0xFF10B981).withOpacity(0.15);
                      textColor = const Color(0xFF10B981);
                      borderColor = const Color(0xFF10B981);
                      icon = Icons.check_circle_rounded;
                    } else if (idx == widget.selected) {
                      backgroundColor = const Color(0xFFEF4444).withOpacity(0.15);
                      textColor = const Color(0xFFEF4444);
                      borderColor = const Color(0xFFEF4444);
                      icon = Icons.cancel_rounded;
                    } else {
                      backgroundColor = Colors.white.withOpacity(0.05);
                      textColor = Colors.white.withOpacity(0.7);
                      borderColor = Colors.white.withOpacity(0.2);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(widget.isDesktop ? 16 : 14),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: borderColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              option,
                              style: GoogleFonts.inter(
                                fontSize: widget.isDesktop ? 16 : 14,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                          if (icon != null) ...[
                            const SizedBox(width: 12),
                            Icon(
                              icon,
                              color: textColor,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),

                  // Answer Summary
                  if (widget.selected != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF334155).withOpacity(0.5),
                            const Color(0xFF475569).withOpacity(0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                children: [
                                  const TextSpan(text: 'Your answer: '),
                                  TextSpan(
                                    text: String.fromCharCode(65 + widget.selected!),
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(text: ' • Correct answer: '),
                                  TextSpan(
                                    text: String.fromCharCode(65 + widget.correct),
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Geometric Background Painter
class GeometricBackgroundPainter extends CustomPainter {
  final double animationValue;

  GeometricBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    // Draw animated geometric shapes
    for (int i = 0; i < 15; i++) {
      final progress = (animationValue + (i * 0.1)) % 1.0;
      final opacity = (math.sin(progress * math.pi * 2) * 0.5 + 0.5) * 0.1;

      paint.color = Colors.white.withOpacity(opacity);

      final x = (size.width * 0.1) + (i * size.width * 0.08);
      final y = size.height * 0.2 + (math.sin(progress * math.pi * 4) * 50);

      canvas.drawCircle(
        Offset(x, y),
        5 + (progress * 10),
        paint,
      );
    }

    // Draw additional geometric elements
    for (int i = 0; i < 8; i++) {
      final progress = (animationValue * 0.5 + (i * 0.125)) % 1.0;
      final opacity = (math.cos(progress * math.pi * 2) * 0.5 + 0.5) * 0.05;

      paint.color = const Color(0xFF667EEA).withOpacity(opacity);

      final rect = Rect.fromCenter(
        center: Offset(
          size.width * 0.8 - (i * size.width * 0.1),
          size.height * 0.7 + (math.cos(progress * math.pi * 3) * 30),
        ),
        width: 20 + (progress * 15),
        height: 20 + (progress * 15),
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GeometricBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}