import 'package:flutter/material.dart';

import '../models/picked_image.dart';
import '../theme/magic_book_theme.dart';

class PhotoPreviewCard extends StatelessWidget {
  const PhotoPreviewCard({this.image, super.key});

  final PickedImage? image;

  @override
  Widget build(BuildContext context) {
    final hasImage = image != null;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFBDE7A5), Color(0xFFFFE0A5), Color(0xFFFFC5D4)],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_shouldRenderBytes(image))
                Image.memory(
                  image!.bytes,
                  key: const ValueKey('selectedPhotoPreview'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const _FallbackPreview(message: 'Photo selected');
                  },
                )
              else
                CustomPaint(
                  painter: _PuppyPreviewPainter(hasImage: hasImage),
                  child: Center(
                    child: hasImage
                        ? const _FallbackPreview(message: 'Demo photo ready')
                        : const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_rounded,
                                size: 54,
                                color: Colors.white,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Choose a photo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              if (hasImage)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: MagicBookColors.mint,
                            size: 20,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Photo added',
                            style: TextStyle(
                              color: MagicBookColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldRenderBytes(PickedImage? image) {
    if (image == null || image.path.startsWith('demo://')) {
      return false;
    }
    return image.bytes.isNotEmpty;
  }
}

class _FallbackPreview extends StatelessWidget {
  const _FallbackPreview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18)),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .9),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.photo_rounded,
                color: MagicBookColors.purple,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                message,
                style: const TextStyle(
                  color: MagicBookColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PuppyPreviewPainter extends CustomPainter {
  const _PuppyPreviewPainter({required this.hasImage});

  final bool hasImage;

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasImage) {
      return;
    }

    final center = Offset(size.width * .5, size.height * .52);
    final fur = Paint()..color = const Color(0xFFFFD886);
    final shadow = Paint()..color = const Color(0x338A5A2B);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, size.height * .08),
        width: size.width * .56,
        height: size.height * .44,
      ),
      shadow,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * .42,
        height: size.height * .50,
      ),
      fur,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .33, size.height * .43),
        width: size.width * .18,
        height: size.height * .33,
      ),
      fur,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .67, size.height * .43),
        width: size.width * .18,
        height: size.height * .33,
      ),
      fur,
    );

    final ink = Paint()..color = MagicBookColors.ink;
    canvas.drawCircle(Offset(size.width * .42, size.height * .47), 6, ink);
    canvas.drawCircle(Offset(size.width * .58, size.height * .47), 6, ink);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .55),
        width: 26,
        height: 18,
      ),
      ink,
    );
    final mouth = Paint()
      ..color = const Color(0xFFFF7766)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * .5, size.height * .64),
        width: 34,
        height: 28,
      ),
      mouth,
    );
  }

  @override
  bool shouldRepaint(covariant _PuppyPreviewPainter oldDelegate) {
    return oldDelegate.hasImage != hasImage;
  }
}
