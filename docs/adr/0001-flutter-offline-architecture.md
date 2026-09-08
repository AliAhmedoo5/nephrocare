# Flutter Offline-First Architecture with GitHub Actions Build Pipeline

## Context and Decision
NephroCare requires an offline-first, cloudless mobile application for renal and urological patient care, while the developer's workstation operates with severely constrained disk storage that cannot sustain a multi-gigabyte local Android SDK, Gradle cache, and emulator suite. We decided to build the application natively in Flutter, utilizing local Windows desktop and Chrome targets for low-footprint instant development and testing, while delegating all native Android APK compilation, packaging, and artifact publishing exclusively to automated GitHub Actions runners.

## Consequences
- The project is initialized in-place via `flutter create . --org com.nephrocare.app --platforms=android,windows,web`.
- Developers need only standard Flutter and Dart SDKs on their workstations without local Android Studio, Gradle caches, or AVD emulator overhead.
- Native Android `.apk` builds are produced reproducibly via an automated GitHub Actions workflow (`.github/workflows/flutter-apk.yml`) using Java 21 and `subosito/flutter-action`, uploading compiled APK artifacts on every push.
- All application data remains strictly local on the client device using embedded SQLite without external cloud dependencies.

