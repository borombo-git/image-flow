# ImageFlow 🪄

A Flutter image processing app that auto-detects content type (faces or documents) and applies the appropriate processing pipeline.

- **Face Flow:** ML Kit face detection → crop faces → B&W filter → composite result
- **Document Flow:** ML Kit text recognition → edge detection → perspective transform → PDF export

## 🛠️ Tools & Workflow

| Tool | Role |
|------|------|
| **Figma** | Reviewed design mockups and UI specs provided with the brief |
| **Screendesigns** | Translated mockups into concrete screen layouts and component decisions |
| **Android Studio** | Primary IDE for Flutter development, debugging, and device testing |
| **Claude Code** | Coding partner — used for implementation, brainstorming architecture trade-offs, and rubber-ducking decisions |

## 🚀 Setup

### Prerequisites

- Flutter SDK `>=3.9.0`
- Xcode 16+ (iOS) / Android Studio (Android)
- CocoaPods (iOS)

### Run

```bash
flutter pub get
flutter run
```

### Other commands

```bash
flutter analyze     # Static analysis
dart format lib/    # Format code
flutter test        # Run tests
```

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| `get` | State management, DI, navigation |
| `google_mlkit_face_detection` | Face detection in images |
| `google_mlkit_text_recognition` | Document/text detection |
| `image` | Pixel-level image manipulation (crop, B&W, composite) |
| `hive` / `hive_flutter` | Local storage for processing history |
| `image_picker` | Camera/gallery image selection |
| `path_provider` | Device storage paths |
| `intl` | Date/time formatting |

## 🏗️ Architecture

**MVVM with GetX**, feature-based folder structure. Two controller layers:

- **Managers** (`GetxController` + `permanent: true`) — global singletons for shared business logic (`ImageProcessingManager`, `HistoryManager`)
- **Screen controllers** (`GetxController`) — per-screen logic, only when the screen has local state. Skipped for simple screens that just read from a manager.

```
lib/
├── manager/          # Global singletons (processing, history)
├── ui/
│   ├── home/         # History grid + FAB
│   ├── capture/      # Camera/gallery picker (bottom sheet)
│   ├── processing/   # Progress screen with step descriptions
│   └── result/       # Before/after comparison + stats
├── model/            # Data models (ProcessingRecord)
├── common/
│   ├── theme/        # Colors, typography
│   ├── widgets/      # Shared widgets (BottomSheetContainer)
│   └── utils/        # Path resolution, formatting, logging
└── routes/           # GetPage definitions + bindings
```

### 💡 Why this structure

My usual go-to for Flutter is [Lazx](https://github.com/borombo-git/lazx), a custom MVVM state management library I built. It uses a 3-layer pattern — `LazxManager` (singleton) → `LazxViewModel` (per-screen) → `LazxView` + `LazxBuilder` — that naturally separates global business logic from screen-specific state.

For this project the requirement was GetX, so I researched how GetX handles DI, reactivity, and navigation, and adapted my MVVM style to fit. The result is the same mental model I use with Lazx: managers for shared state, screen controllers for local orchestration, and simple screens that skip the controller entirely. GetX's `.obs` + `Obx()` maps well to Lazx's reactive data pattern, and `Get.put(permanent: true)` fills the same role as Lazx's singleton managers.

I went with feature-based folders rather than layer-based (grouping all controllers together, all views together, etc.) because it keeps related files close. When working on the home screen, everything I need is under `ui/home/`. Shared concerns live in `common/`.

The two-layer controller pattern (managers vs screen controllers) avoids the common GetX trap of putting everything in one giant controller. Managers own the data and business logic, screen controllers just orchestrate UI-specific state.

## 🧠 Reasoning & Progress

### Step 1 — Model + Persistence

Started with the data layer: a `ProcessingRecord` model (type, date, before/after image paths, metadata) persisted via Hive. The `HistoryManager` handles CRUD and exposes a reactive `RxList` sorted newest-first.

I chose Hive over SQLite because the data is simple key-value records with no relational queries — Hive is lighter and doesn't need code generation for basic operations (just adapters).

### Step 2 — Face Processing Pipeline

The core feature: pick an image → detect faces with ML Kit → apply grayscale to face regions → save composite. The heavy image manipulation (decode, crop, grayscale, composite) runs in `Isolate.run()` to keep the UI thread free.

Key trade-off: ML Kit must run on the main isolate (platform channels), but the `image` package work is pure Dart and moves to a background isolate. This split keeps the UI responsive — the progress screen updates smoothly while processing happens.

`bakeOrientation` is called before any cropping to handle EXIF rotation, which is critical on iOS where camera images come with orientation metadata rather than rotated pixels.

### Step 3 — Result Screen

Before/after comparison with the original and processed images side by side. Extracted into a reusable `BeforeAfterComparison` widget. Stats row shows processing time, face count, and file size.

### Step 4 — Home Screen & Full Loop

Replaced the empty state with a 2-column history grid. Cards show the result image thumbnail, a colored type badge, and the formatted date. Long-press opens a delete confirmation bottom sheet.

This completed the full loop: capture → process → result → home → tap to revisit.

**File path fix:** During testing on iOS, I discovered that stored absolute paths broke between development builds because iOS rotates the app sandbox UUID. Fixed by storing filenames only and resolving the full path at runtime via `path_provider`. The original image is now also copied to the documents directory so it persists alongside the result.

**Refactoring:** Extracted shared patterns as they emerged:
- `BottomSheetContainer` — shared wrapper used by both capture and delete sheets
- `format_utils.dart` — centralized date, duration, and file size formatting
- `path_utils.dart` — filename storage and runtime path resolution
