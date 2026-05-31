import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'StudentDashboardPage.dart';

/// Enhanced ResultScreen with improved design
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

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = false;

  final List<List<Color>> cardGradients = [
    [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
    [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
  ];

  void _backToDashboard() {
    if (_isLoading) return;
    setState(() => _isLoading = true);

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

  double get _scorePercentage => (widget.score / widget.total * 100);

  Color get _scoreColor {
    if (_scorePercentage >= 90) return const Color(0xFF10B981);
    if (_scorePercentage >= 70) return const Color(0xFF00B4DB);
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
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0F23),
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
            ),
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
                          color: AppTheme.backgroundMid.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7B2FBE).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF7B2FBE),
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
                          color: AppTheme.textPrimary,
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
                      // Header
                      _buildEnhancedHeader(isDesktop),

                      SizedBox(height: isDesktop ? 48 : 32),

                      // Score Section
                      _buildEnhancedScoreSection(isDesktop),

                      SizedBox(height: isDesktop ? 48 : 32),

                      // Content Section
                      if (widget.incorrect.isEmpty)
                        _buildSuccessSection()
                      else
                        _buildIncorrectQuestionsSection(isDesktop),

                      SizedBox(height: isDesktop ? 48 : 32),

                      // Action Button
                      _buildEnhancedButton(),

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
            color: const Color(0xFF7B2FBE).withOpacity(0.2),
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
                    color: AppTheme.textPrimary,
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
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Review your performance and learn from mistakes',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 18 : 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary.withOpacity(0.8),
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
          color: AppTheme.textPrimary,
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
              color: AppTheme.textPrimary,
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
                    color: AppTheme.textPrimary.withOpacity(0.9),
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
                        color: AppTheme.textPrimary.withOpacity(0.7),
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
    return Container(
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
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Perfect Score!',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Congratulations! You answered all questions correctly.',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
              color: AppTheme.textPrimary,
              size: isDesktop ? 32 : 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Review Incorrect Answers',
              style: GoogleFonts.inter(
                fontSize: isDesktop ? 28 : 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
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
            final item = widget.incorrect[index];
            final options = (item['options'] as List?)?.cast<String>() ?? [];
            final selected = item['selected'] as int?;
            final correct = item['correct'] as int? ?? 0;

            return EnhancedIncorrectCard(
              question: item['question']?.toString() ?? '',
              options: options,
              selected: selected,
              correct: correct,
              gradient: cardGradients[index % cardGradients.length],
              index: index + 1,
              isDesktop: isDesktop,
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
      'Developed by Brolytics Technologies',
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

class _EnhancedModernButtonState extends State<EnhancedModernButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) {},
        onTapUp: (_) {
          if (!widget.isLoading) widget.onPressed();
        },
        onTapCancel: () {},
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
                color: widget.gradient.first.withOpacity(_isHovered ? 0.6 : 0.4),
                blurRadius: _isHovered ? 30 : 20,
                offset: const Offset(0, 8),
                spreadRadius: _isHovered ? 2 : 0,
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
                    color: AppTheme.textPrimary,
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

class _EnhancedIncorrectCardState extends State<EnhancedIncorrectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: EdgeInsets.only(bottom: widget.isDesktop ? 24 : 16),
        padding: EdgeInsets.all(widget.isDesktop ? 32 : 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundMid.withOpacity(0.95),
              AppTheme.backgroundEnd.withOpacity(0.9),
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
                        color: AppTheme.textPrimary,
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
                      color: AppTheme.textPrimary,
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
                  color: AppTheme.textPrimary,
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
                color: AppTheme.textPrimary.withOpacity(0.8),
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
                      AppTheme.backgroundMid.withOpacity(0.8),
                      AppTheme.border.withOpacity(0.5),
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
                      color: AppTheme.textPrimary.withOpacity(0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary.withOpacity(0.8),
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
  }
}
