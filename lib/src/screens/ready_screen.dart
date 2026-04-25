import 'package:flutter/material.dart';

import '../state/magic_book_scope.dart';
import '../theme/magic_book_theme.dart';
import '../widgets/coloring_artwork.dart';
import '../widgets/palette_legend.dart';
import '../widgets/primary_button.dart';
import 'color_by_numbers_screen.dart';

class ReadyScreen extends StatelessWidget {
  const ReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MagicBookScope.of(context);
    final result = controller.currentResult;

    if (result == null) {
      return const Scaffold(body: Center(child: Text('No coloring page yet.')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Your Coloring is Ready!'),
        actions: [
          IconButton(
            tooltip: 'Download',
            onPressed: controller.saveCurrentResult,
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            ColoringArtwork(result: result, mode: ArtworkMode.lineArt),
            const SizedBox(height: 18),
            PaletteLegend(palette: result.palette),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Draw Now',
              icon: Icons.palette_rounded,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ColorByNumbersScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.shareCurrentResult,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.printCurrentResult,
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: MagicBookColors.line),
              ),
              child: PaletteLegend(palette: result.palette, showLabels: true),
            ),
          ],
        ),
      ),
    );
  }
}
