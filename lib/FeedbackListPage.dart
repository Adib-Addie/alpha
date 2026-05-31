import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'dart:math';
import 'package:flutter/services.dart';

class FeedbackListPage extends StatefulWidget {
  const FeedbackListPage({Key? key}) : super(key: key);

  @override
  State<FeedbackListPage> createState() => _FeedbackListPageState();
}

class _FeedbackListPageState extends State<FeedbackListPage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _particleAnimation;
  late List<AnimationController> _cardControllers;
  late List<Animation<double>> _cardFadeAnimations;
  late List<Animation<Offset>> _cardSlideAnimations;

  bool _isLoading = false;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Unread', 'Read', 'Urgent', 'General', 'Bug Report', 'Feature Request'];

  final List<List<Color>> cardGradients = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    [const Color(0xFF10B981), const Color(0xFF059669)],
    [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
    [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
    [const Color(0xFF8B5CF6), const Color(0xFFA855F7)],
    [const Color(0xFFEF4444), const Color(0xFFDC2626)],
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
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuart),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );

    _headerController.forward();
    _pulseController.repeat(reverse: true);
    _particleController.repeat();

    _cardControllers = [];
    _cardFadeAnimations = [];
    _cardSlideAnimations = [];
  }

  @override
  void dispose() {
    _headerController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
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
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
      );

      _cardControllers.add(controller);
      _cardFadeAnimations.add(fadeAnimation);
      _cardSlideAnimations.add(slideAnimation);

      Future.delayed(Duration(milliseconds: i * 100), () {
        if (mounted) controller.forward();
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance.collection('feedback').doc(id).update({'read': true});
      _showSuccessSnackBar('Feedback marked as read successfully!');
    } catch (e) {
      _showErrorSnackBar('Error marking feedback as read: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance.collection('feedback').doc(id).update({'status': status});
      _showSuccessSnackBar('Status updated to $status');
    } catch (e) {
      _showErrorSnackBar('Error updating status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _showDetails(Map<String, dynamic> data, String docId) async {
    HapticFeedback.lightImpact();
    await showModal(
      context: context,
      configuration: const FadeScaleTransitionConfiguration(
        transitionDuration: Duration(milliseconds: 400),
        reverseTransitionDuration: Duration(milliseconds: 300),
      ),
      builder: (context) {
        final ts = (data['createdAt'] as Timestamp?)?.toDate();
        final date = ts != null
            ? '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
            : '';
        return EnhancedFeedbackDialog(
          data: data,
          date: date,
          docId: docId,
          onClose: () => Navigator.pop(context),
          onMarkAsRead: () => _markAsRead(docId),
          onUpdateStatus: (status) => _updateStatus(docId, status),
        );
      },
    );
  }

  Future<void> _deleteFeedback(String docId) async {
    HapticFeedback.mediumImpact();
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => EnhancedDeleteDialog(
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await FirebaseFirestore.instance.collection('feedback').doc(docId).delete();
        _showSuccessSnackBar('Feedback deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Error deleting feedback: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  List<QueryDocumentSnapshot> _filterFeedbacks(List<QueryDocumentSnapshot> docs) {
    switch (_selectedFilter) {
      case 'Unread':
        return docs.where((doc) => !(doc.data() as Map<String, dynamic>)['read']).toList();
      case 'Read':
        return docs.where((doc) => (doc.data() as Map<String, dynamic>)['read'] == true).toList();
      case 'Urgent':
        return docs.where((doc) => (doc.data() as Map<String, dynamic>)['isUrgent'] == true).toList();
      default:
        if (_selectedFilter == 'All') return docs;
        return docs.where((doc) => (doc.data() as Map<String, dynamic>)['feedbackType'] == _selectedFilter).toList();
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
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          width: 1.5,
                        ),
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
                            'Processing...',
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
                    constraints: BoxConstraints(
                      maxWidth: 1200,
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                    width: double.infinity,
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
                                                'Feedback Dashboard',
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
                                                'View and manage student feedback submissions',
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

                          // Filter Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1E293B).withOpacity(0.9),
                                  const Color(0xFF334155).withOpacity(0.8),
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
                                  color: const Color(0xFF667EEA).withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filter Feedback',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: _filterOptions.map((filter) {
                                    final isSelected = filter == _selectedFilter;
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() => _selectedFilter = filter);
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
                                          filter,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          // Feedback List
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('feedback')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return EnhancedErrorWidget(error: snapshot.error.toString());
                              }

                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const EnhancedLoadingWidget();
                              }

                              final allDocs = snapshot.data!.docs;
                              final filteredDocs = _filterFeedbacks(allDocs);

                              if (filteredDocs.isEmpty) {
                                return EnhancedEmptyWidget(
                                  title: _selectedFilter == 'All' ? 'No Feedback Available' : 'No $_selectedFilter Feedback',
                                  subtitle: _selectedFilter == 'All'
                                      ? 'No student feedback has been submitted yet'
                                      : 'No feedback matches the selected filter',
                                  onRefresh: () => setState(() {}),
                                );
                              }

                              _initializeCardAnimations(filteredDocs.length);

                              return Column(
                                children: [
                                  // Stats Row
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    margin: const EdgeInsets.only(bottom: 24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF1E293B).withOpacity(0.9),
                                          const Color(0xFF334155).withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF475569).withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _buildStatCard(
                                            'Total',
                                            allDocs.length.toString(),
                                            Icons.feedback_rounded,
                                            const Color(0xFF667EEA),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildStatCard(
                                            'Unread',
                                            allDocs.where((doc) => !(doc.data() as Map<String, dynamic>)['read']).length.toString(),
                                            Icons.mark_email_unread_rounded,
                                            const Color(0xFFF59E0B),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildStatCard(
                                            'Urgent',
                                            allDocs.where((doc) => (doc.data() as Map<String, dynamic>)['isUrgent'] == true).length.toString(),
                                            Icons.priority_high_rounded,
                                            const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Feedback Cards
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: filteredDocs.length,
                                    itemBuilder: (context, index) {
                                      final doc = filteredDocs[index];
                                      final data = doc.data() as Map<String, dynamic>;
                                      final gradient = cardGradients[index % cardGradients.length];

                                      return Dismissible(
                                        key: Key(doc.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(right: 20),
                                          margin: const EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.delete_rounded,
                                            color: Colors.white,
                                            size: 32,
                                          ),
                                        ),
                                        confirmDismiss: (direction) async {
                                          await _deleteFeedback(doc.id);
                                          return false;
                                        },
                                        child: FadeTransition(
                                          opacity: _cardFadeAnimations[index],
                                          child: SlideTransition(
                                            position: _cardSlideAnimations[index],
                                            child: EnhancedFeedbackCard(
                                              data: data,
                                              docId: doc.id,
                                              index: index,
                                              gradient: gradient,
                                              onTap: () => _showDetails(data, doc.id),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Footer
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Developed By Brolytics Technologies',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
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

class EnhancedFeedbackCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final int index;
  final List<Color> gradient;
  final VoidCallback onTap;

  const EnhancedFeedbackCard({
    Key? key,
    required this.data,
    required this.docId,
    required this.index,
    required this.gradient,
    required this.onTap,
  }) : super(key: key);

  @override
  State<EnhancedFeedbackCard> createState() => _EnhancedFeedbackCardState();
}

class _EnhancedFeedbackCardState extends State<EnhancedFeedbackCard> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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
    final name = widget.data['name'] ?? 'Anonymous';
    final test = widget.data['test'] ?? '';
    final rating = widget.data['rating'] ?? 0;
    final msg = widget.data['message'] ?? '';
    final read = widget.data['read'] == true;
    final isUrgent = widget.data['isUrgent'] == true;
    final feedbackType = widget.data['feedbackType'] ?? 'General';
    final status = widget.data['status'] ?? 'Pending';

    final ts = (widget.data['createdAt'] as Timestamp?)?.toDate();
    final timeAgo = ts != null ? _getTimeAgo(ts) : '';

    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
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
                    color: widget.gradient.first.withOpacity(_isHovered ? 0.6 : 0.3),
                    width: _isHovered ? 2.0 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.first.withOpacity(_isHovered ? 0.4 : 0.2),
                      blurRadius: _isHovered ? 25 : 15,
                      offset: Offset(0, _isHovered ? 10 : 6),
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Enhanced Avatar
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: widget.gradient.first.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: AnimatedScale(
                        scale: _isHovered ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Enhanced Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  if (isUrgent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'URGENT',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  if (!read)
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: widget.gradient,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.gradient.first.withOpacity(0.6),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (test.isNotEmpty)
                                Expanded(
                                  child: Text(
                                    test,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: widget.gradient.first,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getStatusColor(status).withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _getStatusColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ...List.generate(
                                5,
                                    (i) => Icon(
                                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 18,
                                  color: Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '($rating/5)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const Spacer(),
                              if (timeAgo.isNotEmpty)
                                Text(
                                  timeAgo,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            msg.length > 80 ? '${msg.substring(0, 80)}...' : msg,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF475569).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  feedbackType,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Enhanced Arrow
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.gradient.first.withOpacity(0.2),
                            widget.gradient.last.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.gradient.first.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: AnimatedRotation(
                        turns: _isHovered ? 0.0 : -0.125,
                        duration: const Duration(milliseconds: 300),
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
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF10B981);
      case 'in progress':
        return const Color(0xFFF59E0B);
      case 'urgent':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// Enhanced Feedback Dialog
class EnhancedFeedbackDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final String date;
  final String docId;
  final VoidCallback onClose;
  final VoidCallback onMarkAsRead;
  final Function(String) onUpdateStatus;

  const EnhancedFeedbackDialog({
    Key? key,
    required this.data,
    required this.date,
    required this.docId,
    required this.onClose,
    required this.onMarkAsRead,
    required this.onUpdateStatus,
  }) : super(key: key);

  @override
  State<EnhancedFeedbackDialog> createState() => _EnhancedFeedbackDialogState();
}

class _EnhancedFeedbackDialogState extends State<EnhancedFeedbackDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] ?? 'Anonymous';
    final test = widget.data['test'] ?? '';
    final rating = widget.data['rating'] ?? 0;
    final message = widget.data['message'] ?? '';
    final isUrgent = widget.data['isUrgent'] == true;
    final feedbackType = widget.data['feedbackType'] ?? 'General';
    final status = widget.data['status'] ?? 'Pending';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Transform.scale(
          scale: _scaleAnimation.value,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.transparent,
            child: Container(
              width: 500,
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
                  color: const Color(0xFF667EEA).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Enhanced Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              if (widget.date.isNotEmpty)
                                Text(
                                  widget.date,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isUrgent)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'URGENT',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Enhanced Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (test.isNotEmpty) ...[
                          Text(
                            'Test/Subject',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            test,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
                            Text(
                              'Rating',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: List.generate(
                                5,
                                    (i) => Icon(
                                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                  size: 24,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($rating/5)',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Feedback Type',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF475569).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            feedbackType,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Message',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF475569).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF64748B).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            message,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Text(
                              'Status',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(status).withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Enhanced Actions
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: Text(
                            'Close',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF94A3B8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                widget.onMarkAsRead();
                                widget.onClose();
                              },
                              icon: const Icon(Icons.check_circle_rounded, size: 18),
                              label: Text(
                                'Mark as Read',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                widget.onUpdateStatus(value);
                                widget.onClose();
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'Pending', child: Text('Pending')),
                                const PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
                                const PopupMenuItem(value: 'Resolved', child: Text('Resolved')),
                              ],
                              child: ElevatedButton.icon(
                                onPressed: null,
                                icon: const Icon(Icons.update_rounded, size: 18),
                                label: Text(
                                  'Update Status',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF667EEA),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return const Color(0xFF10B981);
      case 'in progress':
        return const Color(0xFFF59E0B);
      case 'urgent':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }
}

// Enhanced Delete Dialog
class EnhancedDeleteDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const EnhancedDeleteDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<EnhancedDeleteDialog> createState() => _EnhancedDeleteDialogState();
}

class _EnhancedDeleteDialogState extends State<EnhancedDeleteDialog>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFF1E293B),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFDC2626),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Delete Feedback',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete this feedback? This action cannot be undone.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: const Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: widget.onCancel,
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: widget.onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Loading Widget
class EnhancedLoadingWidget extends StatefulWidget {
  const EnhancedLoadingWidget({Key? key}) : super(key: key);

  @override
  State<EnhancedLoadingWidget> createState() => _EnhancedLoadingWidgetState();
}

class _EnhancedLoadingWidgetState extends State<EnhancedLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Feedback...',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch the latest feedback',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Error Widget
class EnhancedErrorWidget extends StatelessWidget {
  final String error;

  const EnhancedErrorWidget({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFDC2626).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Color(0xFFDC2626),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Error: $error',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Trigger a rebuild by calling setState on parent
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(
              'Try Again',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Enhanced Empty Widget
class EnhancedEmptyWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;

  const EnhancedEmptyWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667EEA).withOpacity(0.2),
                  const Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.feedback_rounded,
              size: 60,
              color: const Color(0xFF94A3B8).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Refresh',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Particles Painter for Background Animation
class ParticlesPainter extends CustomPainter {
  final double animationValue;

  ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF667EEA).withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final particles = 50;
    for (int i = 0; i < particles; i++) {
      final x = (size.width * (i * 0.618034) % 1);
      final y = (size.height * (i * 0.314159) % 1);
      final offset = Offset(
        x + (20 * sin(animationValue * 2 + i * 0.1)),
        y + (20 * cos(animationValue * 1.5 + i * 0.2)),
      );

      canvas.drawCircle(
        offset,
        2 + (sin(animationValue * 3 + i * 0.3) * 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}