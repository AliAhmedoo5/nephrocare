import 'package:flutter_test/flutter_test.dart';
import 'package:nephrocare/src/features/clinical_terms_guide/domain/clinical_term.dart';

void main() {
  group('Domain Seam: ClinicalTermsRegistry & ClinicalTerm', () {
    test('Registry contains all key CONTEXT.md concepts with complete metadata', () {
      final terms = ClinicalTermsRegistry.allTerms;
      expect(terms, isNotEmpty);
      expect(terms.length, greaterThanOrEqualTo(15));

      // Key concepts specified in Issue #21
      final expectedKeys = [
        'prescribed_dry_weight',
        'idwg',
        'uf_goal',
        'fistula_arm_safety',
        'native_urine_balance',
        'dialytic_fluid_balance',
        'cauti_risk_window',
        'hematuria_grade',
        'paired_bp',
        'thrill_and_bruit',
        'vascular_access',
        'dialysis_central_line',
        'urine_foley_catheter',
        'phosphate_binder',
        'condition_adaptive_grid',
        'modular_clinical_report',
        'caregiver_mirror',
      ];

      for (final key in expectedKeys) {
        final term = ClinicalTermsRegistry.getTermById(key);
        expect(term, isNotNull, reason: 'Expected term with id $key to exist');
        expect(term!.title, isNotEmpty);
        expect(term.plainLanguageDefinition, isNotEmpty);
        expect(term.clinicalRelevance, isNotEmpty);
        expect(term.category, isNotNull);
      }
    });

    test('Contextual indicator terms specify clear safe ranges and clinical targets', () {
      final idwg = ClinicalTermsRegistry.getTermById('idwg');
      expect(idwg?.safeRangeOrTarget, contains('< 2.0'));

      final ufGoal = ClinicalTermsRegistry.getTermById('uf_goal');
      expect(ufGoal?.safeRangeOrTarget, isNotNull);

      final cauti = ClinicalTermsRegistry.getTermById('cauti_risk_window');
      expect(cauti?.safeRangeOrTarget, contains('14'));

      final hematuria = ClinicalTermsRegistry.getTermById('hematuria_grade');
      expect(hematuria?.safeRangeOrTarget, contains('Grade 1'));

      final pairedBp = ClinicalTermsRegistry.getTermById('paired_bp');
      expect(pairedBp?.safeRangeOrTarget, contains('drop'));
    });

    test('Categorization partitions terms into clinical groupings', () {
      final renalTerms = ClinicalTermsRegistry.getByCategory(ClinicalTermCategory.renalDialysis);
      final fluidTerms = ClinicalTermsRegistry.getByCategory(ClinicalTermCategory.fluidUrology);
      final therapeuticsTerms = ClinicalTermsRegistry.getByCategory(ClinicalTermCategory.therapeuticsVitals);

      expect(renalTerms, isNotEmpty);
      expect(fluidTerms, isNotEmpty);
      expect(therapeuticsTerms, isNotEmpty);

      // Verify no overlap across categories
      final allCount = renalTerms.length + fluidTerms.length + therapeuticsTerms.length;
      expect(allCount, equals(ClinicalTermsRegistry.allTerms.length));

      expect(renalTerms.any((t) => t.id == 'idwg'), isTrue);
      expect(fluidTerms.any((t) => t.id == 'native_urine_balance'), isTrue);
      expect(therapeuticsTerms.any((t) => t.id == 'paired_bp'), isTrue);
    });

    test('Search filtering matches terms across title, definition, and keywords', () {
      final searchBruit = ClinicalTermsRegistry.search('bruit');
      expect(searchBruit.any((t) => t.id == 'thrill_and_bruit'), isTrue);

      final searchCauti = ClinicalTermsRegistry.search('infection');
      expect(searchCauti.any((t) => t.id == 'cauti_risk_window'), isTrue);

      final searchEmpty = ClinicalTermsRegistry.search('');
      expect(searchEmpty.length, equals(ClinicalTermsRegistry.allTerms.length));

      final searchFilteredByCategory = ClinicalTermsRegistry.search('fluid', category: ClinicalTermCategory.fluidUrology);
      expect(searchFilteredByCategory.every((t) => t.category == ClinicalTermCategory.fluidUrology), isTrue);
    });
  });
}
