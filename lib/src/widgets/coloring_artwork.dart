import 'package:flutter/material.dart';

import '../models/coloring_result.dart';
import '../models/palette_color.dart';
import '../theme/magic_book_theme.dart';

enum ArtworkMode { lineArt, preview, interactive }

class ColoringArtwork extends StatelessWidget {
  const ColoringArtwork({
    required this.result,
    required this.mode,
    this.selectedPaletteNumber,
    this.onRegionTap,
    super.key,
  });

  final ColoringResult result;
  final ArtworkMode mode;
  final int? selectedPaletteNumber;
  final ValueChanged<int>? onRegionTap;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: result.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            onTapUp: onRegionTap == null
                ? null
                : (details) {
                    final local = details.localPosition;
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final tapped = _regionAt(local, size);
                    if (tapped != null) {
                      onRegionTap!(tapped);
                    }
                  },
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
                        drawNumbers: false,
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
}

class _ColoringArtworkPainter extends CustomPainter {
  const _ColoringArtworkPainter({
    required this.result,
    required this.mode,
    required this.selectedPaletteNumber,
    this.drawRegions = true,
    this.drawNumbers = true,
  });

  final ColoringResult result;
  final ArtworkMode mode;
  final int? selectedPaletteNumber;
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
        oldDelegate.drawRegions != drawRegions ||
        oldDelegate.drawNumbers != drawNumbers;
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
