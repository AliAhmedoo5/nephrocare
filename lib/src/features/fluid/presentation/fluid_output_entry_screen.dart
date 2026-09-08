import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../catheter/domain/catheter_lifespan_rules.dart';
import '../../profile/data/patient_repository.dart';
import '../data/fluid_repository.dart';
import '../domain/fluid_balance_summary.dart';

/// Fluid output and evacuation entry screen supporting rapid presets, custom volume entry,
/// hematuria bleeding grade assessment, and reactive 24-hour Fluid Balance calculation.
class FluidOutputEntryScreen extends ConsumerStatefulWidget {
  final Patient? patient;

  const FluidOutputEntryScreen({
    super.key,
    this.patient,
  });

  @override
  ConsumerState<FluidOutputEntryScreen> createState() => _FluidOutputEntryScreenState();
}

class _FluidOutputEntryScreenState extends ConsumerState<FluidOutputEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _volumeController = TextEditingController();

  String _selectedOutputType = 'urine';
  int? _selectedHematuriaGrade;
  int? _selectedPreset;
  bool _isSubmitting = false;

  static const List<int> _outputPresets = [100, 200, 300, 500, 1000];

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

  Future<void> _submitOutput(Patient patient) async {
    if (!_formKey.currentState!.validate()) return;

    final volume = int.tryParse(_volumeController.text.trim()) ?? 0;
    if (volume <= 0) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(fluidRepositoryProvider).recordFluidOutput(
            patientId: patient.id,
            volumeMl: volume,
            outputType: _selectedOutputType,
            hematuriaGrade: _selectedOutputType == 'urine' ? _selectedHematuriaGrade : null,
            recordedAt: DateTime.now().toUtc(),
          );

      if (mounted) {
        _volumeController.clear();
        setState(() {
          _selectedPreset = null;
          _selectedHematuriaGrade = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fluid output logged: $volume mL ($_selectedOutputType).'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording fluid output: $e'),
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
        appBar: AppBar(title: const Text('Fluid Output')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final balanceAsync = ref.watch(fluidBalance24hStreamProvider(patient.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Fluid Output & Evacuation',
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
              // 1. Reactive 24-Hour Fluid Balance Summary Card
              _FluidBalanceBannerCard(balanceAsync: balanceAsync),

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
                            'Quick Output Presets',
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
                        children: _outputPresets.map((preset) {
                          final isSelected = _selectedPreset == preset;
                          return SizedBox(
                            height: 48.0,
                            child: FilterChip(
                              key: Key('preset_output_${preset}_button'),
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

              // 3. Fluid Output Entry Form
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
                          'Evacuation Details',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Custom Volume Input
                        TextFormField(
                          key: const Key('output_volume_input'),
                          controller: _volumeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Evacuation Volume (mL) *',
                            hintText: 'e.g., 200',
                            prefixIcon: const Icon(Icons.opacity_rounded),
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
                              return 'Please enter evacuation volume';
                            }
                            final val = int.tryParse(value.trim());
                            if (val == null || val <= 0 || val > 5000) {
                              return 'Enter a valid evacuation volume (1 - 5000 mL)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Evacuation Output Type Selector
                        Text(
                          'Output Mechanism',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            ChoiceChip(
                              key: const Key('output_type_urine'),
                              label: const Text('Urine Evacuation'),
                              selected: _selectedOutputType == 'urine',
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedOutputType = 'urine');
                              },
                            ),
                            ChoiceChip(
                              key: const Key('output_type_peritoneal_drain'),
                              label: const Text('Peritoneal Dialysate Drain'),
                              selected: _selectedOutputType == 'peritonealDrain',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedOutputType = 'peritonealDrain';
                                    _selectedHematuriaGrade = null;
                                  });
                                }
                              },
                            ),
                            ChoiceChip(
                              key: const Key('output_type_ultrafiltration'),
                              label: const Text('Ultrafiltration'),
                              selected: _selectedOutputType == 'ultrafiltration',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedOutputType = 'ultrafiltration';
                                    _selectedHematuriaGrade = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),

                        // 4. Hematuria Grade Selector (Relevant for Urine Evacuation per CONTEXT.md)
                        if (_selectedOutputType == 'urine') ...[
                          const SizedBox(height: 20),
                          Text(
                            'Hematuria Bleeding Grade (Optional)',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Visual bleeding observation per clinical nephrology protocol',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              for (int g = 1; g <= 4; g++) ...[
                                if (g > 1) const SizedBox(height: 6),
                                _HematuriaTile(
                                  key: Key('hematuria_grade_$g'),
                                  grade: g,
                                  title: HematuriaGradeInfo.fromGrade(g).title,
                                  description: HematuriaGradeInfo.fromGrade(g).description,
                                  indicatorColor: HematuriaGradeInfo.fromGrade(g).color,
                                  isSelected: _selectedHematuriaGrade == g,
                                  onSelect: () => setState(() => _selectedHematuriaGrade = (_selectedHematuriaGrade == g ? null : g)),
                                ),
                              ],
                            ],
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          height: 52.0,
                          child: ElevatedButton(
                            key: const Key('save_fluid_output_button'),
                            onPressed: _isSubmitting ? null : () => _submitOutput(patient),
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
                                    'Save Fluid Output Log',
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

              // 5. Historical Output Section
              Text(
                'Today\'s Fluid Output Logs',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _FluidOutputHistoryList(patient: patient),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hematuria option tile with min 48dp height and clear clinical description.
class _HematuriaTile extends StatelessWidget {
  final int grade;
  final String title;
  final String description;
  final Color? indicatorColor;
  final bool isSelected;
  final VoidCallback onSelect;

  const _HematuriaTile({
    super.key,
    required this.grade,
    required this.title,
    required this.description,
    this.indicatorColor,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
              size: 20,
            ),
            const SizedBox(width: 10),
            if (indicatorColor != null) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26, width: 1.0),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner Card calculating and displaying the 24-hour Fluid Balance reactively.
class _FluidBalanceBannerCard extends StatelessWidget {
  final AsyncValue<FluidBalanceSummary> balanceAsync;

  const _FluidBalanceBannerCard({required this.balanceAsync});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return balanceAsync.when(
      data: (summary) {
        final sign = summary.netBalanceMl >= 0 ? '+' : '';
        final netText = '$sign${summary.netBalanceMl} mL';

        return Card(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '24-Hour Fluid Balance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Chip(
                      label: Text(
                        'Net: $netText',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: summary.netBalanceMl > 500
                              ? Colors.orange.shade800
                              : theme.colorScheme.primary,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.surface,
                      side: BorderSide(
                        color: summary.netBalanceMl > 500 ? Colors.orange : theme.colorScheme.outline,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryBox(
                        icon: Icons.local_drink_rounded,
                        label: '24h Intake',
                        value: '${summary.totalIntakeMl} mL',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryBox(
                        icon: Icons.opacity_rounded,
                        label: '24h Output',
                        value: '${summary.totalOutputMl} mL',
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Intake: ${summary.totalIntakeMl} mL  •  Output: ${summary.totalOutputMl} mL  •  Net: $netText',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
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
          child: Text('Error loading 24-hour balance: $e'),
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reactive list widget for fluid output history.
class _FluidOutputHistoryList extends ConsumerWidget {
  final Patient patient;

  const _FluidOutputHistoryList({required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(todayFluidOutputLogsStreamProvider(patient.id));
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
              child: Center(child: Text('No fluid output recorded yet.')),
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

            String typeDisplay;
            switch (log.outputType) {
              case 'urine':
                typeDisplay = 'Urine';
                break;
              case 'peritonealDrain':
                typeDisplay = 'PD Drain';
                break;
              case 'ultrafiltration':
                typeDisplay = 'Ultrafiltration';
                break;
              default:
                typeDisplay = log.outputType;
            }

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
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.opacity_rounded,
                        color: theme.colorScheme.secondary,
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
                                  typeDisplay,
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
                              if (log.hematuriaGrade != null) ...[
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(
                                    'Grade ${log.hematuriaGrade}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: log.hematuriaGrade! > 2
                                      ? theme.colorScheme.errorContainer
                                      : theme.colorScheme.surfaceContainerHighest,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ],
                            ],
                          ),
                        ],
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
      error: (e, _) => Text('Error loading output logs: $e'),
    );
  }
}
