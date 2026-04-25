import 'package:flutter/material.dart';

import '../models/palette_color.dart';
import '../theme/magic_book_theme.dart';

class PaletteLegend extends StatelessWidget {
  const PaletteLegend({
    required this.palette,
    this.selectedNumber,
    this.onSelected,
    this.showLabels = false,
    super.key,
  });

  final List<PaletteColor> palette;
  final int? selectedNumber;
  final ValueChanged<int>? onSelected;
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: palette.map((entry) {
        final selected = selectedNumber == entry.number;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onSelected == null ? null : () => onSelected!(entry.number),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.only(
              left: showLabels ? 8 : 0,
              right: showLabels ? 12 : 0,
            ),
            height: 34,
            decoration: BoxDecoration(
              color: showLabels ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? MagicBookColors.purple : Colors.transparent,
                width: selected ? 3 : 0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entry.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Text(
                    '${entry.number}',
                    style: TextStyle(
                      color: _contrastFor(entry.color),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (showLabels) ...[
                  const SizedBox(width: 6),
                  Text(
                    entry.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _contrastFor(Color color) {
    return color.computeLuminance() > 0.58 ? MagicBookColors.ink : Colors.white;
  }
}
