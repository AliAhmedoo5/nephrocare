# Unified Dialysis Lifecycle, Medication Regimens, Paired BP Assessment, and Dual Fluid Balance

## Context and Decision
Renal patients face fragmented self-care logging when treatments and vitals are compartmentalized into disjointed forms. Following clinical evaluation of user reservations, we decided to:
1. Unify hemodialysis check-in and post-dialysis logs into a single continuous session lifecycle, maintaining pre- and post-dialysis weights side by side.
2. Separate native residual urine output from dialysis ultrafiltration to prevent double counting and confusion, displaying plain-language body fluid retention (+/- mL) alongside machine extraction.
3. Introduce dedicated Medication and Medication Administration tracking across all conditions with 1-tap administration, meal-binder synchronization, and anti-hypertensive pre/post blood pressure workflows.
4. Implement a Paired Anti-Hypertensive Blood Pressure Assessment protocol with 20–35 minute background mobile alarm notifications that ring when the app is closed, logging exact elapsed minutes and pressure deltas for physician consultation.
5. Permit indwelling Foley Catheter tracking across all patient conditions with configurable lifespans (14-day latex, 30/90-day silicone, custom) and scheduled bag empty reminders.
6. Expand vascular access options to include Non-Tunneled Temporary Lines (Vas-Cath) in the neck and thigh/femoral sites, ensuring arm blood pressure lockouts only activate for arm-based accesses.

## Consequences
- The Condition-Adaptive Grid consolidates Hemodialysis into unified Dialysis Session and Fluid Hub cards, making room for Medication Management.
- Blood pressure logging links pre-medication baselines to post-medication checks via local background alarms.
- Modular Clinical Reports render dedicated paired anti-hypertensive tables and separate urine from ultrafiltration.
- In-app Attendant Guides and contextual info buttons demystify clinical indicators for caregivers.
