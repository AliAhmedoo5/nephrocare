import 'package:flutter/material.dart';
import 'clinical_condition.dart';

/// A clinical action card rendered on the Condition-Adaptive Grid.
class ClinicalActionCard {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String semanticLabel;
  final Color? accentColor;

  const ClinicalActionCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.semanticLabel,
    this.accentColor,
  });
}

/// Dynamic orchestrator generating exactly six uncluttered clinical action cards
/// for the Condition-Adaptive Grid based on the patient's diagnosed condition.
class ConditionAdaptiveGridConfig {
  static List<ClinicalActionCard> getCardsForCondition(String? conditionName) {
    final condition = ClinicalCondition.fromString(conditionName) ?? ClinicalCondition.hemodialysis;

    switch (condition) {
      case ClinicalCondition.hemodialysis:
        return const [
          ClinicalActionCard(
            id: 'hd_dialysis_session',
            title: 'Unified Dialysis Session',
            subtitle: 'Pre-Weight, Vitals & Intradialytic Monitoring',
            icon: Icons.sync_alt_rounded,
            semanticLabel: 'Unified hemodialysis session lifecycle, pre-session check-in, and post-session checkout',
          ),
          ClinicalActionCard(
            id: 'hd_blood_pressure',
            title: 'Blood Pressure & Paired BP',
            subtitle: 'Hemodynamics & Safe Arm',
            icon: Icons.favorite_rounded,
            semanticLabel: 'Record blood pressure and paired anti-hypertensive response with fistula safe arm lockout',
          ),
          ClinicalActionCard(
            id: 'hd_fluid_hub',
            title: 'Fluid Hub',
            subtitle: 'Intake, Urine & Dialysis Balance',
            icon: Icons.water_drop_rounded,
            semanticLabel: 'Dual fluid balance hub tracking intake, residual urine, and dialysis ultrafiltration',
          ),
          ClinicalActionCard(
            id: 'hd_medications',
            title: 'Medication Management',
            subtitle: 'Phosphate binders & prescriptions',
            icon: Icons.medication_rounded,
            semanticLabel: 'Log prescribed medications and phosphate binder intake',
          ),
          ClinicalActionCard(
            id: 'hd_catheter_access',
            title: 'Catheter & Access Monitor',
            subtitle: 'Vascular Access Thrill, Bruit & Line Surveillance',
            icon: Icons.health_and_safety_rounded,
            semanticLabel: 'Monitor vascular access thrill, bruit, catheter integrity, and infection signs',
          ),
          ClinicalActionCard(
            id: 'hd_clinical_report',
            title: 'Modular Clinical Report',
            subtitle: 'Consultation export & trends',
            icon: Icons.description_rounded,
            semanticLabel: 'Generate modular clinical report for physician consultation',
          ),
        ];

      case ClinicalCondition.peritonealDialysis:
        return const [
          ClinicalActionCard(
            id: 'pd_exchange_log',
            title: 'Exchange Log',
            subtitle: 'Inflow & drain dwell cycles',
            icon: Icons.sync_rounded,
            semanticLabel: 'Record peritoneal dialysis dwell cycles and exchanges',
          ),
          ClinicalActionCard(
            id: 'pd_exit_site',
            title: 'Exit-Site Inspection',
            subtitle: 'Catheter check & infection signs',
            icon: Icons.health_and_safety_rounded,
            semanticLabel: 'Inspect PD abdominal catheter exit-site for infection',
          ),
          ClinicalActionCard(
            id: 'pd_daily_weight',
            title: 'Daily Weight',
            subtitle: 'Prescribed dry weight tracking',
            icon: Icons.monitor_weight_rounded,
            semanticLabel: 'Record daily weight against prescribed dry weight',
          ),
          ClinicalActionCard(
            id: 'pd_blood_pressure',
            title: 'Blood Pressure',
            subtitle: 'Daily hemodynamics & pulse',
            icon: Icons.favorite_rounded,
            semanticLabel: 'Record daily blood pressure and pulse',
          ),
          ClinicalActionCard(
            id: 'pd_fluid_hub',
            title: 'Fluid Hub',
            subtitle: 'Intake, ultrafiltration & net balance',
            icon: Icons.water_drop_rounded,
            semanticLabel: 'Calculate 24-hour net fluid balance from intake and peritoneal ultrafiltration',
          ),
          ClinicalActionCard(
            id: 'pd_medications',
            title: 'Medication Management',
            subtitle: 'Prescriptions & binders',
            icon: Icons.medication_rounded,
            semanticLabel: 'Log prescribed medications and dosages',
          ),
        ];

      case ClinicalCondition.nonDialysisCkd:
        return const [
          ClinicalActionCard(
            id: 'ckd_blood_pressure',
            title: 'Blood Pressure & Paired BP',
            subtitle: 'Strict hemodynamic control',
            icon: Icons.favorite_rounded,
            semanticLabel: 'Record blood pressure and paired anti-hypertensive response for chronic kidney disease management',
          ),
          ClinicalActionCard(
            id: 'ckd_daily_weight',
            title: 'Daily Weight',
            subtitle: 'Fluid accumulation tracking',
            icon: Icons.monitor_weight_rounded,
            semanticLabel: 'Record daily morning weight for fluid retention surveillance',
          ),
          ClinicalActionCard(
            id: 'ckd_fluid_hub',
            title: 'Fluid Hub',
            subtitle: 'Daily fluid restriction & balance',
            icon: Icons.water_drop_rounded,
            semanticLabel: 'Track daily fluid intake and native urine output balance against prescribed fluid allowance',
          ),
          ClinicalActionCard(
            id: 'ckd_medications',
            title: 'Medication Management',
            subtitle: 'Prescriptions & anti-hypertensives',
            icon: Icons.medication_rounded,
            semanticLabel: 'Log prescribed medications and anti-hypertensive intake',
          ),
          ClinicalActionCard(
            id: 'ckd_symptom_log',
            title: 'Symptom Log',
            subtitle: 'Fatigue, edema & appetite',
            icon: Icons.healing_rounded,
            semanticLabel: 'Log CKD symptoms including swelling, fatigue, and shortness of breath',
          ),
          ClinicalActionCard(
            id: 'ckd_clinical_report',
            title: 'Modular Clinical Report',
            subtitle: 'Consultation export & trends',
            icon: Icons.description_rounded,
            semanticLabel: 'Generate modular clinical report for physician consultation',
          ),
        ];

      case ClinicalCondition.urologicalCatheter:
        return const [
          ClinicalActionCard(
            id: 'uro_catheter_lifespan',
            title: 'Foley Catheter Lifespan',
            subtitle: '14-Day CAUTI Risk Monitor',
            icon: Icons.timer_rounded,
            semanticLabel: 'Monitor indwelling Foley catheter 14-day lifespan and CAUTI risk window',
          ),
          ClinicalActionCard(
            id: 'uro_fluid_hub',
            title: 'Fluid Hub',
            subtitle: 'Hydration intake & urine output balance',
            icon: Icons.water_drop_rounded,
            semanticLabel: 'Track daily fluid consumption and catheter urine evacuation balance',
          ),
          ClinicalActionCard(
            id: 'uro_medications',
            title: 'Medication Management',
            subtitle: 'Antibiotics & prescriptions',
            icon: Icons.medication_rounded,
            semanticLabel: 'Log prescribed medications and antibiotics',
          ),
          ClinicalActionCard(
            id: 'uro_blood_pressure',
            title: 'Blood Pressure',
            subtitle: 'Vital sign monitoring',
            icon: Icons.favorite_rounded,
            semanticLabel: 'Record blood pressure and pulse',
          ),
          ClinicalActionCard(
            id: 'uro_symptom_log',
            title: 'Symptom Log',
            subtitle: 'Pain, catheter blockage & fever',
            icon: Icons.healing_rounded,
            semanticLabel: 'Log urological symptoms such as catheter spasms, leakage, or cloudiness',
          ),
          ClinicalActionCard(
            id: 'uro_clinical_report',
            title: 'Modular Clinical Report',
            subtitle: 'Consultation export & trends',
            icon: Icons.description_rounded,
            semanticLabel: 'Generate modular clinical report for physician consultation',
          ),
        ];
    }
  }
}
