import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/features/dashboard/presentation/dashboard_screen.dart';
import 'src/features/profile/data/patient_repository.dart';
import 'src/features/profile/presentation/patient_profile_setup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: NephroCareApp(),
    ),
  );
}

/// The root widget of the NephroCare application.
class NephroCareApp extends StatelessWidget {
  const NephroCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NephroCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006699), // Deep clinical teal/blue
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ),
      home: const NephroCareHomePage(),
    );
  }
}

/// Clinical root view reactively observing the active patient profile.
/// Routes to [PatientProfileSetupScreen] if no profile exists, or [DashboardScreen].
class NephroCareHomePage extends ConsumerWidget {
  const NephroCareHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePatientAsync = ref.watch(activePatientStreamProvider);

    return activePatientAsync.when(
      data: (patient) {
        if (patient == null) {
          return const PatientProfileSetupScreen();
        }
        return DashboardScreen(patient: patient);
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error loading patient profile: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
