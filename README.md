# MagicBook

MagicBook is a kid-friendly color-by-number app. The current implementation is a Flutter mobile scaffold, and this README documents the architecture, feature set, data contracts, and migration target for rebuilding the product as a mobile-friendly React web app.

The app is intentionally free in this version. There is no paywall, subscription flow, usage limit, or premium feature flag in the current product surface.

## Product Summary

MagicBook lets a child or parent turn a photo into a printable coloring page, then draw directly on the generated artwork with guided difficulty modes.

Core flow:

1. Choose or demo a photo.
2. Pick generation complexity.
3. Wait through a playful processing screen while the image is transformed.
4. Preview the generated coloring page and palette.
5. Draw on the page using one of three drawing modes.
6. Save, share, print, or revisit saved works.

Primary audience:

- Children using touch-first drawing controls.
- Parents or guardians helping choose photos, print pages, or share finished work.
- A future React implementation should prioritize mobile web, PWA behavior, and large touch targets.

## Current Flutter Architecture

The app follows a simple layered architecture:

```text
main.dart
-> MagicBookApp
-> MagicBookScope
-> MagicBookController
-> Screens and widgets
-> Service interfaces
-> Local/mock pipeline implementations
-> Immutable model objects
```

Important source areas:

- `lib/src/app.dart`: application composition and dependency injection.
- `lib/src/state/magic_book_controller.dart`: central state machine and feature actions.
- `lib/src/state/magic_book_scope.dart`: inherited notifier that exposes the controller to widgets.
- `lib/src/screens/`: route-level UI screens.
- `lib/src/widgets/`: reusable UI and custom painting components.
- `lib/src/models/`: immutable app data models and enums.
- `lib/src/services/`: replaceable platform and generation services.
- `assets/images/loading_mascot.png`: generated transparent loading mascot.

Current dependency injection:

```text
MagicBookController(
  imagePickService: MobileImagePickService(),
  pipelineService: LocalColoringPipelineService(),
  galleryStorageService: InMemoryGalleryStorageService(),
  exportService: MobileExportService(),
)
```

For React, this maps cleanly to a context/provider plus reducer or store:

```text
<MagicBookProvider services={...}>
  <AppShell />
</MagicBookProvider>
```

## Feature Inventory

### Create

Current screen: `CreateScreen`

Features:

- Photo preview card.
- Choose photo from gallery.
- Use deterministic demo image.
- Complexity picker with Simple, Medium, and Detailed presets.
- Create button starts the coloring pipeline.
- Free-friendly feature strip: kid friendly, private, easy coloring.

React target:

- Use `<input type="file" accept="image/*">` for gallery/photo intake.
- Use `URL.createObjectURL(file)` for preview.
- Preserve the same preset labels and values.
- Disable create until an image or demo source exists.

### Image Processing

Current screen: `ProcessingScreen`

Features:

- Playful loading screen with animated mascot and sparkles.
- Progress bar bound to pipeline progress.
- Stage label updates as the pipeline advances.
- Automatically navigates to the ready screen when generation completes.

Current progress stages:

```text
0.10 Loading image
0.20 Preprocessing
0.35 Reducing colors
0.55 Finding regions
0.70 Cleaning regions
0.85 Drawing coloring page
1.00 Done
```

React target:

- Keep this as a full-screen mobile route or modal page.
- Use CSS keyframes or Framer Motion for mascot bounce and sparkle motion.
- Use `requestAnimationFrame` only for decorative effects; pipeline progress should come from real worker progress.

### Ready Preview

Current screen: `ReadyScreen`

Features:

- Generated line-art preview.
- Palette legend.
- Primary action: Draw Now.
- Secondary actions: share and print.
- Download/save action in the app bar.

React target:

- Render the generated artwork in an SVG or Canvas container.
- Use `window.print()` for MVP print support.
- Use Web Share API when available, with download fallback.

### Drawing Workspace

Current screen: `ColorByNumbersScreen`

Features:

- Drawing-first workspace.
- Mode selector:
  - `Right color`
  - `Zone color`
  - `Free draw`
- Live score chip.
- Region-aware artwork canvas.
- Palette swatches plus extra playful colors.
- Brush size slider.
- Undo, hint, and reset actions.

Drawing mode behavior:

- `Right color`: strokes only render inside regions whose expected palette color matches the selected color. Wrong or outside samples lower score.
- `Zone color`: the first touched region becomes selected; strokes render only inside that region with any selected color. Outside samples lower score.
- `Free draw`: strokes render anywhere; score compares sampled points against the expected region color and penalizes outside-art points.

Scoring model:

- Each stroke stores normalized points.
- Each sampled point increments `totalSamples`.
- Correct samples increment `correctSamples`.
- Score is `round(correctSamples / totalSamples * 100)`.
- Empty drawing state displays `100%`.

React target:

- Prefer one Canvas for fills/strokes and either SVG or Canvas for region hit-testing.
- Store drawing points normalized to `[0, 1]` so drawings survive responsive layout changes.
- Use `PointerEvent` APIs for mouse, touch, and stylus support.
- Keep region hit-testing deterministic by using `Path2D` or a generated offscreen region-id mask.

### Gallery and Works

Current screens: `GalleryScreen`, `MyWorksScreen`

Features:

- Gallery tab placeholder.
- My Works list backed by in-memory storage.
- Work cards show generated previews and palette counts.

React target:

- MVP can use local component state or `localStorage`.
- PWA-ready version should use IndexedDB for generated pages, source thumbnails, and stroke history.

## Data Models

### PickedImage

```ts
type PickedImage = {
  path: string;
  name: string;
  bytes?: Uint8Array;
  objectUrl?: string;
};
```

React note: browsers do not expose native file paths. Use `File.name`, `File`, `ArrayBuffer`, and `objectUrl` instead.

### ComplexityPreset

```ts
type ComplexityPreset = {
  id: "simple" | "medium" | "detailed";
  label: string;
  maxSide: number;
  paletteSize: number;
  minRegionAreaRatio: number;
  mergeColorThreshold: number;
  contourEpsilonFactor: number;
  strokeWidth: number;
  minNumberArea: number;
  minTextRadius: number;
  targetRegionRange: string;
};
```

Current values:

| Preset | maxSide | paletteSize | target regions |
| --- | ---: | ---: | --- |
| Simple | 768 | 8 | 20-30 |
| Medium | 1024 | 12 | 40-70 |
| Detailed | 1280 | 18 | 80-140 |

### PaletteColor

```ts
type PaletteColor = {
  number: number;
  hex: string;
  label: string;
};
```

### ColoringRegion

```ts
type NormalizedPoint = { x: number; y: number };

type ColoringRegion = {
  id: number;
  paletteNumber: number;
  area: number;
  contour: NormalizedPoint[];
  numberPosition: NormalizedPoint;
  isNumberable: boolean;
};
```

Contours are normalized coordinates. They should be scaled to the current canvas/SVG size at render time.

### ColoringResult

```ts
type ColoringResult = {
  id: string;
  title: string;
  createdAt: string;
  palette: PaletteColor[];
  regions: ColoringRegion[];
  coloredRegionIds: number[];
  canvasWidth: number;
  canvasHeight: number;
  sourceImagePath?: string;
  outlinePngBytes?: Uint8Array;
};
```

React note: prefer `outlinePngUrl?: string` or `outlinePngBlob?: Blob` in browser state.

### DrawingMode and DrawingStroke

```ts
type DrawingMode = "rightColor" | "zoneColor" | "freeDraw";

type DrawingStroke = {
  points: NormalizedPoint[];
  color: string;
  brushSize: number;
  mode: DrawingMode;
  totalSamples: number;
  correctSamples: number;
  selectedRegionId?: number;
};
```

## Service Boundaries

### ImagePickService

Flutter interface:

```text
pickFromCamera() -> PickedImage?
pickFromGallery() -> PickedImage?
```

React replacement:

- `selectImage(file: File): Promise<PickedImage>`
- Optional camera capture through `<input capture="environment">`.

### ColoringPipelineService

Flutter interface:

```text
generate({
  inputImagePath,
  inputImageBytes,
  inputImageName,
  preset,
  onProgress,
}) -> ColoringResult
```

React replacement:

```ts
type GenerateColoringInput = {
  file?: File;
  demoId?: string;
  preset: ComplexityPreset;
  onProgress: (progress: number, stageLabel: string) => void;
};

type ColoringPipelineService = {
  generate(input: GenerateColoringInput): Promise<ColoringResult>;
};
```

Implementation recommendation:

- Run image processing in a Web Worker.
- Use `OffscreenCanvas` when available.
- Keep the service asynchronous and progress-driven so the UI remains responsive.
- Consider OpenCV.js for contour extraction and connected components if parity with native image processing becomes important.

### GalleryStorageService

Flutter interface:

```text
loadWorks() -> List<ColoringResult>
saveWork(result)
```

React replacement:

- MVP: in-memory array or `localStorage`.
- Production/PWA: IndexedDB with separate stores for results, generated outline blobs, and drawing sessions.

### ExportService

Flutter interface:

```text
saveToGallery(result)
share(result)
print(result)
```

React replacement:

- Save/download: render canvas to `Blob`, then trigger download.
- Share: use `navigator.share` and `navigator.canShare` when available.
- Print: generate a printable route or hidden print layout and call `window.print()`.

## Image Pipeline Spec

The current local pipeline is implemented in `LocalColoringPipelineService`. It is pure Dart and should be treated as the behavioral reference for the React rewrite.

Pipeline steps:

```text
load image bytes
-> decode image
-> bake orientation
-> resize to preset maxSide
-> gaussian blur by preset
-> extract outline mask from luminance/saturation
-> build outline PNG
-> convert pixels to Lab color space
-> quantize colors to preset palette size
-> extract connected components
-> filter and merge regions
-> build palette labels
-> trace/simplify contours
-> place region numbers
-> return ColoringResult
```

Important output constraints:

- Region contours must be normalized coordinates.
- Regions must map to `paletteNumber`.
- `canvasWidth` and `canvasHeight` define the original generation aspect ratio.
- The UI must render at any responsive size without changing data coordinates.
- Region lookup for drawing and scoring must match rendered region paths.

Suggested React/Web implementation options:

1. Web Worker plus Canvas/ImageData for MVP parity.
2. OpenCV.js in a worker for stronger contour/component behavior.
3. Server-side image processing if browser performance is not acceptable on low-end mobile devices.

## Vectorization Algorithm Implementation

This section describes the current image-to-region vectorization algorithm in implementation-level detail for the React migration. The goal is to convert a raster photo into a `ColoringResult` made of a limited palette, fillable connected regions, normalized polygon contours, number positions, and an optional outline overlay.

The current Flutter implementation lives in `LocalColoringPipelineService`. It is not a full SVG tracer; it is a pragmatic color-region vectorizer optimized for color-by-number pages.

### Inputs and Outputs

```ts
type VectorizeInput = {
  image: ImageBitmap | ImageData;
  preset: ComplexityPreset;
  onProgress?: (progress: number, stage: string) => void;
};

type VectorizeOutput = {
  palette: PaletteColor[];
  regions: ColoringRegion[];
  canvasWidth: number;
  canvasHeight: number;
  outlinePngBlob?: Blob;
};
```

All region contours and number positions are normalized:

```text
normalizedX = pixelX / canvasWidth
normalizedY = pixelY / canvasHeight
```

This lets the drawing UI scale the artwork to any mobile viewport without mutating the result data.

### 1. Decode, Orient, and Resize

Decode the image into RGBA pixels, apply EXIF orientation if available, then resize it so the longest side equals `preset.maxSide`.

Browser implementation notes:

- Use `createImageBitmap(file, { imageOrientation: "from-image" })` where supported.
- Draw the bitmap to an `OffscreenCanvas` inside a Web Worker.
- Use `ctx.getImageData(0, 0, width, height)` to read pixels.
- For MVP downscaling, Canvas interpolation is acceptable.

```ts
function resizeForPreset(source: ImageBitmap, preset: ComplexityPreset) {
  const longest = Math.max(source.width, source.height);
  const scale = preset.maxSide / longest;
  const width = Math.round(source.width * scale);
  const height = Math.round(source.height * scale);
  return drawToImageData(source, width, height);
}
```

### 2. Smooth the Fill Source

Apply a small blur before color quantization. This reduces speckle and creates larger child-friendly regions.

Current blur radius:

| Preset | Radius |
| --- | ---: |
| Simple | 3 |
| Medium | 2 |
| Detailed | 1 |

The outline mask should be extracted from the resized original, while color quantization uses the smoothed image. This keeps ink/detail detection sharp without making fill regions too noisy.

### 3. Extract the Outline Mask

The outline mask identifies pixels that should become ink rather than fillable color regions.

For each pixel:

```ts
const maxChannel = Math.max(r, g, b);
const minChannel = Math.min(r, g, b);
const luminance = r * 0.2126 + g * 0.7152 + b * 0.0722;
const saturation = maxChannel === 0 ? 0 : (maxChannel - minChannel) / maxChannel;

const isInk = luminance < 92 || (luminance < 125 && saturation < 0.45);
outlineMask[index] = isInk ? 1 : 0;
```

Outline pixels are excluded from quantization and connected-component extraction by assigning label `-1`.

The optional transparent outline overlay is generated from the mask:

- ink color: `rgba(18, 13, 42, alpha)`
- alpha by luminance:
  - `< 40`: `255`
  - `< 92`: `225`
  - otherwise: `185`
- ink thickening radius:
  - Simple: `1`
  - Medium: `1`
  - Detailed: `0`

### 4. Convert RGB to Lab

Convert smoothed fill pixels from sRGB to CIE Lab. Lab distance is used because it is closer to perceived color difference than RGB distance.

Conversion path:

```text
sRGB -> linear RGB -> XYZ using D65 matrix -> Lab
```

Distance function:

```ts
function labDistanceSquared(a: LabColor, b: LabColor) {
  const dl = a.l - b.l;
  const da = a.a - b.a;
  const db = a.b - b.b;
  return dl * dl + da * da + db * db;
}
```

For web performance, prefer typed arrays instead of per-pixel objects:

```ts
const labL = new Float32Array(pixelCount);
const labA = new Float32Array(pixelCount);
const labB = new Float32Array(pixelCount);
```

### 5. Quantize Colors With K-Means

Calculate cluster count:

```ts
const fillPixelCount = countWhere(outlineMask, value => value === 0);
const k = Math.min(preset.paletteSize, Math.max(2, Math.floor(fillPixelCount / 80)));
```

Sample fill pixels so clustering remains mobile-friendly:

```ts
const sampleStride = Math.max(1, Math.floor(totalPixels / 12000));
const samples = [];

for (let i = 0; i < totalPixels; i += sampleStride) {
  if (outlineMask[i] === 0) samples.push(i);
}
```

Initial centers:

1. Sort sampled colors by Lab lightness.
2. Break ties by approximate hue: `atan2(b, a)`.
3. Pick evenly spaced samples from the sorted list.

Run 10 K-means iterations:

```ts
for (let iteration = 0; iteration < 10; iteration++) {
  const sums = makeLabAccumulators(k);

  for (const sampleIndex of samples) {
    const label = nearestCenter(sampleIndex, centers);
    sums[label].add(sampleIndex);
  }

  for (let i = 0; i < k; i++) {
    if (sums[i].count > 0) centers[i] = sums[i].average();
  }
}
```

Label every pixel after clustering:

```ts
const labels = new Int32Array(totalPixels);
const fullSums = makeLabAccumulators(k);

for (let i = 0; i < totalPixels; i++) {
  if (outlineMask[i] === 1) {
    labels[i] = -1;
    continue;
  }

  const label = nearestCenter(i, centers);
  labels[i] = label;
  fullSums[label].add(i);
}
```

The final palette color for each cluster is the full-image average of every pixel assigned to that cluster, not just the sampled average.

### 6. Build and Sort the Palette

Convert final Lab cluster colors back to RGB, then create palette entries:

```ts
type PaletteEntry = {
  sourceLabel: number;
  hex: string;
  label: string;
  hue: number;
  lightness: number;
};
```

Current behavior:

- `hex` is uppercase RGB hex, for example `#FF9F1C`.
- `label` is a broad color family from HSV hue/luminance.
- Entries sort by hue ascending, then lightness descending.
- User-facing palette numbers are assigned after sorting, starting at `1`.

```ts
const paletteNumberByLabel = new Map<number, number>();

sortedPaletteEntries.forEach((entry, index) => {
  paletteNumberByLabel.set(entry.sourceLabel, index + 1);
});
```

Regions store the sorted `paletteNumber`, not the raw K-means label.

### 7. Extract Connected Components

Connected components turn the label image into fillable zones.

Rules:

- Ignore label `-1` outline pixels.
- Use 4-neighbor connectivity: left, right, up, down.
- Only connect pixels with the exact same quantized label.

For each component, collect:

```ts
type Component = {
  label: number;
  area: number;
  sumX: number;
  sumY: number;
  minX: number;
  minY: number;
  maxX: number;
  maxY: number;
  pixels: number[];
};
```

BFS implementation:

```ts
function extractComponents(labels: Int32Array, width: number, height: number) {
  const visited = new Uint8Array(labels.length);
  const queue = new Int32Array(labels.length);
  const components: Component[] = [];

  for (let start = 0; start < labels.length; start++) {
    if (visited[start] || labels[start] < 0) continue;

    const colorLabel = labels[start];
    let head = 0;
    let tail = 0;
    queue[tail++] = start;
    visited[start] = 1;

    const component = createEmptyComponent(colorLabel);

    while (head < tail) {
      const index = queue[head++];
      const x = index % width;
      const y = Math.floor(index / width);
      component.add(index, x, y);

      for (const [dx, dy] of [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
        const nx = x + dx;
        const ny = y + dy;
        if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;

        const neighbor = ny * width + nx;
        if (visited[neighbor] || labels[neighbor] !== colorLabel) continue;

        visited[neighbor] = 1;
        queue[tail++] = neighbor;
      }
    }

    components.push(component);
  }

  return components;
}
```

### 8. Filter and Cap Regions

Sort components by descending area and keep readable regions.

```ts
const imageArea = width * height;
const minArea = Math.max(24, Math.round(imageArea * preset.minRegionAreaRatio));
const maxRegions = maxRegionsForPreset(preset);

const retained = components
  .sort((a, b) => b.area - a.area)
  .filter(component => component.area >= minArea)
  .slice(0, maxRegions);
```

Fallback:

- If all components are filtered out, keep the largest components up to the preset max.

This prevents blank results on unusual images.

### 9. Trace Component Boundaries

Each retained component becomes one polygon contour.

The algorithm traces boundaries on grid-corner points instead of pixel centers. For an image of `width x height`, the boundary grid is `(width + 1) x (height + 1)`.

For every pixel in the component, emit a directed boundary edge for each side that touches the image bounds or a pixel outside the same component.

Clockwise edge emission:

```text
top:    (x, y)         -> (x + 1, y)
right:  (x + 1, y)     -> (x + 1, y + 1)
bottom: (x + 1, y + 1) -> (x, y + 1)
left:   (x, y + 1)     -> (x, y)
```

Point keys:

```ts
const gridWidth = width + 1;
const pointKey = (x: number, y: number) => y * gridWidth + x;
```

Boundary edge shape:

```ts
type BoundaryEdge = {
  start: number;
  end: number;
  key: string;
  direction: 0 | 1 | 2 | 3;
};
```

Direction is derived from `end - start`:

```text
delta == 1   -> 0 east
delta > 1    -> 1 south
delta == -1  -> 2 west
otherwise    -> 3 north
```

Store both a flat edge list and an adjacency map:

```ts
const allEdges: BoundaryEdge[] = [];
const edgesByStart = new Map<number, BoundaryEdge[]>();
```

If fewer than four edges are produced, fall back to the component bounding box.

### 10. Trace Boundary Loops

A component can produce multiple loops if it has holes or ambiguous fragments. Trace all loops and keep the longest loop as the outer contour.

Loop tracing algorithm:

1. Keep a set of unused edge keys.
2. Pick the next unused edge.
3. Start a loop with `firstEdge.start`.
4. Append each `currentEdge.end`.
5. Stop when the current end returns to the first loop point.
6. At each point, candidates are unused edges where `edge.start === currentEdge.end`.
7. Accept only loops with at least five points including the closing point.
8. Remove the duplicated closing point before converting to normalized coordinates.

Candidate selection:

```ts
const turn = (next.direction - current.direction + 4) % 4;

const score =
  turn === 1 ? 3 : // right turn
  turn === 0 ? 2 : // straight
  turn === 3 ? 1 : // left turn
  0;               // reverse
```

Sort candidates by score descending and take the first. This keeps tracing stable at ambiguous grid junctions.

After tracing:

```ts
loops.sort((a, b) => b.length - a.length);
const outerLoop = loops[0];
```

Convert each point key to a normalized point:

```ts
function keyToNormalizedPoint(
  key: number,
  gridWidth: number,
  width: number,
  height: number,
): NormalizedPoint {
  const x = key % gridWidth;
  const y = Math.floor(key / gridWidth);
  return { x: x / width, y: y / height };
}
```

### 11. Simplify the Contour

The current simplifier has two passes.

First, remove collinear points:

```ts
const dx1 = Math.sign(current.x - previous.x);
const dy1 = Math.sign(current.y - previous.y);
const dx2 = Math.sign(next.x - current.x);
const dy2 = Math.sign(next.y - current.y);

const isCollinear = dx1 === dx2 && dy1 === dy2;
```

Drop the current point when it is collinear with its neighbors.

Second, cap contour point count:

```ts
if (points.length > maxContourPoints) {
  const stride = Math.ceil(points.length / maxContourPoints);
  points = points.filter((_, index) => index % stride === 0);
}
```

Current caps:

| Preset | Max contour points |
| --- | ---: |
| Simple | 220 |
| Medium | 360 |
| Detailed | 520 |

This is cheaper than Douglas-Peucker and suitable for the MVP. A React implementation can replace this pass with Ramer-Douglas-Peucker using a preset epsilon, as long as the output remains normalized.

### 12. Place Numbers

The current number position is the component centroid:

```ts
const numberPosition = {
  x: (component.sumX / component.area) / width,
  y: (component.sumY / component.area) / height,
};
```

A region is numberable when both area and short-side size are large enough:

```ts
const shortSide = Math.min(
  component.maxX - component.minX + 1,
  component.maxY - component.minY + 1,
);

const isNumberable =
  component.area >= preset.minNumberArea &&
  shortSide >= preset.minTextRadius * 2;
```

Known limitation:

- A centroid can land outside a concave region.
- A future implementation can use a distance transform or polylabel algorithm while preserving the same `numberPosition` field.

### 13. Build ColoringRegion Objects

For every retained component:

```ts
const region: ColoringRegion = {
  id: nextId++,
  paletteNumber: paletteNumberByLabel.get(component.label) ?? 1,
  area: component.area,
  contour,
  numberPosition,
  isNumberable,
};
```

The final `ColoringResult` includes the sorted palette, retained vector regions, processed canvas dimensions, optional outline PNG overlay, and empty drawing state.

### Failure and Fallback Rules

Required fallbacks:

- If image decode fails, return a user-facing unsupported image error.
- If no fillable pixels exist after outline extraction, fail with `No fillable image regions were found`.
- If a component boundary cannot produce a valid loop, use the component bounding box.
- If all components are filtered out by area threshold, keep the largest components up to the preset max.

### Recommended Web Worker Contract

```ts
type VectorizeWorkerRequest = {
  type: "vectorize";
  id: string;
  fileBuffer: ArrayBuffer;
  fileName: string;
  preset: ComplexityPreset;
};

type VectorizeWorkerProgress = {
  type: "progress";
  id: string;
  progress: number;
  stageLabel: string;
};

type VectorizeWorkerSuccess = {
  type: "success";
  id: string;
  result: ColoringResult;
  outlinePngBuffer?: ArrayBuffer;
};

type VectorizeWorkerFailure = {
  type: "failure";
  id: string;
  message: string;
};
```

Transfer large buffers instead of cloning them:

```ts
worker.postMessage(request, [fileBuffer]);
postMessage(success, outlinePngBuffer ? [outlinePngBuffer] : []);
```

### Performance Notes

- Keep large raster data in typed arrays: `Uint8ClampedArray`, `Uint8Array`, `Int32Array`, and `Float32Array`.
- Avoid storing every pixel as an object in the React implementation.
- Prefer separate channel arrays for Lab:
  - `labL: Float32Array`
  - `labA: Float32Array`
  - `labB: Float32Array`
- Run vectorization off the main thread.
- Generate renderable paths once per result and cache them by `region.id`.
- For drawing hit-tests, use `Path2D` first; if it is too slow on low-end devices, create an offscreen region-id mask.

## React Mobile Web Target Architecture

Recommended stack:

- React with TypeScript.
- Vite or Next.js depending on routing/deployment needs.
- PWA support for installable mobile web.
- CSS modules, Tailwind, or a small design-token CSS layer.
- Zustand, Redux Toolkit, or React reducer/context for app state.
- Canvas/SVG for artwork rendering and pointer drawing.
- IndexedDB through Dexie or a small wrapper for persisted works.
- Vitest plus React Testing Library for unit/component tests.
- Playwright for mobile viewport workflow tests.

Recommended folder shape:

```text
src/
  app/
    App.tsx
    MagicBookProvider.tsx
    routes.tsx
  models/
    coloring.ts
    drawing.ts
    presets.ts
  services/
    coloringPipeline.ts
    galleryStorage.ts
    exportService.ts
    imagePick.ts
  workers/
    coloringPipeline.worker.ts
  screens/
    CreateScreen.tsx
    ProcessingScreen.tsx
    ReadyScreen.tsx
    DrawScreen.tsx
    GalleryScreen.tsx
    MyWorksScreen.tsx
  components/
    ArtworkCanvas.tsx
    ComplexityPicker.tsx
    PaletteLegend.tsx
    PhotoPreviewCard.tsx
    PrimaryButton.tsx
    WorkCard.tsx
  theme/
    tokens.css
```

State slices:

- `job`: selected image, preset, status, progress, error, generated result.
- `navigation`: selected tab or route.
- `drawing`: mode, selected palette/color, selected region, brush size, strokes, active stroke, score.
- `works`: saved generated results.

Suggested job statuses:

```ts
type ColoringJobStatus =
  | "idle"
  | "imageSelected"
  | "processing"
  | "completed"
  | "failed";
```

## UI and Design Specs

Design language:

- Playful, child-friendly, and touch-first.
- Purple/yellow brand accents with pink, mint, and sky supporting colors.
- White drawing surfaces on a lavender app background.
- No premium/freemium affordances.

Current color tokens:

```css
--purple: #7654f5;
--deep-purple: #241a52;
--lavender: #f7f3ff;
--yellow: #ffd84d;
--pink: #ff7fa5;
--mint: #59d2a6;
--sky: #73c7f4;
--ink: #171336;
--line: #e6e0f5;
```

Mobile layout requirements:

- Minimum touch target: 44px.
- Bottom navigation remains reachable by thumb.
- Drawing screen should keep artwork large and controls scrollable below it.
- Avoid tiny color controls; swatches should be at least 40px.
- Use responsive artwork sizing based on `ColoringResult.aspectRatio`.
- Preserve normalized drawing data across orientation and viewport changes.

Core routes/tabs:

- `Create`
- `Gallery`
- `My Works`
- `Processing`
- `Ready`
- `Draw`

## Testing Expectations

Current Flutter tests cover:

- App launch.
- Complexity selection.
- Photo preview.
- Processing navigation.
- Palette rendering.
- Drawing screen controls.
- Drawing score rules.
- Bottom navigation.
- Mock pipeline shape.
- Local segmentation behavior.

React migration should include:

- Unit tests for presets, scoring, region hit-testing, and drawing reducer actions.
- Component tests for Create, Processing, Ready, and Draw screens.
- Worker tests for pipeline progress and result shape.
- Playwright mobile tests for the full create-to-draw flow.
- Snapshot or pixel-tolerance tests for generated artwork rendering if Canvas behavior becomes complex.

Minimum acceptance tests:

- Free UI has no premium icon, premium text, paywall, or locked mode.
- A selected image enables generation.
- Progress screen shows stage and progress until generation completes.
- Generated result contains palette, regions, dimensions, and title.
- Draw screen exposes all three modes.
- Right-color mode clips strokes to matching-color regions.
- Zone-color mode clips strokes to the selected region.
- Free-draw mode renders anywhere and scores against expected region colors.
- Undo/reset update visible strokes and score.

## Migration Notes

- Browser file APIs replace native image paths.
- Flutter `CustomPainter` maps best to Canvas, SVG, or a hybrid:
  - SVG is convenient for region paths and hit-testing.
  - Canvas is better for brush strokes and export.
  - A hybrid can render region paths as SVG and strokes as Canvas overlay.
- Store all region and stroke points normalized so the drawing remains responsive.
- Heavy image processing should not run on the main thread.
- If OpenCV.js is used, lazy-load it only when processing starts.
- Keep the pipeline service interface stable so browser, worker, and server implementations can be swapped.

## Current Development Commands

Flutter commands for the existing implementation:

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

Suggested React commands after migration:

```sh
npm install
npm run dev
npm run lint
npm run test
npm run test:e2e
npm run build
```
