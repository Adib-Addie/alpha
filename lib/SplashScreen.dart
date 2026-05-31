import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'LoginPage.dart';
import 'StudentDashboardPage.dart';
import 'TeacherDashboardPage.dart';

const String _teacherEmail = 'razah5367@gmail.com'; // Static teacher email

class SplashScreen extends StatefulWidget {
const SplashScreen({Key? key}) : super(key: key);

@override
_SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

@override
void initState() {
super.initState();
_checkAuthState();
}

Future<void> _checkAuthState() async {
if (!mounted) return;

User? user;
try {
  // authStateChanges can hang on Windows; use timeout + currentUser fallback
  user = await FirebaseAuth.instance.authStateChanges().first.timeout(
    const Duration(seconds: 4),
    onTimeout: () => FirebaseAuth.instance.currentUser,
  );
} catch (e) {
  debugPrint('Splash auth check failed: $e');
  user = FirebaseAuth.instance.currentUser;
}

// Brief branding only (was 3s — caused slow startup)
await Future.delayed(const Duration(milliseconds: 600));
if (!mounted) return;

try {
if (!mounted) return;

if (user != null) {
if ((user.email ?? '').trim().toLowerCase() == _teacherEmail.toLowerCase()) {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => const TeacherDashboardPage()),
);
} else {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => const StudentDashboardPage(studentName: '')),
);
}
} else {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => const LoginPage()),
);
}
} catch (e) {
if (!mounted) return;
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (context) => const LoginPage()),
);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppTheme.backgroundStart,
body: Stack(
children: [
Container(
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
),
SafeArea(
child: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
Container(
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
color: const Color(0xFF7B2FBE).withOpacity(0.5),
blurRadius: 30,
offset: const Offset(0, 10),
spreadRadius: 2,
),
],
),
),
const SizedBox(height: 32),
Column(
children: [
Text(
'Alpha Graphics',
style: GoogleFonts.inter(
fontSize: 36,
fontWeight: FontWeight.w800,
color: AppTheme.textPrimary,
letterSpacing: -0.5,
),
),
const SizedBox(height: 8),
Text(
'Empowering Creativity & Learning',
style: GoogleFonts.inter(
fontSize: 18,
fontWeight: FontWeight.w500,
color: AppTheme.textSecondary,
),
),
],
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
color: AppTheme.textMuted,
fontWeight: FontWeight.w500,
),
textAlign: TextAlign.center,
),
const SizedBox(height: 4),
Text(
'Developed by Brolytics Technologies',
style: GoogleFonts.inter(
fontSize: 12,
color: AppTheme.textMuted,
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
