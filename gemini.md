# CivicVoice Project Context & Rules

## Architectural Principles
* **State & UI Separation:** Use a flat directory structure separating features (`reporting`, `admin_dashboard`) into discrete layers: Data Layer (Repository contracts), Business Logic Layer (State management), and UI Presentation Layer.
* **Mock Traversal First:** All features must strictly implement a `MockCivicDataRepository` utilizing exhaustive seed data sets (minimum 50 structured entries for coordinates, images, and statuses) before swapping to the concrete Firebase repository framework.
* **Self-Correction Loop:** If any UI or permission adjustments are requested, append them chronologically to the 'Learned Preferences' section at the base of this file immediately [00:28:44].

## Learned Preferences
1. Platform targets confirmed as Android + Web (not iOS). All platform configs should target android and web only.
2. Map package: flutter_map (transitioned from google_maps_flutter to support free, API-key-less OpenStreetMap tiles based on user request).
3. State management: Provider + ChangeNotifier pattern. No Riverpod or BLoC.
4. Relative import path depth from lib/ui/features/<feature>/views/ to lib/ui/core/ is 3 levels (../../../core/), NOT 4.
5. Citizen reporting screen is in Phase 1 scope alongside Admin Dashboard.
6. Use responsive spacing / adaptive buttons in AppBar (e.g. show IconButtons on mobile instead of full Text+Icon buttons) to prevent title and action overflows.
7. Use type-safe direct enum value checks (e.g. status == IncidentStatus.resolved) instead of runtime dynamic string member access (.name) to prevent NoSuchMethodError.
8. Under Phase 2, the 'By District' overview table continues using MockCivicDataRepository.seedData until complete reverse geocoding is implemented.
9. Profile & Forum preferences: Global ThemeProvider manages reactive ThemeMode (light/dark mode). Users can customize nicknames in profile editor. Admins posting anonymously appear as 'Anonymous Admin #hex' with a red-orange custom role badge. Admins can pin/unpin messages to broadcast them at the top of the forum feed.

