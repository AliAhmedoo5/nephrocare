# Drift Reactive SQLite and Riverpod State Persistence

## Context and Decision
NephroCare operates completely offline without cloud servers, requiring relational integrity for complex clinical calculations (e.g., interdialytic weight gain across sequential sessions, 24-hour fluid balance rollups, and vascular access history) alongside reactive UI updates for elderly patient navigation. We decided to adopt Drift (type-safe SQLite ORM) paired with Riverpod 2.x for application state management. 

## Consequences
- All SQLite queries are validated at compile time with auto-generated Dart data classes.
- UI tiles on the Condition-Adaptive Grid reactively observe local database tables without manual polling or refresh handlers.
- Database access is cross-platform compatible with Android devices in production and Windows desktop during zero-overhead local development.
