import 'package:flutter/material.dart';
import 'app_theme.dart';
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

class _TestDisclaimerScreenState extends State<TestDisclaimerScreen> {
  bool _isLoading = false;

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
              AppTheme.backgroundStart,
              AppTheme.backgroundMid,
              AppTheme.backgroundEnd,
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
                      color: Color(0xFF7B2FBE),
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
                        Container(
                          width: maxWidth,
                          padding: EdgeInsets.all(isDesktop ? 24 : 20),
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
                                  icon: Icon(
                                    Icons.arrow_back_rounded,
                                    color: AppTheme.textPrimary,
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
                                        color: AppTheme.textPrimary,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Test Instructions & Guidelines',
                                      style: GoogleFonts.inter(
                                        fontSize: isDesktop ? 16 : 14,
                                        color: AppTheme.textPrimary.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Test Overview Card
                        Container(
                          width: maxWidth,
                          padding: EdgeInsets.all(isDesktop ? 24 : 20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundMid.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.border.withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7B2FBE).withOpacity(0.2),
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
                                    colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF7B2FBE).withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.quiz_rounded,
                                  size: isDesktop ? 32 : 28,
                                  color: AppTheme.textPrimary,
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
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Test Will Be End In 45 Minutes',
                                      style: GoogleFonts.inter(
                                        fontSize: isDesktop ? 14 : 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Instructions
                        Container(
                          width: maxWidth,
                          padding: EdgeInsets.all(isDesktop ? 24 : 20),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundMid.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.border.withOpacity(0.5),
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
                                    color: const Color(0xFF7B2FBE),
                                    size: isDesktop ? 28 : 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Test Instructions',
                                    style: GoogleFonts.inter(
                                      fontSize: isDesktop ? 24 : 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              ...(_buildInstructionsList(isDesktop)),
                            ],
                          ),
                        ),

                        // Start Test Button
                        Center(
                          child: ModernButton(
                            text: 'Start Test',
                            gradient: const [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                            icon: Icons.play_arrow_rounded,
                            onPressed: _startTest,
                            isDesktop: isDesktop,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Footer
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'Developed by Brolytics Technologies',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMuted,
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
                  colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 12 : 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
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
                  color: AppTheme.textSecondary,
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

class _ModernButtonState extends State<ModernButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
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
                color: widget.gradient.first.withOpacity(_isHovered ? 0.5 : 0.4),
                blurRadius: _isHovered ? 20 : 15,
                offset: Offset(0, _isHovered ? 10 : 8),
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
      ),
    );
  }
}
