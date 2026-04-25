import 'package:flutter/material.dart';

import '../models/complexity_preset.dart';
import '../theme/magic_book_theme.dart';

class ComplexityPicker extends StatelessWidget {
  const ComplexityPicker({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ComplexityPreset value;
  final ValueChanged<ComplexityPreset> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MagicBookColors.line),
      ),
      child: Row(
        children: ComplexityPreset.values.map((preset) {
          final selected = preset == value;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(preset),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? MagicBookColors.lavender : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        preset.iconLabel,
                        style: TextStyle(
                          color: selected
                              ? MagicBookColors.purple
                              : MagicBookColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        preset.label,
                        style: TextStyle(
                          color: selected
                              ? MagicBookColors.ink
                              : Colors.black54,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
