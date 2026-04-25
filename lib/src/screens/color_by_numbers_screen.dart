import 'package:flutter/material.dart';

import '../state/magic_book_scope.dart';
import '../theme/magic_book_theme.dart';
import '../widgets/coloring_artwork.dart';
import '../widgets/palette_legend.dart';

class ColorByNumbersScreen extends StatelessWidget {
  const ColorByNumbersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MagicBookScope.of(context);
    final result = controller.currentResult;

    if (result == null) {
      return const Scaffold(body: Center(child: Text('No page selected.')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Color by Numbers'),
        actions: [
          IconButton(
            tooltip: 'Hint',
            onPressed: () {},
            icon: Badge.count(
              count: 3,
              backgroundColor: MagicBookColors.purple,
              child: const Icon(Icons.lightbulb_outline_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            ColoringArtwork(
              result: result,
              mode: ArtworkMode.interactive,
              selectedPaletteNumber: controller.selectedPaletteNumber,
              onRegionTap: controller.colorRegion,
            ),
            const SizedBox(height: 18),
            PaletteLegend(
              palette: result.palette,
              selectedNumber: controller.selectedPaletteNumber,
              onSelected: controller.selectPaletteNumber,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _ToolButton(
                    icon: Icons.undo_rounded,
                    label: 'Undo',
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ToolButton(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Hint',
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ToolButton(
                    icon: Icons.restart_alt_rounded,
                    label: 'Reset',
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
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
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
