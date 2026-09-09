/// Categories for clinical terms per CONTEXT.md groupings.
enum ClinicalTermCategory {
  renalDialysis('Renal & Dialysis', 'Hemodialysis, vascular access, and weight targets.'),
  fluidUrology('Fluid & Urology', 'Fluid balance, catheter lifespan, and urine evacuation.'),
  therapeuticsVitals('Therapeutics, Vitals & Safety', 'Medication regimens, blood pressure safety, and interface concepts.');

  final String displayName;
  final String description;

  const ClinicalTermCategory(this.displayName, this.description);
}

/// Represents a clinical concept defined in plain, accessible language for attendants and caregivers.
class ClinicalTerm {
  final String id;
  final String title;
  final ClinicalTermCategory category;
  final String plainLanguageDefinition;
  final String clinicalRelevance;
  final String? safeRangeOrTarget;
  final List<String> avoidTerms;
  final List<String> searchKeywords;

  const ClinicalTerm({
    required this.id,
    required this.title,
    required this.category,
    required this.plainLanguageDefinition,
    required this.clinicalRelevance,
    this.safeRangeOrTarget,
    this.avoidTerms = const [],
    this.searchKeywords = const [],
  });
}

/// Comprehensive registry of all key renal, urological, and clinical terms
/// defined in CONTEXT.md for the Caregiver & Clinical Terms Guide.
class ClinicalTermsRegistry {
  static const List<ClinicalTerm> allTerms = [
    // 1. Renal & Dialysis
    ClinicalTerm(
      id: 'prescribed_dry_weight',
      title: 'Prescribed Dry Weight',
      category: ClinicalTermCategory.renalDialysis,
      plainLanguageDefinition:
          'The target body weight at the end of a dialysis session at which the patient has no excess fluid and normal blood pressure.',
      clinicalRelevance:
          'Prevents fluid overload (which causes swelling, shortness of breath, and heart strain) while avoiding dehydration (which causes severe cramping and dangerous blood pressure drops).',
      safeRangeOrTarget:
          'Prescribed by the nephrologist (e.g., 68.0 kg). Post-dialysis weight should ideally land within ±0.2–0.5 kg of this target.',
      avoidTerms: ['Target weight', 'Base weight', 'Ideal weight'],
      searchKeywords: ['dry weight', 'target', 'edema', 'post-weight', 'fluid overload', 'kg'],
    ),
    ClinicalTerm(
      id: 'idwg',
      title: 'Interdialytic Weight Gain (IDWG)',
      category: ClinicalTermCategory.renalDialysis,
      plainLanguageDefinition:
          'The fluid weight accumulated between the end of one dialysis session and the start of the next.',
      clinicalRelevance:
          'Because kidneys cannot excrete excess fluid, all consumed liquids remain in the bloodstream. Excessive IDWG forces the dialysis machine to remove fluid too rapidly, risking painful cramps, nausea, and intradialytic hypotension.',
      safeRangeOrTarget:
          'Clinically recommended < 2.0 to 2.5 kg between sessions (or < 4–5% of dry weight). Higher gains warrant immediate fluid intake restrictions.',
      avoidTerms: ['Fluid gain', 'Session gain', 'Weight delta'],
      searchKeywords: ['idwg', 'weight gain', 'interdialytic', 'between sessions', 'fluid retention', 'cramps'],
    ),
    ClinicalTerm(
      id: 'uf_goal',
      title: 'Ultrafiltration Goal (UF Goal)',
      category: ClinicalTermCategory.renalDialysis,
      plainLanguageDefinition:
          'The target volume of fluid to be extracted during a hemodialysis treatment to return the patient to prescribed dry weight.',
      clinicalRelevance:
          'Calculated automatically as: (Pre-Dialysis Weight - Prescribed Dry Weight) in kg × 1000 mL + Volume Allowance (oral liquids or saline rinseback during treatment). Determines machine fluid removal rate.',
      safeRangeOrTarget:
          'Typically 1,500–3,500 mL per session. To protect heart tissue and avoid sudden blood pressure collapse, safe ultrafiltration rate should not exceed 10–13 mL/kg/hr.',
      avoidTerms: ['UF rate', 'Fluid pull', 'Pump volume'],
      searchKeywords: ['uf goal', 'ultrafiltration', 'fluid extraction', 'pump', 'rinseback', 'ml'],
    ),
    ClinicalTerm(
      id: 'fistula_arm_safety',
      title: 'Fistula Arm Safety Flag',
      category: ClinicalTermCategory.renalDialysis,
      plainLanguageDefinition:
          'A critical medical constraint designating the arm bearing a vascular access as strictly prohibited for blood pressure cuffs, blood draws, and IV placement.',
      clinicalRelevance:
          'External cuff inflation or needle punctures on an access arm can collapse high-flow vessels, cause severe hematoma, or trigger vascular thrombosis (clotting), resulting in permanent loss of the patient\'s lifeline.',
      safeRangeOrTarget:
          'Strict 100% lockout on the affected limb. Only use the opposite designated safe arm for blood pressure monitoring.',
      avoidTerms: ['Arm warning', 'Cuff lock', 'Banned arm'],
      searchKeywords: ['fistula', 'arm safety', 'cuff', 'lockout', 'iv', 'prohibited arm', 'thrombosis'],
    ),
    ClinicalTerm(
      id: 'vascular_access',
      title: 'Vascular Access',
      category: ClinicalTermCategory.renalDialysis,
      plainLanguageDefinition:
          'The surgically created site (arteriovenous fistula, arteriovenous graft, or central venous catheter) through which blood is removed and returned during hemodialysis.',
      clinicalRelevance:
          'The patient\'s clinical lifeline. Must be inspected daily for patency (thrill and bruit) and signs of infection (redness, warmth, swelling, or discharge).',
      safeRangeOrTarget:
          'Clean, intact skin without erythema or edema; continuous palpable vibration and whooshing sound present.',
      avoidTerms: ['Port', 'Blood line', 'IV site'],
      searchKeywords: ['access', 'fistula', 'graft', 'permcath', 'lifeline', 'avf', 'avg'],
    ),
    ClinicalTerm(
      id: 'dialysis_central_line',
      title: 'Dialysis Central Line',
      category: ClinicalTermCategory.renalDialysis,
      plainLanguageDefinition:
          'A central venous catheter providing direct venous access for hemodialysis, subdivided clinically into Tunneled (Permcath) and Non-Tunneled Temporary Lines.',
      clinicalRelevance:
          'Permcaths enter the chest/neck with a cuff under the skin for longer-term use. Temporary lines (Vas-Cath) are placed in the neck or groin/thigh for emergent dialysis and do not cause arm blood pressure lockouts.',
      safeRangeOrTarget:
          'Dressing must remain dry, clean, and intact at all times. Never get wet in shower without watertight protection. Inspect exit site daily.',
      avoidTerms: ['IV line', 'Port tube', 'Chest wire'],
      searchKeywords: ['permcath', 'central line', 'catheter', 'vas-cath', 'internal jugular', 'femoral'],
    ),
    ClinicalTerm(
      id: 'thrill_and_bruit',
      title: 'Thrill and Bruit',
      category: ClinicalTermCategory.renalDialysis,
      plainLanguageDefinition:
          'The physical signs of healthy blood flow through an AV fistula or graft: "Thrill" is the continuous vibration felt by gently placing fingertips over the access; "Bruit" is the rhythmic whooshing sound heard through a stethoscope.',
      clinicalRelevance:
          'Absence or sudden weakening of the thrill or bruit signals a blockage (thrombosis) or severe narrowing (stenosis). This is a clinical emergency requiring immediate evaluation to save the access.',
      safeRangeOrTarget:
          'Continuous palpable vibration and rhythmic audible whoosh must be present every single day.',
      avoidTerms: ['Pulse pulse', 'Vessel buzz'],
      searchKeywords: ['thrill', 'bruit', 'whoosh', 'vibration', 'stethoscope', 'inspection', 'patency'],
    ),

    // 2. Fluid & Urology
    ClinicalTerm(
      id: 'native_urine_balance',
      title: 'Native Urine Balance',
      category: ClinicalTermCategory.fluidUrology,
      plainLanguageDefinition:
          'The net difference between total fluid consumed and bladder/catheter urine evacuated over a 24-hour cycle, reflecting native renal fluid retention prior to dialysis.',
      clinicalRelevance:
          'Separates what the patient\'s kidneys retain naturally from machine removal. Positive values indicate true fluid accumulation in body tissues.',
      safeRangeOrTarget:
          'Net Balance = Total Intake - Total Urine Output. Target is to keep positive retention within allowable dry-weight gain tolerances.',
      avoidTerms: ['Gross in-out', 'Mixed balance'],
      searchKeywords: ['native urine', 'urine output', 'intake', 'retention', 'fluid balance', '24h'],
    ),
    ClinicalTerm(
      id: 'dialytic_fluid_balance',
      title: 'Dialytic Fluid Balance',
      category: ClinicalTermCategory.fluidUrology,
      plainLanguageDefinition:
          'The comprehensive 24-hour net fluid balance accounting for both native urine output and machine ultrafiltration (fluid extracted during hemodialysis or peritoneal exchange).',
      clinicalRelevance:
          'Provides complete 24-hour volume reconciliation: Intake minus (Urine + Dialysis Removal). Confirms whether total fluid removed returns patient to equilibrium.',
      safeRangeOrTarget:
          'Net 24h Balance = Intake - (Urine + Dialysis Removal). Near-neutral or slight negative on dialysis days to achieve dry weight.',
      avoidTerms: ['Total water delta', 'Combined pull'],
      searchKeywords: ['dialytic balance', 'machine extraction', 'net balance', 'dual balance', 'ultrafiltration'],
    ),
    ClinicalTerm(
      id: 'urine_foley_catheter',
      title: 'Urine Foley Catheter',
      category: ClinicalTermCategory.fluidUrology,
      plainLanguageDefinition:
          'An indwelling flexible tube draining urine from the bladder into a collection bag, monitored under a configurable clinical lifespan cycle (14-day latex, 30/90-day silicone, or custom).',
      clinicalRelevance:
          'Requires aseptic bag drainage, maintenance of dependent gravity flow without kinks, and timely scheduled replacement before bacterial biofilm forms.',
      safeRangeOrTarget:
          'Empty bag every 4–8 hours or when 2/3 full. Replace according to material lifespan (14 days for latex).',
      avoidTerms: ['Bladder hose', 'Pee tube', 'Catheter pipe'],
      searchKeywords: ['foley', 'catheter', 'drainage', 'bag', 'urology', 'indwelling'],
    ),
    ClinicalTerm(
      id: 'cauti_risk_window',
      title: 'CAUTI Risk Window',
      category: ClinicalTermCategory.fluidUrology,
      plainLanguageDefinition:
          'The operational timeframe beyond which unreplaced urinary collection apparatus poses high risk of catheter-associated urinary tract infections (CAUTI).',
      clinicalRelevance:
          'Bacterial biofilms form inside indwelling catheters over time. Leaving a catheter past its lifespan drastically elevates the risk of severe bladder infection, urosepsis, and hospitalization.',
      safeRangeOrTarget:
          'Days 1–10: Safe Green. Days 11–14: Transition Amber (prepare replacement). Day 15+: CAUTI Risk Active Red (Immediate clinical replacement mandated).',
      avoidTerms: ['Infection timer', 'Dirty bag period'],
      searchKeywords: ['cauti', 'risk window', 'infection', 'overdue', 'lifespan', 'sepsis', 'latex'],
    ),
    ClinicalTerm(
      id: 'hematuria_grade',
      title: 'Hematuria Grade',
      category: ClinicalTermCategory.fluidUrology,
      plainLanguageDefinition:
          'The observed presence and visual density of blood in urine output ranging from clear to clot formation.',
      clinicalRelevance:
          'Graded 1 to 4 to quickly assess bleeding severity. Higher grades alert attendants to bladder trauma, catheter cuff tension, infection, or internal bleeding.',
      safeRangeOrTarget:
          'Grade 1: Clear / Pale Yellow (Normal). Grade 2: Pink / Light Amber (Mild). Grade 3: Tea-Colored / Dark Red (Moderate). Grade 4: Frank Blood with Clots (Severe - Immediate clinical evaluation required).',
      avoidTerms: ['Urine color', 'Bloodiness'],
      searchKeywords: ['hematuria', 'blood in urine', 'clots', 'red urine', 'grades', 'grade 1-4'],
    ),

    // 3. Therapeutics, Vitals & Safety
    ClinicalTerm(
      id: 'paired_bp',
      title: 'Paired Anti-Hypertensive BP Assessment',
      category: ClinicalTermCategory.therapeuticsVitals,
      plainLanguageDefinition:
          'A synchronized clinical protocol capturing blood pressure immediately prior to taking an anti-hypertensive medication and re-measuring at a scheduled interval (20–35 minutes) post-administration to quantify pharmacological hemodynamic response.',
      clinicalRelevance:
          'Provides quantitative evidence of whether blood pressure medication is effective and safe, detecting excessive drops (orthostatic hypotension) or non-response for physician review.',
      safeRangeOrTarget:
          'Target response: 10–25 mmHg drop in systolic BP within 20–35 minutes, without dropping below 90/60 mmHg (hypotension threshold).',
      avoidTerms: ['Random recheck', 'Double BP', 'Second read'],
      searchKeywords: ['paired bp', 'anti-hypertensive', 'blood pressure drop', 'delta', 'follow-up', 'systolic drop'],
    ),
    ClinicalTerm(
      id: 'phosphate_binder',
      title: 'Phosphate Binder',
      category: ClinicalTermCategory.therapeuticsVitals,
      plainLanguageDefinition:
          'A medication required to be ingested strictly during or immediately following a meal to sequester dietary phosphorus.',
      clinicalRelevance:
          'Damaged kidneys cannot clear phosphorus. If taken without food, binders cannot trap meal phosphorus, allowing it to enter the blood and cause severe vascular calcification, bone fractures, and cardiovascular disease.',
      safeRangeOrTarget:
          'Must be taken with the first bites of meals or within 10–15 minutes after eating. Ineffective on an empty stomach.',
      avoidTerms: ['Kidney pill', 'Binder supplement', 'Meal tablet'],
      searchKeywords: ['phosphate', 'binder', 'meal', 'phosphorus', 'sevelamer', 'calcium acetate'],
    ),
    ClinicalTerm(
      id: 'condition_adaptive_grid',
      title: 'Condition-Adaptive Grid',
      category: ClinicalTermCategory.therapeuticsVitals,
      plainLanguageDefinition:
          'A primary dashboard layout presenting exactly six uncluttered clinical action cards automatically configured according to the patient\'s diagnosed renal or urological condition.',
      clinicalRelevance:
          'Reduces cognitive clutter and anxiety for patients and family attendants by dynamically prioritizing the exact clinical actions (dialysis, fluid hub, catheter lifespan, BP) relevant to their diagnosis.',
      safeRangeOrTarget:
          'Exactly 6 focused cards meeting minimum 48dp touch accessibility standards for elderly users.',
      avoidTerms: ['Menu screen', 'Tile list', 'Home grid'],
      searchKeywords: ['grid', 'condition-adaptive', 'dashboard', 'six cards', 'layout'],
    ),
    ClinicalTerm(
      id: 'modular_clinical_report',
      title: 'Modular Clinical Report',
      category: ClinicalTermCategory.therapeuticsVitals,
      plainLanguageDefinition:
          'A patient consultation document generated client-side by selectively including specific clinical modules across a user-defined date window.',
      clinicalRelevance:
          'Enables patients and attendants to generate high-density, professional clinical summaries for nephrology and urology consultations completely offline.',
      safeRangeOrTarget:
          'Selectable date windows (7, 14, 30 days, or custom) and modular section toggles (BP, Dual Fluid, Catheter Lifespan, Meds).',
      avoidTerms: ['Generic export', 'Summary sheet', 'Printout'],
      searchKeywords: ['report', 'modular report', 'pdf', 'consultation', 'print', 'export'],
    ),
    ClinicalTerm(
      id: 'caregiver_mirror',
      title: 'Caregiver Mirror',
      category: ClinicalTermCategory.therapeuticsVitals,
      plainLanguageDefinition:
          'A designated patient profile replica maintained on a caregiver or family member\'s device for monitoring and clinical consultation.',
      clinicalRelevance:
          'Allows family members and clinical attendants to safely review clinical indicators, fluid balances, and vitals via offline synchronization without risking unintentional overwrite of primary patient records.',
      safeRangeOrTarget:
          'Read-only observation with deterministic multi-frame QR and local Wi-Fi handshake ingestion.',
      avoidTerms: ['Secondary account', 'Sub-user', 'Observer'],
      searchKeywords: ['mirror', 'caregiver', 'family', 'read-only', 'sync', 'observer'],
    ),
  ];

  /// Retrieve a clinical term by its unique identifier.
  static ClinicalTerm? getTermById(String id) {
    try {
      return allTerms.firstWhere((term) => term.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Retrieve all clinical terms belonging to a specific category.
  static List<ClinicalTerm> getByCategory(ClinicalTermCategory category) {
    return allTerms.where((term) => term.category == category).toList();
  }

  /// Search clinical terms by query text across title, definition, relevance, and keywords.
  /// Optionally filters by category.
  static List<ClinicalTerm> search(String query, {ClinicalTermCategory? category}) {
    final cleanQuery = query.trim().toLowerCase();
    return allTerms.where((term) {
      if (category != null && term.category != category) {
        return false;
      }
      if (cleanQuery.isEmpty) {
        return true;
      }
      final matchesTitle = term.title.toLowerCase().contains(cleanQuery);
      final matchesDef = term.plainLanguageDefinition.toLowerCase().contains(cleanQuery);
      final matchesRelevance = term.clinicalRelevance.toLowerCase().contains(cleanQuery);
      final matchesKeywords = term.searchKeywords.any((k) => k.toLowerCase().contains(cleanQuery));
      final matchesAvoid = term.avoidTerms.any((a) => a.toLowerCase().contains(cleanQuery));
      final matchesRange = term.safeRangeOrTarget?.toLowerCase().contains(cleanQuery) ?? false;

      return matchesTitle || matchesDef || matchesRelevance || matchesKeywords || matchesAvoid || matchesRange;
    }).toList();
  }
}
