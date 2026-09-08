import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../domain/clinical_report_data.dart';
import '../domain/clinical_report_pdf_generator.dart';

/// Screen providing on-screen interactive PDF document preview and OS export capabilities.
class ClinicalReportPreviewScreen extends StatelessWidget {
  final ClinicalReportData reportData;
  final ClinicalReportPdfGenerator pdfGenerator;

  const ClinicalReportPreviewScreen({
    super.key,
    required this.reportData,
    this.pdfGenerator = const ClinicalReportPdfGenerator(),
  });

  Future<void> _shareModularReport(BuildContext context) async {
    try {
      final pdfBytes = await pdfGenerator.generatePdfBytes(reportData);
      final filename = ClinicalReportPdfGenerator.getReportFilename(reportData.patient);
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Modular Clinical Report ready for sharing.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filename = ClinicalReportPdfGenerator.getReportFilename(reportData.patient);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modular Clinical Report Preview'),
        backgroundColor: theme.colorScheme.primaryContainer,
        actions: [
          IconButton(
            key: const Key('preview_screen_share_button'),
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Modular Clinical Report',
            onPressed: () => _shareModularReport(context),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfGenerator.generatePdfBytes(reportData, format: format),
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: filename,
        allowPrinting: true,
        allowSharing: true,
        loadingWidget: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Compiling modular clinical report...'),
            ],
          ),
        ),
      ),
    );
  }
}
