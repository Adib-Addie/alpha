
import 'package:animations/animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'TestDisclaimerScreen.dart';

class SubjectListScreen extends StatefulWidget {
const SubjectListScreen({super.key});

@override
State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
bool _isLoading = false;

final List<List<Color>> cardGradients = [
[AppTheme.backgroundMid, AppTheme.backgroundEnd, AppTheme.backgroundEnd],
[AppTheme.surfaceElevated, AppTheme.backgroundMid, AppTheme.backgroundEnd],
[AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
[AppTheme.backgroundStart, AppTheme.backgroundMid, AppTheme.backgroundEnd],
];

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
color: AppTheme.textPrimary,
letterSpacing: -0.5,
),
),
const SizedBox(height: 8),
Text(
'Choose a subject to start your test',
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
color: AppTheme.backgroundMid,
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
color: AppTheme.textPrimary,
),
),
const SizedBox(height: 8),
Text(
'Please try again later',
style: GoogleFonts.inter(
fontSize: 16,
color: AppTheme.textSecondary,
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
color: Color(0xFF7B2FBE),
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
color: Color(0xFF7B2FBE),
strokeWidth: 4,
),
);
}

if (validSubjects.isEmpty) {
return Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
Icons.book_rounded,
size: 80,
color: AppTheme.textSecondary.withOpacity(0.5),
),
const SizedBox(height: 16),
Text(
'No Subjects Available',
style: GoogleFonts.inter(
fontSize: 28,
fontWeight: FontWeight.w700,
color: AppTheme.textPrimary,
),
),
const SizedBox(height: 8),
Text(
'No tests are available at the moment.\nPlease check back later.',
style: GoogleFonts.inter(
fontSize: 16,
fontWeight: FontWeight.w500,
color: AppTheme.textSecondary,
height: 1.5,
),
textAlign: TextAlign.center,
),
],
),
);
}

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

return ModernAnimatedCard(
title: subject['name'] ?? 'Unknown',
subtitle: subject['locked']
? '?? Locked - Test unavailable'
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

class _ModernAnimatedCardState extends State<ModernAnimatedCard> {
bool _isHovered = false;

@override
Widget build(BuildContext context) {
return MouseRegion(
onEnter: (_) => setState(() => _isHovered = true),
onExit: (_) => setState(() => _isHovered = false),
child: GestureDetector(
onTap: widget.onPressed,
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
child: Icon(
widget.icon,
size: 24,
color: AppTheme.textPrimary,
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
color: AppTheme.textPrimary,
),
overflow: TextOverflow.ellipsis,
),
const SizedBox(height: 4),
Text(
widget.subtitle,
style: GoogleFonts.inter(
fontSize: 12,
fontWeight: FontWeight.w500,
color: AppTheme.textSecondary,
),
overflow: TextOverflow.ellipsis,
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
child: Icon(
Icons.arrow_forward_ios_rounded,
size: 20,
color: widget.gradient.first,
),
),
],
),
),
),
);
}
}
