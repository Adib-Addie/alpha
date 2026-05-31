import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'TestScreen.dart';

/// Shows instructions before starting the MCQ test.
class TestDisclaimerScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;

  const TestDisclaimerScreen({
    Key? key,
    required this.subjectId,
    required this.subjectName,
  }) : super(key: key);

  @override
  State<TestDisclaimerScreen> createState() => _TestDisclaimerScreenState();
}

class _TestDisclaimerScreenState extends State<TestDisclaimerScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late AnimationController _instructionsController;
  late AnimationController _buttonController;
  late AnimationController _cardController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _instructionsFadeAnimation;
  late Animation<Offset> _instructionsSlideAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<Offset> _cardSlideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _instructionsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuad),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    _instructionsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _instructionsController, curve: Curves.easeOutQuad),
    );
    _instructionsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _instructionsController, curve: Curves.easeOutBack),
    );
    _buttonFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutQuad),
    );
    _buttonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
    );
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutQuad),
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.easeOutBack),
    );

    _headerController.forward();
    _pulseController.repeat(reverse: true);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _instructionsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _pulseController.dispose();
    _instructionsController.dispose();
    _buttonController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _startTest() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TestScreen(
            subjectId: widget.subjectId,
            subjectName: widget.subjectName,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024;
    final maxWidth = isDesktop ? 1000.0 : screenWidth * 0.95;

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
            Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 32.0 : 20.0),
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
                                  width: maxWidth,
                                  padding: EdgeInsets.all(isDesktop ? 24 : 20),
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
                                          icon: Icon(
                                            Icons.arrow_back_rounded,
                                            color: Colors.white,
                                            size: isDesktop ? 28 : 24,
                                          ),
                                          onPressed: () => Navigator.pop(context),
                                          tooltip: 'Back to subjects',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.subjectName,
                                              style: GoogleFonts.inter(
                                                fontSize: isDesktop ? 32 : 24,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Test Instructions & Guidelines',
                                              style: GoogleFonts.inter(
                                                fontSize: isDesktop ? 16 : 14,
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

                        // Test Overview Card
                        FadeTransition(
                          opacity: _cardFadeAnimation,
                          child: SlideTransition(
                            position: _cardSlideAnimation,
                            child: Container(
                              width: maxWidth,
                              padding: EdgeInsets.all(isDesktop ? 24 : 20),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF475569).withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667EEA).withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: isDesktop ? 64 : 56,
                                    height: isDesktop ? 64 : 56,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF667EEA).withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.quiz_rounded,
                                      size: isDesktop ? 32 : 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Test Overview',
                                          style: GoogleFonts.inter(
                                            fontSize: isDesktop ? 20 : 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Test Will Be End In 45 Minutes',
                                          style: GoogleFonts.inter(
                                            fontSize: isDesktop ? 14 : 12,
                                            fontWeight: FontWeight.w500,
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

                        // Instructions
                        FadeTransition(
                          opacity: _instructionsFadeAnimation,
                          child: SlideTransition(
                            position: _instructionsSlideAnimation,
                            child: Container(
                              width: maxWidth,
                              padding: EdgeInsets.all(isDesktop ? 24 : 20),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF475569).withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        color: const Color(0xFF667EEA),
                                        size: isDesktop ? 28 : 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Test Instructions',
                                        style: GoogleFonts.inter(
                                          fontSize: isDesktop ? 24 : 20,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  ...(_buildInstructionsList(isDesktop)),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Start Test Button
                        FadeTransition(
                          opacity: _buttonFadeAnimation,
                          child: ScaleTransition(
                            scale: _buttonScaleAnimation,
                            child: Center(
                              child: ModernButton(
                                text: 'Start Test',
                                gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                                icon: Icons.play_arrow_rounded,
                                onPressed: _startTest,
                                isDesktop: isDesktop,
                              ),
                            ),
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
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInstructionsList(bool isDesktop) {
    final instructions = [
      'The test consists of multiple-choice questions (MCQs).',
      'You have 45 minutes to complete the test.',
      'Use "Next" and "Previous" buttons to navigate between questions.',
      'You must select an answer before proceeding to the next question.',
      'A timer will alert you when 5 minutes remain.',
      'The test will auto-submit when the time is up.',
      'Ensure a stable internet connection for result submission.',
      'Do not close the app during the test to avoid losing progress.',
      'Review your answers before submitting the test.',
    ];

    return instructions.asMap().entries.map((entry) {
      final index = entry.key;
      final instruction = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: isDesktop ? 24 : 20,
              height: isDesktop ? 24 : 20,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 12 : 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                instruction,
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 16 : 14,
                  color: const Color(0xFF94A3B8),
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

/// Modern button widget for consistent styling and animations.
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color> gradient;
  final IconData icon;
  final bool isDesktop;

  const ModernButton({
    Key? key,
    required this.text,
    required this.onPressed,
    required this.gradient,
    required this.icon,
    this.isDesktop = false,
  }) : super(key: key);

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _hoverAnimation;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
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
          animation: Listenable.merge([_scaleAnimation, _hoverAnimation]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * _hoverAnimation.value,
              child: Container(
                width: widget.isDesktop ? 240 : 200,
                padding: EdgeInsets.symmetric(
                  vertical: widget.isDesktop ? 18 : 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.first.withOpacity(_isPressed ? 0.3 : _isHovered ? 0.5 : 0.4),
                      blurRadius: _isPressed ? 8 : _isHovered ? 20 : 15,
                      offset: Offset(0, _isPressed ? 2 : _isHovered ? 10 : 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: widget.isDesktop ? 24 : 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.text,
                      style: GoogleFonts.inter(
                        fontSize: widget.isDesktop ? 18 : 16,
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