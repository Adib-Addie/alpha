import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:animations/animations.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class StudentProfilePage extends StatefulWidget {
  final String studentId;
  const StudentProfilePage({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _isLoading = false;

  final List<List<Color>> cardGradients = [
    [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
    [AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
  ];

  Future<void> _downloadResult(Map<String, dynamic> result, Map<String, dynamic> student) async {
    setState(() => _isLoading = true);
    try {
      final robotoRegular = await PdfGoogleFonts.robotoRegular();
      final robotoBold = await PdfGoogleFonts.robotoBold();
      final robotoMedium = await PdfGoogleFonts.robotoMedium();

      final logoBytes = await rootBundle.load('assets/logoimg.jpg');
      final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

      final pdf = pw.Document();
      final timestamp = (result['timestamp'] as Timestamp?)?.toDate();
      final incorrect = (result['incorrect'] as List<dynamic>? ?? []);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          build: (context) {
            return pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: PdfColor.fromInt(0xFF7B2FBE), width: 6),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        gradient: pw.LinearGradient(
                          colors: [PdfColor.fromInt(0xFF7B2FBE), PdfColor.fromInt(0xFF4A00E0)],
                          begin: pw.Alignment.topLeft,
                          end: pw.Alignment.bottomRight,
                        ),
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: PdfColor.fromInt(0xFF16213E), width: 1.5),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(8),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.white,
                              borderRadius: pw.BorderRadius.circular(40),
                              border: pw.Border.all(color: PdfColor.fromInt(0xFF7B2FBE), width: 2),
                            ),
                            child: pw.ClipOval(
                              child: pw.Image(logoImage, width: 60, height: 60),
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFF1A1A2E),
                              borderRadius: pw.BorderRadius.circular(20),
                            ),
                            child: pw.Text(
                              'ALPHA GRAPHICS',
                              style: pw.TextStyle(
                                font: robotoBold,
                                fontSize: 22,
                                color: PdfColors.white,
                                letterSpacing: 1.5,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: pw.BoxDecoration(
                              gradient: pw.LinearGradient(
                                colors: [PdfColor.fromInt(0xFF7B2FBE), PdfColor.fromInt(0xFF4A00E0)],
                                begin: pw.Alignment.topLeft,
                                end: pw.Alignment.bottomRight,
                              ),
                              borderRadius: pw.BorderRadius.circular(15),
                            ),
                            child: pw.Text(
                              'TEST SERIES RESULT',
                              style: pw.TextStyle(
                                font: robotoMedium,
                                fontSize: 16,
                                color: PdfColors.white,
                                letterSpacing: 0.8,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF0A0A0A),
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: PdfColor.fromInt(0xFF16213E), width: 1.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: pw.BoxDecoration(
                              gradient: pw.LinearGradient(
                                colors: [PdfColor.fromInt(0xFF7B2FBE), PdfColor.fromInt(0xFF4A00E0)],
                                begin: pw.Alignment.topLeft,
                                end: pw.Alignment.bottomRight,
                              ),
                              borderRadius: pw.BorderRadius.circular(8),
                            ),
                            child: pw.Text(
                              'STUDENT DETAILS',
                              style: pw.TextStyle(
                                font: robotoBold,
                                fontSize: 14,
                                color: PdfColors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Table(
                            columnWidths: {
                              0: const pw.FlexColumnWidth(2),
                              1: const pw.FlexColumnWidth(3),
                            },
                            children: [
                              _buildTableRow('Student Name', student['name'] ?? 'Unknown', robotoMedium, robotoRegular),
                              _buildTableRow('Subject', result['subjectName'] ?? 'Unknown', robotoMedium, robotoRegular),
                              _buildTableRow('Score', '${result['score'] ?? 0} / ${result['total'] ?? 0}', robotoMedium, robotoRegular),
                              if (timestamp != null)
                                _buildTableRow(
                                  'Date & Time',
                                  '${timestamp.day.toString().padLeft(2, '0')}/'
                                      '${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} at '
                                      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                                  robotoMedium,
                                  robotoRegular,
                                ),
                              _buildTableRow('Batch', student['batch'] ?? 'N/A', robotoMedium, robotoRegular),
                              _buildTableRow('Batch Timing', student['batchTiming'] ?? 'N/A', robotoMedium, robotoRegular),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: _getPerformanceColor(result['score'] ?? 0, result['total'] ?? 0),
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: PdfColor.fromInt(0xFF16213E), width: 1.5),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'PERFORMANCE',
                            style: pw.TextStyle(
                              font: robotoBold,
                              fontSize: 16,
                              color: PdfColors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            _getPerformanceText(result['score'] ?? 0, result['total'] ?? 0),
                            style: pw.TextStyle(
                              font: robotoMedium,
                              fontSize: 20,
                              color: PdfColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 15),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF0A0A0A),
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(color: PdfColor.fromInt(0xFF16213E), width: 1.5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'About This Test Series',
                            style: pw.TextStyle(
                              font: robotoBold,
                              fontSize: 14,
                              color: PdfColor.fromInt(0xFF7B2FBE),
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            'The Alpha Graphics Test Series is designed to provide students with a comprehensive assessment of their knowledge and skills. This result reflects your performance in the test, highlighting areas of strength and opportunities for improvement. We are committed to supporting your academic growth with detailed feedback and resources.',
                            style: pw.TextStyle(
                              font: robotoRegular,
                              fontSize: 10,
                              color: PdfColors.grey300,
                              lineSpacing: 1.2,
                            ),
                            textAlign: pw.TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                    if (incorrect.isNotEmpty && incorrect.length <= 2) ...[
                      pw.SizedBox(height: 15),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(15),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF0A0A0A),
                          borderRadius: pw.BorderRadius.circular(10),
                          border: pw.Border.all(color: PdfColor.fromInt(0xFFE53E3E), width: 1.5),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFE53E3E),
                                borderRadius: pw.BorderRadius.circular(8),
                              ),
                              child: pw.Text(
                                'INCORRECT ANSWERS - REVIEW SECTION',
                                style: pw.TextStyle(
                                  font: robotoBold,
                                  fontSize: 14,
                                  color: PdfColors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            ...incorrect.asMap().entries.map<pw.Widget>((entry) {
                              final index = entry.key;
                              final e = entry.value;
                              final opts = (e['options'] as List).cast<String>();
                              final selected = e['selected'];
                              final correct = e['correct'];

                              return pw.Container(
                                margin: const pw.EdgeInsets.only(bottom: 10),
                                padding: const pw.EdgeInsets.all(12),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.white,
                                  borderRadius: pw.BorderRadius.circular(8),
                                  border: pw.Border.all(color: PdfColor.fromInt(0xFFE53E3E), width: 1),
                                ),
                                child: pw.Column(
                                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'Q${index + 1}. ${e['question'] ?? 'Unknown'}',
                                      style: pw.TextStyle(
                                        font: robotoBold,
                                        fontSize: 12,
                                        color: PdfColors.grey800,
                                      ),
                                    ),
                                    pw.SizedBox(height: 8),
                                    pw.Row(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Container(
                                          width: 16,
                                          height: 16,
                                          decoration: pw.BoxDecoration(
                                            color: PdfColor.fromInt(0xFFE53E3E),
                                            borderRadius: pw.BorderRadius.circular(8),
                                          ),
                                          child: pw.Center(
                                            child: pw.Text(
                                              '?',
                                              style: pw.TextStyle(
                                                font: robotoBold,
                                                fontSize: 10,
                                                color: PdfColors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        pw.SizedBox(width: 8),
                                        pw.Expanded(
                                          child: pw.Text(
                                            'Your answer: ${selected != null && selected < opts.length ? opts[selected] : 'Not answered'}',
                                            style: pw.TextStyle(
                                              font: robotoRegular,
                                              fontSize: 10,
                                              color: PdfColor.fromInt(0xFFE53E3E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    pw.SizedBox(height: 6),
                                    pw.Row(
                                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                                      children: [
                                        pw.Container(
                                          width: 16,
                                          height: 16,
                                          decoration: pw.BoxDecoration(
                                            color: PdfColor.fromInt(0xFF10B981),
                                            borderRadius: pw.BorderRadius.circular(8),
                                          ),
                                          child: pw.Center(
                                            child: pw.Text(
                                              '?',
                                              style: pw.TextStyle(
                                                font: robotoBold,
                                                fontSize: 10,
                                                color: PdfColors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        pw.SizedBox(width: 8),
                                        pw.Expanded(
                                          child: pw.Text(
                                            'Correct answer: ${correct != null && correct < opts.length ? opts[correct] : 'N/A'}',
                                            style: pw.TextStyle(
                                              font: robotoRegular,
                                              fontSize: 10,
                                              color: PdfColor.fromInt(0xFF10B981),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      );

      Directory? downloadsDir = await getDownloadsDirectory();
      if (downloadsDir == null) {
        downloadsDir = await getApplicationDocumentsDirectory();
      }
      await downloadsDir.create(recursive: true);

      final timestampStr = timestamp?.toIso8601String().replaceAll(':', '-') ?? 'unknown';
      final fileName = 'AlphaGraphics_Result_${result['subjectName']?.replaceAll(' ', '_') ?? 'test'}_$timestampStr.pdf';
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'PDF saved successfully!\nLocation: ${downloadsDir.path}/$fileName',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Failed to generate PDF: $e',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  pw.TableRow _buildTableRow(String label, String value, pw.Font boldFont, pw.Font regularFont) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF0A0A0A),
            border: pw.Border.all(color: PdfColor.fromInt(0xFF16213E), width: 1),
          ),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColor.fromInt(0xFF16213E), width: 1),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 14,
              color: PdfColors.grey800,
            ),
          ),
        ),
      ],
    );
  }

  PdfColor _getPerformanceColor(int score, int total) {
    if (total == 0) return PdfColor.fromInt(0xFF9E9E9E);
    double percentage = (score / total) * 100;
    if (percentage >= 80) return PdfColor.fromInt(0xFF10B981);
    if (percentage >= 60) return PdfColor.fromInt(0xFFF59E0B);
    return PdfColor.fromInt(0xFFE53E3E);
  }

  String _getPerformanceText(int score, int total) {
    if (total == 0) return 'No Data';
    double percentage = (score / total) * 100;
    if (percentage >= 80) return 'EXCELLENT';
    if (percentage >= 60) return 'GOOD';
    if (percentage >= 40) return 'AVERAGE';
    return 'NEEDS IMPROVEMENT';
  }

  Future<void> _deleteResult(String docId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppTheme.backgroundStart,
        title: Text(
          'Delete Test Result',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this test result?',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE53E3E),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('test_results').doc(docId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Test result deleted successfully',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Error deleting test result: $e',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showFullScreenImage(String imageUrl) async {
    await showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        transitionDuration: Duration(milliseconds: 300),
        reverseTransitionDuration: Duration(milliseconds: 200),
      ),
      builder: (context) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        child: Stack(
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Color(0xFF7B2FBE))),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error, color: Color(0xFFE53E3E), size: 50),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textPrimary, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      minHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                                    tooltip: 'Back',
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Student Profile',
                                        style: GoogleFonts.inter(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'View student details and test history',
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
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('students')
                                  .doc(widget.studentId)
                                  .snapshots(),
                              builder: (context, snap) {
                                if (snap.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error: ${snap.error}',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        color: const Color(0xFFE53E3E),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }
                                if (!snap.hasData || !snap.data!.exists) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person_rounded,
                                          size: 80,
                                          color: AppTheme.textSecondary.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Student Not Found',
                                          style: GoogleFonts.inter(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No student data available',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                if (snap.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF7B2FBE),
                                      strokeWidth: 4,
                                    ),
                                  );
                                }
                                final student = snap.data!.data() as Map<String, dynamic>;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Semantics(
                                      label: 'Profile of ${student['name'] ?? 'Unknown'}',
                                      child: ProfileCard(
                                        student: student,
                                        gradient: cardGradients[0],
                                        onImageTap: student['profilePictureUrl'] != null
                                            ? () => _showFullScreenImage(student['profilePictureUrl'])
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    Text(
                                      'Test History',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('test_results')
                                          .where('studentId', isEqualTo: widget.studentId)
                                          .snapshots(),
                                      builder: (context, resSnap) {
                                        if (resSnap.hasError) {
                                          return Center(
                                            child: Text(
                                              'Error: ${resSnap.error}',
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                color: const Color(0xFFE53E3E),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }
                                        if (!resSnap.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF7B2FBE),
                                              strokeWidth: 4,
                                            ),
                                          );
                                        }
                                        final results = resSnap.data!.docs.toList();
                                        results.sort((a, b) {
                                          final ta = (a['timestamp'] as Timestamp?)?.toDate();
                                          final tb = (b['timestamp'] as Timestamp?)?.toDate();
                                          if (ta == null && tb == null) return 0;
                                          if (ta == null) return 1;
                                          if (tb == null) return -1;
                                          return tb.compareTo(ta);
                                        });
                                        if (results.isEmpty) {
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
                                                  'No Test Results',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'No test results available',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          padding: const EdgeInsets.all(0),
                                          itemCount: results.length,
                                          itemBuilder: (context, i) {
                                            final r = results[i];
                                            final data = r.data() as Map<String, dynamic>;
                                            final gradient = cardGradients[i % cardGradients.length];
                                            return Semantics(
                                              label: 'Test result for ${data['subjectName'] ?? 'Unknown'}',
                                              child: Dismissible(
                                                key: Key(r.id),
                                                direction: DismissDirection.endToStart,
                                                background: Container(
                                                  alignment: Alignment.centerRight,
                                                  padding: const EdgeInsets.only(right: 20),
                                                  margin: const EdgeInsets.only(bottom: 16),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE53E3E),
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  child: const Icon(
                                                    Icons.delete_rounded,
                                                    color: AppTheme.textPrimary,
                                                    size: 32,
                                                  ),
                                                ),
                                                confirmDismiss: (direction) async {
                                                  await _deleteResult(r.id);
                                                  return true;
                                                },
                                                child: TestResultCard(
                                                  result: data,
                                                  student: student,
                                                  index: i,
                                                  gradient: gradient,
                                                  onDownload: () => _downloadResult(data, student),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
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
          ],
        ),
      ),
    );
  }
}

class ProfileCard extends StatefulWidget {
  final Map<String, dynamic> student;
  final List<Color> gradient;
  final VoidCallback? onImageTap;

  const ProfileCard({
    Key? key,
    required this.student,
    required this.gradient,
    this.onImageTap,
  }) : super(key: key);

  @override
  _ProfileCardState createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.student['name'] ?? 'Unknown';
    final profilePictureUrl = widget.student['profilePictureUrl'] as String?;
    final courseName = widget.student['courseName'] ?? 'N/A';
    final admissionNumber = widget.student['admissionNumber'] ?? 'N/A';
    final batch = widget.student['batch'] ?? 'N/A';
    final batchTiming = widget.student['batchTiming'] ?? 'N/A';
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
              color: widget.gradient.first.withOpacity(_isHovered ? 0.4 : 0.2),
              blurRadius: _isHovered ? 25 : 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onImageTap,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.gradient.first.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: AnimatedScale(
                      scale: _isHovered ? 1.08 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      child: Center(
                        child: profilePictureUrl != null
                            ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profilePictureUrl,
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(color: Color(0xFF7B2FBE)),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        )
                            : Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        courseName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.gradient.first.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Active Student',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.gradient.first,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ProfileDetailRow(
              icon: Icons.email_rounded,
              label: 'Email',
              value: widget.student['email'] ?? 'N/A',
              gradient: widget.gradient,
            ),
            const SizedBox(height: 12),
            ProfileDetailRow(
              icon: Icons.book_rounded,
              label: 'Course Name',
              value: courseName,
              gradient: widget.gradient,
            ),
            const SizedBox(height: 12),
            ProfileDetailRow(
              icon: Icons.confirmation_number_rounded,
              label: 'Admission Number',
              value: admissionNumber,
              gradient: widget.gradient,
            ),
            const SizedBox(height: 12),
            ProfileDetailRow(
              icon: Icons.person_rounded,
              label: "Father's Name",
              value: widget.student['fatherName'] ?? 'N/A',
              gradient: widget.gradient,
            ),
            const SizedBox(height: 12),
            ProfileDetailRow(
              icon: Icons.location_on_rounded,
              label: 'Address',
              value: widget.student['address'] ?? 'N/A',
              gradient: widget.gradient,
            ),
            const SizedBox(height: 12),
            ProfileDetailRow(
              icon: Icons.group_rounded,
              label: 'Batch',
              value: batch,
              gradient: widget.gradient,
            ),
            const SizedBox(height: 12),
            ProfileDetailRow(
              icon: Icons.schedule_rounded,
              label: 'Batch Timing',
              value: batchTiming,
              gradient: widget.gradient,
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;

  const ProfileDetailRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: gradient.first.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: gradient.first,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TestResultCard extends StatefulWidget {
  final Map<String, dynamic> result;
  final Map<String, dynamic> student;
  final int index;
  final List<Color> gradient;
  final VoidCallback onDownload;

  const TestResultCard({
    Key? key,
    required this.result,
    required this.student,
    required this.index,
    required this.gradient,
    required this.onDownload,
  }) : super(key: key);

  @override
  _TestResultCardState createState() => _TestResultCardState();
}

class _TestResultCardState extends State<TestResultCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final timestamp = (widget.result['timestamp'] as Timestamp?)?.toDate();
    final dateStr = timestamp != null
        ? '${timestamp.day.toString().padLeft(2, '0')}/'
        '${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} '
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
        : 'Unknown';
    final incorrect = (widget.result['incorrect'] as List<dynamic>? ?? []);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
              color: widget.gradient.first.withOpacity(_isHovered ? 0.4 : 0.2),
              blurRadius: _isHovered ? 25 : 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ExpansionTile(
          key: PageStorageKey(widget.result['timestamp'] ?? widget.index),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          backgroundColor: AppTheme.backgroundStart.withOpacity(0.9),
          collapsedBackgroundColor: AppTheme.backgroundStart.withOpacity(0.9),
          iconColor: widget.gradient.first,
          collapsedIconColor: AppTheme.textSecondary,
          trailing: AnimatedIconButton(
            onPressed: widget.onDownload,
            icon: Icons.download_rounded,
            color: widget.gradient.first,
          ),
          title: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.first.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedScale(
                  scale: _isHovered ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: const Center(
                    child: Icon(
                      Icons.quiz_rounded,
                      size: 24,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.result['subjectName'] ?? 'Subject',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Score: ${widget.result['score'] ?? 0} / ${widget.result['total'] ?? 0}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.gradient.first.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AnimatedRotation(
                  turns: _isHovered ? 0.0 : -0.125,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 20,
                    color: widget.gradient.first,
                  ),
                ),
              ),
            ],
          ),
          children: incorrect.map<Widget>((e) {
            final opts = (e['options'] as List).cast<String>();
            final selected = e['selected'];
            final correct = e['correct'];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundStart,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e['question'] ?? 'Unknown',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE53E3E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your answer: ${selected != null && selected < opts.length ? opts[selected] : 'N/A'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFFE53E3E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Correct answer: ${correct != null && correct < opts.length ? opts[correct] : 'N/A'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class AnimatedIconButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;

  const AnimatedIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  _AnimatedIconButtonState createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: Icon(
            widget.icon,
            color: widget.color,
            size: 20,
          ),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
