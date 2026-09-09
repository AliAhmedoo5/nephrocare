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
  tunneledDialysisCentralLine(
    displayName: 'Tunneled Dialysis Central Line (Permcath)',
    isArmAccess: false,
  ),
  nonTunneledTemporaryDialysisLine(
    displayName: 'Non-Tunneled Temporary Dialysis Line (Vas-Cath)',
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

  /// Whether this access is a central line catheter requiring exit-site inspection.
  bool get isCentralLine =>
      this == VascularAccessType.tunneledDialysisCentralLine ||
      this == VascularAccessType.nonTunneledTemporaryDialysisLine;

  /// Whether this access is an arteriovenous fistula or graft.
  bool get isFistulaOrGraft =>
      this == VascularAccessType.arteriovenousFistula ||
      this == VascularAccessType.arteriovenousGraft;

  /// List of anatomically compatible locations for this access type.
  List<AccessLocation> get compatibleLocations {
    switch (this) {
      case VascularAccessType.arteriovenousFistula:
      case VascularAccessType.arteriovenousGraft:
        return const [AccessLocation.leftArm, AccessLocation.rightArm];
      case VascularAccessType.tunneledDialysisCentralLine:
        return const [AccessLocation.chest, AccessLocation.neck];
      case VascularAccessType.nonTunneledTemporaryDialysisLine:
        return const [AccessLocation.neck, AccessLocation.thighGroin];
      case VascularAccessType.peritonealDialysisAccess:
        return const [AccessLocation.abdomen];
      case VascularAccessType.none:
        return const [AccessLocation.none];
    }
  }

  /// Default anatomical location for this access type upon selection.
  AccessLocation get defaultLocation {
    switch (this) {
      case VascularAccessType.arteriovenousFistula:
      case VascularAccessType.arteriovenousGraft:
        return AccessLocation.leftArm;
      case VascularAccessType.tunneledDialysisCentralLine:
        return AccessLocation.chest;
      case VascularAccessType.nonTunneledTemporaryDialysisLine:
        return AccessLocation.neck;
      case VascularAccessType.peritonealDialysisAccess:
        return AccessLocation.abdomen;
      case VascularAccessType.none:
        return AccessLocation.none;
    }
  }

  /// Backward-compatible alias for [tunneledDialysisCentralLine].
  static const VascularAccessType dialysisCentralLine = VascularAccessType.tunneledDialysisCentralLine;

  static VascularAccessType? fromString(String? name) {
    if (name == null) return null;
    if (name == 'dialysisCentralLine') {
      return VascularAccessType.tunneledDialysisCentralLine;
    }
    if (name == 'nonTunneledTemporaryLine' ||
        name == 'nonTunneledTemporaryDialysisLine' ||
        name == 'vasCath') {
      return VascularAccessType.nonTunneledTemporaryDialysisLine;
    }
    if (name == 'tunneledDialysisCentralLine' || name == 'permcath') {
      return VascularAccessType.tunneledDialysisCentralLine;
    }
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
  neck(displayName: 'Neck (Internal Jugular)', isArm: false),
  thighGroin(displayName: 'Thigh / Groin (Femoral)', isArm: false),
  abdomen(displayName: 'Abdomen', isArm: false),
  none(displayName: 'None', isArm: false);

  const AccessLocation({
    required this.displayName,
    required this.isArm,
  });

  final String displayName;
  final bool isArm;

  /// Aliases for clinical anatomical terminology
  static const AccessLocation neckInternalJugular = AccessLocation.neck;
  static const AccessLocation femoral = AccessLocation.thighGroin;

  static AccessLocation? fromString(String? name) {
    if (name == null) return null;
    if (name == 'neck' || name == 'neckInternalJugular') {
      return AccessLocation.neck;
    }
    if (name == 'thighGroin' ||
        name == 'femoral' ||
        name == 'thigh' ||
        name == 'groin' ||
        name == 'thigh/groin' ||
        name == 'thighGroinFemoral') {
      return AccessLocation.thighGroin;
    }
    for (final location in AccessLocation.values) {
      if (location.name == name) return location;
    }
    return null;
  }
}
