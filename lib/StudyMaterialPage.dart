import 'dart:async';

import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class StudyMaterialPage extends StatefulWidget {
  const StudyMaterialPage({Key? key}) : super(key: key);

  @override
  _StudyMaterialPageState createState() => _StudyMaterialPageState();
}

class _StudyMaterialPageState extends State<StudyMaterialPage>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  // Pre-defined gradient colors to avoid repeated list creation
  static const List<List<Color>> _cardGradients = [
    [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
    [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [Color(0xFF0A0020), Color(0xFF150040), Color(0xFF200060)],
    [Color(0xFF12002F), Color(0xFF1C0050), Color(0xFF2D0080)],
    [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
    [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
  ];

  // Cache for subject data to reduce Firestore reads
  final Map<String, String> _subjectCache = {};

  // Stream subscription for better memory management
  StreamSubscription<QuerySnapshot>? _materialsSubscription;

  @override
  void dispose() {
    _materialsSubscription?.cancel();
    super.dispose();
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
    'doc': [Color(0xFF00B4DB), Color(0xFF2563EB)],
    'docx': [Color(0xFF00B4DB), Color(0xFF2563EB)],
    'ppt': [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    'pptx': [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    'txt': [Color(0xFF10B981), Color(0xFF059669)],
    'xls': [Color(0xFF10B981), Color(0xFF059669)],
    'xlsx': [Color(0xFF10B981), Color(0xFF059669)],
    'jpg': [Color(0xFF7B2FBE), Color(0xFF7C3AED)],
    'jpeg': [Color(0xFF7B2FBE), Color(0xFF7C3AED)],
    'png': [Color(0xFF7B2FBE), Color(0xFF7C3AED)],
    'gif': [Color(0xFF7B2FBE), Color(0xFF7C3AED)],
    'mp4': [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    'avi': [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    'mov': [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    'mp3': [Color(0xFF12002F), Color(0xFF1C0050), Color(0xFF2D0080)],
    'wav': [Color(0xFF12002F), Color(0xFF1C0050), Color(0xFF2D0080)],
  };

  List<Color> _getFileGradient(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return _fileGradients[extension] ?? [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd];
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
              AppTheme.backgroundStart,
              AppTheme.backgroundMid,
              AppTheme.backgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: RepaintBoundary(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.backgroundMid,
                          AppTheme.backgroundEnd,
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
                                color: AppTheme.textPrimary,
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
                                      color: const Color(0xFF7B2FBE).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.library_books_rounded,
                                      color: Color(0xFF7B2FBE),
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
                                        color: AppTheme.textPrimary,
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
                                  color: AppTheme.textSecondary,
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
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFF7B2FBE)),
                        ),
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

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final material = materials[index];
                        final gradient = _cardGradients[index % _cardGradients.length];

                        return OptimizedStudyMaterialCard(
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
                      'Developed by Brolytics Technologies',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
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
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
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
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Study Materials',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new uploads',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
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

class _OptimizedStudyMaterialCardState extends State<OptimizedStudyMaterialCard> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.material.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Unknown Title';
    final fileName = data['fileName'] ?? 'Unknown File';
    final subjectId = data['subjectId'] as String?;
    final fileSize = data['fileSize'] as int? ?? 0;
    final fileIcon = widget.getFileIcon(fileName);
    final fileGradient = widget.getFileGradient(fileName);

    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundMid.withOpacity(0.8),
              AppTheme.backgroundEnd.withOpacity(0.6),
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
                      color: AppTheme.textPrimary,
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
                            color: AppTheme.textPrimary,
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
                                  color: AppTheme.textMuted,
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
                                  color: AppTheme.textMuted,
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
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
