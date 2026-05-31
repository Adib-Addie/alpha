import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({Key? key}) : super(key: key);

  @override
  _AboutUsScreenState createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  final List<List<Color>> cardGradients = [
    [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
    [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
  ];

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
                      Container(
                        width: 1000,
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
                                      color: AppTheme.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Learn more about our mission and vision',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
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
                      // Content Sections
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          children: [
                            // Alpha Graphics Section
                            _buildSectionCard(
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
                            const SizedBox(height: 16),
                            // Mission & Vision Section
                            _buildSectionCard(
                              context,
                              title: 'Our Mission & Vision',
                              content: [
                                'Providing best computer training to all the students and make them eligible to get a good job in the always growing market of computer. For students who don\'t know what to do, our mission is to provide them a proper target and a platform to achieve that target.',
                              ],
                              gradient: cardGradients[1],
                              index: 1,
                            ),
                            const SizedBox(height: 16),
                            // Developed By Section
                            _buildSectionCard(
                              context,
                              title: 'Developed by Brolytics Technologies',
                              content: [
                                'This app is proudly developed by Brolytics Technologies, dedicated to delivering innovative and user-friendly solutions for Alpha Graphics.',
                                'Brolytics Technologies is a dynamic software development company specializing in creating cutting-edge solutions for education, business, and technology sectors. With a team of skilled developers and a passion for innovation, Brolytics has crafted Alpha Graphics to meet the evolving needs of modern education. Our commitment to quality and customer satisfaction drives us to deliver world-class applications.',
                              ],
                              gradient: cardGradients[2],
                              index: 2,
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
            color: AppTheme.backgroundMid.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.border.withOpacity(0.5),
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
                  color: AppTheme.textPrimary,
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
                        color: AppTheme.textPrimary,
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
                          color: AppTheme.textSecondary,
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
