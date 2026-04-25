import 'package:flutter/widgets.dart';

import 'magic_book_controller.dart';

class MagicBookScope extends InheritedNotifier<MagicBookController> {
  const MagicBookScope({
    required MagicBookController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static MagicBookController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MagicBookScope>();
    assert(scope != null, 'MagicBookScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
