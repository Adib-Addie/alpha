import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class ProfileStudentPage extends StatefulWidget {
  const ProfileStudentPage({super.key});

  @override
  State<ProfileStudentPage> createState() => _ProfileStudentPageState();
}

class _ProfileStudentPageState extends State<ProfileStudentPage> {
  String? _profileImageUrl;

  final List<Color> profileGradient = [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd];

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
  }

  Future<void> _fetchProfileImage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('profile_pictures/${user.uid}.jpg');
        final url = await ref.getDownloadURL();
        setState(() {
          _profileImageUrl = url;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileImageUrl = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                AppTheme.backgroundStart,
              AppTheme.backgroundMid,
              AppTheme.backgroundEnd,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Text(
                'Not logged in',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 2.5,
            colors: [
              AppTheme.backgroundStart,
              AppTheme.backgroundMid,
              AppTheme.backgroundEnd,
              AppTheme.border,
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53E3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE53E3E).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Color(0xFFE53E3E)),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Profile',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            color: const Color(0xFFE53E3E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            color: profileGradient.first,
                            strokeWidth: 4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Loading Profile...',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_off_outlined,
                            size: 64,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Profile Not Found',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No profile data available for this account',
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

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unknown';
              final email = data['email'] ?? 'N/A';
              final courseName = data['courseName'] ?? 'N/A';
              final fatherName = data['fatherName'] ?? 'N/A';
              final address = data['address'] ?? 'N/A';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Panel - Navigation & Profile Card
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          // Header with back button
                          Container(
                            padding: const EdgeInsets.all(24),
                            margin: const EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: profileGradient.first.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: profileGradient),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: profileGradient.first.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => Navigator.pop(context),
                                      child: const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Icon(
                                          Icons.arrow_back_rounded,
                                          color: AppTheme.textPrimary,
                                          size: 24,
                                        ),
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
                                        'Student Profile',
                                        style: GoogleFonts.inter(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Manage your personal information',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: AppTheme.textPrimary.withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Profile Card
                          Expanded(
                            child: ModernProfileCard(
                              student: data,
                              gradient: profileGradient,
                              profileImageUrl: _profileImageUrl,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Right Panel - Details Grid
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 100), // Align with left panel
                          Text(
                            'Personal Details',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your account information and course details',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.textPrimary.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              childAspectRatio: 1.8,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              children: [
                                ModernDetailCard(
                                  label: 'Email Address',
                                  value: email,
                                  icon: Icons.mail_outline_rounded,
                                  gradient: profileGradient,
                                  delay: 0,
                                ),
                                ModernDetailCard(
                                  label: 'Course Enrolled',
                                  value: courseName,
                                  icon: Icons.school_outlined,
                                  gradient: profileGradient,
                                  delay: 100,
                                ),
                                ModernDetailCard(
                                  label: "Father's Name",
                                  value: fatherName,
                                  icon: Icons.person_outline_rounded,
                                  gradient: profileGradient,
                                  delay: 200,
                                ),
                                ModernDetailCard(
                                  label: 'Address',
                                  value: address,
                                  icon: Icons.location_on_outlined,
                                  gradient: profileGradient,
                                  delay: 300,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Text(
                                'Developed by Brolytics Technologies',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class ModernProfileCard extends StatefulWidget {
  final Map<String, dynamic> student;
  final List<Color> gradient;
  final String? profileImageUrl;

  const ModernProfileCard({
    Key? key,
    required this.student,
    required this.gradient,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  _ModernProfileCardState createState() => _ModernProfileCardState();
}

class _ModernProfileCardState extends State<ModernProfileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.student['name'] ?? 'Unknown';
    final courseName = widget.student['courseName'] ?? 'N/A';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.gradient.first.withOpacity(_isHovered ? 0.4 : 0.2),
              blurRadius: _isHovered ? 30 : 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile Image
            Container(
              width: 140,
              height: 140,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.textPrimary,
                ),
                child: ClipOval(
                  child: widget.profileImageUrl != null
                      ? Image.network(
                    widget.profileImageUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: widget.gradient.first,
                          strokeWidth: 3,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: widget.gradient),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                              fontSize: 48,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      );
                    },
                  )
                      : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: widget.gradient),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Name
            Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.gradient.first.withOpacity(0.3),
                    widget.gradient.last.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.gradient.first.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Active Student',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Course Name
            Text(
              courseName,
              style: GoogleFonts.inter(
                fontSize: 18,
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
}

class ModernDetailCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final int delay;

  const ModernDetailCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.delay = 0,
  }) : super(key: key);

  @override
  _ModernDetailCardState createState() => _ModernDetailCardState();
}

class _ModernDetailCardState extends State<ModernDetailCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(_isHovered ? 0.15 : 0.1),
              Colors.white.withOpacity(_isHovered ? 0.1 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.gradient.first.withOpacity(_isHovered ? 0.3 : 0.1),
              blurRadius: _isHovered ? 25 : 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: widget.gradient.first.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                size: 28,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Label
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            // Value
            Expanded(
              child: Text(
                widget.value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
