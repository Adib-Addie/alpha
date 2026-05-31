import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';
import 'SplashScreen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Preload Inter so login screen does not block on first network font fetch
  try {
    await GoogleFonts.pendingFonts([GoogleFonts.inter()]).timeout(
      const Duration(seconds: 5),
    );
  } catch (e) {
    debugPrint('Font preload skipped: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Alpha Graphics',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.backgroundStart,
        primaryColor: const Color(0xFF7B2FBE),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7B2FBE),
          secondary: Color(0xFF00B4DB),
          surface: AppTheme.backgroundMid,
          background: AppTheme.backgroundStart,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.backgroundStart,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardColor: AppTheme.backgroundMid,
        dividerColor: AppTheme.divider,
      ),
      home: SplashScreen(),
    );
  }
}
