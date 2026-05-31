import 'dart:async';
import 'dart:math' as math;
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

class _TestScreenState extends State<TestScreen> with TickerProviderStateMixin {
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _questions = [];
  int _currentIndex = 0;
  final Map<int, int> _answers = {}; // questionIndex -> selected option
  bool _loading = true;
  bool _submitting = false;
  Timer? _timer;
  Duration _remaining = const Duration(minutes: 45);

  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late AnimationController _questionController;
  late AnimationController _buttonsController;
  late AnimationController _timerController;
  late AnimationController _noQuestionsController;
  late AnimationController _backgroundController;
  late AnimationController _progressController;

  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _questionFadeAnimation;
  late Animation<Offset> _questionSlideAnimation;
  late Animation<double> _buttonsFadeAnimation;
  late Animation<double> _buttonsScaleAnimation;
  late Animation<double> _timerPulseAnimation;
  late Animation<double> _noQuestionsFadeAnimation;
  late Animation<double> _noQuestionsScaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _progressAnimation;

  final List<List<Color>> optionGradients = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    [const Color(0xFF10B981), const Color(0xFF38EF7D)],
    [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
    [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
  ];

  final List<Color> backgroundParticleColors = [
    const Color(0xFF667EEA).withOpacity(0.1),
    const Color(0xFF10B981).withOpacity(0.1),
    const Color(0xFFFC466B).withOpacity(0.1),
    const Color(0xFFF59E0B).withOpacity(0.1),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadQuestions();
    // Enable keyboard shortcuts
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

  void _initializeAnimations() {
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _questionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _buttonsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _noQuestionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Initialize animations - matching SubjectsPage style
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuad),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    _questionFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOutQuad),
    );
    _questionSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOutBack),
    );
    _buttonsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOutQuad),
    );
    _buttonsScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOutBack),
    );
    _timerPulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.easeInOut),
    );
    _noQuestionsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _noQuestionsController, curve: Curves.easeOutQuad),
    );
    _noQuestionsScaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _noQuestionsController, curve: Curves.easeOutBack),
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutQuad),
    );

    // Start animations
    _headerController.forward();
    _pulseController.repeat(reverse: true);
    _backgroundController.repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _headerController.dispose();
    _pulseController.dispose();
    _questionController.dispose();
    _buttonsController.dispose();
    _timerController.dispose();
    _noQuestionsController.dispose();
    _backgroundController.dispose();
    _progressController.dispose();
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
            _progressController.animateTo(_currentIndex / _questions.length);
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) {
                _questionController.forward();
                _buttonsController.forward();
              }
            });
          } else {
            _noQuestionsController.forward();
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
          if (_remaining.inMinutes <= 5 && !_timerController.isAnimating) {
            _timerController.repeat(reverse: true);
          }
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
        _questionController.reset();
        _buttonsController.reset();
        _progressController.animateTo(_currentIndex / _questions.length);
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _questionController.forward();
          _buttonsController.forward();
        }
      });
    } else {
      _finishTest();
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _questionController.reset();
        _buttonsController.reset();
        _progressController.animateTo(_currentIndex / _questions.length);
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _questionController.forward();
          _buttonsController.forward();
        }
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
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white,
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
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
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
                          color: Color(0xFF667EEA),
                          strokeWidth: 4,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _loading ? 'Loading Questions...' : 'Submitting Test...',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
                          // Enhanced Header - matching SubjectsPage style
                          _buildEnhancedHeader(),

                          // Progress Bar
                          if (_questions.isNotEmpty) _buildProgressBar(),

                          const SizedBox(height: 32),

                          // Content Area
                          if (_questions.isEmpty)
                            _buildNoQuestionsView()
                          else
                            _buildQuestionContent(),

                          const SizedBox(height: 32),

                          // Footer
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
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerFadeAnimation,
          child: Transform.scale(
            scale: _headerScaleAnimation.value + (_pulseController.value * 0.03),
            child: Container(
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
                          'Test - ${widget.subjectName}',
                          style: GoogleFonts.inter(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
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
                            AnimatedBuilder(
                              animation: _timerController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _remaining.inMinutes <= 5 ? _timerPulseAnimation.value : 1.0,
                                  child: Text(
                                    'Time Remaining: ${_remaining.inMinutes.toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: _remaining.inMinutes <= 5
                                          ? const Color(0xFFE53E3E)
                                          : Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
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
    );
  }

  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
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
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  Text(
                    '${_currentIndex + 1} of ${_questions.length}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF667EEA),
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
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoQuestionsView() {
    return FadeTransition(
      opacity: _noQuestionsFadeAnimation,
      child: ScaleTransition(
        scale: _noQuestionsScaleAnimation,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.quiz_rounded,
                size: 80,
                color: const Color(0xFF94A3B8).withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Questions Available',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No test questions are available for this subject at the moment',
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
      ),
    );
  }

  Widget _buildQuestionContent() {
    return Column(
      children: [
        FadeTransition(
          opacity: _questionFadeAnimation,
          child: SlideTransition(
            position: _questionSlideAnimation,
            child: EnhancedQuestionCard(
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
          ),
        ),
        const SizedBox(height: 32),
        FadeTransition(
          opacity: _buttonsFadeAnimation,
          child: ScaleTransition(
            scale: _buttonsScaleAnimation,
            child: _buildNavigationButtons(),
          ),
        ),
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
            gradient: const [Color(0xFF94A3B8), Color(0xFF64748B)],
            icon: Icons.arrow_back_rounded,
            onPressed: _prevQuestion,
          )
        else
          const SizedBox(width: 180),

        ModernButton(
          text: _currentIndex == _questions.length - 1 ? 'Submit Test' : 'Next',
          gradient: _currentIndex == _questions.length - 1
              ? const [Color(0xFF10B981), Color(0xFF38EF7D)]
              : const [Color(0xFF667EEA), Color(0xFF764BA2)],
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
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Developed By Brolytics Technologies',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Modern Button matching SubjectsPage style
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

class _ModernButtonState extends State<ModernButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
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
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onPressed();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
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
          },
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

class _EnhancedQuestionCardState extends State<EnhancedQuestionCard>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _optionController;
  late Animation<double> _cardAnimation;
  late Animation<double> _optionAnimation;
  bool _isCardHovered = false;

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _optionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _cardAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeInOut),
    );
    _optionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _optionController, curve: Curves.easeOutQuart),
    );

    _optionController.forward();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isCardHovered = true);
        _cardController.forward();
      },
      onExit: (_) {
        setState(() => _isCardHovered = false);
        _cardController.reverse();
      },
      child: AnimatedBuilder(
        animation: _cardAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _cardAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.95),
                    const Color(0xFF334155).withOpacity(0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isCardHovered
                      ? const Color(0xFF667EEA).withOpacity(0.5)
                      : const Color(0xFF475569).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isCardHovered
                        ? const Color(0xFF667EEA).withOpacity(0.3)
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
                              color: Colors.white,
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
                                color: Colors.white,
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
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Options
                  FadeTransition(
                    opacity: _optionAnimation,
                    child: Column(
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

class _EnhancedOptionCardState extends State<EnhancedOptionCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _selectController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _selectAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _selectController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _selectAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _selectController, curve: Curves.elasticOut),
    );

    if (widget.isSelected) {
      _selectController.forward();
    }
  }

  @override
  void didUpdateWidget(EnhancedOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _selectController.forward();
      } else {
        _selectController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _selectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_hoverAnimation, _selectAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _hoverAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isSelected
                        ? widget.gradient
                        : [
                      const Color(0xFF334155).withOpacity(0.8),
                      const Color(0xFF1E293B).withOpacity(0.8),
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
                        : const Color(0xFF475569).withOpacity(0.3),
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
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),

                    // Selection Indicator
                    AnimatedBuilder(
                      animation: _selectAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _selectAnimation.value,
                          child: widget.isSelected
                              ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: widget.gradient.first,
                            ),
                          )
                              : const SizedBox(width: 32),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Custom Painter for Background Particles
class ParticlesPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;

  ParticlesPainter(this.animation, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 50; i++) {
      final progress = (animation + i * 0.02) % 1.0;
      final x = (i * 37.0) % size.width;
      final y = (i * 23.0 + progress * size.height) % size.height;
      final radius = (math.sin(progress * math.pi * 2) * 2 + 3).abs();

      paint.color = colors[i % colors.length];
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}