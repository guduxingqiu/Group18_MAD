import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/auth/views/login_screen.dart';
import 'features/notifications/viewmodel/proximity_viewmodel.dart';
import 'features/outbreak_map/repository/clinic_repository.dart';
import 'features/report_submission/repository/report_repository.dart';
import 'features/report_submission/viewmodel/report_viewmodel.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/auth/repository/firebase_auth_repository.dart';
import 'features/report_submission/repository/firebase_report_repository.dart';
import 'features/outbreak_map/repository/firebase_clinic_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final AuthRepository authRepo = FirebaseAuthRepository(); // was MockAuthRepository()
  final ReportRepository reportRepo = FirebaseReportRepository(); // was MockReportRepository()
  final ClinicRepository clinicRepo = FirebaseClinicRepository(); // was OverpassClinicRepository()

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