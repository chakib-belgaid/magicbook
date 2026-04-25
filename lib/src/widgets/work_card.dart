import 'package:flutter/material.dart';

import '../models/coloring_result.dart';
import '../theme/magic_book_theme.dart';
import 'coloring_artwork.dart';

class WorkCard extends StatelessWidget {
  const WorkCard({required this.result, this.onTap, super.key});

  final ColoringResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MagicBookColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoringArtwork(result: result, mode: ArtworkMode.preview),
            const SizedBox(height: 10),
            Text(result.title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${result.palette.length} colors',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
