import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animations/animations.dart';
import 'package:url_launcher/url_launcher.dart';

class StudyMaterialPage extends StatefulWidget {
  const StudyMaterialPage({Key? key}) : super(key: key);

  @override
  _StudyMaterialPageState createState() => _StudyMaterialPageState();
}

class _StudyMaterialPageState extends State<StudyMaterialPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  late AnimationController _headerController;
  late AnimationController _loaderController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _loaderRotationAnimation;
  late Animation<double> _loaderPulseAnimation;

  // Cached animations for better performance
  late AnimationController _staggerController;
  List<Animation<double>> _staggeredAnimations = [];

  // Pre-defined gradient colors to avoid repeated list creation
  static const List<List<Color>> _cardGradients = [
    [Color(0xFF667EEA), Color(0xFF764BA2)],
    [Color(0xFF10B981), Color(0xFF38EF7D)],
    [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    [Color(0xFFF59E0B), Color(0xFFEAB308)],
    [Color(0xFFFF6B6B), Color(0xFF4ECDC4)],
    [Color(0xFF845EC2), Color(0xFFD65DB1)],
    [Color(0xFF4E54C8), Color(0xFF8F94FB)],
    [Color(0xFFFF9A8B), Color(0xFFA8E6CF)],
  ];

  // Cache for subject data to reduce Firestore reads
  final Map<String, String> _subjectCache = {};

  // Stream subscription for better memory management
  StreamSubscription<QuerySnapshot>? _materialsSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Header animations
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Reduced duration
    );
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    // Loader animations
    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Reduced duration
    );
    _loaderRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.linear),
    );
    _loaderPulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _loaderController, curve: Curves.easeInOut),
    );

    // Stagger controller for list items
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start header animation immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _headerController.forward();
      }
    });
  }

  void _initializeStaggeredAnimations(int itemCount) {
    if (_staggeredAnimations.length == itemCount) return;
    _staggerController.reset();
    _staggeredAnimations = List.generate(itemCount, (index) {
      final start = (index * 0.1).clamp(0.0, 1.0);
      final end = (start + 0.3).clamp(0.0, 1.0);

      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    if (mounted) {
      _staggerController.forward();
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _loaderController.dispose();
    _staggerController.dispose();
    _materialsSubscription?.cancel();
    super.dispose();
  }

  // Optimized loader with RepaintBoundary
  Widget _buildOptimizedLoader({String text = "Loading..."}) {
    _loaderController.repeat();

    return RepaintBoundary(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _loaderController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _loaderRotationAnimation.value * 2 * 3.14159,
                  child: Transform.scale(
                    scale: _loaderPulseAnimation.value,
                    child: Container(
                      width: 60, // Reduced size
                      height: 60,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.library_books_rounded,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Optimized download function with better error handling
  Future<void> _downloadFile(String url, String title) async {
    if (!mounted) return;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _showSnackBar('Downloading $title...', Colors.green, Icons.download_done_rounded);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      _showSnackBar('Failed to download $title', Colors.red, Icons.error_outline);
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Cached file icon lookup
  static const Map<String, IconData> _fileIcons = {
    'pdf': Icons.picture_as_pdf_rounded,
    'doc': Icons.description_rounded,
    'docx': Icons.description_rounded,
    'ppt': Icons.slideshow_rounded,
    'pptx': Icons.slideshow_rounded,
    'txt': Icons.text_snippet_rounded,
    'xls': Icons.table_chart_rounded,
    'xlsx': Icons.table_chart_rounded,
    'jpg': Icons.image_rounded,
    'jpeg': Icons.image_rounded,
    'png': Icons.image_rounded,
    'gif': Icons.image_rounded,
    'mp4': Icons.video_file_rounded,
    'avi': Icons.video_file_rounded,
    'mov': Icons.video_file_rounded,
    'mp3': Icons.audio_file_rounded,
    'wav': Icons.audio_file_rounded,
  };

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return _fileIcons[extension] ?? Icons.insert_drive_file_rounded;
  }

  // Cached file gradient lookup
  static const Map<String, List<Color>> _fileGradients = {
    'pdf': [Color(0xFFE53E3E), Color(0xFFDC2626)],
    'doc': [Color(0xFF3B82F6), Color(0xFF2563EB)],
    'docx': [Color(0xFF3B82F6), Color(0xFF2563EB)],
    'ppt': [Color(0xFFF59E0B), Color(0xFFEAB308)],
    'pptx': [Color(0xFFF59E0B), Color(0xFFEAB308)],
    'txt': [Color(0xFF10B981), Color(0xFF059669)],
    'xls': [Color(0xFF10B981), Color(0xFF059669)],
    'xlsx': [Color(0xFF10B981), Color(0xFF059669)],
    'jpg': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    'jpeg': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    'png': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    'gif': [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
    'mp4': [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    'avi': [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    'mov': [Color(0xFFFC466B), Color(0xFF3F5EFB)],
    'mp3': [Color(0xFF845EC2), Color(0xFFD65DB1)],
    'wav': [Color(0xFF845EC2), Color(0xFFD65DB1)],
  };

  List<Color> _getFileGradient(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return _fileGradients[extension] ?? [const Color(0xFF667EEA), const Color(0xFF764BA2)];
  }

  // Optimized file size formatting
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(), // Better scroll physics
            slivers: [
              // Header as sliver for better performance
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _headerController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: Transform.scale(
                          scale: _headerScaleAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF1E293B),
                                  Color(0xFF334155),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF667EEA).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.library_books_rounded,
                                              color: Color(0xFF667EEA),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Study Materials',
                                              style: GoogleFonts.inter(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Browse and download educational resources',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.white70,
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
                ),
              ),

              // Content area as sliver
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('study_materials')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildOptimizedLoader(text: "Loading materials..."),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: _buildErrorWidget(),
                    );
                  }

                  final materials = snapshot.data?.docs ?? [];

                  if (materials.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildEmptyWidget(),
                    );
                  }

                  _initializeStaggeredAnimations(materials.length);

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final material = materials[index];
                        final gradient = _cardGradients[index % _cardGradients.length];

                        return AnimatedBuilder(
                          animation: _staggeredAnimations[index],
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 20 * (1 - _staggeredAnimations[index].value)),
                              child: Opacity(
                                opacity: _staggeredAnimations[index].value,
                                child: OptimizedStudyMaterialCard(
                                  material: material,
                                  gradient: gradient,
                                  onDownload: () => _downloadFile(
                                    material['fileUrl'] ?? '',
                                    material['title'] ?? 'Unknown',
                                  ),
                                  getFileIcon: _getFileIcon,
                                  getFileGradient: _getFileGradient,
                                  formatFileSize: _formatFileSize,
                                  subjectCache: _subjectCache,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      childCount: materials.length,
                    ),
                  );
                },
              ),

              // Footer
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'Developed By Brolytics Technologies',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFE53E3E),
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Materials',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: const Color(0xFF94A3B8).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Study Materials',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new uploads',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OptimizedStudyMaterialCard extends StatefulWidget {
  final QueryDocumentSnapshot material;
  final List<Color> gradient;
  final VoidCallback onDownload;
  final IconData Function(String) getFileIcon;
  final List<Color> Function(String) getFileGradient;
  final String Function(int) formatFileSize;
  final Map<String, String> subjectCache;

  const OptimizedStudyMaterialCard({
    Key? key,
    required this.material,
    required this.gradient,
    required this.onDownload,
    required this.getFileIcon,
    required this.getFileGradient,
    required this.formatFileSize,
    required this.subjectCache,
  }) : super(key: key);

  @override
  _OptimizedStudyMaterialCardState createState() => _OptimizedStudyMaterialCardState();
}

class _OptimizedStudyMaterialCardState extends State<OptimizedStudyMaterialCard>
    with SingleTickerProviderStateMixin {

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.material.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Unknown Title';
    final fileName = data['fileName'] ?? 'Unknown File';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final subjectId = data['subjectId'] as String?;
    final fileSize = data['fileSize'] as int? ?? 0;
    final fileIcon = widget.getFileIcon(fileName);
    final fileGradient = widget.getFileGradient(fileName);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E293B).withOpacity(0.8),
                    const Color(0xFF334155).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: fileGradient.first.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: widget.onDownload,
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // File Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: fileGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            fileIcon,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // File Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),

                              // Subject Name with caching
                              if (subjectId != null)
                                _buildSubjectChip(subjectId, fileGradient),

                              const SizedBox(height: 4),

                              // File info
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white60,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (fileSize > 0) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      widget.formatFileSize(fileSize),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white60,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Download button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: fileGradient,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.download_rounded,
                            size: 20,
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
    );
  }

  Widget _buildSubjectChip(String subjectId, List<Color> fileGradient) {
    // Check cache first
    if (widget.subjectCache.containsKey(subjectId)) {
      return _buildChip(widget.subjectCache[subjectId]!, fileGradient);
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('subjects')
          .doc(subjectId)
          .snapshots(),
      builder: (context, snapshot) {
        String subjectName = 'Loading...';

        if (snapshot.hasData && snapshot.data!.exists) {
          subjectName = snapshot.data!['name'] ?? 'Unknown Subject';
          // Cache the result
          widget.subjectCache[subjectId] = subjectName;
        }

        return _buildChip(subjectName, fileGradient);
      },
    );
  }

  Widget _buildChip(String text, List<Color> fileGradient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fileGradient.first.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: fileGradient.first,
        ),
      ),
    );
  }
}