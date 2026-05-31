import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enhanced feedback screen with better animations and design
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _testController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  int _rating = 5;
  String _feedbackType = 'General';
  bool _isSending = false;
  bool _isUrgent = false;

  // Animation Controllers
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late AnimationController _formController;
  late AnimationController _particleController;
  late AnimationController _successController;

  // Animations
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _particleAnimation;

  final List<String> _feedbackTypes = [
    'General', 'Bug Report', 'Feature Request', 'UI/UX Issue',
    'Performance', 'Content Issue', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuart),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );
    _formFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutQuart),
    );
    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutBack),
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );

    _headerController.forward();
    _pulseController.repeat(reverse: true);
    _particleController.repeat();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _formController.forward();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _testController.dispose();
    _messageController.dispose();
    _headerController.dispose();
    _pulseController.dispose();
    _formController.dispose();
    _particleController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('feedback').add({
        'studentId': user?.uid,
        'name': _nameController.text.trim(),
        'test': _testController.text.trim(),
        'feedbackType': _feedbackType,
        'rating': _rating,
        'message': _messageController.text.trim(),
        'isUrgent': _isUrgent,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'status': 'pending',
      });

      if (mounted) {
        _successController.forward();
        HapticFeedback.heavyImpact();

        _showSuccessDialog();

        // Clear form
        _nameController.clear();
        _testController.clear();
        _messageController.clear();
        setState(() {
          _rating = 5;
          _feedbackType = 'General';
          _isUrgent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnhancedSuccessDialog(
        onClose: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to send feedback. Please try again.',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _submit,
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
              Color(0xFF0F172A),
              Color(0xFF1E293B),
              Color(0xFF334155),
              Color(0xFF1E293B),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles background
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: ParticlesPainter(_particleAnimation.value),
                );
              },
            ),

            // Loading overlay
            if (_isSending)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF667EEA),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sending your feedback...',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Enhanced Header
                          AnimatedBuilder(
                            animation: _headerController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _headerFadeAnimation,
                                child: Transform.scale(
                                  scale: _headerScaleAnimation.value + (_pulseController.value * 0.02),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    margin: const EdgeInsets.only(bottom: 32),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF1E293B).withOpacity(0.9),
                                          const Color(0xFF334155).withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: const Color(0xFF667EEA).withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF667EEA).withOpacity(0.2),
                                          blurRadius: 25,
                                          offset: const Offset(0, 10),
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        EnhancedBackButton(
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              Text(
                                                'Feedback Hub',
                                                style: GoogleFonts.inter(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: -0.5,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Share your thoughts & help us improve',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: const Color(0xFF94A3B8),
                                                  fontWeight: FontWeight.w400,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 60),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Enhanced Form
                          FadeTransition(
                            opacity: _formFadeAnimation,
                            child: SlideTransition(
                              position: _formSlideAnimation,
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF1E293B).withOpacity(0.95),
                                      const Color(0xFF334155).withOpacity(0.9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF475569).withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667EEA).withOpacity(0.15),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: EnhancedTextField(
                                              controller: _nameController,
                                              label: 'Your Name',
                                              icon: Icons.person_outline_rounded,
                                              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your name' : null,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: EnhancedTextField(
                                              controller: _testController,
                                              label: 'Test/Subject (Optional)',
                                              icon: Icons.subject_rounded,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 24),

                                      // Feedback Type Selector
                                      Text(
                                        'Feedback Category',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      FeedbackTypeSelector(
                                        selectedType: _feedbackType,
                                        types: _feedbackTypes,
                                        onTypeSelected: (type) => setState(() => _feedbackType = type),
                                      ),

                                      const SizedBox(height: 24),

                                      // Rating Section
                                      Text(
                                        'Overall Rating',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      EnhancedRatingStars(
                                        rating: _rating,
                                        onRatingChanged: (value) => setState(() => _rating = value),
                                      ),

                                      const SizedBox(height: 24),

                                      EnhancedTextField(
                                        controller: _messageController,
                                        label: 'Your Message',
                                        icon: Icons.message_outlined,
                                        maxLines: 4,
                                        validator: (v) => v == null || v.trim().isEmpty ? 'Please share your feedback' : null,
                                      ),

                                      const SizedBox(height: 20),

                                      // Urgent checkbox
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF475569).withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: _isUrgent,
                                              onChanged: (value) => setState(() => _isUrgent = value ?? false),
                                              activeColor: const Color(0xFFDC2626),
                                              checkColor: Colors.white,
                                            ),
                                            const SizedBox(width: 12),
                                            Icon(
                                              Icons.priority_high_rounded,
                                              color: _isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Mark as urgent (requires immediate attention)',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  color: _isUrgent ? Colors.white : const Color(0xFF94A3B8),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 32),

                                      Center(
                                        child: EnhancedSubmitButton(
                                          text: _isSending ? 'Sending...' : 'Send Feedback',
                                          isLoading: _isSending,
                                          onPressed: _isSending ? null : _submit,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          Text(
                            'Developed By Brolytics Technologies',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
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

// Enhanced Components

class EnhancedBackButton extends StatefulWidget {
  final VoidCallback onPressed;

  const EnhancedBackButton({super.key, required this.onPressed});

  @override
  State<EnhancedBackButton> createState() => _EnhancedBackButtonState();
}

class _EnhancedBackButtonState extends State<EnhancedBackButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}

class EnhancedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const EnhancedTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF334155).withOpacity(_isFocused ? 1.0 : 0.8),
            const Color(0xFF475569).withOpacity(_isFocused ? 0.9 : 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? const Color(0xFF667EEA) : const Color(0xFF64748B).withOpacity(0.3),
          width: _isFocused ? 2.0 : 1.5,
        ),
        boxShadow: [
          if (_isFocused)
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Focus(
        onFocusChange: (focused) => setState(() => _isFocused = focused),
        child: TextFormField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused ? const Color(0xFF667EEA) : const Color(0xFF94A3B8),
              size: 20,
            ),
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              color: _isFocused ? const Color(0xFF667EEA) : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
          validator: widget.validator,
        ),
      ),
    );
  }
}

class FeedbackTypeSelector extends StatelessWidget {
  final String selectedType;
  final List<String> types;
  final ValueChanged<String> onTypeSelected;

  const FeedbackTypeSelector({
    super.key,
    required this.selectedType,
    required this.types,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: types.map((type) {
        final isSelected = type == selectedType;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onTypeSelected(type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isSelected ? null : const Color(0xFF475569).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF667EEA) : const Color(0xFF64748B),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
                  : null,
            ),
            child: Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class EnhancedRatingStars extends StatefulWidget {
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const EnhancedRatingStars({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  State<EnhancedRatingStars> createState() => _EnhancedRatingStarsState();
}

class _EnhancedRatingStarsState extends State<EnhancedRatingStars> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _rotationAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      5,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );
    _scaleAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();
    _rotationAnimations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 0.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onStarTap(int index) {
    HapticFeedback.mediumImpact();
    widget.onRatingChanged(index + 1);
    _controllers[index].forward().then((_) => _controllers[index].reverse());
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    Row(
    children: [
    ...List.generate(5, (index) {
      return GestureDetector(
        onTap: () => _onStarTap(index),
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimations[index], _rotationAnimations[index]]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimations[index].value,
              child: Transform.rotate(
                angle: _rotationAnimations[index].value,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    index < widget.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 32,
                  ),
                ),
              ),
            );
          },
        ),
      );
    }),
      const SizedBox(width: 16),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(widget.rating),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667EEA).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _getRatingText(widget.rating),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ],
    ),
          const SizedBox(height: 8),
          Text(
            'Tap stars to rate your experience',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
    );
  }
}

class EnhancedSubmitButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const EnhancedSubmitButton({
    super.key,
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<EnhancedSubmitButton> createState() => _EnhancedSubmitButtonState();
}

class _EnhancedSubmitButtonState extends State<EnhancedSubmitButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.6).animate(
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
          if (widget.onPressed != null) widget.onPressed!();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 240,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: widget.onPressed != null
                      ? const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : LinearGradient(
                    colors: [
                      const Color(0xFF64748B).withOpacity(0.5),
                      const Color(0xFF475569).withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.onPressed != null
                        ? const Color(0xFF667EEA).withOpacity(0.5)
                        : const Color(0xFF64748B).withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (widget.onPressed != null)
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(_glowAnimation.value),
                        blurRadius: _isPressed ? 12 : 20,
                        offset: Offset(0, _isPressed ? 4 : 8),
                        spreadRadius: _isPressed ? 1 : 3,
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    const SizedBox(width: 12),
                    Text(
                      widget.text,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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

class EnhancedSuccessDialog extends StatefulWidget {
  final VoidCallback onClose;

  const EnhancedSuccessDialog({super.key, required this.onClose});

  @override
  State<EnhancedSuccessDialog> createState() => _EnhancedSuccessDialogState();
}

class _EnhancedSuccessDialogState extends State<EnhancedSuccessDialog> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _checkController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeOutBack),
    );

    _scaleController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _checkController.forward();
      _confettiController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _checkController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF334155),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _checkAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _checkAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF047857)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Feedback Sent!',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Thank you for your valuable feedback.\nWe\'ll review it and get back to you soon!',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  EnhancedSubmitButton(
                    text: 'Close',
                    isLoading: false,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF667EEA).withOpacity(0.1)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 50; i++) {
      final x = (size.width / 50) * i + (animationValue * 20) % size.width;
      final y = (size.height / 3) + (i % 3) * (size.height / 3) +
          (animationValue * 30 * (i % 2 == 0 ? 1 : -1)) % (size.height / 3);

      canvas.drawCircle(
        Offset(x, y),
        2.0 + (animationValue * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}