import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  _AboutUsScreenState createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardFadeAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;

  final List<List<Color>> cardGradients = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    [const Color(0xFF10B981), const Color(0xFF38EF7D)],
    [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
    [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
  ];

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
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuad),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
    );
    _headerController.forward();
    _pulseController.repeat(reverse: true);

    _cardControllers = [];
    _cardFadeAnimations = [];
    _cardSlideAnimations = [];

    // Initialize animations for 3 sections (Alpha Graphics, Mission & Vision, Developed By)
    _initializeCardAnimations(3);
  }

  void _initializeCardAnimations(int itemCount) {
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
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
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
            ],
          ),
        ),
        child: SafeArea(
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
                      // Header Section
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
                                        tooltip: 'Back to Dashboard',
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'About Us',
                                            style: GoogleFonts.inter(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Learn more about our mission and vision',
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
                      // Content Sections
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          children: [
                            // Alpha Graphics Section
                            FadeTransition(
                              opacity: _cardFadeAnimations[0],
                              child: SlideTransition(
                                position: _cardSlideAnimations[0],
                                child: _buildSectionCard(
                                  context,
                                  title: 'Alpha Graphics',
                                  content: [
                                    'Alpha Graphics is a Computer Training Institute Since 2004, which is also Registered by Government of India. Our mission is to empower individuals with the essential computer skills needed to succeed in today\'s rapidly evolving digital landscape. We are committed to providing high-quality, accessible, and industry-relevant computer training in Patna.',
                                    'Our core values are rooted in excellence, integrity, and student success. We believe in fostering a supportive and engaging learning environment where every student can thrive.',
                                    'We are proud of the success of our students, many of whom have secured fulfilling careers in top companies or have launched their own successful ventures. Our commitment to excellence has made us a leading computer training institute in Patna, and we are dedicated to continuing to empower individuals with the skills they need to achieve their full potential.',
                                  ],
                                  gradient: cardGradients[0],
                                  index: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Mission & Vision Section
                            FadeTransition(
                              opacity: _cardFadeAnimations[1],
                              child: SlideTransition(
                                position: _cardSlideAnimations[1],
                                child: _buildSectionCard(
                                  context,
                                  title: 'Our Mission & Vision',
                                  content: [
                                    'Providing best computer training to all the students and make them eligible to get a good job in the always growing market of computer. For students who don\'t know what to do, our mission is to provide them a proper target and a platform to achieve that target.',
                                  ],
                                  gradient: cardGradients[1],
                                  index: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Developed By Section
                            FadeTransition(
                              opacity: _cardFadeAnimations[2],
                              child: SlideTransition(
                                position: _cardSlideAnimations[2],
                                child: _buildSectionCard(
                                  context,
                                  title: 'Developed By Brolytics Technologies',
                                  content: [
                                    'This app is proudly developed by Brolytics Technologies, dedicated to delivering innovative and user-friendly solutions for Alpha Graphics.',
                                    'Brolytics Technologies is a dynamic software development company specializing in creating cutting-edge solutions for education, business, and technology sectors. With a team of skilled developers and a passion for innovation, Brolytics has crafted Alpha Graphics to meet the evolving needs of modern education. Our commitment to quality and customer satisfaction drives us to deliver world-class applications.',
                                  ],
                                  gradient: cardGradients[2],
                                  index: 2,
                                ),
                              ),
                            ),
                          ],
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
      ),
    );
  }

  Widget _buildSectionCard(
      BuildContext context, {
        required String title,
        required List<String> content,
        required List<Color> gradient,
        required int index,
      }) {
    return MouseRegion(
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
      child: GestureDetector(
        onTap: () {},
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
                color: gradient.first.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.info_rounded,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...content.map((paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        paragraph,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}