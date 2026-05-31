import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animations/animations.dart';
import 'LoginPage.dart';
import 'StudentDashboardPage.dart';
import 'TeacherDashboardPage.dart';

const String _teacherEmail = 'razah5367@gmail.com'; // Static teacher email

class SplashScreen extends StatefulWidget {
const SplashScreen({Key? key}) : super(key: key);

@override
_SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
late AnimationController _logoController;
late AnimationController _textController;
late AnimationController _waveController;
late Animation<double> _logoRotationAnimation;
late Animation<double> _logoFadeAnimation;
late Animation<double> _textFadeAnimation;
late Animation<Offset> _textSlideAnimation;
late Animation<double> _waveAnimation;
bool _isInitialized = false;

@override
void initState() {
super.initState();
// Initialize animation controllers
_logoController = AnimationController(
vsync: this,
duration: const Duration(milliseconds: 2000),
);
_textController = AnimationController(
vsync: this,
duration: const Duration(milliseconds: 1200),
);
_waveController = AnimationController(
vsync: this,
duration: const Duration(milliseconds: 4000),
);

// Set up animations
_logoRotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
);
_logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
);
_textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _textController, curve: Curves.easeOutQuad),
);
_textSlideAnimation = Tween<Offset>(
begin: const Offset(0, 0.3),
end: Offset.zero,
).animate(
CurvedAnimation(parent: _textController, curve: Curves.easeOutBack),
);
_waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
CurvedAnimation(parent: _waveController, curve: Curves.easeIn),
);

// Start animations
_logoController.forward();
_waveController.repeat();
Future.delayed(const Duration(milliseconds: 300), () {
if (mounted) {
_textController.forward();
setState(() => _isInitialized = true);
}
});

// Check authentication and navigate
_checkAuthState();
}

@override
void dispose() {
_logoController.dispose();
_textController.dispose();
_waveController.dispose();
super.dispose();
}

Future<void> _checkAuthState() async {
await Future.delayed(const Duration(seconds: 3)); // Show splash for 3 seconds
if (!mounted) return;

try {
// authStateChanges().first waits until Firebase Auth has fully restored
// the persisted session from disk — more reliable than currentUser on Windows
final user = await FirebaseAuth.instance.authStateChanges().first;
if (!mounted) return;

if (user != null) {
if (user.email == _teacherEmail) {
Navigator.pushReplacement(
context,
PageRouteBuilder(
pageBuilder: (context, animation, secondaryAnimation) => const TeacherDashboardPage(),
transitionsBuilder: (context, animation, secondaryAnimation, child) =>
SharedAxisTransition(
animation: animation,
secondaryAnimation: secondaryAnimation,
transitionType: SharedAxisTransitionType.horizontal,
fillColor: Colors.transparent,
child: child,
),
),
);
} else {
Navigator.pushReplacement(
context,
PageRouteBuilder(
pageBuilder: (context, animation, secondaryAnimation) => const StudentDashboardPage(studentName: ''),
transitionsBuilder: (context, animation, secondaryAnimation, child) =>
SharedAxisTransition(
animation: animation,
secondaryAnimation: secondaryAnimation,
transitionType: SharedAxisTransitionType.horizontal,
fillColor: Colors.transparent,
child: child,
),
),
);
}
} else {
Navigator.pushReplacement(
context,
PageRouteBuilder(
pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
transitionsBuilder: (context, animation, secondaryAnimation, child) =>
SharedAxisTransition(
animation: animation,
secondaryAnimation: secondaryAnimation,
transitionType: SharedAxisTransitionType.horizontal,
fillColor: Colors.transparent,
child: child,
),
),
);
}
} catch (e) {
if (!mounted) return;
Navigator.pushReplacement(
context,
PageRouteBuilder(
pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
transitionsBuilder: (context, animation, secondaryAnimation, child) =>
SharedAxisTransition(
animation: animation,
secondaryAnimation: secondaryAnimation,
transitionType: SharedAxisTransitionType.horizontal,
fillColor: Colors.transparent,
child: child,
),
),
);
}
}

@override
Widget build(BuildContext context) {
if (!_isInitialized) {
return const Scaffold(
backgroundColor: Color(0xFF1E293B),
body: Center(child: CircularProgressIndicator(color: Color(0xFF667EEA))),
);
}

return Scaffold(
body: Stack(
children: [
// Background with subtle wave animation
AnimatedBuilder(
animation: _waveAnimation,
builder: (context, child) {
return Container(
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [
const Color(0xFF0F172A).withOpacity(1.0 - _waveAnimation.value * 0.1),
const Color(0xFF1E293B),
const Color(0xFF334155).withOpacity(1.0 - _waveAnimation.value * 0.1),
],
),
),
);
},
),
SafeArea(
child: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
// Rotating and fading logo
AnimatedBuilder(
animation: _logoController,
builder: (context, child) {
return FadeTransition(
opacity: _logoFadeAnimation,
child: Transform.rotate(
angle: _logoRotationAnimation.value,
child: Container(
width: 150,
height: 150,
decoration: BoxDecoration(
image: const DecorationImage(
image: AssetImage('assets/logoimg.jpg'),
fit: BoxFit.cover,
),
shape: BoxShape.circle,
boxShadow: [
BoxShadow(
color: const Color(0xFF667EEA).withOpacity(0.5),
blurRadius: 30,
offset: const Offset(0, 10),
spreadRadius: 2,
),
],
),
),
),
);
},
),
const SizedBox(height: 32),
// Sliding and fading text
AnimatedBuilder(
animation: _textController,
builder: (context, child) {
return FadeTransition(
opacity: _textFadeAnimation,
child: SlideTransition(
position: _textSlideAnimation,
child: Column(
children: [
Text(
'Alpha Graphics',
style: GoogleFonts.inter(
fontSize: 36,
fontWeight: FontWeight.w800,
color: Colors.white,
letterSpacing: -0.5,
),
),
const SizedBox(height: 8),
Text(
'Empowering Creativity & Learning',
style: GoogleFonts.inter(
fontSize: 18,
fontWeight: FontWeight.w500,
color: const Color(0xFF94A3B8),
),
),
],
),
),
);
},
),
],
),
),
),
// Footer
Positioned(
bottom: 16,
left: 0,
right: 0,
child: Column(
children: [
Text(
'© 2024 Alpha Graphics. All rights reserved.',
style: GoogleFonts.inter(
fontSize: 12,
color: const Color(0xFF64748B),
fontWeight: FontWeight.w500,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 4),
Text(
'Developed By Brolytics Technologies',
style: GoogleFonts.inter(
fontSize: 12,
color: const Color(0xFF64748B),
fontWeight: FontWeight.w500,
),
textAlign: TextAlign.center,
),
],
),
),
],
),
);
}
}
