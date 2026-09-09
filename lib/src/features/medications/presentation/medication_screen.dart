import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../profile/data/patient_repository.dart';
import '../data/medication_repository.dart';

/// Screen managing active Medication Regimens and 1-tap Administrations.
class MedicationScreen extends ConsumerStatefulWidget {
  final Patient? patient;

  const MedicationScreen({
    super.key,
    this.patient,
  });

  @override
  ConsumerState<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends ConsumerState<MedicationScreen> {
  Future<void> _record1TapAdministration(Patient patient, Medication med) async {
    try {
      await ref.read(medicationRepositoryProvider).recordAdministration(
            patientId: patient.id,
            medicationId: med.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Administered ${med.name} (${med.dosage})'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error administering medication: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddMedicationDialog(BuildContext context, Patient patient) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    final instructionsCtrl = TextEditingController();
    bool isBinder = false;
    bool isAntiHyp = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Prescribe Medication Regimen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('med_name_input'),
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name *',
                    hintText: 'e.g., Sevelamer Carbonate',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('med_dosage_input'),
                  controller: dosageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prescribed Dosage *',
                    hintText: 'e.g., 800 mg',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('med_frequency_input'),
                  controller: freqCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Frequency / Schedule *',
                    hintText: 'e.g., Three times daily with meals',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('med_instructions_input'),
                  controller: instructionsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Instructions',
                    hintText: 'e.g., Ingest with meals',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  key: const Key('med_is_phosphate_binder_checkbox'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Phosphate Binder'),
                  subtitle: const Text('Must be taken with or immediately after meals'),
                  value: isBinder,
                  onChanged: (val) {
                    setDialogState(() => isBinder = val ?? false);
                  },
                ),
                CheckboxListTile(
                  key: const Key('med_is_antihypertensive_checkbox'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Anti-Hypertensive'),
                  subtitle: const Text('Blood pressure lowering agent'),
                  value: isAntiHyp,
                  onChanged: (val) {
                    setDialogState(() => isAntiHyp = val ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('save_medication_button'),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final dosage = dosageCtrl.text.trim();
                final freq = freqCtrl.text.trim();
                if (name.isEmpty || dosage.isEmpty || freq.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill required medication details'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                await ref.read(medicationRepositoryProvider).createMedication(
                      patientId: patient.id,
                      name: name,
                      dosage: dosage,
                      frequency: freq,
                      instructions: instructionsCtrl.text.trim().isNotEmpty ? instructionsCtrl.text.trim() : null,
                      isPhosphateBinder: isBinder,
                      isAntiHypertensive: isAntiHyp,
                    );

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save Regimen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMedicationDialog(BuildContext context, Medication med) {
    final nameCtrl = TextEditingController(text: med.name);
    final dosageCtrl = TextEditingController(text: med.dosage);
    final freqCtrl = TextEditingController(text: med.frequency);
    final instructionsCtrl = TextEditingController(text: med.instructions ?? '');
    bool isBinder = med.isPhosphateBinder;
    bool isAntiHyp = med.isAntiHypertensive;
    bool isActive = med.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Medication Regimen'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dosageCtrl,
                  decoration: const InputDecoration(labelText: 'Dosage', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: freqCtrl,
                  decoration: const InputDecoration(labelText: 'Frequency', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionsCtrl,
                  decoration: const InputDecoration(labelText: 'Instructions', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Regimen'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val ?? true),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Phosphate Binder'),
                  value: isBinder,
                  onChanged: (val) => setDialogState(() => isBinder = val ?? false),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Anti-Hypertensive'),
                  value: isAntiHyp,
                  onChanged: (val) => setDialogState(() => isAntiHyp = val ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(medicationRepositoryProvider).updateMedication(
                      id: med.id,
                      name: nameCtrl.text.trim(),
                      dosage: dosageCtrl.text.trim(),
                      frequency: freqCtrl.text.trim(),
                      instructions: instructionsCtrl.text.trim(),
                      isPhosphateBinder: isBinder,
                      isAntiHypertensive: isAntiHyp,
                      isActive: isActive,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAdminDialog(BuildContext context, MedicationAdministration admin) {
    final dosageCtrl = TextEditingController(text: admin.dosage);
    final notesCtrl = TextEditingController(text: admin.notes ?? '');
    DateTime editedTime = admin.administeredAt;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Administration Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('edit_admin_dosage_input'),
                controller: dosageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dosage Administered',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('edit_admin_notes_input'),
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Clinical Notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Administration Time'),
                subtitle: Text(
                  '${editedTime.toLocal().hour.toString().padLeft(2, '0')}:${editedTime.toLocal().minute.toString().padLeft(2, '0')}',
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final pickedTime = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(editedTime.toLocal()),
                    );
                    if (pickedTime != null) {
                      setDialogState(() {
                        editedTime = DateTime(
                          editedTime.year,
                          editedTime.month,
                          editedTime.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        ).toUtc();
                      });
                    }
                  },
                  child: const Text('Change Time'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('confirm_edit_admin_button'),
              onPressed: () async {
                await ref.read(medicationRepositoryProvider).updateAdministration(
                      id: admin.id,
                      dosage: dosageCtrl.text.trim(),
                      notes: notesCtrl.text.trim(),
                      administeredAt: editedTime,
                    );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAdmin(BuildContext context, MedicationAdministration admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Administration Record'),
        content: Text('Delete entry for ${admin.medicationName} (${admin.dosage})? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_admin_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              await ref.read(medicationRepositoryProvider).deleteAdministration(admin.id);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activePatientAsync = ref.watch(activePatientStreamProvider);
    final Patient? patient = widget.patient ?? activePatientAsync.valueOrNull;

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Medication Regimen')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final activeMedsAsync = ref.watch(activeMedicationsStreamProvider(patient.id));
    final todayAdminsAsync = ref.watch(todayAdministrationsStreamProvider(patient.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Medication Regimen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            key: const Key('add_medication_button'),
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Prescribed Medication',
            onPressed: () => _showAddMedicationDialog(context, patient),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header description
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Prescriptions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddMedicationDialog(context, patient),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Prescribe'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Active Regimens List
              activeMedsAsync.when(
                data: (meds) {
                  if (meds.isEmpty) {
                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.medication_outlined, size: 40, color: theme.colorScheme.secondary),
                            const SizedBox(height: 8),
                            const Text(
                              'No active prescribed medications.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap "Prescribe" to configure medications and enable 1-tap administration.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: meds.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final med = meds[index];
                      return Card(
                        key: Key('med_card_${med.id}'),
                        elevation: 0,
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.5),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      med.isPhosphateBinder
                                          ? Icons.restaurant_rounded
                                          : (med.isAntiHypertensive
                                              ? Icons.favorite_rounded
                                              : Icons.medication_rounded),
                                      color: theme.colorScheme.primary,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${med.dosage} • ${med.frequency}',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (med.instructions != null && med.instructions!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            med.instructions!,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    key: Key('med_menu_${med.id}'),
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () => _showEditMedicationDialog(context, med),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Badges
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (med.isPhosphateBinder)
                                    Chip(
                                      avatar: const Icon(Icons.restaurant_rounded, size: 14),
                                      label: const Text('Phosphate Binder', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      backgroundColor: theme.colorScheme.tertiaryContainer,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.zero,
                                    ),
                                  if (med.isAntiHypertensive)
                                    Chip(
                                      avatar: const Icon(Icons.favorite_rounded, size: 14),
                                      label: const Text('Anti-Hypertensive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      backgroundColor: theme.colorScheme.secondaryContainer,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // 1-Tap Administration Button (Min 48dp)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton.icon(
                                  key: Key('take_medication_${med.id}'),
                                  icon: const Icon(Icons.check_circle_outline_rounded),
                                  label: const Text(
                                    'Take Dose (1-Tap)',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _record1TapAdministration(patient, med),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Text('Error loading medications: $e'),
              ),

              const SizedBox(height: 24),

              // Section: Today's Administrations
              Text(
                'Today\'s Administrations',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              todayAdminsAsync.when(
                data: (admins) {
                  if (admins.isEmpty) {
                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text('No doses recorded today yet.')),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: admins.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final admin = admins[index];
                      final time =
                          '${admin.administeredAt.hour.toString().padLeft(2, '0')}:${admin.administeredAt.minute.toString().padLeft(2, '0')}';

                      return Card(
                        key: Key('admin_tile_${admin.id}'),
                        elevation: 0,
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Administered ${admin.medicationName}',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${admin.dosage} • $time${admin.notes != null ? ' • ${admin.notes}' : ''}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuButton<String>(
                                key: Key('admin_menu_${admin.id}'),
                                tooltip: 'Administration Actions',
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    _showEditAdminDialog(context, admin);
                                  } else if (action == 'delete') {
                                    _confirmDeleteAdmin(context, admin);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit Record'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete Record', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Text('Error loading administrations: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
