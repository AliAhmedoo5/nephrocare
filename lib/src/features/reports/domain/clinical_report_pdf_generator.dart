import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/database/app_database.dart';
import '../../catheter/domain/catheter_lifespan_rules.dart';
import '../../profile/domain/clinical_condition.dart';
import 'clinical_report_config.dart';
import 'clinical_report_data.dart';

/// Client-side PDF generation engine compiling modular clinical datasets
/// into publication-quality, multi-page PDF documents.
class ClinicalReportPdfGenerator {
  const ClinicalReportPdfGenerator();

  /// Generates the canonical filename for a Modular Clinical Report document.
  static String getReportFilename(Patient patient) {
    return 'nephrocare_clinical_report_${patient.name.replaceAll(' ', '_')}.pdf';
  }

  /// Builds a [pw.Document] containing formatted clinical modules.
  pw.Document buildPdfDocument(
    ClinicalReportData reportData, {
    PdfPageFormat format = PdfPageFormat.a4,
    bool compress = true,
  }) {
    final doc = pw.Document(
      version: PdfVersion.pdf_1_5,
      compress: compress,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPageHeader(reportData, context),
        footer: (context) => _buildPageFooter(context),
        build: (context) => [
          _buildReportTitleBanner(reportData),
          pw.SizedBox(height: 14),

          // 1. Patient Demographics & Diagnosis Module
          if (reportData.config.isModuleEnabled(ClinicalReportModule.patientDemographicsAndDiagnosis)) ...[
            _buildSectionHeader('1. Patient Demographics & Clinical Condition'),
            pw.SizedBox(height: 6),
            _buildDemographicsSection(reportData.patient),
            pw.SizedBox(height: 14),
          ],

          // 2. Weight Trends Module
          if (reportData.config.isModuleEnabled(ClinicalReportModule.weightTrends)) ...[
            _buildSectionHeader('2. Weight Trends (Pre/Post/Prescribed Dry Weight)'),
            pw.SizedBox(height: 6),
            _buildWeightTrendsSection(reportData),
            pw.SizedBox(height: 14),
          ],

          // 3. Blood Pressure & Pulse Module
          if (reportData.config.isModuleEnabled(ClinicalReportModule.bloodPressureAndPulse)) ...[
            _buildSectionHeader('3. Blood Pressure & Hemodynamic Trends'),
            pw.SizedBox(height: 6),
            _buildBloodPressureSection(reportData),
            pw.SizedBox(height: 14),
          ],

          // 4. 24-Hour Fluid Balance & Intake Logs Module
          if (reportData.config.isModuleEnabled(ClinicalReportModule.fluidBalanceAndIntake)) ...[
            _buildSectionHeader('4. 24-Hour Fluid Balance & Intake Logs'),
            pw.SizedBox(height: 6),
            _buildFluidBalanceSection(reportData),
            pw.SizedBox(height: 14),
          ],

          // 5. Access Inspection & Catheter Lifespan History Module
          if (reportData.config.isModuleEnabled(ClinicalReportModule.accessInspectionAndCatheterHistory)) ...[
            _buildSectionHeader('5. Access Inspection & Catheter Lifespan History'),
            pw.SizedBox(height: 6),
            _buildAccessAndCatheterSection(reportData),
            pw.SizedBox(height: 14),
          ],
        ],
      ),
    );

    return doc;
  }

  /// Compiles the report document directly into a binary PDF [Uint8List] byte stream.
  Future<Uint8List> generatePdfBytes(
    ClinicalReportData reportData, {
    PdfPageFormat format = PdfPageFormat.a4,
    bool compress = true,
  }) async {
    final doc = buildPdfDocument(reportData, format: format, compress: compress);
    return doc.save();
  }

  // --- Header & Footer Builders ---

  pw.Widget _buildPageHeader(ClinicalReportData reportData, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue900, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'NephroCare Modular Clinical Report',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.Text(
            'Patient: ${reportData.patient.name} | Generated: ${_formatDate(reportData.generatedAt)}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Confidential Clinical Consultation Document - Generated Client-Side via NephroCare',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportTitleBanner(ClinicalReportData reportData) {
    final startStr = _formatDate(reportData.dateRange.start);
    final endStr = _formatDate(reportData.dateRange.end);
    final windowTitle = '${reportData.config.dateWindow.displayName} ($startStr to $endStr)';

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.blue200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Modular Clinical Report',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              if (reportData.patient.isCaregiverMirror)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.purple100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    border: pw.Border.all(color: PdfColors.purple300),
                  ),
                  child: pw.Text(
                    'Caregiver Mirror Profile',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Observation Window: $windowTitle',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
      ),
    );
  }

  // --- Clinical Section 1: Demographics ---

  pw.Widget _buildDemographicsSection(Patient patient) {
    final condition = ClinicalCondition.fromString(patient.diagnosis);
    final accessLocation = AccessLocation.fromString(patient.fistulaArmLocation);
    final isFistulaArmActive = accessLocation != null && accessLocation.isArm;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              children: [
                _buildInfoCell('Patient Full Name', patient.name),
                _buildInfoCell('Clinical Diagnosis', condition?.displayName ?? patient.diagnosis),
              ],
            ),
            pw.TableRow(
              children: [
                _buildInfoCell(
                  'Prescribed Dry Weight',
                  patient.prescribedDryWeightKg != null ? '${patient.prescribedDryWeightKg} kg' : 'Not set',
                ),
                _buildInfoCell(
                  'Daily Fluid Allowance',
                  patient.dailyFluidAllowanceMl != null ? '${patient.dailyFluidAllowanceMl} mL / 24h' : 'Not set',
                ),
              ],
            ),
            pw.TableRow(
              children: [
                _buildInfoCell(
                  'Vascular Access Type',
                  patient.vascularAccessType ?? 'None',
                ),
                _buildInfoCell(
                  'Fistula Arm Location',
                  accessLocation?.displayName ?? patient.fistulaArmLocation ?? 'None',
                ),
              ],
            ),
          ],
        ),
        if (isFistulaArmActive) ...[
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: PdfColors.red400),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'Fistula Arm Safety Flag Active: ',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red900),
                ),
                pw.Expanded(
                  child: pw.Text(
                    '${accessLocation.displayName} bearing vascular access. Prohibited for blood pressure cuffs, blood draws, and IV placement.',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.red800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- Clinical Section 2: Weight Trends ---

  pw.Widget _buildWeightTrendsSection(ClinicalReportData reportData) {
    final sessions = reportData.dialysisSessions;
    if (sessions.isEmpty) {
      return _buildEmptyStateBox('No hemodialysis sessions recorded in this observation date window.');
    }

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      cellAlignment: pw.Alignment.centerLeft,
      headers: [
        'Session Date',
        'Pre-Weight',
        'Post-Weight',
        'IDWG',
        'UF Goal',
        'Actual Removed',
        'Dry Wt Diff',
        'Symptoms / Notes',
      ],
      data: sessions.map((s) {
        final idwg = s.calculatedInterdialyticWeightGainKg != null ? '${s.calculatedInterdialyticWeightGainKg} kg' : '-';
        final ufGoal = s.calculatedUltrafiltrationGoalMl != null ? '${s.calculatedUltrafiltrationGoalMl} mL' : '-';
        final removed = s.actualFluidRemovedMl != null ? '${s.actualFluidRemovedMl} mL' : '-';
        final diff = s.calculatedPostWeightDifferenceKg != null
            ? '${s.calculatedPostWeightDifferenceKg! >= 0 ? '+' : ''}${s.calculatedPostWeightDifferenceKg} kg'
            : '-';
        final symptomsOrNotes = [
          if (s.symptoms != null && s.symptoms!.isNotEmpty) 'Symptoms: ${s.symptoms}',
          if (s.notes != null && s.notes!.isNotEmpty) s.notes!,
        ].join(' | ');

        return [
          _formatDateTime(s.startedAt),
          s.preWeightKg != null ? '${s.preWeightKg} kg' : '-',
          s.postWeightKg != null ? '${s.postWeightKg} kg' : '-',
          idwg,
          ufGoal,
          removed,
          diff,
          symptomsOrNotes.isNotEmpty ? symptomsOrNotes : 'None',
        ];
      }).toList(),
    );
  }

  // --- Clinical Section 3: Blood Pressure & Pulse ---

  pw.Widget _buildBloodPressureSection(ClinicalReportData reportData) {
    final logs = reportData.bloodPressureLogs;
    if (logs.isEmpty) {
      return _buildEmptyStateBox('No blood pressure readings recorded in this observation date window.');
    }

    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      cellAlignment: pw.Alignment.centerLeft,
      headers: [
        'Recorded Date / Time',
        'Blood Pressure (mmHg)',
        'Pulse (bpm)',
        'Arm Used',
        'Fistula Arm Safety Flag',
      ],
      data: logs.map((bp) {
        final arm = AccessLocation.fromString(bp.armUsed)?.displayName ?? bp.armUsed;
        final safetyStatus = bp.isSafeArm ? 'Safe Arm (Compliant)' : 'Safety Breach Flagged';
        return [
          _formatDateTime(bp.recordedAt),
          '${bp.systolic} / ${bp.diastolic} mmHg',
          '${bp.pulse} bpm',
          arm,
          safetyStatus,
        ];
      }).toList(),
    );
  }

  // --- Clinical Section 4: 24-Hour Fluid Balance & Intake ---

  pw.Widget _buildFluidBalanceSection(ClinicalReportData reportData) {
    final intakes = reportData.fluidIntakeLogs;
    final outputs = reportData.fluidOutputLogs;
    final summary = reportData.fluidBalanceSummary;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (summary != null) ...[
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol('Daily Fluid Allowance', '${summary.dailyFluidAllowanceMl} mL'),
                _buildMetricCol('Total 24h Intake', '${summary.totalIntakeMl} mL'),
                _buildMetricCol('Total 24h Output', '${summary.totalOutputMl} mL'),
                _buildMetricCol(
                  '24h Net Fluid Balance',
                  '${summary.netBalanceMl >= 0 ? '+' : ''}${summary.netBalanceMl} mL',
                  isHighlighted: true,
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        pw.Text('Recent Fluid Intake Logs:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        if (intakes.isEmpty)
          _buildEmptyStateBox('No fluid intake logs recorded in this window.')
        else
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Time', 'Beverage / Fluid', 'Volume (mL)', 'Phosphate Binder Taken'],
            data: intakes.map((i) {
              return [
                _formatDateTime(i.recordedAt),
                i.beverageType,
                '${i.volumeMl} mL',
                i.phosphateBinderTaken ? 'Yes (Sequestered)' : 'No',
              ];
            }).toList(),
          ),
        pw.SizedBox(height: 8),
        pw.Text('Recent Fluid Output Logs:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        if (outputs.isEmpty)
          _buildEmptyStateBox('No fluid output logs recorded in this window.')
        else
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Time', 'Output Type', 'Volume (mL)', 'Hematuria Grade'],
            data: outputs.map((o) {
              String hematuriaText = '-';
              if (o.hematuriaGrade != null) {
                try {
                  hematuriaText = HematuriaGradeInfo.fromGrade(o.hematuriaGrade!).title;
                } catch (_) {
                  hematuriaText = 'Grade ${o.hematuriaGrade}';
                }
              }
              return [
                _formatDateTime(o.recordedAt),
                o.outputType,
                '${o.volumeMl} mL',
                hematuriaText,
              ];
            }).toList(),
          ),
      ],
    );
  }

  // --- Clinical Section 5: Access Inspection & Catheter Lifespan ---

  pw.Widget _buildAccessAndCatheterSection(ClinicalReportData reportData) {
    final inspections = reportData.accessInspections;
    final catheterEvents = reportData.catheterEvents;
    final catheterSummary = reportData.catheterLifespanSummary;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (catheterSummary != null) ...[
          _buildCatheterLifespanBanner(catheterSummary),
          pw.SizedBox(height: 8),
        ],
        pw.Text('Vascular Access Inspections:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        if (inspections.isEmpty)
          _buildEmptyStateBox('No access inspections recorded in this window.')
        else
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Time', 'Access Type', 'Location', 'Thrill / Bruit', 'Infection Findings', 'Notes'],
            data: inspections.map((ins) {
              final thrillBruit = [
                if (ins.thrillPresent != null) 'Thrill: ${ins.thrillPresent! ? "Present" : "Absent"}',
                if (ins.bruitPresent != null) 'Bruit: ${ins.bruitPresent! ? "Present" : "Absent"}',
              ].join(', ');

              final infectionFindings = [
                if (ins.rednessPresent == true) 'Redness',
                if (ins.swellingPresent == true) 'Swelling',
                if (ins.dischargePresent == true) 'Discharge',
                if (ins.painPresent == true) 'Pain',
              ];

              return [
                _formatDateTime(ins.recordedAt),
                ins.accessType,
                ins.anatomicalLocation,
                thrillBruit.isNotEmpty ? thrillBruit : '-',
                infectionFindings.isNotEmpty ? infectionFindings.join(', ') : 'None (Clear)',
                ins.notes ?? '-',
              ];
            }).toList(),
          ),
        pw.SizedBox(height: 8),
        pw.Text('Catheter Lifespan History Events:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        if (catheterEvents.isEmpty)
          _buildEmptyStateBox('No catheter events recorded in this window.')
        else
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Insertion Date', 'Due Date', 'Catheter Type', 'Status', 'Notes'],
            data: catheterEvents.map((c) {
              return [
                _formatDate(c.insertionDate),
                _formatDate(c.replacementDueDate),
                c.catheterType,
                c.status.toUpperCase(),
                c.notes ?? '-',
              ];
            }).toList(),
          ),
      ],
    );
  }

  // --- Helper Widgets & Formatters ---

  pw.Widget _buildCatheterLifespanBanner(CatheterLifespanSummary summary) {
    PdfColor bgColor;
    PdfColor borderColor;
    PdfColor textColor;
    String statusMessage;

    switch (summary.status) {
      case CatheterLifespanStatus.green:
        bgColor = PdfColors.green50;
        borderColor = PdfColors.green400;
        textColor = PdfColors.green900;
        statusMessage = '${summary.daysRemaining} days remaining in 14-day lifespan cycle';
        break;
      case CatheterLifespanStatus.amber:
        bgColor = PdfColors.amber50;
        borderColor = PdfColors.amber500;
        textColor = PdfColors.amber900;
        statusMessage = 'REPLACEMENT APPROACHING (${summary.daysRemaining}d remaining before 14-day limit)';
        break;
      case CatheterLifespanStatus.red:
        bgColor = PdfColors.red50;
        borderColor = PdfColors.red500;
        textColor = PdfColors.red900;
        statusMessage = 'CAUTI RISK WINDOW ACTIVE (+${summary.daysOverdue}d overdue)';
        break;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Urine Foley Catheter Lifespan: Day ${summary.dayOfCycle} of 14',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900),
              ),
              pw.Text(
                statusMessage,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          if (summary.isCautiRiskActive) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Clinical Alert: Indwelling Foley catheter has exceeded the mandatory 14-day lifespan cycle. Immediate replacement required to avoid catheter-associated urinary tract infection.',
              style: pw.TextStyle(fontSize: 7.5, color: textColor),
            ),
          ] else if (summary.status == CatheterLifespanStatus.amber) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Clinical Notice: Mandatory catheter replacement approaching. Prepare for catheter exchange within ${summary.daysRemaining} day(s).',
              style: pw.TextStyle(fontSize: 7.5, color: textColor),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildInfoCell(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _buildMetricCol(String label, String value, {bool isHighlighted = false}) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: isHighlighted ? PdfColors.blue900 : PdfColors.black,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildEmptyStateBox(String message) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        message,
        style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateTime(DateTime dt) {
    final date = _formatDate(dt);
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$date $h:$min';
  }
}
