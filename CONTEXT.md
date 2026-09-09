# NephroCare

An offline-first personal health management application for patients with Chronic Kidney Disease (CKD), End-Stage Renal Disease (ESRD) on dialysis, and urological or catheter conditions.

## Language

### Renal & Dialysis

**Prescribed Dry Weight**:
The target body weight at the end of a dialysis session at which the patient has no excess fluid and normal blood pressure.
_Avoid_: Target weight, base weight, ideal weight

**Interdialytic Weight Gain**:
The fluid weight accumulated between the end of one dialysis session and the start of the next.
_Avoid_: Fluid gain, session gain, weight delta

**Ultrafiltration Goal**:
The target volume of fluid to be extracted during a hemodialysis treatment to return the patient to prescribed dry weight.
_Avoid_: UF rate, fluid pull, pump volume

**Vascular Access**:
The surgically created site (arteriovenous fistula, arteriovenous graft, or central venous catheter) through which blood is removed and returned during hemodialysis.
_Avoid_: Port, blood line, IV site

**Fistula Arm Safety Flag**:
A critical medical constraint designating the arm bearing a vascular access as strictly prohibited for blood pressure cuffs, blood draws, and IV placement.
_Avoid_: Arm warning, cuff lock, banned arm

**Dialysis Central Line**:
A central venous catheter providing direct venous access for hemodialysis, subdivided clinically into Tunneled (Permcath) and Non-Tunneled Temporary Lines.
_Avoid_: IV line, port tube, chest wire

**Tunneled Dialysis Central Line (Permcath)**:
A long-term cuffed catheter tunneled under the skin into the internal jugular vein, typically exiting on the chest wall.
_Avoid_: Short line, temporary port

**Non-Tunneled Temporary Dialysis Line**:
A short-term uncuffed vascular catheter (Vas-Cath) placed directly into the internal jugular vein (neck) or femoral vein (thigh/groin) for emergent or interim hemodialysis. Does not cause arm lockout for blood pressure measurements.
_Avoid_: Permcath, permanent line, thigh needle

**Unified Hemodialysis Session**:
A consolidated clinical workflow capturing the full treatment lifecycle: pre-dialysis check-in (pre-weight, access inspection, target UF), intra-dialytic monitoring, and post-dialysis checkout (post-weight, actual fluid removed, recovery symptoms).
_Avoid_: Split check-in, disconnected post-log

**Peritoneal Dialysis Access**:
A permanent catheter placed in the abdomen used to infuse and drain dialysate fluid for peritoneal filtration.
_Avoid_: Belly tube, PD tube, port

### Fluid & Urology

**Fluid Allowance**:
The nephrologist-prescribed maximum volume of total fluid intake permitted across a 24-hour cycle.
_Avoid_: Fluid ceiling, water limit, daily target

**Native Urine Balance**:
The net difference between total fluid consumed and bladder/catheter urine evacuated over a 24-hour cycle, reflecting native renal fluid retention prior to dialysis.
_Avoid_: Gross in-out, mixed balance

**Dialytic Fluid Balance**:
The comprehensive 24-hour net fluid balance accounting for both native urine output and machine ultrafiltration (fluid extracted during hemodialysis or peritoneal exchange).
_Avoid_: Total water delta, combined pull

**Urine Foley Catheter**:
An indwelling flexible tube draining urine from the bladder into a collection bag, monitored under a configurable clinical lifespan cycle (14-day latex, 30/90-day silicone, or custom) with scheduled bag emptying and replacement reminders.
_Avoid_: Bladder hose, pee tube, catheter pipe

**CAUTI Risk Window**:
The operational timeframe beyond which unreplaced urinary collection apparatus poses high risk of catheter-associated urinary tract infections.
_Avoid_: Infection timer, dirty bag period

**Hematuria Grade**:
The observed presence and visual density of blood in urine output ranging from clear to clot formation.
_Avoid_: Urine color, bloodiness

### Therapeutics, Interface & Exchange

**Phosphate Binder**:
A medication required to be ingested strictly during or immediately following a meal to sequester dietary phosphorus.
_Avoid_: Kidney pill, binder supplement, meal tablet

**Condition-Adaptive Grid**:
A primary dashboard layout presenting exactly six uncluttered clinical action cards automatically configured according to the patient's diagnosed renal or urological condition.
_Avoid_: Menu screen, tile list, home grid

**Modular Clinical Report**:
A patient consultation document generated client-side by selectively including specific clinical modules across a user-defined date window.
_Avoid_: Generic export, summary sheet, printout

**Animated Multi-Frame QR**:
A sequential visual transmission of chunked, compressed, encrypted data frames displayed on-screen and captured by a receiving device camera without network access.
_Avoid_: Moving barcode, video code, QR video

**Local Wi-Fi Handshake**:
A direct offline data transfer between two devices connected to the same local Wi-Fi or mobile hotspot using an embedded transient server and QR code pairing.
_Avoid_: Wi-Fi sync, local upload

**Encrypted Patient Export**:
A standalone, encrypted archive (`.nephro`) containing a patient's complete relational dataset for transfer via local file sharing.
_Avoid_: Data dump, backup file, JSON export

**Caregiver Mirror**:
A designated patient profile replica maintained on a caregiver or family member's device for monitoring and clinical consultation.
_Avoid_: Secondary account, sub-user, observer

**Paired Anti-Hypertensive BP Assessment**:
A synchronized clinical protocol capturing blood pressure immediately prior to taking an anti-hypertensive medication and re-measuring at a scheduled interval (20–35 minutes) post-administration to quantify pharmacological hemodynamic response.
_Avoid_: Random recheck, double BP, second read

**Medication Regimen**:
The patient's active prescribed drug schedule detailing medication names, dosages, administration frequencies, and contextual clinical constraints (e.g., synchronized with meals for phosphate binders, pre/post BP tracking for anti-hypertensives).
_Avoid_: Pill list, drug cabinet, meds tracker

**Caregiver & Clinical Terms Guide**:
An integrated in-app plain-language medical dictionary and contextual educational tool designed for family members and attendants to interpret clinical indicators, vital signs, and safety protocols without jargon.
_Avoid_: FAQ, help manual, medical wiki
