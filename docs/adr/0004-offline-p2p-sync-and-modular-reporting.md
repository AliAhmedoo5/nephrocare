# Offline Peer-to-Peer Sync and Modular Clinical Reporting

## Context and Decision
NephroCare operates in environments where internet connectivity, cloud accounts, or cellular phone numbers may not be available (e.g. clinic examination rooms, air-gapped hospital wards, remote homes). To enable seamless transfer of full patient records between devices (patients, family caregivers, and nephrologists) while maintaining patient privacy and zero cloud dependence, we decided to implement a triple-channel offline sync suite: (1) an air-gapped Animated Multi-Frame QR Code stream for visual camera-to-screen sync, (2) an embedded local Wi-Fi / Hotspot HTTP endpoint with QR pairing for 1-second bulk transfers, and (3) an AES-encrypted `.nephro` file export via native OS share (Quick Share/Bluetooth). All records use UUIDv4 primary keys and `updated_at` timestamps to support bi-directional merging across multi-patient profiles. Furthermore, clinical reporting uses a client-side modular PDF engine allowing doctors to select specific modules and observation date ranges.

## Consequences
- Full patient history can be transferred between any two mobile devices running the app without internet access or cellular numbers.
- Receiving devices can maintain multiple patient profiles simultaneously (Caregiver/Doctor mode).
- Clinicians can generate targeted, uncluttered PDF consultation sheets containing only the relevant modules (e.g., weights and blood pressure for the last 14 days).
