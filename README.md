# MagicBook

MagicBook is a Flutter mobile scaffold for a kid-friendly color-by-number app. It includes photo intake, complexity presets, local generation progress, printable coloring-page preview, palette legend, interactive coloring, gallery, and saved works.

## Current Scaffold

- Flutter app for Android and iOS with package id `com.chakiblabs.magicbook`.
- Inspired playful UI with purple/yellow branding, child-friendly controls, and bottom navigation.
- Replaceable service interfaces for image picking, generation, gallery storage, and export.
- Local pure-Dart backend that decodes images, resizes, smooths, quantizes in Lab color space, extracts connected regions, filters tiny components, and returns numbered regions for the UI.
- Mock pipeline remains available for demo paths and deterministic widget tests while the native OpenCV bridge is pending.
- Widget and unit tests for launch, complexity selection, generation flow, palette rendering, navigation, presets, mock result shape, and real-image local segmentation.

## Pipeline Boundary

The app currently injects `LocalColoringPipelineService`, which is a portable MVP backend. A later native implementation can replace it with `OpenCvColoringPipelineService` behind the same interface:

```text
resize
-> bilateral filter
-> Lab k-means
-> connected components
-> adjacency-based small-region merging
-> contour tracing
-> approxPolyDP simplification
-> distance-transform number placement
-> PNG/SVG export
```

The preset values live in `lib/src/models/complexity_preset.dart`.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```
