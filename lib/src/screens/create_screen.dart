import 'dart:async';

import 'package:flutter/material.dart';

import '../state/magic_book_scope.dart';
import '../theme/magic_book_theme.dart';
import '../widgets/complexity_picker.dart';
import '../widgets/photo_preview_card.dart';
import '../widgets/primary_button.dart';
import 'processing_screen.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MagicBookScope.of(context);
    final job = controller.job;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Create'),
            leading: IconButton(
              tooltip: 'Menu',
              onPressed: () {},
              icon: const Icon(
                Icons.menu_rounded,
                color: MagicBookColors.purple,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            sliver: SliverList.list(
              children: [
                Text(
                  '1. Upload a picture',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                PhotoPreviewCard(image: job.inputImage),
                const SizedBox(height: 16),
                PrimaryButton(
                  key: const ValueKey('choosePhotoButton'),
                  label: job.inputImagePath == null
                      ? 'Choose Photo'
                      : 'Choose Another Photo',
                  icon: Icons.photo_library_rounded,
                  onPressed: () async {
                    await controller.choosePhoto();
                  },
                ),
                TextButton.icon(
                  key: const ValueKey('useDemoPhotoButton'),
                  onPressed: controller.useDemoPhoto,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Use demo puppy'),
                ),
                const SizedBox(height: 24),
                Text(
                  '2. Choose complexity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ComplexityPicker(
                  value: job.preset,
                  onChanged: controller.setPreset,
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  key: const ValueKey('createColoringButton'),
                  label: 'Create Coloring',
                  icon: Icons.auto_awesome_rounded,
                  backgroundColor: MagicBookColors.yellow,
                  foregroundColor: MagicBookColors.ink,
                  onPressed: controller.canCreate
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ProcessingScreen(),
                            ),
                          );
                          unawaited(controller.createColoring());
                        }
                      : null,
                ),
                const SizedBox(height: 24),
                const _FeatureStrip(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.child_care_rounded, 'Kid friendly', MagicBookColors.mint),
      (Icons.lock_rounded, 'Private', MagicBookColors.purple),
      (Icons.palette_rounded, 'Easy coloring', MagicBookColors.pink),
    ];
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MagicBookColors.line),
            ),
            child: Column(
              children: [
                Icon(item.$1, color: item.$3),
                const SizedBox(height: 6),
                Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
