# ImageFlow 🪄

A Flutter image processing app that auto-detects content type (faces or documents) and applies the appropriate processing pipeline.

- **Face Flow:** ML Kit face detection → crop faces → B&W filter → composite result
- **Document Flow:** ML Kit text recognition → luminance edge detection → crop + enhance → PDF export

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
| `image` | Pixel-level image manipulation (crop, B&W, composite, luminance scanning) |
| `hive` / `hive_flutter` | Local storage for processing history |
| `pdf` | PDF generation from processed documents |
| `open_filex` | Open PDF in system default viewer (iOS/Android) |
| `image_picker` | Camera/gallery image selection |
| `share_plus` | Share files (images, PDFs) |
| `gal` | Save images to device photo gallery |
| `path_provider` | Device storage paths |
| `intl` | Date/time formatting |

## 🏗️ Architecture

**MVVM with GetX**, feature-based folder structure. Two controller layers:

- **Managers** (`GetxController` + `permanent: true`) — global singletons for shared business logic (`ImageProcessingManager`, `HistoryManager`)
- **Processors** (`GetxController`) — pipeline-specific logic (`FaceProcessor`, `DocumentProcessor`)
- **Screen controllers** (`GetxController`) — per-screen logic, only when the screen has local state. Skipped for simple screens that just read from a manager.

```
lib/
├── manager/          # Global singletons + processors
│   ├── image_processing_manager.dart  # Orchestrator: auto-detection + EXIF normalization
│   ├── face_processor.dart            # Face detection + grayscale pipeline
│   ├── document_processor.dart        # Text detection + edge detection + PDF
│   ├── document_edge_detection.dart   # Isolate: luminance-based edge detection
│   └── history_manager.dart           # Hive CRUD
├── ui/
│   ├── home/         # History grid + FAB
│   ├── capture/      # Camera/gallery picker (bottom sheet)
│   ├── processing/   # Progress screen with step descriptions
│   ├── result/       # Type router → face or document result view
│   │   └── document_collector_controller.dart  # Multi-page state
│   └── detail/       # Type-routed history detail (face + document)
├── model/            # Data models (ProcessingRecord, DocumentPage)
├── common/
│   ├── exceptions/   # Typed processing exceptions
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

## 🧠 Progress

1. **Model + Persistence** — `ProcessingRecord` with Hive, `HistoryManager` with reactive list. Chose Hive over SQLite: flat data, no relations, no queries beyond "load all".
2. **Face Processing Pipeline** — ML Kit face detection → isolate-based grayscale compositing → save result. Heavy pixel work runs in `Isolate.run()` to keep the UI thread free.
3. **Result Screen** — Before/after comparison, stats row, Done button.
4. **Home Screen & Full Loop** — 2-column history grid with type badges, animated delete, empty state. Completed the capture → process → result → home loop.
5. **Document Pipeline, Auto-Detection & Detail** — Auto-detection entry point (text recognizer first, face detection fallback). Luminance-based edge detection → crop + enhance → PDF. Type-routed detail screen for both face and document records.
6. **Polish & Hardening** — Race condition guards, file cleanup, Android permissions, image picker constraints. UX: staggered animations, haptic feedback, custom page transitions, styled snackbars, app icon.
7. **Bonus: OCR Text Extraction** — Persisted already-available recognized text. Built a collapsible card with copy-to-clipboard and in-text search with highlighted matches.
8. **Bonus: Multi-page PDF** — Deferred PDF generation, page collector with thumbnail strip, drag-to-reorder, per-page removal with confirmation, "Add Page" with background processing overlay.
9. **Code Audit & Cleanup** — Async file I/O, reentrance guards, temp file cleanup, dead code removal, file extraction, widget folder reorganization.

## 🔑 Key Technical Decisions

### Bonus Feature Choice

The brief offered four bonus options (max 2): Real-time Camera Overlay, Multi-page PDF, Batch Processing, and OCR Text Extraction. I went with **OCR** and **Multi-page PDF**. OCR was low-hanging fruit — the document pipeline already runs text recognition, so the detected text just needed to be persisted and surfaced in the UI. Multi-page PDF adds the most user-facing value to the document flow and required an interesting architectural change (deferring PDF generation, introducing a page collector). Both build on existing infrastructure rather than requiring new native dependencies.

### EXIF Orientation

Real camera photos had offset face overlays while AI-generated images worked fine. Root cause: `image_picker` on iOS writes correctly-oriented pixels but keeps a stale EXIF tag. ML Kit reads the file natively (handles EXIF correctly), but the `image` package sees the stale tag and rotates *already-correct* pixels again — so the two disagree on where faces are.

Fixed with a normalize-once pattern: the orchestrator bakes EXIF orientation upfront in a dedicated isolate and re-encodes as JPEG (which strips the tag). Both ML Kit and the processing isolate then work from the same, correctly-oriented pixels. Small cost (~200–500ms extra) for eliminating an entire class of platform-specific bugs.

### Luminance Edge Detection

Initial approach used text block bounds + padding to crop the document. This clipped content on pages with wide margins or sparse text. Replaced with luminance scanning: sample the paper brightness from the center of the text region, then scan outward from each seed edge row-by-row until brightness drops below 60% of the paper color. This finds actual paper boundaries regardless of text layout.

### Perspective Transform — Why We Skip It

The brief mentions perspective transformation. A proper implementation requires a 3x3 homography matrix with bilinear pixel interpolation — the `image` package doesn't provide this. It would require either OpenCV (native dependency, breaks the pure-Dart isolate approach) or ~200 lines of custom matrix math. Conscious trade-off: pure Dart with zero native CV dependencies, at the cost of not straightening angled shots. The edge detection + crop still produces clean results for documents photographed roughly straight-on.

### Isolate Strategy

ML Kit requires the main isolate (platform channels to native iOS/Android APIs). Pixel manipulation is pure Dart and CPU-heavy (500ms–2s for a 12MP photo). Running both on main would freeze the UI. Solution: ML Kit stays on main, all pixel work moves to `Isolate.run()`. The progress bar and animations stay smooth while processing happens in the background. PDF generation stays on main too — it's just wrapping already-encoded bytes, not crunching pixels.

### File Path Strategy

iOS rotates the app sandbox UUID on every reinstall/rebuild, breaking stored absolute paths. We store relative filenames only and resolve the full path at runtime via `path_provider`. Original images are copied to the documents directory alongside results so everything persists together.
