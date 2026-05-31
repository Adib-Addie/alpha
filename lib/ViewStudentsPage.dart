import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'StudentProfilePage.dart';

class ModernAnimatedCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onPressed;
  final int delay;
  final bool? isLocked;
  final VoidCallback? onLockToggle;
  final String? profilePictureUrl;
  final String? batch;
  final String? batchTiming;

  const ModernAnimatedCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onPressed,
    required this.delay,
    this.isLocked,
    this.onLockToggle,
    this.profilePictureUrl,
    this.batch,
    this.batchTiming,
  }) : super(key: key);

  @override
  _ModernAnimatedCardState createState() => _ModernAnimatedCardState();
}

class _ModernAnimatedCardState extends State<ModernAnimatedCard>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  AnimationController? _hoverController;
  AnimationController? _shimmerController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _hoverAnimation;
  Animation<double>? _shimmerAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeOutBack));
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _hoverController!, curve: Curves.easeInOut),
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController!, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted && _controller != null) _controller!.forward();
    });

    _shimmerController!.repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _hoverController?.dispose();
    _shimmerController?.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _hoverController?.forward();
    } else {
      _hoverController?.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fadeAnimation == null ||
        _slideAnimation == null ||
        _hoverAnimation == null ||
        _shimmerAnimation == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation!,
      child: SlideTransition(
        position: _slideAnimation!,
        child: MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          child: GestureDetector(
            onTap: widget.onPressed,
            child: ScaleTransition(
              scale: _hoverAnimation!,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: Stack(
                  children: [
                    // Main card container
                    IntrinsicHeight(
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          minHeight: 120,
                          maxHeight: 180,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradient.first.withOpacity(
                                _isHovered ? 0.6 : 0.3,
                              ),
                              blurRadius: _isHovered ? 30 : 20,
                              offset: const Offset(0, 10),
                              spreadRadius: _isHovered ? 4 : 2,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Top row with profile and arrow
                            Flexible(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Profile picture with improved handling
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.4),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _buildProfileImage(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Name and email section
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          widget.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.subtitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white.withOpacity(0.85),
                                            letterSpacing: 0.1,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Animated arrow
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(_isHovered ? 0.3 : 0.2),
                                          Colors.white.withOpacity(_isHovered ? 0.1 : 0.05),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(_isHovered ? 0.4 : 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: AnimatedRotation(
                                      turns: _isHovered ? 0.0 : -0.1,
                                      duration: const Duration(milliseconds: 300),
                                      child: Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Batch timing section
                            if (widget.batchTiming != null &&
                                widget.batchTiming!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                constraints: const BoxConstraints(maxWidth: double.infinity),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.15),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.schedule_rounded,
                                        size: 12,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        widget.batchTiming!,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white.withOpacity(0.95),
                                          letterSpacing: 0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Shimmer effect overlay
                    if (_isHovered)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _shimmerAnimation!,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: LinearGradient(
                                  begin: Alignment(-1.0 + _shimmerAnimation!.value, 0.0),
                                  end: Alignment(-0.5 + _shimmerAnimation!.value, 0.0),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty) {
      return Image.network(
        widget.profilePictureUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.7),
                  ),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultProfileIcon();
        },
        // Add cache headers
        headers: {
          'Cache-Control': 'no-cache',
        },
      );
    } else {
      return _buildDefaultProfileIcon();
    }
  }

  Widget _buildDefaultProfileIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        widget.icon,
        size: 24,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }
}

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearchChanged;

  const SearchBarWidget({Key? key, required this.onSearchChanged})
      : super(key: key);

  @override
  _SearchBarWidgetState createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    _pulseController!.repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation!,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0F172A).withOpacity(0.8),
                const Color(0xFF1E293B).withOpacity(0.9),
                const Color(0xFF334155).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: 2,
              color: _isFocused
                  ? Colors.white.withOpacity(0.4)
                  : Colors.white.withOpacity(0.2 + (_pulseAnimation!.value * 0.1)),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF334155).withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 2,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 2,
                spreadRadius: 0,
                offset: const Offset(0, 2),
                blurStyle: BlurStyle.inner,
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
                onTap: () => setState(() => _isFocused = true),
                onTapOutside: (_) => setState(() => _isFocused = false),
                decoration: InputDecoration(
                  hintText: '🔍 Search students by name or batch...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 0.2,
                  ),
                  prefixIcon: Container(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? Container(
                    margin: const EdgeInsets.all(8),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.clear_rounded,
                            color: Colors.white.withOpacity(0.8),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                ),
                onChanged: widget.onSearchChanged,
              ),
            ),
          ),
        );
      },
    );
  }
}

class BatchSection extends StatefulWidget {
  final String batchName;
  final List<Map<String, dynamic>> students;
  final List<List<Color>> gradients;
  final Function(String, String) onDeleteStudent;

  const BatchSection({
    Key? key,
    required this.batchName,
    required this.students,
    required this.gradients,
    required this.onDeleteStudent,
  }) : super(key: key);

  @override
  _BatchSectionState createState() => _BatchSectionState();
}

class _BatchSectionState extends State<BatchSection>
    with TickerProviderStateMixin {
  late AnimationController _expansionController;
  late AnimationController _headerController;
  late Animation<double> _expandAnimation;
  late Animation<double> _headerGlowAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _expansionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );
    _headerGlowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeInOut),
    );
    _expansionController.forward();
    _headerController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expansionController.forward();
      } else {
        _expansionController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E293B).withOpacity(0.8),
              const Color(0xFF334155).withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 12),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 2),
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          GestureDetector(
          onTap: _toggleExpansion,
          child: AnimatedBuilder(
            animation: _headerGlowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667EEA).withOpacity(_headerGlowAnimation.value),
                      const Color(0xFF764BA2).withOpacity(_headerGlowAnimation.value),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667EEA).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.group_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.batchName.isNotEmpty ? widget.batchName : '📚 Unassigned Batch',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.white.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${widget.students.length} student${widget.students.length != 1 ? 's' : ''} 👥',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
                padding: const EdgeInsets.all(24),
                child: // Inside BatchSection's build method, replace the GridView.builder with this:

                LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate responsive grid parameters
                    double cardWidth = 350;
                    int crossAxisCount = (constraints.maxWidth / cardWidth).floor();
                    if (crossAxisCount < 1) crossAxisCount = 1;

                    double actualCardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;
                    double childAspectRatio = actualCardWidth / 160; // Increased from 140 to 160

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                      ),
                      itemCount: widget.students.length,
                      itemBuilder: (context, index) {
                        final student = widget.students[index];
                        final gradient = widget.gradients[index % widget.gradients.length];

                        return Dismissible(
                          key: Key(student['id']!),
                          direction: DismissDirection.startToEnd,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE53E3E).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete Student',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                backgroundColor: const Color(0xFF1E293B),
                                title: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53E3E).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.warning_rounded,
                                        color: Color(0xFFE53E3E),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Delete Student',
                                      style: GoogleFonts.inter(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.05),
                                        Colors.white.withOpacity(0.02),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Are you sure you want to delete "${student['name']}"? This action cannot be undone. 🗑️',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: const Color(0xFF94A3B8),
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                                actions: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF94A3B8),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFE53E3E), Color(0xFFDC2626)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFE53E3E).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Delete',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          onDismissed: (direction) {
                            widget.onDeleteStudent(student['id'] ?? '', student['name'] ?? 'Unknown');
                          },
                          child: ModernAnimatedCard(
                            title: student['name'] ?? 'Unknown',
                            subtitle: student['email'] ?? '',
                            profilePictureUrl: student['profilePictureUrl'],
                            batch: student['batch'],
                            batchTiming: student['batchTiming'],
                            icon: Icons.person_rounded,
                            gradient: gradient,
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      StudentProfilePage(
                                        studentId: student['id']!,
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
                            delay: index * 100,
                          ),
                        );
                      },
                    );
                  },
                )
            ),
        )],
        ),
    );
  }
}

// ViewStudentsPage class
class ViewStudentsPage extends StatefulWidget {
  const ViewStudentsPage({Key? key}) : super(key: key);

  @override
  _ViewStudentsPageState createState() => _ViewStudentsPageState();
}

class _ViewStudentsPageState extends State<ViewStudentsPage>
    with TickerProviderStateMixin {
  AnimationController? _headerController;
  AnimationController? _pulseController;
  Animation<double>? _headerFadeAnimation;
  Animation<double>? _headerScaleAnimation;
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  final List<List<Color>> cardGradients = [
    [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    [const Color(0xFF10B981), const Color(0xFF38EF7D)],
    [const Color(0xFFFC466B), const Color(0xFF3F5EFB)],
    [const Color(0xFFF59E0B), const Color(0xFFEAB308)],
    [const Color(0xFFEE0979), const Color(0xFFFF6A00)],
    [const Color(0xFF56AB2F), const Color(0xFFA8E063)],
    [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
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
      CurvedAnimation(parent: _headerController!, curve: Curves.easeOutQuad),
    );
    _headerScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _headerController!, curve: Curves.easeOutBack),
    );

    _headerController!.forward();
    _pulseController!.repeat(reverse: true);
  }

  @override
  void dispose() {
    _headerController?.dispose();
    _pulseController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteStudent(String studentId, String studentName) async {
    try {
      await FirebaseFirestore.instance.collection('students').doc(studentId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Student Deleted Successfully! 🎉',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$studentName has been removed from the system.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Failed to Delete Student 😔',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Error: $e',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color(0xFFE53E3E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupStudentsByBatch(
      List<Map<String, dynamic>> students) {
    Map<String, List<Map<String, dynamic>>> groupedStudents = {};

    for (var student in students) {
      String batch = student['batch'] ?? '';
      if (batch.isEmpty) batch = 'Unassigned';

      if (!groupedStudents.containsKey(batch)) {
        groupedStudents[batch] = [];
      }
      groupedStudents[batch]!.add(student);
    }

    var sortedBatches = groupedStudents.keys.toList()
      ..sort((a, b) {
        if (a == 'Unassigned') return 1;
        if (b == 'Unassigned') return -1;
        return a.compareTo(b);
      });

    Map<String, List<Map<String, dynamic>>> sortedGroupedStudents = {};
    for (var batch in sortedBatches) {
      sortedGroupedStudents[batch] = groupedStudents[batch]!;
    }

    return sortedGroupedStudents;
  }

  @override
  Widget build(BuildContext context) {
    if (_headerController == null ||
        _pulseController == null ||
        _headerFadeAnimation == null ||
        _headerScaleAnimation == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF667EEA),
            strokeWidth: 4,
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(32.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  AnimatedBuilder(
                    animation: _headerController!,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _headerFadeAnimation!,
                        child: Transform.scale(
                          scale: _headerScaleAnimation!.value +
                              (_pulseController!.value * 0.03),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            margin: const EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF0F172A).withOpacity(0.9),
                                  const Color(0xFF1E293B).withOpacity(0.95),
                                  const Color(0xFF334155).withOpacity(0.9),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF334155).withOpacity(0.6),
                                  blurRadius: 35,
                                  offset: const Offset(0, 15),
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 2),
                                  blurStyle: BlurStyle.inner,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.white.withOpacity(0.1),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_rounded,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                    tooltip: 'Back to Dashboard',
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '🧑‍🎓 Registered Students',
                                        style: GoogleFonts.inter(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: -0.8,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.15),
                                              Colors.white.withOpacity(0.08),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '✨ Browse and manage student profiles in your classroom',
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            color: Colors.white.withOpacity(0.95),
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.2,
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
                    },
                  ),
                  SearchBarWidget(
                    onSearchChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              sliver: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE53E3E).withOpacity(0.1),
                                const Color(0xFFDC2626).withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFE53E3E).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: const Color(0xFFE53E3E).withOpacity(0.8),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Oops! Something went wrong 😟',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE53E3E),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error: ${snapshot.error}',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: const Color(0xFF94A3B8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  color: const Color(0xFF667EEA),
                                  strokeWidth: 6,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Loading students... 📚',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final dynamicStudents = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>?;
                    return {
                      'id': doc.id,
                      'name': data?['name'] as String? ?? 'Unknown Student',
                      'email': data?['email'] as String? ?? 'No Email',
                      'profilePictureUrl': data?['profilePictureUrl'] as String?,
                      'batch': data?['batch'] as String?,
                      'batchTiming': data?['batchTiming'] as String?,
                      'createdAt': data?['createdAt'],
                    };
                  }).where((student) =>
                  (student['name'] ?? '')
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                      (student['batch'] ?? '')
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase())).toList();

                  if (dynamicStudents.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          margin: const EdgeInsets.symmetric(vertical: 60),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF94A3B8).withOpacity(0.2),
                                      const Color(0xFF94A3B8).withOpacity(0.1),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.people_alt_rounded
                                      : Icons.search_off_rounded,
                                  size: 80,
                                  color: const Color(0xFF94A3B8).withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No Students Registered Yet! 🧑‍🎓'
                                    : 'No Students Found! 🔍',
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'New student registrations will appear here. ✨'
                                      : 'Try a different search term or check the spelling.',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final groupedStudents = _groupStudentsByBatch(dynamicStudents);

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final batchName = groupedStudents.keys.elementAt(index);
                        final students = groupedStudents[batchName]!;

                        return BatchSection(
                          batchName: batchName,
                          students: students,
                          gradients: cardGradients,
                          onDeleteStudent: _deleteStudent,
                        );
                      },
                      childCount: groupedStudents.length,
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
            ),
          ],
        ),
      ),
    );
  }
}
