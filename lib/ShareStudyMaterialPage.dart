import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:animations/animations.dart';
import 'dart:io';
import 'dart:math' as math;

class ShareStudyMaterialPage extends StatefulWidget {
  const ShareStudyMaterialPage({Key? key}) : super(key: key);

  @override
  _ShareStudyMaterialPageState createState() => _ShareStudyMaterialPageState();
}

class _ShareStudyMaterialPageState extends State<ShareStudyMaterialPage>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  String? _selectedSubjectId;
  File? _selectedFile;
  bool _isUploading = false;

  late AnimationController _mainAnimationController;
  late AnimationController _backgroundController;
  late AnimationController _cardAnimationController;
  late AnimationController _loaderController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: -80.0, end: 0.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.elasticOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.elasticOut),
    );

    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.linear),
    );

    _mainAnimationController.forward();
    _backgroundController.repeat();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _mainAnimationController.dispose();
    _backgroundController.dispose();
    _cardAnimationController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
        _showSnackBar('File selected successfully!', const Color(0xFF10B981));
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', const Color(0xFFE53E3E));
    }
  }

  Future<void> _uploadMaterial() async {
    if (_selectedSubjectId == null || _titleController.text.trim().isEmpty || _selectedFile == null) {
      _showSnackBar('Please fill all fields and select a file', const Color(0xFFF59E0B));
      return;
    }

    setState(() => _isUploading = true);
    _loaderController.repeat();

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('No authenticated user found', const Color(0xFFE53E3E));
        return;
      }

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.path.split('/').last}';
      final ref = FirebaseStorage.instance.ref().child('study_materials/$fileName');
      await ref.putFile(_selectedFile!);
      final fileUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('study_materials').add({
        'title': _titleController.text.trim(),
        'subjectId': _selectedSubjectId,
        'fileUrl': fileUrl,
        'fileName': _selectedFile!.path.split('/').last,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.email,
      });

      _titleController.clear();
      setState(() {
        _selectedFile = null;
        _selectedSubjectId = null;
      });
      _showSnackBar('Material uploaded successfully!', const Color(0xFF10B981));
    } catch (e) {
      _showSnackBar('Failed to upload material: $e', const Color(0xFFE53E3E));
    } finally {
      setState(() => _isUploading = false);
      _loaderController.stop();
    }
  }

  Future<void> _deleteMaterial(String materialId, String fileUrl, String title) async {
    final confirmed = await _showConfirmDialog('Delete Material', 'Are you sure you want to delete "$title"?');
    if (!confirmed) return;

    try {
      await FirebaseFirestore.instance.collection('study_materials').doc(materialId).delete();
      await FirebaseStorage.instance.refFromURL(fileUrl).delete();
      _showSnackBar('"$title" deleted successfully', const Color(0xFF10B981));
    } catch (e) {
      _showSnackBar('Failed to delete material: $e', const Color(0xFFE53E3E));
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53E3E).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.warning_rounded, color: Color(0xFFE53E3E), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  void _shareMaterial(String fileUrl, String title) {
    Share.share(
      'Check out this study material: $title\n\nDownload: $fileUrl',
      subject: 'Study Material: $title',
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  color == const Color(0xFF10B981) ? Icons.check_circle_rounded :
                  color == const Color(0xFFF59E0B) ? Icons.warning_rounded : Icons.error_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      color == const Color(0xFF10B981) ? 'Success' :
                      color == const Color(0xFFF59E0B) ? 'Warning' : 'Error',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      message,
                      style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        elevation: 10,
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return const Color(0xFFE53E3E);
      case 'doc':
      case 'docx':
        return const Color(0xFF3B82F6);
      case 'ppt':
      case 'pptx':
        return const Color(0xFFF59E0B);
      case 'txt':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth < 600;

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
              Color(0xFF0F172A),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    const Color(0xFF667EEA).withOpacity(0.1 + (_backgroundAnimation.value * 0.05)),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomLeft,
                    radius: 1.2,
                    colors: [
                      const Color(0xFF764BA2).withOpacity(0.08 + (_backgroundAnimation.value * 0.03)),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Floating orbs
                    Positioned(
                      top: screenHeight * 0.1,
                      right: screenWidth * 0.1,
                      child: _buildFloatingOrb(60, const Color(0xFF667EEA), 3000),
                    ),
                    Positioned(
                      top: screenHeight * 0.3,
                      left: screenWidth * 0.05,
                      child: _buildFloatingOrb(40, const Color(0xFF764BA2), 4000),
                    ),
                    Positioned(
                      bottom: screenHeight * 0.2,
                      right: screenWidth * 0.2,
                      child: _buildFloatingOrb(50, const Color(0xFF10B981), 5000),
                    ),
                    SafeArea(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                              child: Column(
                                children: [
                                  _buildHeader(isMobile, isTablet),
                                  SizedBox(height: isMobile ? 20 : 32),
                                  _buildUploadSection(isMobile, isTablet),
                                  SizedBox(height: isMobile ? 20 : 32),
                                ],
                              ),
                            ),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                isMobile ? 16.0 : 24.0,
                                0,
                                isMobile ? 16.0 : 24.0,
                                isMobile ? 16.0 : 24.0,
                              ),
                              child: _buildMaterialsList(screenHeight, isMobile, isTablet),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isUploading) _buildCustomLoader(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingOrb(double size, Color color, int duration) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: duration),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(value * 2 * math.pi) * 20,
            math.cos(value * 2 * math.pi) * 15,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile, bool isTablet) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E293B).withOpacity(0.9),
                const Color(0xFF334155).withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
            border: Border.all(
              color: const Color(0xFF475569).withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.6),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 5,
              ),
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: isMobile
              ? Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667EEA).withOpacity(0.3),
                          const Color(0xFF764BA2).withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF667EEA).withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF667EEA), size: 22),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.library_books_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF10B981)],
                    ).createShader(bounds),
                    child: Text(
                      'Share Study Material',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Upload and manage educational resources for students',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          )
              : Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667EEA).withOpacity(0.3),
                      const Color(0xFF764BA2).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF667EEA), size: 28),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF10B981)],
                      ).createShader(bounds),
                      child: Text(
                        'Share Study Material',
                        style: GoogleFonts.inter(
                          fontSize: isTablet ? 36 : 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Upload and manage educational resources for students',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.library_books_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection(bool isMobile, bool isTablet) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 28 : 36),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E293B).withOpacity(0.9),
              const Color(0xFF334155).withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
          border: Border.all(
            color: const Color(0xFF475569).withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.6),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF38EF7D)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload New Material',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 20 : 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Share knowledge with the community',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (isMobile)
              Column(
                children: [
                  _buildSubjectDropdown(),
                  const SizedBox(height: 20),
                  _buildTitleField(),
                  const SizedBox(height: 20),
                  _buildFileSelector(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _buildUploadButton(),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSubjectDropdown()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildTitleField()),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildFileSelector()),
                      const SizedBox(width: 20),
                      _buildUploadButton(),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectDropdown() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF334155).withOpacity(0.6),
                    const Color(0xFF475569).withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF475569).withOpacity(0.4)),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF667EEA), strokeWidth: 2),
              ),
            );
          }

          final subjects = snapshot.data!.docs;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF334155).withOpacity(0.6),
                  const Color(0xFF475569).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF475569).withOpacity(0.4)),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedSubjectId,
              hint: Text(
                'Select Subject',
                style: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF667EEA)),
              dropdownColor: const Color(0xFF1E293B),
              items: subjects.map((doc) {
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(
                    doc['name'] ?? 'Unknown',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSubjectId = value),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.subject_rounded, color: Color(0xFF667EEA)),
              ),
            ),
          );
        },
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF334155).withOpacity(0.6),
            const Color(0xFF475569).withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF475569).withOpacity(0.4)),
      ),
      child: TextField(
        controller: _titleController,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: 'Material Title',
          labelStyle: GoogleFonts.inter(color: Colors.white.withOpacity(0.7), fontSize: 14),
          prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF667EEA)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          floatingLabelStyle: GoogleFonts.inter(color: const Color(0xFF667EEA)),
        ),
      ),
    );
  }

  Widget _buildFileSelector() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _selectedFile != null
                ? [
              const Color(0xFF10B981).withOpacity(0.2),
              const Color(0xFF38EF7D).withOpacity(0.1),
            ]
                : [
              const Color(0xFF334155).withOpacity(0.6),
              const Color(0xFF475569).withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _selectedFile != null
                ? const Color(0xFF10B981).withOpacity(0.5)
                : const Color(0xFF475569).withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _selectedFile != null
                      ? [const Color(0xFF10B981), const Color(0xFF38EF7D)]
                      : [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (_selectedFile != null
                        ? const Color(0xFF10B981)
                        : const Color(0xFF667EEA)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _selectedFile != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFile != null ? 'File Selected' : 'Choose File',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedFile != null
                        ? _selectedFile!.path.split('/').last
                        : 'PDF, DOC, PPT, TXT supported',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.folder_open_rounded,
              color: Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isUploading ? null : _uploadMaterial,
        icon: _isUploading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.cloud_upload_rounded, size: 22),
        label: Text(
          _isUploading ? 'Uploading...' : 'Upload',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildMaterialsList(double screenHeight, bool isMobile, bool isTablet) {
    double listHeight;
    if (isMobile) {
      listHeight = screenHeight * 0.45;
    } else if (isTablet) {
      listHeight = screenHeight * 0.55;
    } else {
      listHeight = screenHeight * 0.6;
    }

    listHeight = listHeight < 350 ? 350 : listHeight;

    return Container(
      height: listHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B).withOpacity(0.9),
            const Color(0xFF334155).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 28),
        border: Border.all(
          color: const Color(0xFF475569).withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.6),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 24 : 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF334155).withOpacity(0.6),
                  const Color(0xFF475569).withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isMobile ? 24 : 28),
                topRight: Radius.circular(isMobile ? 24 : 28),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.folder_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Uploaded Materials',
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('study_materials')
                      .snapshots(),
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF8B5CF6).withOpacity(0.3),
                            const Color(0xFFA855F7).withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        count.toString(),
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8B5CF6),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('study_materials')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF667EEA), strokeWidth: 3),
                          const SizedBox(height: 16),
                          Text(
                            'Loading materials...',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final materials = snapshot.data!.docs;
                if (materials.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF334155).withOpacity(0.3),
                                const Color(0xFF475569).withOpacity(0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.folder_open_rounded,
                            size: isMobile ? 48 : 64,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No study materials uploaded yet',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 16 : 18,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF667EEA).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Upload your first material to get started',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 12 : 14,
                              color: const Color(0xFF667EEA),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 400 + (index * 100)),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: _buildMaterialCard(material, index, isMobile, isTablet),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(QueryDocumentSnapshot material, int index, bool isMobile, bool isTablet) {
    final fileName = material['fileName'] ?? 'Unknown file';
    final fileIcon = _getFileIcon(fileName);
    final fileColor = _getFileColor(fileName);

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 20),
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF334155).withOpacity(0.6),
            const Color(0xFF475569).withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        border: Border.all(
          color: fileColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: fileColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      fileColor.withOpacity(0.3),
                      fileColor.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 14),
                  boxShadow: [
                    BoxShadow(
                      color: fileColor.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(fileIcon, color: fileColor, size: isMobile ? 22 : 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material['title'] ?? 'Untitled',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: isMobile ? 15 : 17,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('subjects')
                          .doc(material['subjectId'])
                          .snapshots(),
                      builder: (context, subjectSnapshot) {
                        final subjectName = subjectSnapshot.hasData
                            ? subjectSnapshot.data!['name'] ?? 'Unknown'
                            : 'Loading...';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF667EEA).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            subjectName,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF667EEA),
                              fontSize: isMobile ? 11 : 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF475569).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file_rounded, color: Colors.white.withOpacity(0.6), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.share_rounded,
                  color: const Color(0xFF10B981),
                  onPressed: () => _shareMaterial(material['fileUrl'], material['title']),
                  tooltip: 'Share',
                  isMobile: isMobile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete_rounded,
                  color: const Color(0xFFE53E3E),
                  onPressed: () => _deleteMaterial(
                    material.id,
                    material['fileUrl'],
                    material['title'],
                  ),
                  tooltip: 'Delete',
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  fileColor.withOpacity(0.3),
                  fileColor.withOpacity(0.2),
                ],
              ),
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              boxShadow: [
                BoxShadow(
                  color: fileColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(fileIcon, color: fileColor, size: isMobile ? 22 : 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material['title'] ?? 'Untitled',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 15 : 18,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('subjects')
                      .doc(material['subjectId'])
                      .snapshots(),
                  builder: (context, subjectSnapshot) {
                    final subjectName = subjectSnapshot.hasData
                        ? subjectSnapshot.data!['name'] ?? 'Unknown'
                        : 'Loading...';
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF667EEA).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.subject_rounded, color: const Color(0xFF667EEA), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                subjectName,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF667EEA),
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.insert_drive_file_rounded, color: Colors.white.withOpacity(0.6), size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            fileName,
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                icon: Icons.share_rounded,
                color: const Color(0xFF10B981),
                onPressed: () => _shareMaterial(material['fileUrl'], material['title']),
                tooltip: 'Share',
                isMobile: isMobile,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.delete_rounded,
                color: const Color(0xFFE53E3E),
                onPressed: () => _deleteMaterial(
                  material.id,
                  material['fileUrl'],
                  material['title'],
                ),
                tooltip: 'Delete',
                isMobile: isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
    required bool isMobile,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isMobile
            ? TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: color, size: 16),
          label: Text(
            tooltip,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        )
            : IconButton(
          icon: Icon(icon, color: color, size: 20),
          onPressed: onPressed,
          padding: const EdgeInsets.all(12),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            hoverColor: color.withOpacity(0.1),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomLoader() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1E293B).withOpacity(0.95),
                const Color(0xFF334155).withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF475569).withOpacity(0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.8),
                blurRadius: 30,
                offset: const Offset(0, 15),
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF667EEA).withOpacity(0.2),
                          const Color(0xFF667EEA).withOpacity(0.05),
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667EEA).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.cloud_upload_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: LoaderPainter(_rotationAnimation.value),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF10B981)],
                ).createShader(bounds),
                child: Text(
                  'Uploading Material...',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Please wait while we securely upload your file',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF10B981),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoaderPainter extends CustomPainter {
  final double progress;

  LoaderPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = const Color(0xFF475569).withOpacity(0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 10, backgroundPaint);

    // Progress circle
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF10B981)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(LoaderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }}