import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/auth/views/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        // add each feature's ViewModel here, one line per feature
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