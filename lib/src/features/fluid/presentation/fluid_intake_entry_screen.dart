import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../profile/data/patient_repository.dart';
import '../data/fluid_repository.dart';
import '../domain/fluid_balance_summary.dart';
import '../domain/fluid_calculation_rules.dart';

/// Fluid intake entry screen supporting rapid volume presets, custom volume input,
/// visual fluid allowance progression tracking, and contextual Phosphate Binder prompts.
class FluidIntakeEntryScreen extends ConsumerStatefulWidget {
  final Patient? patient;

  static const List<String> beverageOptions = [
    'Water',
    'Tea',
    'Coffee',
    'Soup / Broth',
    'Juice',
    'Other',
  ];

  const FluidIntakeEntryScreen({
    super.key,
    this.patient,
  });

  @override
  ConsumerState<FluidIntakeEntryScreen> createState() => _FluidIntakeEntryScreenState();
}

class _FluidIntakeEntryScreenState extends ConsumerState<FluidIntakeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _volumeController = TextEditingController();

  String _selectedBeverage = 'Water';
  bool _phosphateBinderTaken = false;
  int? _selectedPreset;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _volumeController.dispose();
    super.dispose();
  }

  void _selectPreset(int volume) {
    setState(() {
      _selectedPreset = volume;
      _volumeController.text = volume.toString();
    });
  }

  Future<void> _submitIntake(Patient patient) async {
    if (!_formKey.currentState!.validate()) return;

    final volume = int.tryParse(_volumeController.text.trim()) ?? 0;
    if (volume <= 0) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(fluidRepositoryProvider).recordFluidIntake(
            patientId: patient.id,
            volumeMl: volume,
            beverageType: _selectedBeverage,
            phosphateBinderTaken: _phosphateBinderTaken,
            recordedAt: DateTime.now().toUtc(),
          );

      if (mounted) {
        final binderNote = _phosphateBinderTaken ? ' with Phosphate Binder' : '';
        _volumeController.clear();
        setState(() {
          _selectedPreset = null;
          _phosphateBinderTaken = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fluid intake logged: $volume mL ($_selectedBeverage)$binderNote.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording fluid intake: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
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
    final activePatientAsync = ref.watch(activePatientStreamProvider);
    final Patient? patient = widget.patient ?? activePatientAsync.valueOrNull;

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fluid Intake')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final balanceAsync = ref.watch(fluidBalance24hStreamProvider(patient.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fluid Intake & Binders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Prescribed Fluid Allowance Visual Progression Card
              _FluidAllowanceProgressCard(
                patient: patient,
                balanceAsync: balanceAsync,
              ),

              const SizedBox(height: 16),

              // 2. Rapid Volume Presets
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: theme.colorScheme.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Quick Volume Presets',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: FluidCalculationRules.defaultVolumePresetsMl.map((preset) {
                          final isSelected = _selectedPreset == preset;
                          return SizedBox(
                            height: 48.0,
                            child: FilterChip(
                              key: Key('preset_${preset}_button'),
                              label: Text(
                                '$preset mL',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor: theme.colorScheme.surface,
                              side: BorderSide(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                                width: 1.5,
                              ),
                              onSelected: (_) => _selectPreset(preset),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 3. Custom Fluid Intake Entry Form
              Form(
                key: _formKey,
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Fluid Intake Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Custom Volume Field
                        TextFormField(
                          key: const Key('volume_input'),
                          controller: _volumeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Intake Volume (mL) *',
                            hintText: 'e.g., 250',
                            prefixIcon: const Icon(Icons.local_drink_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          onChanged: (val) {
                            final parsed = int.tryParse(val.trim());
                            if (parsed != _selectedPreset) {
                              setState(() => _selectedPreset = null);
                            }
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter intake volume';
                            }
                            final val = int.tryParse(value.trim());
                            if (val == null || val <= 0 || val > 3000) {
                              return 'Enter a valid intake volume (1 - 3000 mL)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Beverage Type Dropdown
                        DropdownButtonFormField<String>(
                          key: const Key('beverage_type_dropdown'),
                          initialValue: _selectedBeverage,
                          decoration: InputDecoration(
                            labelText: 'Beverage / Fluid Type',
                            prefixIcon: const Icon(Icons.category_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          items: FluidIntakeEntryScreen.beverageOptions.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            if (newVal != null) {
                              setState(() => _selectedBeverage = newVal);
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        // 4. Contextual Phosphate Binder Reminder Callout & Checkbox
                        Material(
                          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.tertiary.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.medication_rounded,
                                      color: theme.colorScheme.tertiary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Phosphate Binder Timing',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onTertiaryContainer,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  FluidCalculationRules.phosphateBinderEducationalPrompt,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onTertiaryContainer,
                                    height: 1.3,
                                  ),
                                ),
                                const Divider(height: 20),
                                CheckboxListTile(
                                  key: const Key('phosphate_binder_toggle'),
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity.leading,
                                  title: Text(
                                    'Phosphate Binder Ingested with this Fluid / Meal',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Recorded with this intake event',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  value: _phosphateBinderTaken,
                                  onChanged: (val) {
                                    setState(() => _phosphateBinderTaken = val ?? false);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Save Button (Min 48dp height)
                        SizedBox(
                          height: 52.0,
                          child: ElevatedButton(
                            key: const Key('save_fluid_intake_button'),
                            onPressed: _isSubmitting ? null : () => _submitIntake(patient),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const CircularProgressIndicator.adaptive()
                                : const Text(
                                    'Save Fluid Intake Log',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 5. Historical Fluid Intake Section
              Text(
                'Today\'s Fluid Intake Logs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _FluidIntakeHistoryList(patient: patient),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visual Progression Widget tracking daily intake against prescribed Fluid Allowance.
class _FluidAllowanceProgressCard extends StatelessWidget {
  final Patient patient;
  final AsyncValue<FluidBalanceSummary> balanceAsync;

  const _FluidAllowanceProgressCard({
    required this.patient,
    required this.balanceAsync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allowance = patient.dailyFluidAllowanceMl;

    return balanceAsync.when(
      data: (summary) {
        final consumed = summary.totalIntakeMl;
        final percentage = summary.intakePercentageOfAllowance ?? 0.0;
        final remaining = summary.remainingAllowanceMl;
        final status = summary.allowanceStatus;

        Color progressColor;
        String statusLabel;
        IconData statusIcon;

        switch (status) {
          case FluidAllowanceStatus.withinLimit:
            progressColor = theme.colorScheme.primary;
            statusLabel = 'Within Limit';
            statusIcon = Icons.check_circle_outline_rounded;
            break;
          case FluidAllowanceStatus.nearingLimit:
            progressColor = Colors.orange;
            statusLabel = 'Nearing Limit';
            statusIcon = Icons.warning_amber_rounded;
            break;
          case FluidAllowanceStatus.exceeded:
            progressColor = theme.colorScheme.error;
            statusLabel = 'Allowance Exceeded';
            statusIcon = Icons.error_outline_rounded;
            break;
          case FluidAllowanceStatus.noAllowanceSpecified:
            progressColor = theme.colorScheme.secondary;
            statusLabel = 'No Prescribed Allowance';
            statusIcon = Icons.info_outline_rounded;
            break;
        }

        final progressRatio = (allowance != null && allowance > 0)
            ? (consumed / allowance).clamp(0.0, 1.0)
            : 0.0;

        return Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: status == FluidAllowanceStatus.exceeded
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
              width: status == FluidAllowanceStatus.exceeded ? 2.0 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Daily Fluid Allowance Tracker',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      avatar: Icon(statusIcon, size: 16, color: progressColor),
                      label: Text(
                        statusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: progressColor.withValues(alpha: 0.12),
                      side: BorderSide(color: progressColor, width: 1.0),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        children: [
                          TextSpan(text: '$consumed'),
                          TextSpan(
                            text: allowance != null ? ' / $allowance mL' : ' mL logged',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (allowance != null)
                      Text(
                        '$percentage%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: progressColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
                if (allowance != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    status == FluidAllowanceStatus.exceeded
                        ? 'Exceeded prescribed allowance by ${consumed - allowance} mL'
                        : '$remaining mL remaining for today',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: status == FluidAllowanceStatus.exceeded
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading allowance status: $e'),
        ),
      ),
    );
  }
}

/// Reactive list widget for fluid intake history.
class _FluidIntakeHistoryList extends ConsumerWidget {
  final Patient patient;

  const _FluidIntakeHistoryList({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(todayFluidIntakeLogsStreamProvider(patient.id));
    final theme = Theme.of(context);

    return logsAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(child: Text('No fluid intake recorded yet.')),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: logs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final log = logs[index];
            final formattedTime =
                '${log.recordedAt.hour.toString().padLeft(2, '0')}:${log.recordedAt.minute.toString().padLeft(2, '0')}';

            return Card(
              elevation: 0,
              color: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.local_drink_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${log.volumeMl} mL',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  log.beverageType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                backgroundColor: theme.colorScheme.secondaryContainer,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                formattedTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (log.phosphateBinderTaken) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.medication_rounded,
                                  size: 14,
                                  color: theme.colorScheme.tertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Binder Ingested',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.tertiary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      key: Key('intake_menu_${log.id}'),
                      icon: const Icon(Icons.more_vert_rounded),
                      tooltip: 'Intake Actions',
                      onSelected: (action) {
                        if (action == 'edit') {
                          _showEditIntakeDialog(context, ref, log);
                        } else if (action == 'delete') {
                          _confirmDeleteIntake(context, ref, log);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Edit Entry'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
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
      error: (e, _) => Text('Error loading intake logs: $e'),
    );
  }

  void _showEditIntakeDialog(BuildContext context, WidgetRef ref, FluidIntakeLog log) {
    final volumeCtrl = TextEditingController(text: log.volumeMl.toString());
    String selectedBeverage = log.beverageType;
    bool binderTaken = log.phosphateBinderTaken;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Fluid Intake'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('edit_intake_volume_input'),
                  controller: volumeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Volume (mL)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('edit_intake_beverage_dropdown'),
                  initialValue: FluidIntakeEntryScreen.beverageOptions.contains(selectedBeverage)
                      ? selectedBeverage
                      : 'Other',
                  decoration: const InputDecoration(
                    labelText: 'Beverage',
                    border: OutlineInputBorder(),
                  ),
                  items: FluidIntakeEntryScreen.beverageOptions
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedBeverage = val);
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  key: const Key('edit_intake_binder_checkbox'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Phosphate Binder Ingested'),
                  value: binderTaken,
                  onChanged: (val) {
                    setDialogState(() => binderTaken = val ?? false);
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
              key: const Key('save_edit_intake_button'),
              onPressed: () async {
                final vol = int.tryParse(volumeCtrl.text.trim());
                if (vol == null || vol <= 0) return;
                await ref.read(fluidRepositoryProvider).updateFluidIntake(
                      id: log.id,
                      volumeMl: vol,
                      beverageType: selectedBeverage,
                      phosphateBinderTaken: binderTaken,
                    );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteIntake(BuildContext context, WidgetRef ref, FluidIntakeLog log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Intake Entry?'),
        content: Text('Delete ${log.volumeMl} mL (${log.beverageType})? This will update your 24-hour Fluid Balance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_intake_button'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await ref.read(fluidRepositoryProvider).deleteFluidIntake(log.id);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
