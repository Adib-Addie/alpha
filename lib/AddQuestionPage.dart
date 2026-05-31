import 'dart:async';
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

class AddQuestionPage extends StatefulWidget {
  final String subjectName;
  final String subjectId;

  const AddQuestionPage({super.key, required this.subjectName, required this.subjectId});

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> with TickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  int? _correctOptionIndex;
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  List<AnimationController> _cardControllers = [];
  List<Animation<double>> _cardFadeAnimations = [];
  List<Animation<Offset>> _cardSlideAnimations = [];
  bool _isLoading = false;
  int _lastItemCount = 0;

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
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _headerController.dispose();
    _pulseController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeCardAnimations(int itemCount) {
    if (_lastItemCount == itemCount) return;

    for (var controller in _cardControllers) {
      controller.dispose();
    }
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
    _lastItemCount = itemCount;
  }

  Future<void> _saveQuestion() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }
      if (_correctOptionIndex == null) {
        throw Exception('Please select a correct option');
      }
      final questionData = {
        'subjectId': widget.subjectId,
        'subjectName': widget.subjectName.substring(0, widget.subjectName.length.clamp(1, 50)),
        'question': _questionController.text.trim().substring(0, _questionController.text.trim().length.clamp(1, 500)),
        'options': _optionControllers
            .map((controller) => controller.text.trim().substring(0, controller.text.trim().length.clamp(1, 200)))
            .toList(),
        'correctOptionIndex': _correctOptionIndex,
        'createdAt': FieldValue.serverTimestamp(),
        'hidden': false,
      };

      await SchedulerBinding.instance.scheduleTask(() async {
        await FirebaseFirestore.instance.collection('questions').add(questionData);
      }, Priority.animation);

      _questionController.clear();
      for (var controller in _optionControllers) {
        controller.clear();
      }
      setState(() => _correctOptionIndex = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Question added successfully!',
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
                'Failed to add question: $e',
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

  Future<void> _uploadQuestionsFromPDF() async {
    setState(() => _isLoading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = result.files.single;
      final text = await _extractTextFromPDF(file.path!);

      final questions = _parsePDFText(text);
      if (questions.isEmpty) {
        throw Exception('No valid questions found in PDF');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await SchedulerBinding.instance.scheduleTask(() async {
        final batch = FirebaseFirestore.instance.batch();
        for (var question in questions) {
          final docRef = FirebaseFirestore.instance.collection('questions').doc();
          batch.set(docRef, {
            'subjectId': widget.subjectId,
            'subjectName': widget.subjectName.substring(0, widget.subjectName.length.clamp(1, 50)),
            'question': question['question'].substring(0, question['question'].length.clamp(1, 500)),
            'options': question['options'].map((opt) => opt.substring(0, opt.length.clamp(1, 200))).toList(),
            'correctOptionIndex': question['correctOptionIndex'],
            'createdAt': FieldValue.serverTimestamp(),
            'hidden': false,
          });
        }
        await batch.commit();
      }, Priority.animation);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                '${questions.length} questions added successfully!',
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
                'Failed to upload questions: $e',
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

// Replace the existing _extractTextFromPDF method with this corrected version
  Future<String> _extractTextFromPDF(String filePath) async {
    try {
      // Read the PDF file as bytes
      final File file = File(filePath);
      final List<int> bytes = await file.readAsBytes();

      // Load the PDF document from bytes
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      // Extract text from all pages
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();

      // Close the document
      document.dispose();

      return text;
    } catch (e) {
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  List<Map<String, dynamic>> _parsePDFText(String text) {
    final questions = <Map<String, dynamic>>[];
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    int i = 0;

    while (i < lines.length) {
      if (RegExp(r'^\d+\.\s').hasMatch(lines[i])) {
        final questionText = lines[i].replaceFirst(RegExp(r'^\d+\.\s'), '');
        final options = <String>[];
        int correctOptionIndex = -1;

        i++;
        while (i < lines.length && RegExp(r'^[A-D]\)\s').hasMatch(lines[i])) {
          options.add(lines[i].replaceFirst(RegExp(r'^[A-D]\)\s'), ''));
          i++;
        }

        if (i < lines.length && lines[i].startsWith('Correct Answer: ')) {
          final answer = lines[i].replaceFirst('Correct Answer: ', '').trim();
          correctOptionIndex = 'ABCD'.indexOf(answer);
          if (correctOptionIndex == -1) {
            correctOptionIndex = int.tryParse(answer) ?? -1;
            if (correctOptionIndex > 0) correctOptionIndex--; // Convert to 0-based index
          }
          i++;
        }

        if (options.length == 4 && correctOptionIndex >= 0 && correctOptionIndex < 4) {
          questions.add({
            'question': questionText,
            'options': options,
            'correctOptionIndex': correctOptionIndex,
          });
        }
      } else {
        i++;
      }
    }

    return questions;
  }

  Future<void> _deleteQuestion(String questionId) async {
    setState(() => _isLoading = true);
    try {
      await SchedulerBinding.instance.scheduleTask(() async {
        await FirebaseFirestore.instance.collection('questions').doc(questionId).delete();
      }, Priority.animation);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Question deleted successfully!',
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
                'Failed to delete question: $e',
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

  Future<void> _toggleQuestionVisibility(String questionId, bool currentHidden) async {
    setState(() => _isLoading = true);
    try {
      await SchedulerBinding.instance.scheduleTask(() async {
        await FirebaseFirestore.instance
            .collection('questions')
            .doc(questionId)
            .update({'hidden': !currentHidden});
      }, Priority.animation);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                currentHidden ? 'Question unhidden successfully!' : 'Question hidden successfully!',
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
                'Failed to toggle visibility: $e',
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

  Future<void> _showDetails(Map<String, dynamic> data, String questionId) async {
    await showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        transitionDuration: Duration(milliseconds: 300),
        reverseTransitionDuration: Duration(milliseconds: 200),
      ),
      builder: (context) {
        final ts = (data['createdAt'] as Timestamp?)?.toDate();
        final date = ts != null
            ? '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
            : '';
        return AnimatedQuestionDialog(
          data: data,
          date: date,
          questionId: questionId,
          onClose: () => Navigator.pop(context),
          onDelete: () {
            _deleteQuestion(questionId);
            Navigator.pop(context);
          },
          onToggleVisibility: () => _toggleQuestionVisibility(questionId, data['hidden'] ?? false),
        );
      },
    );
  }

  void _showAddQuestionDialog() {
    final formKey = GlobalKey<FormState>();
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        transitionDuration: Duration(milliseconds: 300),
        reverseTransitionDuration: Duration(milliseconds: 200),
      ),
      builder: (BuildContext context) {
        final isDesktop = MediaQuery.of(context).size.width > 600;
        final dialogWidth = isDesktop ? 600.0 : MediaQuery.of(context).size.width * 0.9;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF1E293B),
          child: Container(
            width: dialogWidth,
            padding: EdgeInsets.all(isDesktop ? 32.0 : 24.0),
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
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add New Question',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 26.0 : 24.0,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create an MCQ for ${widget.subjectName}',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 16.0 : 14.0,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ModernTextField(
                      controller: _questionController,
                      label: 'Question Text',
                      icon: Icons.question_mark_rounded,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a valid question';
                        }
                        if (value.trim().length > 500) {
                          return 'Question cannot exceed 500 chars';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ..._optionControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ModernTextField(
                          controller: controller,
                          label: 'Option ${index + 1}',
                          icon: Icons.radio_button_unchecked_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter option ${index + 1}';
                            }
                            if (value.trim().length > 200) {
                              return 'Option cannot exceed 200 chars';
                            }
                            return null;
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    Text(
                      'Select Correct Answer',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 18.0 : 16.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: _optionControllers.asMap().entries.map((entry) {
                        final index = entry.key;
                        return RadioListTile<int>(
                          title: Text(
                            'Option ${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: isDesktop ? 16.0 : 14.0,
                              color: Colors.white,
                            ),
                          ),
                          value: index,
                          groupValue: _correctOptionIndex,
                          onChanged: (value) {
                            setState(() => _correctOptionIndex = value);
                          },
                          activeColor: const Color(0xFF667EEA),
                          contentPadding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: ModernButton(
                            text: 'Cancel',
                            gradient: const [Color(0xFF94A3B8), Color(0xFF64748B)],
                            icon: Icons.close_rounded,
                            onPressed: () {
                              _questionController.clear();
                              for (var controller in _optionControllers) {
                                controller.clear();
                              }
                              setState(() => _correctOptionIndex = null);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: ModernButton(
                            text: 'Save Question',
                            gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                            icon: Icons.save_rounded,
                            onPressed: () {
                              if (formKey.currentState!.validate() && _correctOptionIndex != null) {
                                _saveQuestion();
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.white),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Please fill all fields and select the correct option.',
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
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(String questionId, String questionText) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1E293B),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Text(
                'Delete Question',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Are you sure you want to delete this question?',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    questionText.length > 50 ? '${questionText.substring(0, 50)}...' : questionText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await _deleteQuestion(questionId);
    }
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
            SafeArea(
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
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
                                                widget.subjectName,
                                                style: GoogleFonts.inter(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                  letterSpacing: -0.5,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Add and manage questions for this subject',
                                                style: GoogleFonts.inter(
                                                  fontSize: 18,
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
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
                                                  Icons.upload_file_rounded,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                                onPressed: _uploadQuestionsFromPDF,
                                                tooltip: 'Upload Questions from PDF',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
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
                                                  Icons.add_rounded,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                                onPressed: _showAddQuestionDialog,
                                                tooltip: 'Add Question',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('questions')
                                  .where('subjectId', isEqualTo: widget.subjectId)
                                  .orderBy('createdAt', descending: false)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Error: ${snapshot.error}',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            color: const Color(0xFFE53E3E),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        TextButton(
                                          onPressed: () => setState(() {}),
                                          child: Text(
                                            'Retry',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              color: const Color(0xFF667EEA),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF667EEA),
                                      strokeWidth: 4,
                                    ),
                                  );
                                }

                                final questions = snapshot.data!.docs;
                                if (questions.isEmpty) {
                                  return Center(
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
                                          'Add a new question or upload a PDF to get started',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                _initializeCardAnimations(questions.length);

                                final isDesktop = MediaQuery.of(context).size.width > 600;
                                return isDesktop
                                    ? GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 500,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 2.1,
                                  ),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: questions.length,
                                  itemBuilder: (context, index) {
                                    final questionData = questions[index].data() as Map<String, dynamic>;
                                    final animationIndex = index < _cardFadeAnimations.length ? index : _cardFadeAnimations.length - 1;
                                    return FadeTransition(
                                      opacity: _cardFadeAnimations[animationIndex],
                                      child: SlideTransition(
                                        position: _cardSlideAnimations[animationIndex],
                                        child: QuestionCard(
                                          data: questionData,
                                          questionId: questions[index].id,
                                          index: index,
                                          gradient: cardGradients[index % cardGradients.length],
                                          onTap: () => _showDetails(questionData, questions[index].id),
                                          onDelete: () => _showDeleteConfirmationDialog(
                                            questions[index].id,
                                            questionData['question'] as String,
                                          ),
                                          onToggleVisibility: () => _toggleQuestionVisibility(
                                            questions[index].id,
                                            questionData['hidden'] ?? false,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                                    : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: questions.length,
                                  itemBuilder: (context, index) {
                                    final questionData = questions[index].data() as Map<String, dynamic>;
                                    final animationIndex = index < _cardFadeAnimations.length ? index : _cardFadeAnimations.length - 1;
                                    return FadeTransition(
                                      opacity: _cardFadeAnimations[animationIndex],
                                      child: SlideTransition(
                                        position: _cardSlideAnimations[animationIndex],
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 16),
                                          child: QuestionCard(
                                            data: questionData,
                                            questionId: questions[index].id,
                                            index: index,
                                            gradient: cardGradients[index % cardGradients.length],
                                            onTap: () => _showDetails(questionData, questions[index].id),
                                            onDelete: () => _showDeleteConfirmationDialog(
                                              questions[index].id,
                                              questionData['question'] as String,
                                            ),
                                            onToggleVisibility: () => _toggleQuestionVisibility(
                                              questions[index].id,
                                              questionData['hidden'] ?? false,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
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
          ],
        ),
      ),
    );
  }
}

class QuestionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String questionId;
  final int index;
  final List<Color> gradient;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;

  const QuestionCard({
    Key? key,
    required this.data,
    required this.questionId,
    required this.index,
    required this.gradient,
    required this.onTap,
    required this.onDelete,
    required this.onToggleVisibility,
  }) : super(key: key);

  @override
  _QuestionCardState createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
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
    final questionText = widget.data['question'] ?? '';
    final options = (widget.data['options'] as List<dynamic>?)?.cast<String>() ?? [];
    final correctOptionIndex = widget.data['correctOptionIndex'] as int? ?? -1;
    final isHidden = widget.data['hidden'] ?? false;

    return Dismissible(
      key: Key(widget.questionId),
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
          color: Colors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        widget.onDelete();
        return false;
      },
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _hoverAnimation.value,
              child: GestureDetector(
                onTap: widget.onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isHidden ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFF1E293B).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isHidden ? const Color(0xFF475569).withOpacity(0.1) : const Color(0xFF475569).withOpacity(0.3),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          child: Center(
                            child: Text(
                              questionText.isNotEmpty ? questionText[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    questionText,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: isHidden ? Colors.white.withOpacity(0.5) : Colors.white,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Semantics(
                                  label: isHidden ? 'Unhide question' : 'Hide question',
                                  child: IconButton(
                                    icon: Icon(
                                      isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      color: isHidden ? const Color(0xFF94A3B8) : const Color(0xFF667EEA),
                                      size: 20,
                                    ),
                                    onPressed: widget.onToggleVisibility,
                                    tooltip: isHidden ? 'Unhide Question' : 'Hide Question',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...options.asMap().entries.map((entry) {
                              final optIndex = entry.key;
                              final option = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      optIndex == correctOptionIndex
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: optIndex == correctOptionIndex
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF94A3B8),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        option,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: optIndex == correctOptionIndex ? FontWeight.w500 : FontWeight.w400,
                                          color: optIndex == correctOptionIndex
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
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
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AnimatedQuestionDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final String date;
  final String questionId;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onToggleVisibility;

  const AnimatedQuestionDialog({
    Key? key,
    required this.data,
    required this.date,
    required this.questionId,
    required this.onClose,
    required this.onDelete,
    required this.onToggleVisibility,
  }) : super(key: key);

  @override
  _AnimatedQuestionDialogState createState() => _AnimatedQuestionDialogState();
}

class _AnimatedQuestionDialogState extends State<AnimatedQuestionDialog> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questionText = widget.data['question'] ?? '';
    final options = (widget.data['options'] as List<dynamic>?)?.cast<String>() ?? [];
    final correctOptionIndex = widget.data['correctOptionIndex'] as int? ?? -1;
    final isHidden = widget.data['hidden'] ?? false;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF1E293B),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Text(
                  questionText.length > 50 ? '${questionText.substring(0, 50)}...' : questionText,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questionText,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isHidden ? Colors.white.withOpacity(0.5) : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...options.asMap().entries.map((entry) {
                      final optIndex = entry.key;
                      final option = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              optIndex == correctOptionIndex
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: optIndex == correctOptionIndex
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                option,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: optIndex == correctOptionIndex ? FontWeight.w500 : FontWeight.w400,
                                  color: optIndex == correctOptionIndex
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (widget.date.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.date,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onClose,
                      child: Text(
                        'Close',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.onToggleVisibility,
                      child: Text(
                        isHidden ? 'Unhide' : 'Hide',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isHidden ? const Color(0xFF667EEA) : const Color(0xFFFFB300),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: widget.onDelete,
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModernTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
  });

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _borderAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _borderAnimation = ColorTween(
      begin: const Color(0xFF475569),
      end: const Color(0xFF667EEA),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return AnimatedBuilder(
      animation: _borderAnimation,
      builder: (context, child) {
        return TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          onTap: () {
            if (!_isFocused) {
              setState(() => _isFocused = true);
              _controller.forward();
            }
          },
          onTapOutside: (_) {
            if (_isFocused) {
              setState(() => _isFocused = false);
              _controller.reverse();
            }
          },
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 18.0 : 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: GoogleFonts.inter(
              color: _isFocused ? const Color(0xFF667EEA) : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
              fontSize: isDesktop ? 16.0 : 14.0,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused ? const Color(0xFF667EEA) : const Color(0xFF94A3B8),
              size: isDesktop ? 22.0 : 20.0,
            ),
            filled: true,
            fillColor: _isFocused ? const Color(0xFF667EEA).withOpacity(0.1) : const Color(0xFF334155).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _borderAnimation.value!, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: const Color(0xFF475569).withOpacity(0.3), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: isDesktop ? 20.0 : 16.0, vertical: isDesktop ? 18.0 : 16.0),
          ),
        );
      },
    );
  }
}

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
  bool _isHovered = false;

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
    final isDesktop = MediaQuery.of(context).size.width > 600;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onPressed,
        focusColor: widget.gradient.first.withOpacity(0.1),
        onHighlightChanged: (highlighted) {
          setState(() => _isPressed = highlighted);
          if (highlighted) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: isDesktop ? 180.0 : 160.0,
                padding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 14.0 : 12.0,
                  horizontal: isDesktop ? 12.0 : 10.0,
                ),
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
                      color: widget.gradient.first.withOpacity(_isHovered ? 0.4 : 0.3),
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
                      size: isDesktop ? 22.0 : 20.0,
                    ),
                    if (widget.text.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        widget.text,
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 16.0 : 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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