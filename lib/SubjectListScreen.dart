
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'TestDisclaimerScreen.dart';

class SubjectListScreen extends StatefulWidget {
const SubjectListScreen({super.key});

@override
State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> with TickerProviderStateMixin {
late AnimationController _headerController;
late AnimationController _pulseController;
late AnimationController _noSubjectsController;
late Animation<double> _headerFadeAnimation;
late Animation<double> _headerScaleAnimation;
late Animation<double> _noSubjectsFadeAnimation;
late Animation<double> _noSubjectsScaleAnimation;
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
_noSubjectsController = AnimationController(
vsync: this,
duration: const Duration(milliseconds: 1000),
);
_headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _headerController, curve: Curves.easeOutQuad),
);
_headerScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
CurvedAnimation(parent: _headerController, curve: Curves.easeOutBack),
);
_noSubjectsFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _noSubjectsController, curve: Curves.easeOutQuad),
);
_noSubjectsScaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
CurvedAnimation(parent: _noSubjectsController, curve: Curves.easeOutBack),
);
_headerController.forward();
_pulseController.repeat(reverse: true);
_noSubjectsController.forward();

_cardControllers = [];
_cardFadeAnimations = [];
_cardSlideAnimations = [];
}

@override
void dispose() {
_headerController.dispose();
_pulseController.dispose();
_noSubjectsController.dispose();
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

final maxAnimatedCards = itemCount > 5 ? 5 : itemCount;
for (int i = 0; i < maxAnimatedCards; i++) {
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

void _showLockedSubjectSnackBar() {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Row(
children: [
const Icon(Icons.lock_rounded, color: Colors.white),
const SizedBox(width: 12),
Text(
'This subject is locked',
style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
),
],
),
backgroundColor: const Color(0xFFE53E3E),
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
margin: const EdgeInsets.all(16),
duration: const Duration(seconds: 3),
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
tooltip: 'Back to previous screen',
),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Select Subject',
style: GoogleFonts.inter(
fontSize: 36,
fontWeight: FontWeight.w800,
color: Colors.white,
letterSpacing: -0.5,
),
),
const SizedBox(height: 8),
Text(
'Choose a subject to start your test',
style: GoogleFonts.inter(
fontSize: 18,
color: Colors.white.withOpacity(0.9),
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
);
},
),
ConstrainedBox(
constraints: const BoxConstraints(maxWidth: 1000),
child: StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
    .collection('subjects')
    .orderBy('createdAt', descending: false)
    .snapshots(),
builder: (context, snapshot) {
if (snapshot.hasError) {
return Center(
child: Container(
padding: const EdgeInsets.all(24),
decoration: BoxDecoration(
color: const Color(0xFF1E293B),
borderRadius: BorderRadius.circular(16),
border: Border.all(
color: const Color(0xFFE53E3E).withOpacity(0.3),
),
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Icon(
Icons.error_outline_rounded,
color: Color(0xFFE53E3E),
size: 48,
),
const SizedBox(height: 12),
Text(
'Error Loading Subjects',
style: GoogleFonts.inter(
fontSize: 20,
fontWeight: FontWeight.w700,
color: Colors.white,
),
),
const SizedBox(height: 8),
Text(
'Please try again later',
style: GoogleFonts.inter(
fontSize: 16,
color: const Color(0xFF94A3B8),
),
),
],
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

final subjects = snapshot.data!.docs;
final validSubjects = <Map<String, dynamic>>[];

return FutureBuilder(
future: Future.wait(subjects.map((doc) async {
final data = doc.data() as Map<String, dynamic>?;
final subjectId = doc.id;
final questionSnapshot = await FirebaseFirestore.instance
    .collection('questions')
    .where('subjectId', isEqualTo: subjectId)
    .limit(1)
    .get();
if (questionSnapshot.docs.isNotEmpty) {
validSubjects.add({
'id': doc.id,
'name': data?['name'] as String? ?? 'Unknown',
'createdAt': data?['createdAt'] ?? FieldValue.serverTimestamp(),
'locked': data?.containsKey('locked') == true ? data!['locked'] as bool : false,
});
}
})),
builder: (context, AsyncSnapshot snapshot) {
if (snapshot.connectionState == ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(
color: Color(0xFF667EEA),
strokeWidth: 4,
),
);
}

if (validSubjects.isEmpty) {
return Center(
child: FadeTransition(
opacity: _noSubjectsFadeAnimation,
child: ScaleTransition(
scale: _noSubjectsScaleAnimation,
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
'No tests are available at the moment.\nPlease check back later.',
style: GoogleFonts.inter(
fontSize: 16,
fontWeight: FontWeight.w500,
color: const Color(0xFF94A3B8),
height: 1.5,
),
textAlign: TextAlign.center,
),
],
),
),
),
);
}

_initializeCardAnimations(validSubjects.length);

return GridView.builder(
shrinkWrap: true,
physics: const NeverScrollableScrollPhysics(),
gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
maxCrossAxisExtent: 400,
mainAxisSpacing: 16,
crossAxisSpacing: 16,
childAspectRatio: 3.5,
),
itemCount: validSubjects.length,
itemBuilder: (context, index) {
final subject = validSubjects[index];
final gradient = cardGradients[index % cardGradients.length];
final animationIndex = index < _cardFadeAnimations.length ? index : 0;

return FadeTransition(
opacity: _cardFadeAnimations[animationIndex],
child: SlideTransition(
position: _cardSlideAnimations[animationIndex],
child: ModernAnimatedCard(
title: subject['name'] ?? 'Unknown',
subtitle: subject['locked']
? '🛑 Locked - Test unavailable'
    : 'Start your test',
icon: Icons.quiz_rounded,
gradient: gradient,
onPressed: () {
if (subject['locked']) {
_showLockedSubjectSnackBar();
} else {
Navigator.push(
context,
PageRouteBuilder(
pageBuilder: (context, animation, secondaryAnimation) =>
TestDisclaimerScreen(
subjectId: subject['id'],
subjectName: subject['name'] ?? 'Unknown',
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
}
},
isLocked: subject['locked'],
delay: index * 150,
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
