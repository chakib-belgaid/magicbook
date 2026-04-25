import 'package:flutter/material.dart';

import '../models/drawing_mode.dart';
import '../state/magic_book_scope.dart';
import '../theme/magic_book_theme.dart';
import '../widgets/coloring_artwork.dart';

class ColorByNumbersScreen extends StatelessWidget {
  const ColorByNumbersScreen({super.key});

  static const _extraSwatches = <_ExtraSwatch>[
    _ExtraSwatch('Berry', Color(0xFFE85D9E)),
    _ExtraSwatch('Ocean', Color(0xFF28A9E0)),
    _ExtraSwatch('Lime', Color(0xFF9BDB36)),
    _ExtraSwatch('Grape', Color(0xFF8657FF)),
    _ExtraSwatch('Sun', Color(0xFFFFC928)),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = MagicBookScope.of(context);
    final result = controller.currentResult;

    if (result == null) {
      return const Scaffold(body: Center(child: Text('No page selected.')));
    }

    final selectedColor = controller.selectedDrawingColor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Draw'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(
              child: _ScoreChip(score: controller.drawingScorePercent),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            SegmentedButton<DrawingMode>(
              key: const ValueKey('drawingModeSelector'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: DrawingMode.rightColor,
                  icon: Icon(Icons.verified_rounded),
                  label: Text('Right color'),
                ),
                ButtonSegment(
                  value: DrawingMode.zoneColor,
                  icon: Icon(Icons.gesture_rounded),
                  label: Text('Zone color'),
                ),
                ButtonSegment(
                  value: DrawingMode.freeDraw,
                  icon: Icon(Icons.brush_rounded),
                  label: Text('Free draw'),
                ),
              ],
              selected: {controller.drawingMode},
              onSelectionChanged: (selection) {
                controller.setDrawingMode(selection.first);
              },
            ),
            const SizedBox(height: 14),
            ColoringArtwork(
              result: result,
              mode: ArtworkMode.lineArt,
              selectedPaletteNumber: controller.selectedPaletteNumber,
              selectedRegionId: controller.selectedDrawingRegionId,
              strokes: controller.drawingStrokes,
              onDrawingStart: controller.beginDrawing,
              onDrawingUpdate: controller.updateDrawing,
              onDrawingEnd: controller.endDrawing,
            ),
            const SizedBox(height: 16),
            _ToolPanel(
              brushSize: controller.brushSize,
              onBrushSizeChanged: controller.setBrushSize,
              onUndo: controller.undoDrawingStroke,
              onHint: controller.showDrawingHint,
              onReset: controller.resetDrawing,
            ),
            const SizedBox(height: 16),
            _SwatchTray(
              palette: result.palette
                  .map(
                    (entry) => _DrawingSwatch(
                      label: '${entry.number}',
                      color: entry.color,
                      paletteNumber: entry.number,
                    ),
                  )
                  .toList(),
              extras: _extraSwatches
                  .map(
                    (entry) => _DrawingSwatch(
                      label: entry.label.substring(0, 1),
                      color: entry.color,
                    ),
                  )
                  .toList(),
              selectedColor: selectedColor,
              onSelected: (swatch) {
                controller.selectDrawingColor(
                  swatch.color,
                  paletteNumber: swatch.paletteNumber,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('drawingScoreChip'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: MagicBookColors.yellow,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: MagicBookColors.ink.withValues(alpha: .08)),
      ),
      child: Text(
        '$score%',
        style: const TextStyle(
          color: MagicBookColors.ink,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ToolPanel extends StatelessWidget {
  const _ToolPanel({
    required this.brushSize,
    required this.onBrushSizeChanged,
    required this.onUndo,
    required this.onHint,
    required this.onReset,
  });

  final double brushSize;
  final ValueChanged<double> onBrushSizeChanged;
  final VoidCallback onUndo;
  final VoidCallback onHint;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MagicBookColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.format_paint_rounded,
                color: MagicBookColors.purple,
              ),
              Expanded(
                child: Slider(
                  key: const ValueKey('brushSizeSlider'),
                  value: brushSize,
                  min: 8,
                  max: 34,
                  divisions: 13,
                  label: brushSize.round().toString(),
                  onChanged: onBrushSizeChanged,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _ToolButton(
                  icon: Icons.undo_rounded,
                  label: 'Undo',
                  onPressed: onUndo,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToolButton(
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Hint',
                  onPressed: onHint,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToolButton(
                  icon: Icons.restart_alt_rounded,
                  label: 'Reset',
                  onPressed: onReset,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwatchTray extends StatelessWidget {
  const _SwatchTray({
    required this.palette,
    required this.extras,
    required this.selectedColor,
    required this.onSelected,
  });

  final List<_DrawingSwatch> palette;
  final List<_DrawingSwatch> extras;
  final Color? selectedColor;
  final ValueChanged<_DrawingSwatch> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('drawingSwatchTray'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MagicBookColors.line),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [...palette.map(_buildSwatch), ...extras.map(_buildSwatch)],
      ),
    );
  }

  Widget _buildSwatch(_DrawingSwatch swatch) {
    final selected = selectedColor?.toARGB32() == swatch.color.toARGB32();
    return Tooltip(
      message: swatch.paletteNumber == null
          ? swatch.label
          : 'Color ${swatch.paletteNumber}',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onSelected(swatch),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: swatch.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? MagicBookColors.ink : Colors.black12,
              width: selected ? 3 : 1,
            ),
          ),
          child: Text(
            swatch.label,
            style: TextStyle(
              color: swatch.color.computeLuminance() > .58
                  ? MagicBookColors.ink
                  : Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: MagicBookColors.purple),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _DrawingSwatch {
  const _DrawingSwatch({
    required this.label,
    required this.color,
    this.paletteNumber,
  });

  final String label;
  final Color color;
  final int? paletteNumber;
}

class _ExtraSwatch {
  const _ExtraSwatch(this.label, this.color);

  final String label;
  final Color color;
}
