import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../fluid/presentation/fluid_output_entry_screen.dart';
import '../data/catheter_repository.dart';
import '../domain/catheter_lifespan_rules.dart';

/// Urine Foley Catheter 14-Day Lifespan Monitor Screen.
///
/// Features automated 14-day countdown engine transitioning through Green (Days 1–10),
/// Amber (Days 11–14), and Red (Days 15+ CAUTI Risk Window) states mandating timely replacement.
class CatheterLifespanScreen extends ConsumerStatefulWidget {
  final Patient patient;

  const CatheterLifespanScreen({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<CatheterLifespanScreen> createState() => _CatheterLifespanScreenState();
}

class _CatheterLifespanScreenState extends ConsumerState<CatheterLifespanScreen> {
  Future<void> _showCatheterEventDialog({required bool isReplacement}) async {
    DateTime selectedDate = DateTime.now();
    CatheterMaterial selectedMaterial = CatheterMaterial.latex14Day;
    int? selectedIntervalHours = 6;
    final customDaysController = TextEditingController(text: '14');
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final dateStr =
                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

            return AlertDialog(
              title: Text(
                isReplacement ? 'Log Catheter Replacement' : 'Record Catheter Insertion',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isReplacement
                          ? 'Retires existing active catheter and starts a fresh monitoring cycle.'
                          : 'Records insertion of indwelling Urine Foley Catheter and starts lifespan tracking.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // 1. Material Dropdown
                    DropdownButtonFormField<CatheterMaterial>(
                      key: const Key('catheter_material_dropdown'),
                      initialValue: selectedMaterial,
                      decoration: InputDecoration(
                        labelText: 'Catheter Material & Lifespan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.science_outlined),
                      ),
                      items: CatheterMaterial.values.map((material) {
                        return DropdownMenuItem<CatheterMaterial>(
                          value: material,
                          child: Text(material.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedMaterial = val;
                          });
                        }
                      },
                    ),
                    if (selectedMaterial == CatheterMaterial.custom) ...[
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('custom_lifespan_days_input'),
                        controller: customDaysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Custom Lifespan (Days)',
                          hintText: 'e.g. 21',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    // 2. Collection Bag Emptying Interval
                    DropdownButtonFormField<int?>(
                      key: const Key('bag_emptying_interval_dropdown'),
                      initialValue: selectedIntervalHours,
                      decoration: InputDecoration(
                        labelText: 'Collection Bag Reminder Interval',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.notifications_active_outlined),
                      ),
                      items: const [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('None / Off'),
                        ),
                        DropdownMenuItem<int?>(
                          value: 4,
                          child: Text('Every 4 Hours'),
                        ),
                        DropdownMenuItem<int?>(
                          value: 6,
                          child: Text('Every 6 Hours'),
                        ),
                        DropdownMenuItem<int?>(
                          value: 8,
                          child: Text('Every 8 Hours'),
                        ),
                      ],
                      onChanged: (val) {
                        setDialogState(() {
                          selectedIntervalHours = val;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    // 3. Insertion / Replacement Date Picker
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Event Date'),
                      subtitle: Text(dateStr),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedDate.hour,
                              selectedDate.minute,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('catheter_notes_input'),
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Clinical Notes (Optional)',
                        hintText: 'e.g., 16 Fr Foley catheter, 10cc balloon',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  key: const Key('confirm_catheter_event_button'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(isReplacement ? 'Confirm Replacement' : 'Confirm Insertion'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(catheterRepositoryProvider);
      final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
      final customDays = selectedMaterial == CatheterMaterial.custom
          ? int.tryParse(customDaysController.text.trim()) ?? 14
          : null;

      if (isReplacement) {
        await repo.recordCatheterReplacement(
          patientId: widget.patient.id,
          replacementDate: selectedDate,
          material: selectedMaterial,
          customLifespanDays: customDays,
          bagEmptyingIntervalHours: selectedIntervalHours,
          notes: notes,
        );
      } else {
        await repo.recordCatheterInsertion(
          patientId: widget.patient.id,
          insertionDate: selectedDate,
          material: selectedMaterial,
          customLifespanDays: customDays,
          bagEmptyingIntervalHours: selectedIntervalHours,
          notes: notes,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isReplacement
                ? 'Catheter replacement recorded. Lifespan cycle reset.'
                : 'Catheter insertion recorded. Lifespan monitoring active.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showOneTapBagEmptiedDialog() async {
    int selectedVolume = 400;
    int selectedGrade = 1;
    final volumeController = TextEditingController(text: '400');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);

            return AlertDialog(
              key: const Key('bag_emptied_dialog'),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.opacity_rounded,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '1-Tap Bag Emptied',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Document evacuated volume and Hematuria Grade in one unified motion.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Evacuation Volume (mL)',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [200, 400, 600, 800, 1000].map((vol) {
                        final isSelected = selectedVolume == vol;
                        return ChoiceChip(
                          key: Key('volume_chip_$vol'),
                          label: Text('$vol mL'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                selectedVolume = vol;
                                volumeController.text = vol.toString();
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('evacuated_volume_input'),
                      controller: volumeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Volume (mL)',
                        suffixText: 'mL',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null && parsed > 0) {
                          setDialogState(() {
                            selectedVolume = parsed;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Hematuria Grade (1 to 4)',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [1, 2, 3, 4].map((g) {
                        final info = HematuriaGradeInfo.fromGrade(g);
                        final isSelected = selectedGrade == g;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: InkWell(
                            key: Key('hematuria_chip_$g'),
                            onTap: () {
                              setDialogState(() {
                                selectedGrade = g;
                              });
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? info.color.withValues(alpha: 0.15)
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? info.color : theme.colorScheme.outlineVariant,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: info.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          info.title,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? theme.colorScheme.onSurface
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          info.description,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 10,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle_rounded, color: info.color, size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  key: const Key('confirm_bag_emptied_button'),
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Confirm Bag Emptied'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(catheterRepositoryProvider);
      final finalVol = int.tryParse(volumeController.text.trim()) ?? selectedVolume;
      try {
        await repo.recordBagEmptied(
          patientId: widget.patient.id,
          volumeMl: finalVol,
          hematuriaGrade: selectedGrade,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bag emptied recorded: $finalVol mL (Grade $selectedGrade). Schedule updated.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error recording bag emptied: $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _navigateToUrineEvacuation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FluidOutputEntryScreen(patient: widget.patient),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCatheterAsync = ref.watch(activeCatheterStreamProvider(widget.patient.id));
    final historyAsync = ref.watch(catheterHistoryStreamProvider(widget.patient.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Urine Foley Catheter Lifespan',
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
              // 1. Active Catheter Lifespan Monitor Section
              activeCatheterAsync.when(
                data: (activeCatheter) {
                  if (activeCatheter == null) {
                    return _NoActiveCatheterCard(
                      onRecordInsertion: () => _showCatheterEventDialog(isReplacement: false),
                    );
                  }

                  final summary = CatheterLifespanRules.evaluateLifespan(
                    insertionDate: activeCatheter.insertionDate,
                    replacementDueDate: activeCatheter.replacementDueDate,
                    material: CatheterMaterial.fromString(activeCatheter.material),
                    customLifespanDays: activeCatheter.lifespanDays,
                    bagEmptyingIntervalHours: activeCatheter.bagEmptyingIntervalHours,
                    lastBagEmptiedAt: activeCatheter.lastBagEmptiedAt,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ActiveCatheterCard(
                        activeCatheter: activeCatheter,
                        summary: summary,
                        onLogReplacement: () => _showCatheterEventDialog(isReplacement: true),
                        onOneTapBagEmptied: _showOneTapBagEmptiedDialog,
                      ),
                      const SizedBox(height: 16),
                      _BagEmptyingStatusCard(
                        summary: summary,
                        onOneTapBagEmptied: _showOneTapBagEmptiedDialog,
                      ),
                      if (summary.isCautiRiskActive) ...[
                        const SizedBox(height: 16),
                        _CautiRiskAlertBanner(summary: summary),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading catheter status: $e'),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Urine Evacuation & Hematuria Grading Shortcut
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.opacity_rounded,
                          color: theme.colorScheme.secondary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Urine Evacuation & Hematuria',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Log drainage output with standardized 4-tier visual hematuria scale.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        key: const Key('record_urine_evacuation_button'),
                        onPressed: _navigateToUrineEvacuation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                        ),
                        child: const Text('Log Output'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Catheter Events History
              Text(
                'Catheter History & Replacements',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              historyAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Center(child: Text('No catheter history recorded.')),
                      ),
                    );
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final insertDateStr =
                          '${event.insertionDate.year}-${event.insertionDate.month.toString().padLeft(2, '0')}-${event.insertionDate.day.toString().padLeft(2, '0')}';
                      final dueDateStr =
                          '${event.replacementDueDate.year}-${event.replacementDueDate.month.toString().padLeft(2, '0')}-${event.replacementDueDate.day.toString().padLeft(2, '0')}';

                      final isActive = event.status == 'active';

                      return Card(
                        elevation: 0,
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isActive ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                            width: isActive ? 1.5 : 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.timer_rounded,
                                  color: isActive
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Inserted: $insertDateStr',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            event.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isActive
                                                  ? theme.colorScheme.onPrimaryContainer
                                                  : theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          backgroundColor: isActive
                                              ? theme.colorScheme.primaryContainer
                                              : theme.colorScheme.surfaceContainerHighest,
                                          padding: EdgeInsets.zero,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Due: $dueDateStr',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (event.notes != null && event.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        event.notes!,
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
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
                error: (e, _) => Text('Error loading catheter history: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card displayed when no active catheter exists.
class _NoActiveCatheterCard extends StatelessWidget {
  final VoidCallback onRecordInsertion;

  const _NoActiveCatheterCard({required this.onRecordInsertion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No Active Urine Foley Catheter',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Record the catheter insertion date to initiate automated 14-day lifespan tracking and CAUTI risk prevention.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('record_catheter_insertion_button'),
                onPressed: onRecordInsertion,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text(
                  'Record Catheter Insertion',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Active catheter card showing progress gauge, material, and state transitions.
class _ActiveCatheterCard extends StatelessWidget {
  final CatheterEvent activeCatheter;
  final CatheterLifespanSummary summary;
  final VoidCallback onLogReplacement;
  final VoidCallback onOneTapBagEmptied;

  const _ActiveCatheterCard({
    required this.activeCatheter,
    required this.summary,
    required this.onLogReplacement,
    required this.onOneTapBagEmptied,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final insertDateStr =
        '${activeCatheter.insertionDate.year}-${activeCatheter.insertionDate.month.toString().padLeft(2, '0')}-${activeCatheter.insertionDate.day.toString().padLeft(2, '0')}';
    final dueDateStr =
        '${activeCatheter.replacementDueDate.year}-${activeCatheter.replacementDueDate.month.toString().padLeft(2, '0')}-${activeCatheter.replacementDueDate.day.toString().padLeft(2, '0')}';

    final progressRatio = (summary.dayOfCycle / summary.totalLifespanDays).clamp(0.0, 1.0);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: summary.statusColor,
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: summary.statusBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer_rounded,
                        color: summary.statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Day ${summary.dayOfCycle} of ${summary.totalLifespanDays}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: summary.statusColor,
                          ),
                        ),
                        Text(
                          'Indwelling Foley Catheter • ${summary.material.displayName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    summary.statusTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: summary.statusColor,
                    ),
                  ),
                  backgroundColor: summary.statusBackgroundColor,
                  side: BorderSide(color: summary.statusColor, width: 1.2),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressRatio,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(summary.statusColor),
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              summary.statusDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.3,
              ),
            ),

            const Divider(height: 24),

            // Date Metrics
            Row(
              children: [
                Expanded(
                  child: _CatheterMetric(
                    label: 'Insertion Date',
                    value: insertDateStr,
                    icon: Icons.login_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CatheterMetric(
                    label: 'Replacement Due',
                    value: dueDateStr,
                    icon: Icons.event_available_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _CatheterMetric(
              label: 'Catheter Material & Lifespan',
              value: '${summary.material.displayName} (${summary.totalLifespanDays} Days)',
              icon: Icons.science_rounded,
            ),

            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      key: const Key('one_tap_bag_emptied_button'),
                      onPressed: onOneTapBagEmptied,
                      icon: const Icon(Icons.opacity_rounded),
                      label: const Text(
                        '1-Tap Bag Emptied',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      key: const Key('log_catheter_replacement_button'),
                      onPressed: onLogReplacement,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: const Text(
                        'Log Replacement',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card displaying Collection Bag Emptying schedule and status.
class _BagEmptyingStatusCard extends StatelessWidget {
  final CatheterLifespanSummary summary;
  final VoidCallback onOneTapBagEmptied;

  const _BagEmptyingStatusCard({
    required this.summary,
    required this.onOneTapBagEmptied,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intervalHours = summary.bagEmptyingIntervalHours;

    final intervalStr = intervalHours != null ? 'Every $intervalHours hours' : 'Manual / On Demand';
    String dueStatusStr;
    Color statusColor;

    if (intervalHours == null) {
      dueStatusStr = 'No automated interval scheduled.';
      statusColor = theme.colorScheme.onSurfaceVariant;
    } else if (summary.isBagEmptyingDue) {
      dueStatusStr = 'Bag Emptying Due Now!';
      statusColor = theme.colorScheme.error;
    } else {
      final hours = (summary.minutesUntilNextBagEmptying ?? 0) ~/ 60;
      final mins = (summary.minutesUntilNextBagEmptying ?? 0) % 60;
      dueStatusStr = 'Next emptying in ${hours}h ${mins}m';
      statusColor = theme.colorScheme.primary;
    }

    String lastEmptiedStr = 'None recorded yet';
    if (summary.lastBagEmptiedAt != null) {
      final dt = summary.lastBagEmptiedAt!.toLocal();
      lastEmptiedStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Card(
      key: const Key('bag_emptying_status_card'),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: summary.isBagEmptyingDue ? theme.colorScheme.error : theme.colorScheme.outlineVariant,
          width: summary.isBagEmptyingDue ? 1.8 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: summary.isBagEmptyingDue
                        ? theme.colorScheme.errorContainer
                        : theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.notifications_active_rounded,
                    color: summary.isBagEmptyingDue
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collection Bag Reminders',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        intervalStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    summary.isBagEmptyingDue ? 'DUE NOW' : 'SCHEDULED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: summary.isBagEmptyingDue
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.primary,
                    ),
                  ),
                  backgroundColor: summary.isBagEmptyingDue
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dueStatusStr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last: $lastEmptiedStr',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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

/// Alert banner displayed during CAUTI Risk Window.
class _CautiRiskAlertBanner extends StatelessWidget {
  final CatheterLifespanSummary summary;

  const _CautiRiskAlertBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('cauti_risk_window_alert'),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error,
          width: 2.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: theme.colorScheme.onErrorContainer,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAUTI Risk Window Active',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Immediate replacement required to avoid CAUTI. Catheter has exceeded the ${summary.totalLifespanDays}-day indwelling safety lifespan by ${summary.daysOverdue} day${summary.daysOverdue == 1 ? '' : 's'}. High risk of Catheter-Associated Urinary Tract Infection.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    height: 1.3,
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

class _CatheterMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _CatheterMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
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
