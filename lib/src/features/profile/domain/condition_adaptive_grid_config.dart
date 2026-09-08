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
            id: 'hd_check_in',
            title: 'Check-in',
            subtitle: 'Pre-Weight & Access Inspection',
            icon: Icons.how_to_reg_rounded,
            semanticLabel: 'Hemodialysis pre-session check-in for pre-weight and access inspection',
          ),
          ClinicalActionCard(
            id: 'hd_post_dialysis',
            title: 'Post-Dialysis Log',
            subtitle: 'Post-Weight & Symptoms',
            icon: Icons.assignment_turned_in_rounded,
            semanticLabel: 'Log post-dialysis weight and recovery symptoms',
          ),
          ClinicalActionCard(
            id: 'hd_blood_pressure',
            title: 'Blood Pressure',
            subtitle: 'Hemodynamics & Safe Arm',
            icon: Icons.favorite_rounded,
            semanticLabel: 'Record blood pressure with fistula safe arm lockout',
          ),
          ClinicalActionCard(
            id: 'hd_fluid_intake',
            title: 'Fluid Intake & Binders',
            subtitle: 'Log beverage & meal binders',
            icon: Icons.local_drink_rounded,
            semanticLabel: 'Log fluid intake and meal-synchronized phosphate binders',
          ),
          ClinicalActionCard(
            id: 'hd_fluid_output',
            title: 'Fluid Output',
            subtitle: 'Urine & Ultrafiltration',
            icon: Icons.opacity_rounded,
            semanticLabel: 'Record fluid evacuation volume and urine output',
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
            subtitle: 'Catheter check & redness',
            icon: Icons.health_and_safety_rounded,
            semanticLabel: 'Inspect PD abdominal catheter exit-site for infection',
          ),
          ClinicalActionCard(
            id: 'pd_daily_weight',
            title: 'Daily Weight & Dry Weight',
            subtitle: 'Prescribed dry weight tracking',
            icon: Icons.monitor_weight_rounded,
            semanticLabel: 'Record daily weight against prescribed dry weight',
          ),
          ClinicalActionCard(
            id: 'pd_blood_pressure',
            title: 'Blood Pressure',
            subtitle: 'Daily hemodynamics',
            icon: Icons.favorite_rounded,
            semanticLabel: 'Record daily blood pressure and pulse',
          ),
          ClinicalActionCard(
            id: 'pd_fluid_balance',
            title: '24h Fluid Balance',
            subtitle: 'Net intake minus ultrafiltration',
            icon: Icons.balance_rounded,
            semanticLabel: 'Calculate 24-hour net fluid balance from intake and peritoneal ultrafiltration',
          ),
          ClinicalActionCard(
            id: 'pd_clinical_report',
            title: 'Modular Clinical Report',
            subtitle: 'Consultation export & trends',
            icon: Icons.description_rounded,
            semanticLabel: 'Generate modular clinical report for physician consultation',
          ),
        ];

      case ClinicalCondition.nonDialysisCkd:
        return const [
          ClinicalActionCard(
            id: 'ckd_blood_pressure',
            title: 'Blood Pressure',
            subtitle: 'Strict hemodynamic control',
            icon: Icons.favorite_rounded,
            semanticLabel: 'Record blood pressure for chronic kidney disease management',
          ),
          ClinicalActionCard(
            id: 'ckd_daily_weight',
            title: 'Daily Weight',
            subtitle: 'Fluid accumulation tracking',
            icon: Icons.monitor_weight_rounded,
            semanticLabel: 'Record daily morning weight for fluid retention surveillance',
          ),
          ClinicalActionCard(
            id: 'ckd_fluid_allowance',
            title: 'Fluid Allowance Tracker',
            subtitle: 'Daily fluid restriction tracking',
            icon: Icons.local_drink_rounded,
            semanticLabel: 'Track daily fluid intake against prescribed fluid allowance',
          ),
          ClinicalActionCard(
            id: 'ckd_medication_binders',
            title: 'Medication & Binders',
            subtitle: 'Phosphate binders & prescriptions',
            icon: Icons.medication_rounded,
            semanticLabel: 'Log prescribed medications and phosphate binder intake',
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
            id: 'uro_urine_evacuation',
            title: 'Urine Evacuation',
            subtitle: 'Volume & Hematuria Grade',
            icon: Icons.opacity_rounded,
            semanticLabel: 'Record urine evacuation volume and hematuria bleeding grade',
          ),
          ClinicalActionCard(
            id: 'uro_fluid_intake',
            title: 'Fluid Intake',
            subtitle: 'Daily intake hydration tracking',
            icon: Icons.local_drink_rounded,
            semanticLabel: 'Track daily fluid consumption to maintain catheter flushing',
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
