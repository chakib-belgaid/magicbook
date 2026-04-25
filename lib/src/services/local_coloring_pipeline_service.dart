import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/coloring_region.dart';
import '../models/coloring_result.dart';
import '../models/complexity_preset.dart';
import '../models/palette_color.dart';
import 'coloring_pipeline_service.dart';
import 'mock_coloring_pipeline_service.dart';

class LocalColoringPipelineService implements ColoringPipelineService {
  const LocalColoringPipelineService({
    this.mockFallback = const MockColoringPipelineService(),
  });

  final ColoringPipelineService mockFallback;

  @override
  Future<ColoringResult> generate({
    required String inputImagePath,
    Uint8List? inputImageBytes,
    String? inputImageName,
    required ComplexityPreset preset,
    required PipelineProgressCallback onProgress,
  }) async {
    if (inputImagePath.startsWith('demo://')) {
      return mockFallback.generate(
        inputImagePath: inputImagePath,
        inputImageBytes: inputImageBytes,
        inputImageName: inputImageName,
        preset: preset,
        onProgress: onProgress,
      );
    }

    onProgress(.10, 'Loading image');
    final imageBytes = inputImageBytes ?? await _readImageFile(inputImagePath);
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw StateError('Unsupported image format.');
    }

    onProgress(.20, 'Preprocessing');
    final source = img.bakeOrientation(decoded);
    final resized = _resizeForPreset(source, preset);
    final smoothed = img.gaussianBlur(resized, radius: _blurRadiusFor(preset));

    onProgress(.35, 'Reducing colors');
    final labPixels = _extractLabPixels(smoothed);
    final outlineMask = _extractOutlineMask(resized);
    final outlinePngBytes = _buildOutlinePng(
      smoothed.width,
      smoothed.height,
      resized,
      outlineMask,
      preset,
    );
    final quantized = _quantize(
      labPixels,
      outlineMask: outlineMask,
      requestedK: preset.paletteSize,
    );

    onProgress(.55, 'Finding regions');
    final components = _extractComponents(
      labels: quantized.labels,
      width: smoothed.width,
      height: smoothed.height,
    );

    onProgress(.70, 'Cleaning regions');
    final paletteEntries = _buildPalette(quantized.palette);
    final paletteNumberByLabel = <int, int>{
      for (var i = 0; i < paletteEntries.length; i += 1)
        paletteEntries[i].sourceLabel: i + 1,
    };
    final regions = _buildRegions(
      components: components,
      width: smoothed.width,
      height: smoothed.height,
      preset: preset,
      paletteNumberByLabel: paletteNumberByLabel,
    );

    onProgress(.85, 'Drawing coloring page');
    final now = DateTime.now();
    final title = _titleFromPath(inputImageName ?? inputImagePath);

    onProgress(1, 'Done');
    return ColoringResult(
      id: 'local-${now.microsecondsSinceEpoch}',
      title: title,
      createdAt: now,
      sourceImagePath: inputImagePath,
      palette: paletteEntries
          .map(
            (entry) => PaletteColor(
              number: paletteNumberByLabel[entry.sourceLabel]!,
              hex: entry.hex,
              label: entry.label,
            ),
          )
          .toList(),
      regions: regions,
      coloredRegionIds: const <int>{},
      canvasWidth: smoothed.width,
      canvasHeight: smoothed.height,
      outlinePngBytes: outlinePngBytes,
    );
  }

  img.Image _resizeForPreset(img.Image source, ComplexityPreset preset) {
    final longestSide = math.max(source.width, source.height);
    final targetSide = preset.maxSide;
    if (longestSide == targetSide) {
      return source;
    }

    final scale = targetSide / longestSide;
    return img.copyResize(
      source,
      width: (source.width * scale).round(),
      height: (source.height * scale).round(),
      interpolation: scale > 1
          ? img.Interpolation.cubic
          : img.Interpolation.average,
    );
  }

  int _blurRadiusFor(ComplexityPreset preset) {
    return switch (preset) {
      ComplexityPreset.simple => 3,
      ComplexityPreset.medium => 2,
      ComplexityPreset.detailed => 1,
    };
  }

  Future<Uint8List> _readImageFile(String inputImagePath) async {
    final imageFile = File(inputImagePath);
    if (!imageFile.existsSync()) {
      throw StateError('Image file does not exist: $inputImagePath');
    }
    return imageFile.readAsBytes();
  }

  List<_LabColor> _extractLabPixels(img.Image image) {
    final pixels = List<_LabColor>.filled(
      image.width * image.height,
      const _LabColor(0, 0, 0),
    );
    var index = 0;
    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        pixels[index] = _rgbToLab(
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
        );
        index += 1;
      }
    }
    return pixels;
  }

  Uint8List _extractOutlineMask(img.Image image) {
    final mask = Uint8List(image.width * image.height);
    var index = 0;
    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        final red = pixel.r.toInt();
        final green = pixel.g.toInt();
        final blue = pixel.b.toInt();
        final maxChannel = math.max(red, math.max(green, blue));
        final minChannel = math.min(red, math.min(green, blue));
        final luminance = red * .2126 + green * .7152 + blue * .0722;
        final saturation = maxChannel == 0
            ? 0
            : (maxChannel - minChannel) / maxChannel;
        if (luminance < 92 || (luminance < 125 && saturation < .45)) {
          mask[index] = 1;
        }
        index += 1;
      }
    }
    return mask;
  }

  Uint8List _buildOutlinePng(
    int width,
    int height,
    img.Image source,
    Uint8List outlineMask,
    ComplexityPreset preset,
  ) {
    final outline = img.Image(width: width, height: height, numChannels: 4);
    final radius = _inkRadiusFor(preset);

    for (var y = 0; y < height; y += 1) {
      for (var x = 0; x < width; x += 1) {
        final index = y * width + x;
        if (outlineMask[index] == 0) {
          continue;
        }
        final alpha = _inkAlphaFor(source.getPixel(x, y));
        for (var dy = -radius; dy <= radius; dy += 1) {
          final ny = y + dy;
          if (ny < 0 || ny >= height) {
            continue;
          }
          for (var dx = -radius; dx <= radius; dx += 1) {
            final nx = x + dx;
            if (nx < 0 || nx >= width || dx * dx + dy * dy > radius * radius) {
              continue;
            }
            final existingAlpha = outline.getPixel(nx, ny).a.toInt();
            if (alpha > existingAlpha) {
              outline.setPixelRgba(nx, ny, 18, 13, 42, alpha);
            }
          }
        }
      }
    }

    return Uint8List.fromList(img.encodePng(outline));
  }

  int _inkRadiusFor(ComplexityPreset preset) {
    return switch (preset) {
      ComplexityPreset.simple => 1,
      ComplexityPreset.medium => 1,
      ComplexityPreset.detailed => 0,
    };
  }

  int _inkAlphaFor(img.Pixel pixel) {
    final red = pixel.r.toInt();
    final green = pixel.g.toInt();
    final blue = pixel.b.toInt();
    final luminance = red * .2126 + green * .7152 + blue * .0722;
    if (luminance < 40) {
      return 255;
    }
    if (luminance < 92) {
      return 225;
    }
    return 185;
  }

  _QuantizationResult _quantize(
    List<_LabColor> pixels, {
    required Uint8List outlineMask,
    required int requestedK,
  }) {
    final fillPixelCount = outlineMask.where((value) => value == 0).length;
    final k = math.min(requestedK, math.max(2, fillPixelCount ~/ 80));
    final sampleStride = math.max(1, pixels.length ~/ 12000);
    final samples = <_LabColor>[
      for (var i = 0; i < pixels.length; i += sampleStride)
        if (outlineMask[i] == 0) pixels[i],
    ];
    if (samples.isEmpty) {
      throw StateError('No fillable image regions were found.');
    }
    final centers = _initialCenters(samples, k);

    for (var iteration = 0; iteration < 10; iteration += 1) {
      final sums = List<_LabAccumulator>.generate(k, (_) => _LabAccumulator());
      for (final pixel in samples) {
        sums[_nearestCenter(pixel, centers)].add(pixel);
      }
      for (var i = 0; i < centers.length; i += 1) {
        if (sums[i].count > 0) {
          centers[i] = sums[i].average();
        }
      }
    }

    final labels = Int32List(pixels.length);
    final fullSums = List<_LabAccumulator>.generate(
      k,
      (_) => _LabAccumulator(),
    );
    for (var i = 0; i < pixels.length; i += 1) {
      if (outlineMask[i] == 1) {
        labels[i] = -1;
        continue;
      }
      final label = _nearestCenter(pixels[i], centers);
      labels[i] = label;
      fullSums[label].add(pixels[i]);
    }

    final palette = <_LabColor>[
      for (var i = 0; i < k; i += 1)
        fullSums[i].count == 0 ? centers[i] : fullSums[i].average(),
    ];

    return _QuantizationResult(labels: labels, palette: palette);
  }

  List<_LabColor> _initialCenters(List<_LabColor> samples, int k) {
    final sorted = [...samples]
      ..sort((a, b) {
        final lightness = a.l.compareTo(b.l);
        if (lightness != 0) {
          return lightness;
        }
        final aHue = math.atan2(a.b, a.a);
        final bHue = math.atan2(b.b, b.a);
        return aHue.compareTo(bHue);
      });

    return [
      for (var i = 0; i < k; i += 1)
        sorted[((i + .5) * sorted.length / k).floor().clamp(
          0,
          sorted.length - 1,
        )],
    ];
  }

  int _nearestCenter(_LabColor color, List<_LabColor> centers) {
    var bestIndex = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < centers.length; i += 1) {
      final distance = color.distanceSquaredTo(centers[i]);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  List<_Component> _extractComponents({
    required Int32List labels,
    required int width,
    required int height,
  }) {
    final visited = Uint8List(labels.length);
    final queue = Int32List(labels.length);
    final components = <_Component>[];

    for (var start = 0; start < labels.length; start += 1) {
      if (visited[start] == 1 || labels[start] < 0) {
        continue;
      }

      final colorLabel = labels[start];
      var head = 0;
      var tail = 0;
      queue[tail] = start;
      tail += 1;
      visited[start] = 1;

      var area = 0;
      var sumX = 0;
      var sumY = 0;
      var minX = width;
      var minY = height;
      var maxX = 0;
      var maxY = 0;
      final pixels = <int>[];

      while (head < tail) {
        final index = queue[head];
        head += 1;

        final x = index % width;
        final y = index ~/ width;
        area += 1;
        pixels.add(index);
        sumX += x;
        sumY += y;
        minX = math.min(minX, x);
        minY = math.min(minY, y);
        maxX = math.max(maxX, x);
        maxY = math.max(maxY, y);

        const neighborOffsets = [-1, 1, 0, 0];
        const rowOffsets = [0, 0, -1, 1];
        for (var direction = 0; direction < 4; direction += 1) {
          final nx = x + neighborOffsets[direction];
          final ny = y + rowOffsets[direction];
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
            continue;
          }
          final neighbor = ny * width + nx;
          if (visited[neighbor] == 1 || labels[neighbor] != colorLabel) {
            continue;
          }
          visited[neighbor] = 1;
          queue[tail] = neighbor;
          tail += 1;
        }
      }

      components.add(
        _Component(
          label: colorLabel,
          area: area,
          sumX: sumX,
          sumY: sumY,
          minX: minX,
          minY: minY,
          maxX: maxX,
          maxY: maxY,
          pixels: pixels,
        ),
      );
    }

    return components;
  }

  List<_PaletteEntry> _buildPalette(List<_LabColor> palette) {
    final entries = <_PaletteEntry>[];
    for (var i = 0; i < palette.length; i += 1) {
      final rgb = _labToRgb(palette[i]);
      final color = Color.fromARGB(255, rgb.r, rgb.g, rgb.b);
      entries.add(
        _PaletteEntry(
          sourceLabel: i,
          hex: _rgbToHex(rgb),
          label: _nameForColor(color),
          hue: HSVColor.fromColor(color).hue,
          lightness: palette[i].l,
        ),
      );
    }

    entries.sort((a, b) {
      final hue = a.hue.compareTo(b.hue);
      if (hue != 0) {
        return hue;
      }
      return b.lightness.compareTo(a.lightness);
    });
    return entries;
  }

  List<ColoringRegion> _buildRegions({
    required List<_Component> components,
    required int width,
    required int height,
    required ComplexityPreset preset,
    required Map<int, int> paletteNumberByLabel,
  }) {
    final imageArea = width * height;
    final minArea = math.max(
      24,
      (imageArea * preset.minRegionAreaRatio).round(),
    );
    final maxRegions = _maxRegionsFor(preset);
    final sorted = [...components]..sort((a, b) => b.area.compareTo(a.area));
    final retained = sorted
        .where((component) => component.area >= minArea)
        .take(maxRegions)
        .toList();

    final fallback = retained.isEmpty
        ? sorted.take(math.min(maxRegions, sorted.length)).toList()
        : retained;

    var id = 1;
    return fallback.map((component) {
      final normalizedContour = _contourFromBoundary(
        component,
        width,
        height,
        preset,
      );
      final center = Offset(
        (component.sumX / component.area) / width,
        (component.sumY / component.area) / height,
      );
      final shortSide = math.min(
        component.maxX - component.minX + 1,
        component.maxY - component.minY + 1,
      );

      return ColoringRegion(
        id: id++,
        paletteNumber: paletteNumberByLabel[component.label] ?? 1,
        area: component.area,
        contour: normalizedContour,
        numberPosition: center,
        isNumberable:
            component.area >= preset.minNumberArea &&
            shortSide >= preset.minTextRadius * 2,
      );
    }).toList();
  }

  int _maxRegionsFor(ComplexityPreset preset) {
    return switch (preset) {
      ComplexityPreset.simple => 30,
      ComplexityPreset.medium => 70,
      ComplexityPreset.detailed => 140,
    };
  }

  List<Offset> _contourFromBoundary(
    _Component component,
    int width,
    int height,
    ComplexityPreset preset,
  ) {
    final members = component.pixels.toSet();
    final gridWidth = width + 1;
    final edgesByStart = <int, List<_BoundaryEdge>>{};
    final allEdges = <_BoundaryEdge>[];

    for (final index in component.pixels) {
      final x = index % width;
      final y = index ~/ width;

      if (y == 0 || !members.contains(index - width)) {
        _addBoundaryEdge(
          edgesByStart,
          allEdges,
          _pointKey(x, y, gridWidth),
          _pointKey(x + 1, y, gridWidth),
        );
      }
      if (x == width - 1 || !members.contains(index + 1)) {
        _addBoundaryEdge(
          edgesByStart,
          allEdges,
          _pointKey(x + 1, y, gridWidth),
          _pointKey(x + 1, y + 1, gridWidth),
        );
      }
      if (y == height - 1 || !members.contains(index + width)) {
        _addBoundaryEdge(
          edgesByStart,
          allEdges,
          _pointKey(x + 1, y + 1, gridWidth),
          _pointKey(x, y + 1, gridWidth),
        );
      }
      if (x == 0 || !members.contains(index - 1)) {
        _addBoundaryEdge(
          edgesByStart,
          allEdges,
          _pointKey(x, y + 1, gridWidth),
          _pointKey(x, y, gridWidth),
        );
      }
    }

    if (allEdges.length < 4) {
      return _contourFromBounds(component, width, height);
    }

    final loops = _traceBoundaryLoops(allEdges, edgesByStart);
    if (loops.isEmpty) {
      return _contourFromBounds(component, width, height);
    }
    loops.sort((a, b) => b.length.compareTo(a.length));
    final contour = loops.first
        .map((key) => _offsetFromPointKey(key, gridWidth, width, height))
        .toList();

    if (contour.length < 4) {
      return _contourFromBounds(component, width, height);
    }

    return _simplifyContour(contour, preset);
  }

  int _pointKey(int x, int y, int gridWidth) => y * gridWidth + x;

  void _addBoundaryEdge(
    Map<int, List<_BoundaryEdge>> edgesByStart,
    List<_BoundaryEdge> allEdges,
    int start,
    int end,
  ) {
    final edge = _BoundaryEdge(start: start, end: end);
    allEdges.add(edge);
    edgesByStart.putIfAbsent(start, () => <_BoundaryEdge>[]).add(edge);
  }

  List<List<int>> _traceBoundaryLoops(
    List<_BoundaryEdge> allEdges,
    Map<int, List<_BoundaryEdge>> edgesByStart,
  ) {
    final unused = allEdges.map((edge) => edge.key).toSet();
    final loops = <List<int>>[];

    for (final firstEdge in allEdges) {
      if (!unused.contains(firstEdge.key)) {
        continue;
      }

      final loop = <int>[firstEdge.start];
      var currentEdge = firstEdge;
      unused.remove(currentEdge.key);

      for (var guard = 0; guard < allEdges.length + 4; guard += 1) {
        loop.add(currentEdge.end);
        if (currentEdge.end == loop.first) {
          break;
        }

        final candidates = edgesByStart[currentEdge.end]
            ?.where((edge) => unused.contains(edge.key))
            .toList();
        if (candidates == null || candidates.isEmpty) {
          break;
        }

        currentEdge = _chooseNextEdge(currentEdge, candidates);
        unused.remove(currentEdge.key);
      }

      if (loop.length >= 5 && loop.last == loop.first) {
        loop.removeLast();
        loops.add(loop);
      }
    }

    return loops;
  }

  _BoundaryEdge _chooseNextEdge(
    _BoundaryEdge current,
    List<_BoundaryEdge> candidates,
  ) {
    if (candidates.length == 1) {
      return candidates.first;
    }
    candidates.sort(
      (a, b) => _turnScore(current, b).compareTo(_turnScore(current, a)),
    );
    return candidates.first;
  }

  int _turnScore(_BoundaryEdge current, _BoundaryEdge next) {
    final turn = (next.direction - current.direction) % 4;
    return switch (turn) {
      1 => 3,
      0 => 2,
      3 => 1,
      _ => 0,
    };
  }

  Offset _offsetFromPointKey(
    int key,
    int gridWidth,
    int imageWidth,
    int imageHeight,
  ) {
    final x = key % gridWidth;
    final y = key ~/ gridWidth;
    return Offset(x / imageWidth, y / imageHeight);
  }

  List<Offset> _simplifyContour(List<Offset> points, ComplexityPreset preset) {
    if (points.length <= 4) {
      return points;
    }

    final noCollinear = <Offset>[];
    for (var i = 0; i < points.length; i += 1) {
      final previous = points[(i - 1 + points.length) % points.length];
      final current = points[i];
      final next = points[(i + 1) % points.length];
      final dx1 = (current.dx - previous.dx).sign;
      final dy1 = (current.dy - previous.dy).sign;
      final dx2 = (next.dx - current.dx).sign;
      final dy2 = (next.dy - current.dy).sign;
      if (dx1 == dx2 && dy1 == dy2) {
        continue;
      }
      noCollinear.add(current);
    }

    final simplified = noCollinear.length >= 4 ? noCollinear : points;
    final maxPoints = _maxContourPointsFor(preset);
    if (simplified.length <= maxPoints) {
      return simplified;
    }

    final stride = (simplified.length / maxPoints).ceil();
    return [for (var i = 0; i < simplified.length; i += stride) simplified[i]];
  }

  int _maxContourPointsFor(ComplexityPreset preset) {
    return switch (preset) {
      ComplexityPreset.simple => 220,
      ComplexityPreset.medium => 360,
      ComplexityPreset.detailed => 520,
    };
  }

  List<Offset> _contourFromBounds(_Component component, int width, int height) {
    final left = component.minX / width;
    final top = component.minY / height;
    final right = (component.maxX + 1) / width;
    final bottom = (component.maxY + 1) / height;
    return [
      Offset(left, top),
      Offset(right, top),
      Offset(right, bottom),
      Offset(left, bottom),
    ];
  }

  String _titleFromPath(String path) {
    final fileName = path.split(RegExp(r'[\\/]')).last;
    final base = fileName.contains('.') ? fileName.split('.').first : fileName;
    if (base.trim().isEmpty) {
      return 'Coloring Page';
    }
    return base
        .split(RegExp(r'[_\-\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  _LabColor _rgbToLab(int red, int green, int blue) {
    double pivotRgb(int value) {
      final normalized = value / 255;
      return normalized <= .04045
          ? normalized / 12.92
          : math.pow((normalized + .055) / 1.055, 2.4).toDouble();
    }

    final r = pivotRgb(red);
    final g = pivotRgb(green);
    final b = pivotRgb(blue);

    final x = (r * .4124 + g * .3576 + b * .1805) / .95047;
    final y = (r * .2126 + g * .7152 + b * .0722) / 1.00000;
    final z = (r * .0193 + g * .1192 + b * .9505) / 1.08883;

    double pivotXyz(double value) {
      return value > .008856
          ? math.pow(value, 1 / 3).toDouble()
          : (7.787 * value) + (16 / 116);
    }

    final fx = pivotXyz(x);
    final fy = pivotXyz(y);
    final fz = pivotXyz(z);

    return _LabColor((116 * fy) - 16, 500 * (fx - fy), 200 * (fy - fz));
  }

  _RgbColor _labToRgb(_LabColor lab) {
    final y = (lab.l + 16) / 116;
    final x = lab.a / 500 + y;
    final z = y - lab.b / 200;

    double pivotLab(double value) {
      final cubed = value * value * value;
      return cubed > .008856 ? cubed : (value - 16 / 116) / 7.787;
    }

    final xyzX = .95047 * pivotLab(x);
    final xyzY = 1.00000 * pivotLab(y);
    final xyzZ = 1.08883 * pivotLab(z);

    var r = xyzX * 3.2406 + xyzY * -1.5372 + xyzZ * -.4986;
    var g = xyzX * -.9689 + xyzY * 1.8758 + xyzZ * .0415;
    var b = xyzX * .0557 + xyzY * -.2040 + xyzZ * 1.0570;

    int pivotRgb(double value) {
      final corrected = value <= .0031308
          ? 12.92 * value
          : 1.055 * math.pow(value, 1 / 2.4).toDouble() - .055;
      return (corrected.clamp(0, 1) * 255).round();
    }

    return _RgbColor(pivotRgb(r), pivotRgb(g), pivotRgb(b));
  }

  String _rgbToHex(_RgbColor color) {
    String channel(int value) =>
        value.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}';
  }

  String _nameForColor(Color color) {
    final hsv = HSVColor.fromColor(color);
    final luminance = color.computeLuminance();
    if (luminance > .86) {
      return 'Light';
    }
    if (luminance < .12) {
      return 'Dark';
    }
    if (hsv.saturation < .16) {
      return luminance > .5 ? 'Soft Gray' : 'Gray';
    }
    final hue = hsv.hue;
    if (hue < 20 || hue >= 340) {
      return 'Red';
    }
    if (hue < 45) {
      return 'Orange';
    }
    if (hue < 70) {
      return 'Yellow';
    }
    if (hue < 155) {
      return 'Green';
    }
    if (hue < 205) {
      return 'Teal';
    }
    if (hue < 255) {
      return 'Blue';
    }
    if (hue < 300) {
      return 'Purple';
    }
    return 'Pink';
  }
}

class _QuantizationResult {
  const _QuantizationResult({required this.labels, required this.palette});

  final Int32List labels;
  final List<_LabColor> palette;
}

class _LabColor {
  const _LabColor(this.l, this.a, this.b);

  final double l;
  final double a;
  final double b;

  double distanceSquaredTo(_LabColor other) {
    final dl = l - other.l;
    final da = a - other.a;
    final db = b - other.b;
    return dl * dl + da * da + db * db;
  }
}

class _LabAccumulator {
  double l = 0;
  double a = 0;
  double b = 0;
  int count = 0;

  void add(_LabColor color) {
    l += color.l;
    a += color.a;
    b += color.b;
    count += 1;
  }

  _LabColor average() => _LabColor(l / count, a / count, b / count);
}

class _RgbColor {
  const _RgbColor(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;
}

class _Component {
  const _Component({
    required this.label,
    required this.area,
    required this.sumX,
    required this.sumY,
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.pixels,
  });

  final int label;
  final int area;
  final int sumX;
  final int sumY;
  final int minX;
  final int minY;
  final int maxX;
  final int maxY;
  final List<int> pixels;
}

class _BoundaryEdge {
  const _BoundaryEdge({required this.start, required this.end});

  final int start;
  final int end;

  String get key => '$start:$end';

  int get direction {
    final delta = end - start;
    if (delta == 1) {
      return 0;
    }
    if (delta > 1) {
      return 1;
    }
    if (delta == -1) {
      return 2;
    }
    return 3;
  }
}

class _PaletteEntry {
  const _PaletteEntry({
    required this.sourceLabel,
    required this.hex,
    required this.label,
    required this.hue,
    required this.lightness,
  });

  final int sourceLabel;
  final String hex;
  final String label;
  final double hue;
  final double lightness;
}
