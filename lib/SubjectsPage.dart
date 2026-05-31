import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'AddQuestionPage.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> with TickerProviderStateMixin {
  final TextEditingController _subjectController = TextEditingController();
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardFadeAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;
  bool _isLoading = false;

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
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _headerController.dispose();
    _pulseController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeCardAnimations(int itemCount) {
    if (_cardControllers.length == itemCount) return;
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
  }

  Future<void> _deleteSubject(String subjectId, String subjectName, Map<String, dynamic> subjectData) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Delete Subject',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$subjectName"?',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF94A3B8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance.collection('subjects').doc(subjectId).delete();
                final snackBar = SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Text(
                        '"$subjectName" deleted',
                        style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFFE53E3E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                  action: SnackBarAction(
                    label: 'Undo',
                    textColor: Colors.white,
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('subjects').doc(subjectId).set(subjectData);
                    },
                  ),
                  duration: const Duration(seconds: 4),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: const Color(0xFFE53E3E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
                'Failed to delete subject: $e',
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
  }

  Future<void> _toggleLock(String subjectId, String subjectName, bool currentLockState) async {
    try {
      await FirebaseFirestore.instance.collection('subjects').doc(subjectId).update({
        'locked': !currentLockState,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                '"$subjectName" ${!currentLockState ? 'locked' : 'unlocked'}',
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
                'Failed to ${!currentLockState ? 'lock' : 'unlock'} subject: $e',
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
  }

  void _showCreateSubjectDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        transitionDuration: Duration(milliseconds: 300),
        reverseTransitionDuration: Duration(milliseconds: 200),
      ),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF1E293B),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add New Subject',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter the name of the new subject',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ModernTextField(
                    controller: _subjectController,
                    label: 'Subject Name',
                    icon: Icons.book_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a subject name';
                      }
                      if (value.trim().length < 2 || value.trim().length > 50) {
                        return 'Subject name must be between 2 and 50 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ModernButton(
                        text: 'Cancel',
                        gradient: const [Color(0xFF94A3B8), Color(0xFF64748B)],
                        icon: Icons.close_rounded,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      ModernButton(
                        text: 'Add Subject',
                        gradient: const [Color(0xFF667EEA), const Color(0xFF764BA2)],
                        icon: Icons.add_rounded,
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            _createSubject();
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _createSubject() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('subjects').add({
        'name': _subjectController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'locked': false,
      });
      _subjectController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Subject added successfully!',
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
                'Failed to add subject: $e',
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
            Center(
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
                                          tooltip: 'Back',
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Subjects',
                                              style: GoogleFonts.inter(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Manage and add subjects for your classroom',
                                              style: GoogleFonts.inter(
                                                fontSize: 18,
                                                color: Colors.white.withOpacity(0.9),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                          onPressed: () => _showCreateSubjectDialog(context),
                                          tooltip: 'Add Subject',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 1000),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('subjects')
                                .orderBy('createdAt', descending: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Error: ${snapshot.error}',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      color: const Color(0xFFE53E3E),
                                      fontWeight: FontWeight.w500,
                                    ),
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

                              final dynamicSubjects = snapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>?;
                                return {
                                  'id': doc.id,
                                  'name': data?['name'] as String? ?? 'Unknown',
                                  'createdAt': data?['createdAt'],
                                  'locked': data?.containsKey('locked') == true ? data!['locked'] as bool : false,
                                };
                              }).toList();

                              if (dynamicSubjects.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.book_rounded,
                                        size: 80,
                                        color: const Color(0xFF94A3B8).withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Subjects Available',
                                        style: GoogleFonts.inter(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add a new subject to get started',
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

                              _initializeCardAnimations(dynamicSubjects.length);

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 400,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 3.5,
                                ),
                                itemCount: dynamicSubjects.length,
                                itemBuilder: (context, index) {
                                  final subject = dynamicSubjects[index];
                                  final gradient = cardGradients[index % cardGradients.length];

                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('questions')
                                        .where('subjectId', isEqualTo: subject['id'])
                                        .snapshots(),
                                    builder: (context, questionSnapshot) {
                                      int questionCount = 0;
                                      if (questionSnapshot.hasData) {
                                        questionCount = questionSnapshot.data!.docs.length;
                                      }

                                      return Dismissible(
                                        key: Key(subject['id']!),
                                        direction: DismissDirection.startToEnd,
                                        background: Container(
                                          alignment: Alignment.centerLeft,
                                          padding: const EdgeInsets.only(left: 20),
                                          margin: const EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE53E3E),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 32),
                                        ),
                                        onDismissed: (direction) {
                                          _deleteSubject(
                                            subject['id']!,
                                            subject['name']!,
                                            {
                                              'name': subject['name'],
                                              'createdAt': subject['createdAt'],
                                              'locked': subject['locked'],
                                            },
                                          );
                                        },
                                        child: FadeTransition(
                                          opacity: _cardFadeAnimations[index],
                                          child: SlideTransition(
                                            position: _cardSlideAnimations[index],
                                            child: ModernAnimatedCard(
                                              title: subject['name']!,
                                              subtitle: questionCount > 0
                                                  ? '$questionCount Question${questionCount == 1 ? '' : 's'} • ${subject['locked'] ? '🛑 Locked - Add or view questions' : 'Add or view questions'}'
                                                  : 'No Questions • ${subject['locked'] ? '🛑 Locked - Add or view questions' : 'Add or view questions'}',
                                              icon: Icons.book_rounded,
                                              gradient: gradient,
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  PageRouteBuilder(
                                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                                        AddQuestionPage(
                                                          subjectName: subject['name']!,
                                                          subjectId: subject['id']!,
                                                        ),
                                                    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                                                        SharedAxisTransition(
                                                          animation: animation,
                                                          secondaryAnimation: secondaryAnimation,
                                                          transitionType: SharedAxisTransitionType.scaled,
                                                          child: child,
                                                        ),
                                                  ),
                                                );
                                              },
                                              isLocked: subject['locked'],
                                              onLockToggle: () => _toggleLock(
                                                subject['id']!,
                                                subject['name']!,
                                                subject['locked'],
                                              ),
                                              delay: index * 150,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
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
          ],
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
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: GoogleFonts.inter(
              color: _isFocused ? const Color(0xFF667EEA) : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused ? const Color(0xFF667EEA) : const Color(0xFF94A3B8),
              size: 24,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
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
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 180,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                      color: widget.gradient.first.withOpacity(_isPressed ? 0.2 : 0.4),
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
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.text,
                      style: GoogleFonts.inter(
                        fontSize: 16,
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

class ModernAnimatedCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onPressed;
  final int delay;
  final bool isLocked;
  final VoidCallback? onLockToggle;

  const ModernAnimatedCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onPressed,
    required this.delay,
    this.isLocked = false,
    this.onLockToggle,
  });

  @override
  State<ModernAnimatedCard> createState() => _ModernAnimatedCardState();
}

class _ModernAnimatedCardState extends State<ModernAnimatedCard> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _hoverController;
  late AnimationController _lockController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _hoverAnimation;
  late Animation<double> _lockScaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
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
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _lockScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _lockController, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hoverController.dispose();
    _lockController.dispose();
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
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _hoverAnimation.value,
                child: GestureDetector(
                  onTap: widget.onPressed,
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
                          color: widget.gradient.first.withOpacity(_isHovered ? 0.4 : 0.2),
                          blurRadius: _isHovered ? 25 : 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
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
                            child: Icon(
                              widget.icon,
                              size: 24,
                              color: Colors.white,
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
                                widget.title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (widget.onLockToggle != null)
                          GestureDetector(
                            onTap: () {
                              _lockController.forward().then((_) => _lockController.reverse());
                              widget.onLockToggle!();
                            },
                            child: AnimatedBuilder(
                              animation: _lockScaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _lockScaleAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: widget.gradient.first.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      widget.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                      size: 20,
                                      color: widget.gradient.first,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: _isHovered ? 0.0 : -0.125,
                          duration: const Duration(milliseconds: 250),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.gradient.first.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
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
      ),
    );
  }
}