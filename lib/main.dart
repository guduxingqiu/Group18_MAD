import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/auth/views/login_screen.dart';
import 'features/report_submission/viewmodel/report_viewmodel.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // add each feature's ViewModel here, one line per feature
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
      ],
      child: const WthApp(),
    ),
  );
}

class WthApp extends StatelessWidget {
  const WthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What The Health',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}