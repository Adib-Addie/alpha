import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class RegisterStudentPage extends StatefulWidget {
  const RegisterStudentPage({Key? key}) : super(key: key);

  @override
  _RegisterStudentPageState createState() => _RegisterStudentPageState();
}

class _RegisterStudentPageState extends State<RegisterStudentPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _admissionNumberController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _batchTimingController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _teacherPasswordController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureTeacherPassword = true;
  late AnimationController _mainAnimationController;
  late AnimationController _headerController;
  late AnimationController _backgroundController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOutBack),
    );
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    _mainAnimationController.forward();
    _headerController.repeat(reverse: true);
    _backgroundController.repeat();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _courseNameController.dispose();
    _admissionNumberController.dispose();
    _fatherNameController.dispose();
    _batchController.dispose();
    _batchTimingController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _teacherPasswordController.dispose();
    _mainAnimationController.dispose();
    _headerController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

// Also update your image picker to include compression
  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Limit image dimensions
        maxHeight: 800,
        imageQuality: 85, // Compress to 85% quality
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // Validate file size
        final sizeInBytes = await imageFile.length();
        if (sizeInBytes > 5 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'Image size must be less than 5MB';
          });
          return;
        }

        // Validate file type
        final extension = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          setState(() {
            _errorMessage = 'Only JPG, JPEG, or PNG images are allowed';
          });
          return;
        }

        setState(() {
          _profileImage = imageFile;
          _errorMessage = null;
        });

        // image selected successfully
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

// Updated _uploadProfilePicture function with better folder structure
  Future<String?> _uploadProfilePicture(String studentId) async {
    if (_profileImage == null) return null;

    try {
      // Create a timestamp for unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_${studentId}_$timestamp.jpg';

      // Use a cleaner folder structure: profile_pictures/studentId.jpg
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);

      // Set metadata for better handling
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'studentId': studentId,
          'uploadedAt': DateTime.now().toIso8601String(),
          'type': 'profile_picture',
        },
        cacheControl: 'public, max-age=31536000', // Cache for 1 year
      );

      // Upload the file with metadata
      final uploadTask = storageRef.putFile(_profileImage!, metadata);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }

    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload profile picture: ${e.message}';
      });
      return null;
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to upload profile picture: $e';
      });
      return null;
    }
  }
  Future<bool> _isAdmissionNumberUnique(String admissionNumber) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('students')
        .where('admissionNumber', isEqualTo: admissionNumber.trim())
        .get();
    return querySnapshot.docs.isEmpty;
  }

  Future<void> _registerStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final isUnique = await _isAdmissionNumberUnique(_admissionNumberController.text.trim());
      if (!isUnique) {
        setState(() {
          _errorMessage = 'Admission Number already exists';
          _isLoading = false;
        });
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Teacher not logged in. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      // 1. Create new Student User
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final studentUser = userCredential.user;
      if (studentUser == null) {
        setState(() {
          _errorMessage = 'Failed to create student account.';
          _isLoading = false;
        });
        return;
      }

      // 2. Upload profile picture
      String? profilePictureUrl = await _uploadProfilePicture(studentUser.uid);

      // 3. Sign-out Student, Sign back in as Teacher
      await FirebaseAuth.instance.signOut();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: currentUser.email!,
        password: _teacherPasswordController.text.trim(),
      );

      // 4. Save Student Details to Firestore
      final studentRef = FirebaseFirestore.instance.collection('students').doc(studentUser.uid);
      await studentRef.set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'courseName': _courseNameController.text.trim(),
        'admissionNumber': _admissionNumberController.text.trim(),
        'fatherName': _fatherNameController.text.trim(),
        'batch': _batchController.text.trim(),
        'batchTiming': _batchTimingController.text.trim(),
        'address': _addressController.text.trim(),
        'profilePictureUrl': profilePictureUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser.uid,
        'lastLogin': null,
      });

      setState(() {
        _errorMessage = 'Student created successfully!';
        _isLoading = false;
      });

      // Clear form fields
      _nameController.clear();
      _emailController.clear();
      _courseNameController.clear();
      _admissionNumberController.clear();
      _fatherNameController.clear();
      _batchController.clear();
      _batchTimingController.clear();
      _addressController.clear();
      _passwordController.clear();
      _teacherPasswordController.clear();
      _profileImage = null;

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Failed to create student: ${e.message}';
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Firestore/Storage error: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
              const Color(0xFF334155),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _backgroundAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F172A).withOpacity(0.9),
                    const Color(0xFF1E293B).withOpacity(0.8),
                    const Color(0xFF334155).withOpacity(0.9),
                  ],
                  stops: [
                    0.0,
                    0.5 + (_backgroundAnimation.value * 0.2),
                    1.0,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      _buildSidebar(),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildMainContent(),
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

  Widget _buildSidebar() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _mainAnimationController,
        curve: Curves.easeOutCubic,
      )),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF475569).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: AnimatedBuilder(
                animation: _headerController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_headerController.value * 0.05),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF667EEA),
                            Color(0xFF764BA2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Register',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Text(
                    'New Student',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              color: Color(0xFF475569),
              thickness: 0.5,
              height: 1,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF475569).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: const Color(0xFF667EEA),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Back to Dashboard',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
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

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF475569).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Register New Student',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a new student to the system',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF667EEA),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: _profileImage != null
                          ? DecorationImage(
                        image: FileImage(_profileImage!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: _profileImage == null
                        ? const Icon(
                      Icons.person_rounded,
                      size: 50,
                      color: Color(0xFF94A3B8),
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                ModernButton(
                  text: 'Choose Profile Picture',
                  onPressed: _pickImage,
                  gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
                  icon: Icons.camera_alt_rounded,
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _errorMessage!.contains('successfully')
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE53E3E),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _errorMessage!.contains('successfully')
                            ? const Color(0xFF10B981)
                            : const Color(0xFFE53E3E),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),
                ModernTextField(
                  controller: _nameController,
                  label: 'Student Name',
                  icon: Icons.person_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 2 || value.trim().length > 100) {
                      return 'Name must be between 2 and 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ModernTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ModernTextField(
                  controller: _courseNameController,
                  label: 'Course Name',
                  icon: Icons.book_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Course name is required';
                    }
                    if (value.trim().length > 100) {
                      return 'Course name must not exceed 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ModernTextField(
                  controller: _admissionNumberController,
                  label: 'Admission Number',
                  icon: Icons.confirmation_number_rounded,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Admission Number is required';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
                      return 'Admission Number must be alphanumeric';
                    }
                    if (value.trim().length > 20) {
                      return 'Admission Number must not exceed 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ModernTextField(
                  controller: _fatherNameController,
                  label: 'Father\'s Name',
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Father\'s name is required';
                    }
                    if (value.trim().length < 2 || value.trim().length > 100) {
                      return 'Father\'s name must be between 2 and 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ModernTextField(
                  controller: _batchController,
                  label: 'Batch',
                  icon: Icons.group_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Batch is required';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9\s-]+$').hasMatch(value.trim())) {
                      return 'Batch must be alphanumeric with spaces or hyphens';
                    }
                    if (value.trim().length > 50) {
                      return 'Batch must not exceed 50 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ModernTextField(
                  controller: _batchTimingController,
                  label: 'Batch Timing',
                  icon: Icons.schedule_rounded,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Batch Timing is required';
                    }
                    if (value.trim().length > 100) {
                      return 'Batch Timing must not exceed 100 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ModernTextField(
                  controller: _addressController,
                  label: 'Address',
                  icon: Icons.location_on_rounded,
                  keyboardType: TextInputType.streetAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address is required';
                    }
                    if (value.trim().length > 500) {
                      return 'Address must not exceed 500 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ModernTextField(
                  controller: _passwordController,
                  label: 'Student Password',
                  icon: Icons.lock_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: const Color(0xFF94A3B8),
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Password is required';
                    }
                    if (value.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                ModernTextField(
                  controller: _teacherPasswordController,
                  label: 'Teacher Password',
                  icon: Icons.lock_rounded,
                  obscureText: _obscureTeacherPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureTeacherPassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: const Color(0xFF94A3B8),
                    ),
                    onPressed: () => setState(() => _obscureTeacherPassword = !_obscureTeacherPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Teacher password is required';
                    }
                    if (value.trim().length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ModernButton(
                  text: 'Register Student',
                  onPressed: _isLoading ? () {} : _registerStudent,
                  gradient: const [Color(0xFFFC466B), Color(0xFF3F5EFB)],
                  icon: Icons.person_add_rounded,
                ),
                const SizedBox(height: 24),
                Text(
                  'Developed By Brolytics Technologies',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const ModernTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  }) : super(key: key);

  @override
  _ModernTextFieldState createState() => _ModernTextFieldState();
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
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
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
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: GoogleFonts.inter(
              color: _isFocused ? const Color(0xFF667EEA) : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _isFocused ? const Color(0xFF6677EA) : const Color(0xFF94A3B8),
            ),
            suffixIcon: widget.suffixIcon,
            filled: true,
            fillColor: const Color(0xFF334155).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: _borderAnimation.value!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: const Color(0xFF475569).withOpacity(0.3), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    Key? key,
    required this.text,
    required this.onPressed,
    required this.gradient,
    required this.icon,
  }) : super(key: key);

  @override
  _ModernButtonState createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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
      onEnter: (_) => setState(() {
        _isHovered = true;
        _controller.forward();
      }),
      onExit: (_) => setState(() {
        _isHovered = false;
        _controller.reverse();
      }),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.first.withOpacity(_isHovered ? 0.3 : 0.1),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 20,
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