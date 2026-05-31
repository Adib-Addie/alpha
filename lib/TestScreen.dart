import 'dart:async';
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ResultScreen.dart';

/// Enhanced Screen for conducting the MCQ test with improved design and animations
class TestScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  const TestScreen({super.key, required this.subjectId, required this.subjectName});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _questions = [];
  int _currentIndex = 0;
  final Map<int, int> _answers = {}; // questionIndex -> selected option
  bool _loading = true;
  bool _submitting = false;
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 45);

  final List<List<Color>> optionGradients = [
    [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
    [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
  ];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _setupKeyboardShortcuts();
  }

  void _setupKeyboardShortcuts() {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _prevQuestion();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextQuestion();
        return true;
      } else if (event.logicalKey.keyId >= LogicalKeyboardKey.digit1.keyId &&
          event.logicalKey.keyId <= LogicalKeyboardKey.digit4.keyId) {
        final optionIndex = event.logicalKey.keyId - LogicalKeyboardKey.digit1.keyId;

        if (_questions.isNotEmpty && optionIndex < _questions[_currentIndex].data()['options'].length) {
          setState(() {
            _answers[_currentIndex] = optionIndex;
          });
        }
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    try {
      await SchedulerBinding.instance.scheduleTask(() async {
        final snapshot = await FirebaseFirestore.instance
            .collection('questions')
            .where('subjectId', isEqualTo: widget.subjectId)
            .orderBy('createdAt')
            .get();

        if (mounted) {
          setState(() {
            _questions = snapshot.docs.where((doc) {
              final data = doc.data();
              return !data.containsKey('hidden') || data['hidden'] != true;
            }).toList();
            _loading = false;
          });

          if (_questions.isNotEmpty) {
            _startTimer();
          }
        }
      }, Priority.animation);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnackBar(
          message: 'Failed to load questions: ${e.toString()}',
          backgroundColor: const Color(0xFFE53E3E),
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remaining.inSeconds <= 1) {
        timer.cancel();
        _finishTest();
      } else {
        setState(() {
          _remaining -= const Duration(seconds: 1);
        });
      }
    });
  }

  void _nextQuestion() {
    if (_answers[_currentIndex] == null) {
      _showSnackBar(
        message: 'Please select an option to continue',
        backgroundColor: const Color(0xFFE53E3E),
        icon: Icons.warning_outlined,
      );
      return;
    }

    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishTest();
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _finishTest() async {
    if (_submitting) return;

    setState(() => _submitting = true);
    _timer?.cancel();

    try {
      final int total = _questions.length;
      int correct = 0;
      final incorrectDetails = <Map<String, dynamic>>[];

      for (int i = 0; i < total; i++) {
        final q = _questions[i].data();
        final selected = _answers[i];
        final correctIndex = q['correctOptionIndex'] as int;

        if (selected == correctIndex) {
          correct++;
        } else {
          incorrectDetails.add({
            'question': q['question'],
            'options': q['options'],
            'selected': selected,
            'correct': correctIndex,
          });
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('test_results').add({
          'studentId': user.uid,
          'subjectId': widget.subjectId,
          'subjectName': widget.subjectName,
          'score': correct,
          'total': total,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ResultScreen(
              subjectName: widget.subjectName,
              score: correct,
              total: total,
              incorrect: incorrectDetails,
            ),
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
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        _showSnackBar(
          message: 'Failed to submit test: ${e.toString()}',
          backgroundColor: const Color(0xFFE53E3E),
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _showSnackBar({
    required String message,
    required Color backgroundColor,
    IconData? icon,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: AppTheme.textPrimary, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isWideScreen = screenSize.width > 1200;

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
            ],
          ),
        ),
        child: Stack(
          children: [
            // Loading/Submitting Overlay
            if (_loading || _submitting)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF7B2FBE),
                          strokeWidth: 4,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _loading ? 'Loading Questions...' : 'Submitting Test...',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWideScreen ? 1200 : 1000,
                      minHeight: screenSize.height - 100,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildEnhancedHeader(),

                          if (_questions.isNotEmpty) _buildProgressBar(),

                          const SizedBox(height: 32),

                          if (_questions.isEmpty)
                            _buildNoQuestionsView()
                          else
                            _buildQuestionContent(),

                          const SizedBox(height: 32),

                          _buildFooter(),
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

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppTheme.backgroundStart,
              AppTheme.backgroundMid,
              AppTheme.backgroundEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.backgroundMid.withOpacity(0.8),
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
                color: AppTheme.textPrimary,
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
                  'Test - ${widget.subjectName}',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: _remaining.inMinutes <= 5
                          ? const Color(0xFFE53E3E)
                          : const Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Time Remaining: ${_remaining.inMinutes.toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _remaining.inMinutes <= 5
                            ? const Color(0xFFE53E3E)
                            : Colors.white.withOpacity(0.9),
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
  }

  Widget _buildProgressBar() {
    final progress = _questions.isNotEmpty ? _currentIndex / _questions.length : 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary.withOpacity(0.9),
                ),
              ),
              Text(
                '${_currentIndex + 1} of ${_questions.length}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7B2FBE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoQuestionsView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.quiz_rounded,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Questions Available',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No test questions are available for this subject at the moment',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    return Column(
      children: [
        EnhancedQuestionCard(
          question: _questions[_currentIndex].data()['question'] ?? '',
          options: (_questions[_currentIndex].data()['options'] as List).cast<String>(),
          selectedOption: _answers[_currentIndex],
          questionNumber: _currentIndex + 1,
          totalQuestions: _questions.length,
          gradients: optionGradients,
          onOptionSelected: (index) {
            HapticFeedback.lightImpact();
            setState(() => _answers[_currentIndex] = index);
          },
        ),
        const SizedBox(height: 32),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentIndex > 0)
          ModernButton(
            text: 'Previous',
            gradient: const [AppTheme.textSecondary, AppTheme.textMuted],
            icon: Icons.arrow_back_rounded,
            onPressed: _prevQuestion,
          )
        else
          const SizedBox(width: 180),

        ModernButton(
          text: _currentIndex == _questions.length - 1 ? 'Submit Test' : 'Next',
          gradient: _currentIndex == _questions.length - 1
              ? const [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd]
              : const [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
          icon: _currentIndex == _questions.length - 1
              ? Icons.check_circle_rounded
              : Icons.arrow_forward_rounded,
          onPressed: _nextQuestion,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Text(
              'Use arrow keys to navigate • Press 1-4 to select options',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Developed by Brolytics Technologies',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Button
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> gradient;
  final IconData icon;

  const ModernButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.gradient,
    required this.icon,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        width: 180,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.gradient,
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
              color: widget.gradient.first.withOpacity(_isPressed ? 0.2 : 0.4),
              blurRadius: _isPressed ? 8 : 15,
              offset: Offset(0, _isPressed ? 2 : 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              color: Colors.white,
              size: 22,
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
    );
  }
}

class EnhancedQuestionCard extends StatefulWidget {
  final String question;
  final List<String> options;
  final int? selectedOption;
  final int questionNumber;
  final int totalQuestions;
  final List<List<Color>> gradients;
  final ValueChanged<int> onOptionSelected;

  const EnhancedQuestionCard({
    super.key,
    required this.question,
    required this.options,
    required this.selectedOption,
    required this.questionNumber,
    required this.totalQuestions,
    required this.gradients,
    required this.onOptionSelected,
  });

  @override
  State<EnhancedQuestionCard> createState() => _EnhancedQuestionCardState();
}

class _EnhancedQuestionCardState extends State<EnhancedQuestionCard> {
  bool _isCardHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isCardHovered = true),
      onExit: (_) => setState(() => _isCardHovered = false),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundMid.withOpacity(0.95),
              AppTheme.backgroundEnd.withOpacity(0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isCardHovered
                ? const Color(0xFF7B2FBE).withOpacity(0.5)
                : AppTheme.border.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isCardHovered
                  ? const Color(0xFF7B2FBE).withOpacity(0.3)
                  : Colors.black.withOpacity(0.3),
              blurRadius: _isCardHovered ? 30 : 20,
              offset: const Offset(0, 8),
              spreadRadius: _isCardHovered ? 2 : 0,
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
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradients[0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradients[0].first.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${widget.questionNumber}',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
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
                        'Question ${widget.questionNumber} of ${widget.totalQuestions}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.gradients[0],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        width: 100,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question Text
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                widget.question,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Options
            Column(
              children: widget.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final gradient = widget.gradients[index % widget.gradients.length];
                final isSelected = widget.selectedOption == index;
                final optionLabel = String.fromCharCode(65 + index); // A, B, C, D

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: EnhancedOptionCard(
                    option: option,
                    optionLabel: optionLabel,
                    gradient: gradient,
                    isSelected: isSelected,
                    onTap: () => widget.onOptionSelected(index),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class EnhancedOptionCard extends StatefulWidget {
  final String option;
  final String optionLabel;
  final List<Color> gradient;
  final bool isSelected;
  final VoidCallback onTap;

  const EnhancedOptionCard({
    super.key,
    required this.option,
    required this.optionLabel,
    required this.gradient,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<EnhancedOptionCard> createState() => _EnhancedOptionCardState();
}

class _EnhancedOptionCardState extends State<EnhancedOptionCard> {
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
              colors: widget.isSelected
                  ? widget.gradient
                  : [
                AppTheme.backgroundEnd.withOpacity(0.8),
                AppTheme.backgroundMid.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? widget.gradient.first.withOpacity(0.8)
                  : _isHovered
                  ? Colors.white.withOpacity(0.3)
                  : AppTheme.border.withOpacity(0.5),
              width: widget.isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              if (widget.isSelected || _isHovered)
                BoxShadow(
                  color: widget.isSelected
                      ? widget.gradient.first.withOpacity(0.4)
                      : Colors.white.withOpacity(0.1),
                  blurRadius: widget.isSelected ? 20 : 10,
                  offset: const Offset(0, 4),
                  spreadRadius: widget.isSelected ? 2 : 0,
                ),
            ],
          ),
          child: Row(
            children: [
              // Option Letter
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.isSelected
                        ? widget.gradient.first
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.optionLabel,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: widget.isSelected
                          ? widget.gradient.first
                          : Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Option Text
              Expanded(
                child: Text(
                  widget.option,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),

              // Selection Indicator
              if (widget.isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 20,
                    color: widget.gradient.first,
                  ),
                )
              else
                const SizedBox(width: 32),
            ],
          ),
        ),
      ),
    );
  }
}
