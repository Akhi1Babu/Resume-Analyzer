import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'services/auth_service.dart';
import 'services/resume_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  final authService = AuthService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (_) => ResumeService()),
      ],
      child: ResumeAnalyzerApp(authService: authService),
    ),
  );
}

class ResumeAnalyzerApp extends StatelessWidget {
  final AuthService authService;
  const ResumeAnalyzerApp({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AI Resume Analyzer',
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: AppRouter.createRouter(authService),
      debugShowCheckedModeBanner: false,
    );
  }
}
