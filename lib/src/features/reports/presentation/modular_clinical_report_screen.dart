import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/database/app_database.dart';
import '../../profile/domain/clinical_condition.dart';
import '../data/clinical_report_repository.dart';
import '../domain/clinical_report_config.dart';
import '../domain/clinical_report_data.dart';
import '../domain/clinical_report_pdf_generator.dart';
import '../../clinical_terms_guide/presentation/clinical_info_trigger.dart';
import 'clinical_report_preview_screen.dart';

/// Screen allowing clinicians and patients to configure modular parameters,
/// select observation date windows, toggle clinical sections, and generate/export PDF reports.
class ModularClinicalReportScreen extends ConsumerStatefulWidget {
  final Patient patient;

  const ModularClinicalReportScreen({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<ModularClinicalReportScreen> createState() => _ModularClinicalReportScreenState();
}

class _ModularClinicalReportScreenState extends ConsumerState<ModularClinicalReportScreen> {
  ReportDateWindow _dateWindow = ReportDateWindow.last14Days;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  late Set<ClinicalReportModule> _enabledModules;
  bool _isProcessing = false;

  final ClinicalReportPdfGenerator _pdfGenerator = ClinicalReportPdfGenerator();

  @override
  void initState() {
    super.initState();
    final defaultCfg = ModularReportConfig.defaultConfig();
    _enabledModules = Set<ClinicalReportModule>.from(defaultCfg.enabledModules);
    final now = DateTime.now();
    _customStartDate = now.subtract(const Duration(days: 14));
    _customEndDate = now;
  }

  void _selectWindow(ReportDateWindow window) {
    setState(() {
      _dateWindow = window;
    });
  }

  void _toggleModule(ClinicalReportModule module, bool value) {
    setState(() {
      if (value) {
        _enabledModules.add(module);
      } else {
        _enabledModules.remove(module);
      }
    });
  }

  void _selectAllModules(bool selectAll) {
    setState(() {
      if (selectAll) {
        _enabledModules.addAll(ClinicalReportModule.values);
      } else {
        _enabledModules.clear();
      }
    });
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(
        start: _customStartDate ?? now.subtract(const Duration(days: 14)),
        end: _customEndDate ?? now,
      ),
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  Future<ClinicalReportData?> _compileReportData() async {
    if (_enabledModules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one clinical module to include in the report.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return null;
    }

    setState(() => _isProcessing = true);

    try {
      final config = ModularReportConfig(
        dateWindow: _dateWindow,
        customStartDate: _customStartDate,
        customEndDate: _customEndDate,
        enabledModules: _enabledModules,
      );

      final repository = ref.read(clinicalReportRepositoryProvider);
      final reportData = await repository.compileReportData(
        patientId: widget.patient.id,
        config: config,
      );
      return reportData;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error preparing clinical report: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _generateAndPreview() async {
    final reportData = await _compileReportData();
    if (reportData == null || !mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClinicalReportPreviewScreen(
          reportData: reportData,
          pdfGenerator: _pdfGenerator,
        ),
      ),
    );
  }

  Future<void> _shareModularReport() async {
    final reportData = await _compileReportData();
    if (reportData == null || !mounted) return;

    try {
      setState(() => _isProcessing = true);
      final pdfBytes = await _pdfGenerator.generatePdfBytes(reportData);
      final filename = ClinicalReportPdfGenerator.getReportFilename(widget.patient);
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modular Clinical Report shared successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget? _getModuleInfoTrigger(ClinicalReportModule module) {
    switch (module) {
      case ClinicalReportModule.pairedAntiHypertensiveBp:
        return const ClinicalInfoTrigger(
          key: Key('report_module_info_paired_bp'),
          termId: 'paired_bp',
          iconSize: 18,
        );
      case ClinicalReportModule.dualFluidBalance:
        return const ClinicalInfoTrigger(
          key: Key('report_module_info_dual_fluid'),
          termId: 'dialytic_fluid_balance',
          iconSize: 18,
        );
      case ClinicalReportModule.accessInspectionAndCatheterHistory:
        return const ClinicalInfoTrigger(
          key: Key('report_module_info_catheter'),
          termId: 'cauti_risk_window',
          iconSize: 18,
        );
      case ClinicalReportModule.weightTrends:
        return const ClinicalInfoTrigger(
          key: Key('report_module_info_weight_trends'),
          termId: 'idwg',
          iconSize: 18,
        );
      case ClinicalReportModule.medicationRegimenAndAdherence:
        return const ClinicalInfoTrigger(
          key: Key('report_module_info_medication_regimen'),
          termId: 'phosphate_binder',
          iconSize: 18,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final condition = ClinicalCondition.fromString(widget.patient.diagnosis);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modular Clinical Report',
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
              // 1. Patient Profile Summary Card
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
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        child: const Icon(Icons.person_outline),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.patient.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              condition?.displayName ?? widget.patient.diagnosis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.patient.isCaregiverMirror)
                        Chip(
                          label: const Text('Caregiver Mirror', style: TextStyle(fontSize: 11)),
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 2. Date Window Selection
              Text(
                'Observation Date Window',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    key: const Key('report_date_window_7d'),
                    label: const Text('7 Days'),
                    selected: _dateWindow == ReportDateWindow.last7Days,
                    onSelected: (selected) {
                      if (selected) _selectWindow(ReportDateWindow.last7Days);
                    },
                  ),
                  ChoiceChip(
                    key: const Key('report_date_window_14d'),
                    label: const Text('14 Days'),
                    selected: _dateWindow == ReportDateWindow.last14Days,
                    onSelected: (selected) {
                      if (selected) _selectWindow(ReportDateWindow.last14Days);
                    },
                  ),
                  ChoiceChip(
                    key: const Key('report_date_window_30d'),
                    label: const Text('30 Days'),
                    selected: _dateWindow == ReportDateWindow.last30Days,
                    onSelected: (selected) {
                      if (selected) _selectWindow(ReportDateWindow.last30Days);
                    },
                  ),
                  ChoiceChip(
                    key: const Key('report_date_window_custom'),
                    label: const Text('Custom'),
                    selected: _dateWindow == ReportDateWindow.custom,
                    onSelected: (selected) {
                      if (selected) _selectWindow(ReportDateWindow.custom);
                    },
                  ),
                ],
              ),

              // Custom Date Boundaries
              if (_dateWindow == ReportDateWindow.custom) ...[
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From: ${_formatDate(_customStartDate)}',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'To: ${_formatDate(_customEndDate)}',
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              key: const Key('custom_start_date_button'),
                              icon: const Icon(Icons.date_range_outlined, size: 16),
                              label: const Text('Select Range'),
                              onPressed: () => _pickCustomDateRange(context),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              key: const Key('custom_end_date_button'),
                              icon: const Icon(Icons.edit_calendar_outlined, size: 20),
                              tooltip: 'Modify End Date',
                              onPressed: () => _pickCustomDateRange(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // 3. Clinical Modules Checklist
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Clinical Modules Checklist',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const ClinicalInfoTrigger(
                        key: Key('report_modules_info_trigger'),
                        termId: 'modular_clinical_report',
                        iconSize: 18,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _selectAllModules(true),
                        child: const Text('Select All'),
                      ),
                      TextButton(
                        onPressed: () => _selectAllModules(false),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: ClinicalReportModule.values.map((module) {
                    final isEnabled = _enabledModules.contains(module);
                    return CheckboxListTile(
                      key: module.widgetKey,
                      value: isEnabled,
                      title: Text(
                        module.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        module.description,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      secondary: _getModuleInfoTrigger(module),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        _toggleModule(module, val ?? false);
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // 4. Action Buttons
              FilledButton.icon(
                key: const Key('preview_report_button'),
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: Text(_isProcessing ? 'Compiling Report...' : 'Generate & Preview PDF'),
                onPressed: _isProcessing ? null : _generateAndPreview,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                key: const Key('export_share_button'),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share Modular Clinical Report'),
                onPressed: _isProcessing ? null : _shareModularReport,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
