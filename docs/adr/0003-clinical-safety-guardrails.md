# Clinical Safety Guardrails and Device Lifespans

## Context and Decision
Renal and urological patients face severe risks from erroneous self-care logging, specifically vascular access thrombosis from blood pressure cuff inflation on an Arteriovenous Fistula arm, and Catheter-Associated Urinary Tract Infections (CAUTI) from prolonged indwelling Foley usage. We decided to enforce a hard lockout on the blood pressure logging interface when an active fistula arm is designated, locking the input exclusively to the safe arm. Furthermore, we implemented a 14-day tracking cycle for Urine Foley Catheters and exit-site inspection logs for Dialysis Central Lines (Permcath/CVC).

## Consequences
- The Blood Pressure entry screen disables selection of the arm registered in the patient profile as bearing a vascular fistula/graft.
- Catheter lifespan monitors provide a 14-day countdown progression (Green days 1-10, Amber days 11-14, Red days 15+) to mandate catheter hygiene and replacement.
- Dialysis line monitoring prompts patients to check thrill/bruit, redness, and discharge at every hemodialysis pre-session check-in.
