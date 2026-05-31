import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Enhanced feedback screen with better design
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _testController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  int _rating = 5;
  String _feedbackType = 'General';
  bool _isSending = false;
  bool _isUrgent = false;

  final List<String> _feedbackTypes = [
    'General', 'Bug Report', 'Feature Request', 'UI/UX Issue',
    'Performance', 'Content Issue', 'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _testController.dispose();
    _messageController.dispose();
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
        HapticFeedback.heavyImpact();
        _showSuccessDialog();

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
              AppTheme.backgroundStart,
              AppTheme.backgroundMid,
              AppTheme.backgroundEnd,
              AppTheme.backgroundMid,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Loading overlay
            if (_isSending)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundMid,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B2FBE).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF7B2FBE),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sending your feedback...',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.textPrimary,
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
                          // Header
                          Container(
                            padding: const EdgeInsets.all(24),
                            margin: const EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.backgroundMid.withOpacity(0.9),
                                  AppTheme.backgroundEnd.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF7B2FBE).withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B2FBE).withOpacity(0.2),
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
                                          color: AppTheme.textPrimary,
                                          letterSpacing: -0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Share your thoughts & help us improve',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
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

                          // Form
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.backgroundMid.withOpacity(0.95),
                                  AppTheme.backgroundEnd.withOpacity(0.9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.divider.withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7B2FBE).withOpacity(0.15),
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

                                  Text(
                                    'Feedback Category',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  FeedbackTypeSelector(
                                    selectedType: _feedbackType,
                                    types: _feedbackTypes,
                                    onTypeSelected: (type) => setState(() => _feedbackType = type),
                                  ),

                                  const SizedBox(height: 24),

                                  Text(
                                    'Overall Rating',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
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
                                      color: AppTheme.border.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isUrgent ? const Color(0xFFDC2626) : AppTheme.textMuted,
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
                                          color: _isUrgent ? const Color(0xFFDC2626) : AppTheme.textMuted,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Mark as urgent (requires immediate attention)',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: _isUrgent ? Colors.white : AppTheme.textSecondary,
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

                          const SizedBox(height: 32),

                          Text(
                            'Developed by Brolytics Technologies',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.textMuted,
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

class EnhancedBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EnhancedBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2FBE).withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppTheme.textPrimary,
          size: 24,
        ),
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
            AppTheme.backgroundEnd.withOpacity(_isFocused ? 1.0 : 0.8),
            AppTheme.divider.withOpacity(_isFocused ? 0.9 : 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? const Color(0xFF7B2FBE) : AppTheme.textMuted.withOpacity(0.3),
          width: _isFocused ? 2.0 : 1.5,
        ),
        boxShadow: [
          if (_isFocused)
            BoxShadow(
              color: const Color(0xFF7B2FBE).withOpacity(0.2),
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
              color: _isFocused ? const Color(0xFF7B2FBE) : AppTheme.textSecondary,
              size: 20,
            ),
            labelStyle: GoogleFonts.inter(
              fontSize: 14,
              color: _isFocused ? const Color(0xFF7B2FBE) : AppTheme.textSecondary,
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
            color: AppTheme.textPrimary,
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
                colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : null,
              color: isSelected ? null : AppTheme.divider.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF7B2FBE) : AppTheme.textMuted,
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                BoxShadow(
                  color: const Color(0xFF7B2FBE).withOpacity(0.3),
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
                color: isSelected ? Colors.white : AppTheme.textSecondary,
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

class _EnhancedRatingStarsState extends State<EnhancedRatingStars> {
  void _onStarTap(int index) {
    HapticFeedback.mediumImpact();
    widget.onRatingChanged(index + 1);
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
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    index < widget.rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 32,
                  ),
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
                    colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B2FBE).withOpacity(0.3),
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
                    color: AppTheme.textPrimary,
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
            color: AppTheme.textMuted,
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

class _EnhancedSubmitButtonState extends State<EnhancedSubmitButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          if (widget.onPressed != null) widget.onPressed!();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          width: 240,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.onPressed != null
                ? const LinearGradient(
              colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : LinearGradient(
              colors: [
                AppTheme.textMuted.withOpacity(0.5),
                AppTheme.divider.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.onPressed != null
                  ? const Color(0xFF7B2FBE).withOpacity(0.5)
                  : AppTheme.textMuted.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              if (widget.onPressed != null)
                BoxShadow(
                  color: const Color(0xFF7B2FBE).withOpacity(_isPressed ? 0.3 : 0.6),
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
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              const SizedBox(width: 12),
              Text(
                widget.text,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EnhancedSuccessDialog extends StatelessWidget {
  final VoidCallback onClose;

  const EnhancedSuccessDialog({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppTheme.backgroundMid,
              AppTheme.backgroundEnd,
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
            Container(
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
                color: AppTheme.textPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Feedback Sent!',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Thank you for your valuable feedback.\nWe\'ll review it and get back to you soon!',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            EnhancedSubmitButton(
              text: 'Close',
              isLoading: false,
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}
