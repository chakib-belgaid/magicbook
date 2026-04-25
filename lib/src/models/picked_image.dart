import 'package:flutter/foundation.dart';

@immutable
class PickedImage {
  const PickedImage({
    required this.path,
    required this.name,
    required this.bytes,
  });

  final String path;
  final String name;
  final Uint8List bytes;
}
