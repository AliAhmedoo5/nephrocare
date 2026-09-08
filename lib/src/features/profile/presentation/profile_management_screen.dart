import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/patient_repository.dart';
import '../domain/clinical_condition.dart';
import 'patient_profile_setup_screen.dart';

/// Screen allowing users to manage, view, create, and switch between
/// multiple patient profiles and Caregiver Mirror profiles on a single device.
class ProfileManagementScreen extends ConsumerWidget {
  const ProfileManagementScreen({super.key});

  void _navigateToCreateProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PatientProfileSetupScreen(),
      ),
    );
  }

  void _navigateToEditProfile(BuildContext context, Patient patient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PatientProfileSetupScreen(
          existingPatient: patient,
        ),
      ),
    );
  }

  Future<void> _switchProfile(BuildContext context, WidgetRef ref, Patient patient) async {
    final repository = ref.read(patientRepositoryProvider);
    await repository.setActivePatient(patient.id);
    ref.read(activePatientIdProvider.notifier).state = patient.id;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched active profile to ${patient.name}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allPatientsAsync = ref.watch(allPatientsStreamProvider);
    final activePatientAsync = ref.watch(activePatientStreamProvider);
    final activePatient = activePatientAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profiles & Caregiver Mirrors',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            key: const Key('add_profile_appbar_button'),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Add Patient Profile',
            onPressed: () => _navigateToCreateProfile(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_new_profile_button'),
        onPressed: () => _navigateToCreateProfile(context),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Profile'),
      ),
      body: SafeArea(
        child: allPatientsAsync.when(
          data: (patients) {
            if (patients.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 64,
                        color: theme.colorScheme.primary.withAlpha(150),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Profiles Found',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Establish a direct patient profile or Caregiver Mirror profile to start clinical tracking.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: const Key('add_profile_button'),
                        onPressed: () => _navigateToCreateProfile(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Establish Profile'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              itemCount: patients.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final patient = patients[index];
                final condition = ClinicalCondition.fromString(patient.diagnosis) ?? ClinicalCondition.hemodialysis;
                final isActive = activePatient != null && activePatient.id == patient.id;

                return Card(
                  key: Key('profile_item_${patient.id}'),
                  elevation: isActive ? 2 : 0,
                  color: isActive
                      ? theme.colorScheme.primaryContainer.withAlpha(80)
                      : theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      width: isActive ? 2.0 : 1.0,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _switchProfile(context, ref, patient),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: patient.isCaregiverMirror
                                    ? theme.colorScheme.secondaryContainer
                                    : theme.colorScheme.primaryContainer,
                                child: Icon(
                                  patient.isCaregiverMirror
                                      ? Icons.supervisor_account_rounded
                                      : Icons.person_rounded,
                                  color: patient.isCaregiverMirror
                                      ? theme.colorScheme.onSecondaryContainer
                                      : theme.colorScheme.onPrimaryContainer,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            patient.name,
                                            style: theme.textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        if (isActive)
                                          Container(
                                            key: Key('active_badge_${patient.id}'),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check_circle_rounded, size: 14, color: Colors.white),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Active',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Chip(
                                          label: Text(
                                            condition.displayName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        if (patient.isCaregiverMirror)
                                          Chip(
                                            key: Key('mirror_badge_${patient.id}'),
                                            avatar: const Icon(Icons.visibility_outlined, size: 14),
                                            label: const Text(
                                              'Caregiver Mirror',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            backgroundColor: theme.colorScheme.secondaryContainer,
                                            padding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                key: Key('edit_profile_${patient.id}'),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit Profile',
                                onPressed: () => _navigateToEditProfile(context, patient),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isActive ? 'Currently Selected' : 'Tap to switch active profile',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Icon(
                                isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('Error loading patient profiles: $err'),
            ),
          ),
        ),
      ),
    );
  }
}
