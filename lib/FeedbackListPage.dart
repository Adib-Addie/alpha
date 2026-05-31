import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:flutter/services.dart';

class FeedbackListPage extends StatefulWidget {
  const FeedbackListPage({Key? key}) : super(key: key);

  @override
  State<FeedbackListPage> createState() => _FeedbackListPageState();
}

class _FeedbackListPageState extends State<FeedbackListPage> {
  bool _isLoading = false;
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Unread', 'Read', 'Urgent', 'General', 'Bug Report', 'Feature Request'];

  final List<List<Color>> cardGradients = [
    [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
    [const Color(0xFF10B981), const Color(0xFF059669)],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
    [const Color(0xFF7B2FBE), const Color(0xFFA855F7)],
    [const Color(0xFFEF4444), const Color(0xFFDC2626)],
  ];

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
            const Icon(Icons.check_circle_rounded, color: AppTheme.textPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
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
            const Icon(Icons.error_outline_rounded, color: AppTheme.textPrimary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
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
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundMid,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF7B2FBE).withOpacity(0.3),
                          width: 1.5,
                        ),
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
                            'Processing...',
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
                    constraints: BoxConstraints(
                      maxWidth: 1200,
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
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
                                        'Feedback Dashboard',
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
                                        'View and manage student feedback submissions',
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

                          // Filter Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.backgroundMid.withOpacity(0.9),
                                  AppTheme.backgroundEnd.withOpacity(0.8),
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
                                  color: const Color(0xFF7B2FBE).withOpacity(0.1),
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
                                    color: AppTheme.textPrimary,
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
                                          filter,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                            color: isSelected ? Colors.white : AppTheme.textSecondary,
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

                              return Column(
                                children: [
                                  // Stats Row
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    margin: const EdgeInsets.only(bottom: 24),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.backgroundMid.withOpacity(0.9),
                                          AppTheme.backgroundEnd.withOpacity(0.8),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.divider.withOpacity(0.4),
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
                                            const Color(0xFF7B2FBE),
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
                                            color: AppTheme.textPrimary,
                                            size: 32,
                                          ),
                                        ),
                                        confirmDismiss: (direction) async {
                                          await _deleteFeedback(doc.id);
                                          return false;
                                        },
                                        child: EnhancedFeedbackCard(
                                          data: data,
                                          docId: doc.id,
                                          index: index,
                                          gradient: gradient,
                                          onTap: () => _showDetails(data, doc.id),
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
                              'Developed by Brolytics Technologies',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textMuted,
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
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
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

class _EnhancedFeedbackCardState extends State<EnhancedFeedbackCard> {
  bool _isHovered = false;

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
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
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
              // Avatar
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
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
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
                              color: AppTheme.textPrimary,
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
                                    color: AppTheme.textPrimary,
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
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (timeAgo.isNotEmpty)
                          Text(
                            timeAgo,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textMuted,
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
                        color: AppTheme.textSecondary,
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
                            color: AppTheme.border.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            feedbackType,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
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

class EnhancedFeedbackDialog extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Anonymous';
    final test = data['test'] ?? '';
    final rating = data['rating'] ?? 0;
    final message = data['message'] ?? '';
    final isUrgent = data['isUrgent'] == true;
    final feedbackType = data['feedbackType'] ?? 'General';
    final status = data['status'] ?? 'Pending';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 500,
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
            color: const Color(0xFF7B2FBE).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B2FBE).withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
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
                          color: AppTheme.textPrimary,
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
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (date.isNotEmpty)
                          Text(
                            date,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textPrimary.withOpacity(0.8),
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
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Content
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
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      test,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
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
                          color: AppTheme.textSecondary,
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
                          color: AppTheme.textPrimary,
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
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.border.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      feedbackType,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Message',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.divider.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.textMuted.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
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
                          color: AppTheme.textSecondary,
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
            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundStart,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text(
                      'Close',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          onMarkAsRead();
                          onClose();
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
                          onUpdateStatus(value);
                          onClose();
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
                            backgroundColor: const Color(0xFF7B2FBE),
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
    );
  }
}

class EnhancedDeleteDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const EnhancedDeleteDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.backgroundStart,
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
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to delete this feedback? This action cannot be undone.',
        style: GoogleFonts.inter(
          fontSize: 16,
          color: AppTheme.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onConfirm,
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
    );
  }
}

class EnhancedLoadingWidget extends StatelessWidget {
  const EnhancedLoadingWidget({Key? key}) : super(key: key);

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
              gradient: const LinearGradient(
                colors: [AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7B2FBE).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppTheme.textPrimary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading Feedback...',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we fetch the latest feedback',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

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
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Error: $error',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

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
                  const Color(0xFF7B2FBE).withOpacity(0.2),
                  AppTheme.backgroundEnd.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.feedback_rounded,
              size: 60,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
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
                backgroundColor: const Color(0xFF7B2FBE),
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
