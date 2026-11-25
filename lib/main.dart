import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/repository/mock_auth_repository.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/auth/views/login_screen.dart';
import 'features/notifications/viewmodel/proximity_viewmodel.dart';
import 'features/outbreak_map/repository/clinic_repository.dart';
import 'features/outbreak_map/repository/overpass_clinic_repository.dart';
import 'features/report_submission/repository/mock_report_repository.dart';
import 'features/report_submission/repository/report_repository.dart';
import 'features/report_submission/viewmodel/report_viewmodel.dart';

void main() {
  // To use the real database later, swap these three lines only.
  final AuthRepository authRepo = MockAuthRepository();
  final ReportRepository reportRepo = MockReportRepository();
  final ClinicRepository clinicRepo = OverpassClinicRepository();

  runApp(
    MultiProvider(
      providers: [
        Provider<ClinicRepository>.value(value: clinicRepo),
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepo)),
        ChangeNotifierProvider(create: (_) => ReportViewModel(reportRepo)),
        ChangeNotifierProvider(create: (_) => ProximityViewModel()),
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