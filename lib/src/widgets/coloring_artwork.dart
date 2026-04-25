import 'package:flutter/material.dart';

import '../models/coloring_region.dart';
import '../models/coloring_result.dart';
import '../models/drawing_mode.dart';
import '../models/drawing_stroke.dart';
import '../models/palette_color.dart';
import '../theme/magic_book_theme.dart';

enum ArtworkMode { lineArt, preview, interactive }

class ColoringArtwork extends StatelessWidget {
  const ColoringArtwork({
    required this.result,
    required this.mode,
    this.selectedPaletteNumber,
    this.strokes = const <DrawingStroke>[],
    this.selectedRegionId,
    this.onRegionTap,
    this.onDrawingStart,
    this.onDrawingUpdate,
    this.onDrawingEnd,
    super.key,
  });

  final ColoringResult result;
  final ArtworkMode mode;
  final int? selectedPaletteNumber;
  final List<DrawingStroke> strokes;
  final int? selectedRegionId;
  final ValueChanged<int>? onRegionTap;
  final ValueChanged<Offset>? onDrawingStart;
  final ValueChanged<Offset>? onDrawingUpdate;
  final VoidCallback? onDrawingEnd;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: result.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapUp: onRegionTap == null && onDrawingStart == null
                ? null
                : (details) {
                    final local = details.localPosition;
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    if (onDrawingStart != null) {
                      onDrawingStart!(_normalize(local, size));
                      onDrawingEnd?.call();
                      return;
                    }
                    final tapped = _regionAt(local, size);
                    if (tapped != null && onRegionTap != null) {
                      onRegionTap!(tapped);
                    }
                  },
            onPanStart: onDrawingStart == null
                ? null
                : (details) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    onDrawingStart!(_normalize(details.localPosition, size));
                  },
            onPanUpdate: onDrawingUpdate == null
                ? null
                : (details) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    onDrawingUpdate!(_normalize(details.localPosition, size));
                  },
            onPanEnd: onDrawingEnd == null ? null : (_) => onDrawingEnd!(),
            onPanCancel: onDrawingEnd,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _ColoringArtworkPainter(
                        result: result,
                        mode: mode,
                        selectedPaletteNumber: selectedPaletteNumber,
                        selectedRegionId: selectedRegionId,
                        drawNumbers: false,
                      ),
                    ),
                    CustomPaint(
                      painter: _DrawingStrokePainter(
                        result: result,
                        strokes: strokes,
                      ),
                    ),
                    if (result.outlinePngBytes != null)
                      Image.memory(
                        result.outlinePngBytes!,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.high,
                      ),
                    CustomPaint(
                      painter: _ColoringArtworkPainter(
                        result: result,
                        mode: mode,
                        selectedPaletteNumber: selectedPaletteNumber,
                        selectedRegionId: selectedRegionId,
                        drawRegions: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int? _regionAt(Offset position, Size size) {
    for (final region in result.regions.reversed) {
      final path = _pathFor(region.contour, size);
      if (path.contains(position)) {
        return region.id;
      }
    }
    return null;
  }

  Offset _normalize(Offset position, Size size) {
    return Offset(position.dx / size.width, position.dy / size.height);
  }
}

class _ColoringArtworkPainter extends CustomPainter {
  const _ColoringArtworkPainter({
    required this.result,
    required this.mode,
    required this.selectedPaletteNumber,
    required this.selectedRegionId,
    this.drawRegions = true,
    this.drawNumbers = true,
  });

  final ColoringResult result;
  final ArtworkMode mode;
  final int? selectedPaletteNumber;
  final int? selectedRegionId;
  final bool drawRegions;
  final bool drawNumbers;

  @override
  void paint(Canvas canvas, Size size) {
    if (drawRegions) {
      _drawBackdrop(canvas, size);
    }

    final sorted = [...result.regions]
      ..sort((a, b) => b.area.compareTo(a.area));
    for (final region in sorted) {
      final path = _pathFor(region.contour, size);
      final paletteColor = _paletteColorFor(region.paletteNumber);
      final isColored = result.coloredRegionIds.contains(region.id);
      final shouldFill = switch (mode) {
        ArtworkMode.lineArt => false,
        ArtworkMode.preview => true,
        ArtworkMode.interactive => isColored,
      };

      if (drawRegions) {
        final fill = Paint()
          ..style = PaintingStyle.fill
          ..color = shouldFill ? paletteColor.color : Colors.white;
        canvas.drawPath(path, fill);

        if (region.id == selectedRegionId) {
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.fill
              ..color = MagicBookColors.yellow.withValues(alpha: .16),
          );
        }

        if (result.outlinePngBytes == null) {
          final stroke = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = mode == ArtworkMode.preview ? 1.5 : 2.2
            ..strokeJoin = StrokeJoin.round
            ..color = MagicBookColors.ink;
          canvas.drawPath(path, stroke);
        }
      }

      if (drawNumbers) {
        if (region.isNumberable &&
            (mode != ArtworkMode.preview || !shouldFill)) {
          _drawNumber(
            canvas,
            size,
            region.paletteNumber,
            region.numberPosition,
          );
        } else if (mode == ArtworkMode.interactive && !isColored) {
          _drawNumber(
            canvas,
            size,
            region.paletteNumber,
            region.numberPosition,
          );
        }
      }
    }

    if (drawNumbers &&
        mode == ArtworkMode.interactive &&
        selectedPaletteNumber != null) {
      _drawSelectionHint(canvas, size);
    }
  }

  void _drawBackdrop(Canvas canvas, Size size) {
    if (mode == ArtworkMode.lineArt || mode == ArtworkMode.interactive) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
      return;
    }

    final sky = Paint()..color = const Color(0xFFE6F5FF);
    canvas.drawRect(Offset.zero & Size(size.width, size.height * .5), sky);
    final ground = Paint()..color = const Color(0xFFE8F7C3);
    canvas.drawRect(
      Offset(0, size.height * .48) & Size(size.width, size.height * .52),
      ground,
    );
  }

  PaletteColor _paletteColorFor(int number) {
    return result.palette.firstWhere(
      (entry) => entry.number == number,
      orElse: () => result.palette.first,
    );
  }

  void _drawNumber(Canvas canvas, Size size, int number, Offset normalized) {
    final painter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: const TextStyle(
          color: MagicBookColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final center = Offset(
      normalized.dx * size.width,
      normalized.dy * size.height,
    );
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _drawSelectionHint(Canvas canvas, Size size) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'Color $selectedPaletteNumber',
        style: const TextStyle(
          color: MagicBookColors.purple,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width - painter.width - 24,
        12,
        painter.width + 14,
        26,
      ),
      const Radius.circular(13),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = Colors.white.withValues(alpha: .86),
    );
    painter.paint(canvas, Offset(size.width - painter.width - 17, 16));
  }

  @override
  bool shouldRepaint(covariant _ColoringArtworkPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.mode != mode ||
        oldDelegate.selectedPaletteNumber != selectedPaletteNumber ||
        oldDelegate.selectedRegionId != selectedRegionId ||
        oldDelegate.drawRegions != drawRegions ||
        oldDelegate.drawNumbers != drawNumbers;
  }
}

class _DrawingStrokePainter extends CustomPainter {
  const _DrawingStrokePainter({required this.result, required this.strokes});

  final ColoringResult result;
  final List<DrawingStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) {
        continue;
      }

      final clipPath = _clipPathFor(stroke, size);
      if (clipPath == null && stroke.mode != DrawingMode.freeDraw) {
        continue;
      }

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.brushSize
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = stroke.color.withValues(alpha: .78);

      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = stroke.color.withValues(alpha: .78);

      canvas.save();
      if (clipPath != null) {
        canvas.clipPath(clipPath, doAntiAlias: true);
      }

      Offset? previous;
      final maxGap = (stroke.brushSize / size.shortestSide * 3).clamp(
        .025,
        .08,
      );
      for (final point in stroke.points) {
        final scaled = Offset(point.dx * size.width, point.dy * size.height);
        canvas.drawCircle(scaled, stroke.brushSize / 2, dotPaint);
        if (previous != null && (point - previous).distance <= maxGap) {
          final start = Offset(
            previous.dx * size.width,
            previous.dy * size.height,
          );
          canvas.drawLine(start, scaled, paint);
        }
        previous = point;
      }
      canvas.restore();
    }
  }

  Path? _clipPathFor(DrawingStroke stroke, Size size) {
    final path = Path();
    var hasPath = false;

    for (final region in result.regions) {
      final include = switch (stroke.mode) {
        DrawingMode.rightColor => _regionMatchesColor(region, stroke.color),
        DrawingMode.zoneColor => region.id == stroke.selectedRegionId,
        DrawingMode.freeDraw => false,
      };
      if (include) {
        path.addPath(_pathFor(region.contour, size), Offset.zero);
        hasPath = true;
      }
    }

    return hasPath ? path : null;
  }

  bool _regionMatchesColor(ColoringRegion region, Color color) {
    for (final entry in result.palette) {
      if (entry.number == region.paletteNumber) {
        return entry.color.toARGB32() == color.toARGB32();
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant _DrawingStrokePainter oldDelegate) {
    return oldDelegate.result != result || oldDelegate.strokes != strokes;
  }
}

Path _pathFor(List<Offset> normalizedPoints, Size size) {
  final path = Path();
  for (var i = 0; i < normalizedPoints.length; i += 1) {
    final point = normalizedPoints[i];
    final scaled = Offset(point.dx * size.width, point.dy * size.height);
    if (i == 0) {
      path.moveTo(scaled.dx, scaled.dy);
    } else {
      path.lineTo(scaled.dx, scaled.dy);
    }
  }
  return path..close();
}
