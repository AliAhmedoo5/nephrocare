import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/patient_repository.dart';
import '../domain/clinical_condition.dart';

/// Screen allowing patients and clinicians to establish an initial patient profile
/// or edit clinical parameters (diagnosis, dry weight, fluid allowance, vascular access).
class PatientProfileSetupScreen extends ConsumerStatefulWidget {
  final Patient? existingPatient;

  const PatientProfileSetupScreen({
    super.key,
    this.existingPatient,
  });

  @override
  ConsumerState<PatientProfileSetupScreen> createState() => _PatientProfileSetupScreenState();
}

class _PatientProfileSetupScreenState extends ConsumerState<PatientProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dryWeightController;
  late TextEditingController _fluidAllowanceController;

  ClinicalCondition _selectedCondition = ClinicalCondition.hemodialysis;
  VascularAccessType _selectedAccessType = VascularAccessType.arteriovenousFistula;
  AccessLocation _selectedAccessLocation = AccessLocation.leftArm;
  bool _isCaregiverMirror = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final patient = widget.existingPatient;
    _nameController = TextEditingController(text: patient?.name ?? '');
    _dryWeightController = TextEditingController(
      text: patient?.prescribedDryWeightKg != null ? patient!.prescribedDryWeightKg.toString() : '',
    );
    _fluidAllowanceController = TextEditingController(
      text: patient?.dailyFluidAllowanceMl != null ? patient!.dailyFluidAllowanceMl.toString() : '',
    );

    if (patient != null) {
      _selectedCondition = ClinicalCondition.fromString(patient.diagnosis) ?? ClinicalCondition.hemodialysis;
      _selectedAccessType = VascularAccessType.fromString(patient.vascularAccessType) ?? VascularAccessType.none;
      _selectedAccessLocation = AccessLocation.fromString(patient.fistulaArmLocation) ?? AccessLocation.none;
      _isCaregiverMirror = patient.isCaregiverMirror;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dryWeightController.dispose();
    _fluidAllowanceController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repository = ref.read(patientRepositoryProvider);
      final dryWeight = double.tryParse(_dryWeightController.text.trim());
      final fluidAllowance = int.tryParse(_fluidAllowanceController.text.trim());

      final accessLocationName = _selectedAccessLocation.name;

      if (widget.existingPatient != null) {
        await repository.updatePatientProfile(
          id: widget.existingPatient!.id,
          name: _nameController.text.trim(),
          diagnosis: _selectedCondition.name,
          prescribedDryWeightKg: dryWeight,
          dailyFluidAllowanceMl: fluidAllowance,
          vascularAccessType: _selectedAccessType.name,
          fistulaArmLocation: accessLocationName,
          isCaregiverMirror: _isCaregiverMirror,
        );
      } else {
        final newPatient = await repository.createPatientProfile(
          name: _nameController.text.trim(),
          diagnosis: _selectedCondition.name,
          prescribedDryWeightKg: dryWeight,
          dailyFluidAllowanceMl: fluidAllowance,
          vascularAccessType: _selectedAccessType.name,
          fistulaArmLocation: accessLocationName,
          isCaregiverMirror: _isCaregiverMirror,
        );
        await repository.setActivePatient(newPatient.id);
        ref.read(activePatientIdProvider.notifier).state = newPatient.id;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingPatient != null
                  ? 'Patient profile updated successfully'
                  : 'Patient profile established successfully',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingPatient != null ? 'Edit Patient Profile' : 'Patient Profile Setup',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Informational Header Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.medical_information_rounded,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Offline Clinical Profile',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Establish your nephrologist-prescribed parameters. All records remain encrypted in local SQLite on this device.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Patient Name Field
                TextFormField(
                  key: const Key('patient_name_input'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Patient Full Name *',
                    hintText: 'e.g., Eleanor Vance',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  style: theme.textTheme.bodyLarge,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter patient full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Caregiver Mirror Designation Toggle
                Card(
                  elevation: 0,
                  color: _isCaregiverMirror
                      ? theme.colorScheme.secondaryContainer.withAlpha(120)
                      : theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _isCaregiverMirror
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    child: SwitchListTile(
                      key: const Key('caregiver_mirror_switch'),
                      value: _isCaregiverMirror,
                      onChanged: (val) {
                        setState(() {
                          _isCaregiverMirror = val;
                        });
                      },
                      title: Text(
                        'Caregiver Mirror Profile',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Designate as a replica maintained on a caregiver or family member's device for monitoring and clinical consultation.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      secondary: Icon(
                        Icons.supervisor_account_rounded,
                        color: _isCaregiverMirror ? theme.colorScheme.secondary : theme.colorScheme.onSurfaceVariant,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Primary Clinical Condition
                DropdownButtonFormField<ClinicalCondition>(
                  key: const Key('diagnosis_dropdown'),
                  initialValue: _selectedCondition,
                  decoration: const InputDecoration(
                    labelText: 'Primary Clinical Condition *',
                    prefixIcon: Icon(Icons.health_and_safety_outlined),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: ClinicalCondition.values.map((condition) {
                    return DropdownMenuItem<ClinicalCondition>(
                      value: condition,
                      child: Text(condition.displayName, style: theme.textTheme.bodyLarge),
                    );
                  }).toList(),
                  onChanged: (condition) {
                    if (condition != null) {
                      setState(() {
                        _selectedCondition = condition;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedCondition.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Prescribed Dry Weight
                TextFormField(
                  key: const Key('dry_weight_input'),
                  controller: _dryWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Prescribed Dry Weight (kg)',
                    hintText: 'e.g., 68.5',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.monitor_weight_outlined),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    helperText: 'Prescribed Dry Weight at the end of a dialysis session with no excess fluid',
                  ),
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    if (_selectedCondition.requiresPrescribedDryWeight) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Prescribed Dry Weight is required for dialysis patients';
                      }
                      final val = double.tryParse(value);
                      if (val == null || val <= 0) {
                        return 'Please enter a valid positive weight';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 4. Daily Fluid Allowance
                TextFormField(
                  key: const Key('fluid_allowance_input'),
                  controller: _fluidAllowanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily Fluid Allowance (mL)',
                    hintText: 'e.g., 1200',
                    suffixText: 'mL/24h',
                    prefixIcon: Icon(Icons.water_drop_outlined),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    helperText: 'Nephrologist-prescribed 24-hour total fluid intake allowance',
                  ),
                  style: theme.textTheme.bodyLarge,
                  validator: (value) {
                    if (_selectedCondition.requiresFluidAllowance) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Daily Fluid Allowance is required';
                      }
                      final val = int.tryParse(value);
                      if (val == null || val <= 0) {
                        return 'Please enter a valid positive fluid volume';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 5. Vascular Access Configuration Header
                Text(
                  'Vascular Access Configuration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // Vascular Access Type
                DropdownButtonFormField<VascularAccessType>(
                  key: const Key('access_type_dropdown'),
                  initialValue: _selectedAccessType,
                  decoration: const InputDecoration(
                    labelText: 'Vascular Access Type',
                    prefixIcon: Icon(Icons.biotech_outlined),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: VascularAccessType.values.map((access) {
                    return DropdownMenuItem<VascularAccessType>(
                      value: access,
                      child: Text(access.displayName, style: theme.textTheme.bodyLarge),
                    );
                  }).toList(),
                  onChanged: (access) {
                    if (access != null) {
                      setState(() {
                        _selectedAccessType = access;
                        if (!access.isArmAccess && _selectedAccessLocation.isArm) {
                          _selectedAccessLocation = AccessLocation.chest;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Access Location / Fistula Arm Location
                DropdownButtonFormField<AccessLocation>(
                  key: const Key('access_location_dropdown'),
                  initialValue: _selectedAccessLocation,
                  decoration: const InputDecoration(
                    labelText: 'Access Anatomical Location',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    helperText: 'Arm access automatically enforces Fistula Arm Safety Flag',
                  ),
                  items: AccessLocation.values.map((location) {
                    return DropdownMenuItem<AccessLocation>(
                      value: location,
                      child: Text(location.displayName, style: theme.textTheme.bodyLarge),
                    );
                  }).toList(),
                  onChanged: (location) {
                    if (location != null) {
                      setState(() {
                        _selectedAccessLocation = location;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button (Constraint: minimum 48dp touch target)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52.0),
                  child: FilledButton.icon(
                    key: const Key('save_profile_button'),
                    onPressed: _isSubmitting ? null : _submitProfile,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 24),
                    label: Text(
                      widget.existingPatient != null ? 'Update Patient Profile' : 'Save Patient Profile',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
