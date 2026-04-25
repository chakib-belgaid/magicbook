import 'package:flutter/material.dart';

import '../state/magic_book_scope.dart';
import '../theme/magic_book_theme.dart';
import '../widgets/work_card.dart';

class MyWorksScreen extends StatelessWidget {
  const MyWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = MagicBookScope.of(context);
    final works = controller.works;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, title: Text('My Works')),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: works.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: MagicBookColors.line),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: MagicBookColors.pink,
                              size: 46,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Saved favorites will live here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList.separated(
                    itemCount: works.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) =>
                        WorkCard(result: works[index]),
                  ),
          ),
        ],
      ),
    );
  }
}
