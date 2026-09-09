import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../data/dialysis_session_repository.dart';

/// Screen allowing Peritoneal Dialysis patients to record dialysate inflow and
/// drain volumes per exchange, track dialysate effluent clarity, and view a
/// longitudinal exchange timeline per CONTEXT.md and User Stories 17 & 33.
class PeritonealExchangeScreen extends ConsumerStatefulWidget {
  final Patient patient;

  const PeritonealExchangeScreen({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<PeritonealExchangeScreen> createState() => _PeritonealExchangeScreenState();
}

class _PeritonealExchangeScreenState extends ConsumerState<PeritonealExchangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inflowController = TextEditingController(text: '2000');
  final _drainController = TextEditingController();
  final _notesController = TextEditingController();

  String _clarity = 'Clear';
  bool _isSubmitting = false;

  static const List<String> _clarityOptions = [
    'Clear',
    'Slightly Hazy',
    'Cloudy (Possible Peritonitis)',
    'Fibrin Strands',
    'Bloody',
  ];

  @override
  void dispose() {
    _inflowController.dispose();
    _drainController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _currentInflow => int.tryParse(_inflowController.text.trim());
  int? get _currentDrain => int.tryParse(_drainController.text.trim());
  int? get _currentNetUf {
    final inflow = _currentInflow;
    final drain = _currentDrain;
    if (inflow != null && drain != null) {
      return drain - inflow;
    }
    return null;
  }

  Future<void> _submitExchange() async {
    if (!_formKey.currentState!.validate()) return;
    final inflow = _currentInflow;
    final drain = _currentDrain;
    if (inflow == null || drain == null) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(dialysisSessionRepositoryProvider);
      await repo.recordPeritonealExchange(
        patientId: widget.patient.id,
        inflowVolumeMl: inflow,
        drainVolumeMl: drain,
        clarity: _clarity,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        recordedAt: DateTime.now().toUtc(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peritoneal exchange recorded successfully!'),
            backgroundColor: Colors.teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _drainController.clear();
        _notesController.clear();
        setState(() {
          _clarity = 'Clear';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record exchange: $e'),
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
    final sessionsAsync = ref.watch(dialysisSessionsStreamProvider(widget.patient.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peritoneal Dialysis Exchange'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Overview Header Card with 24h PD Ultrafiltration
            sessionsAsync.when(
              data: (sessions) {
                final pdSessions = sessions.where((s) => s.sessionType == 'peritoneal').toList();
                final now = DateTime.now();
                final dayStart = DateTime(now.year, now.month, now.day);
                final todayUf = pdSessions
                    .where((s) => s.startedAt.isAfter(dayStart))
                    .fold<int>(0, (sum, s) => sum + (s.actualFluidRemovedMl ?? 0));

                return _buildHeaderCard(theme, pdSessions.length, todayUf);
              },
              loading: () => _buildHeaderCard(theme, 0, 0),
              error: (_, _) => _buildHeaderCard(theme, 0, 0),
            ),

            const SizedBox(height: 16),

            // 2. New Exchange Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Record New Exchange',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Inflow Volume Field
                      TextFormField(
                        key: const Key('inflow_volume_field'),
                        controller: _inflowController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Dialysate Inflow Volume',
                          suffixText: 'mL',
                          prefixIcon: Icon(Icons.input_rounded),
                          border: OutlineInputBorder(),
                          helperText: 'Standard bag volume (e.g. 1500, 2000, 2500 mL)',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter inflow volume in mL';
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid positive volume in mL';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),

                      // Inflow Quick Preset Chips
                      Wrap(
                        spacing: 8,
                        children: [1500, 2000, 2500].map((vol) {
                          return ActionChip(
                            label: Text('$vol mL'),
                            onPressed: () {
                              setState(() {
                                _inflowController.text = vol.toString();
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Drain Volume Field
                      TextFormField(
                        key: const Key('drain_volume_field'),
                        controller: _drainController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Effluent Drain Volume',
                          suffixText: 'mL',
                          prefixIcon: Icon(Icons.output_rounded),
                          border: OutlineInputBorder(),
                          helperText: 'Volume drained from peritoneal cavity',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter drain volume in mL';
                          }
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Enter a valid volume in mL';
                          }
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),

                      // Drain Quick Preset Chips
                      Wrap(
                        spacing: 8,
                        children: [1800, 2000, 2200, 2500].map((vol) {
                          return ActionChip(
                            label: Text('$vol mL'),
                            onPressed: () {
                              setState(() {
                                _drainController.text = vol.toString();
                              });
                            },
                          );
                        }).toList(),
                      ),

                      // Live Net Ultrafiltration Badge
                      if (_currentNetUf != null) ...[
                        const SizedBox(height: 16),
                        _buildNetUfIndicator(theme, _currentNetUf!),
                      ],

                      const SizedBox(height: 16),

                      // Effluent Clarity Dropdown
                      DropdownButtonFormField<String>(
                        key: const Key('pd_clarity_dropdown'),
                        initialValue: _clarity,
                        decoration: const InputDecoration(
                          labelText: 'Effluent Clarity & Appearance',
                          prefixIcon: Icon(Icons.remove_red_eye_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: _clarityOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(opt),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _clarity = val);
                          }
                        },
                      ),

                      // Cloudy Effluent Peritonitis Warning Banner
                      if (_clarity.contains('Cloudy') || _clarity.contains('Hazy')) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.colorScheme.error),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Cloudy effluent is a critical sign of Peritonitis. Preserve the bag and notify your nephrologist immediately.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Notes / Dwell Time
                      TextFormField(
                        key: const Key('pd_notes_field'),
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes / Dwell Time (Optional)',
                          hintText: 'e.g., 4-hour dwell, 2.5% dextrose',
                          prefixIcon: Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton.icon(
                        key: const Key('save_pd_exchange_button'),
                        onPressed: _isSubmitting ? null : _submitExchange,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_rounded),
                        label: const Text('Record Peritoneal Exchange'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Longitudinal Exchanges Timeline Section
            Text(
              'Exchange History Timeline',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            sessionsAsync.when(
              data: (sessions) {
                final pdSessions = sessions.where((s) => s.sessionType == 'peritoneal').toList();
                if (pdSessions.isEmpty) {
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No peritoneal exchanges recorded yet.\nRecord your first exchange above to track daily ultrafiltration.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pdSessions.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final session = pdSessions[index];
                    return _buildExchangeTimelineCard(context, theme, session);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading exchange history: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(ThemeData theme, int totalCount, int todayUf) {
    return Card(
      elevation: 2,
      color: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  child: const Icon(Icons.sync_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patient.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Peritoneal Dialysis Exchange Log',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeaderMetric(theme, 'Today\'s Ultrafiltration', '+$todayUf mL', Icons.opacity_rounded, Colors.teal),
                _buildHeaderMetric(theme, 'Total Exchanges', '$totalCount', Icons.history_rounded, theme.colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderMetric(ThemeData theme, String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildNetUfIndicator(ThemeData theme, int netUf) {
    final isPositive = netUf > 0;
    final isZero = netUf == 0;
    final color = isPositive
        ? Colors.teal
        : isZero
            ? Colors.blueGrey
            : Colors.amber.shade800;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.check_circle_outline_rounded : (isZero ? Icons.info_outline_rounded : Icons.warning_amber_rounded),
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPositive
                      ? 'Net Peritoneal Ultrafiltration: +$netUf mL'
                      : isZero
                          ? 'Net Fluid Balance: 0 mL (Even)'
                          : 'Fluid Retention: $netUf mL',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  isPositive
                      ? 'Contributes directly to 24-hour fluid output calculation.'
                      : 'Retention: Drain volume is less than dialysate inflow volume.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeTimelineCard(BuildContext context, ThemeData theme, DialysisSession session) {
    final timeStr = _formatTimestamp(session.startedAt);
    final notes = session.notes ?? '';
    final uf = session.actualFluidRemovedMl ?? 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync_alt_rounded, size: 20, color: Colors.teal.shade700),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: uf > 0 ? Colors.teal.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: uf > 0 ? Colors.teal : Colors.grey.shade400),
                  ),
                  child: Text(
                    uf > 0 ? '+$uf mL UF' : '$uf mL UF',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: uf > 0 ? Colors.teal.shade800 : Colors.grey.shade800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onSelected: (val) async {
                    if (val == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Exchange Entry?'),
                          content: const Text('Are you sure you want to remove this peritoneal exchange entry?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        final repo = ref.read(dialysisSessionRepositoryProvider);
                        await repo.deleteDialysisSession(session.id);
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Delete Entry', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                notes,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade800, height: 1.3),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}
