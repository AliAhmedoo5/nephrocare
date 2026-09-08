/// Primary clinical diagnosis conditions recognized by NephroCare per CONTEXT.md.
enum ClinicalCondition {
  hemodialysis(
    displayName: 'Hemodialysis',
    description: 'End-Stage Renal Disease managed with hemodialysis filtration sessions.',
    requiresPrescribedDryWeight: true,
    requiresFluidAllowance: true,
  ),
  peritonealDialysis(
    displayName: 'Peritoneal Dialysis',
    description: 'Continuous or automated peritoneal dialysis via abdominal catheter.',
    requiresPrescribedDryWeight: true,
    requiresFluidAllowance: true,
  ),
  nonDialysisCkd(
    displayName: 'Non-dialysis CKD',
    description: 'Chronic Kidney Disease managed with conservative medication and dietary restriction.',
    requiresPrescribedDryWeight: false,
    requiresFluidAllowance: true,
  ),
  urologicalCatheter(
    displayName: 'Urological / Catheter',
    description: 'Urinary drainage managed via indwelling Foley catheter or urological apparatus.',
    requiresPrescribedDryWeight: false,
    requiresFluidAllowance: true,
  );

  const ClinicalCondition({
    required this.displayName,
    required this.description,
    required this.requiresPrescribedDryWeight,
    required this.requiresFluidAllowance,
  });

  final String displayName;
  final String description;
  final bool requiresPrescribedDryWeight;
  final bool requiresFluidAllowance;

  static ClinicalCondition? fromString(String? name) {
    if (name == null) return null;
    for (final condition in ClinicalCondition.values) {
      if (condition.name == name) return condition;
    }
    return null;
  }
}

/// Surgical vascular access types for renal & urological patients per ADR-0003.
enum VascularAccessType {
  arteriovenousFistula(
    displayName: 'Arteriovenous Fistula',
    isArmAccess: true,
  ),
  arteriovenousGraft(
    displayName: 'Arteriovenous Graft',
    isArmAccess: true,
  ),
  dialysisCentralLine(
    displayName: 'Dialysis Central Line (Permcath/CVC)',
    isArmAccess: false,
  ),
  peritonealDialysisAccess(
    displayName: 'Peritoneal Dialysis Catheter',
    isArmAccess: false,
  ),
  none(
    displayName: 'None / Not Applicable',
    isArmAccess: false,
  );

  const VascularAccessType({
    required this.displayName,
    required this.isArmAccess,
  });

  final String displayName;
  final bool isArmAccess;

  static VascularAccessType? fromString(String? name) {
    if (name == null) return null;
    for (final access in VascularAccessType.values) {
      if (access.name == name) return access;
    }
    return null;
  }
}

/// Anatomical location for vascular access sites.
enum AccessLocation {
  leftArm(displayName: 'Left Arm', isArm: true),
  rightArm(displayName: 'Right Arm', isArm: true),
  chest(displayName: 'Chest', isArm: false),
  abdomen(displayName: 'Abdomen', isArm: false),
  none(displayName: 'None', isArm: false);

  const AccessLocation({
    required this.displayName,
    required this.isArm,
  });

  final String displayName;
  final bool isArm;

  static AccessLocation? fromString(String? name) {
    if (name == null) return null;
    for (final location in AccessLocation.values) {
      if (location.name == name) return location;
    }
    return null;
  }
}
