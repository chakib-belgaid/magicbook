import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/coloring_job.dart';
import '../state/magic_book_scope.dart';
import '../theme/magic_book_theme.dart';
import 'ready_screen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  bool _navigated = false;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeNavigate();
  }

  @override
  void didUpdateWidget(covariant ProcessingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeNavigate();
  }

  void _maybeNavigate() {
    final controller = MagicBookScope.of(context);
    if (_navigated || controller.job.status != ColoringJobStatus.completed) {
      return;
    }
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ReadyScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = MagicBookScope.of(context);
    final progress = controller.job.progress.clamp(0.0, 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeNavigate());

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const Spacer(),
              _PlayfulLoadingMascot(animation: _animationController),
              const SizedBox(height: 34),
              Text(
                'Creating...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: MagicBookColors.purple,
                ),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: progress,
                minHeight: 16,
                borderRadius: BorderRadius.circular(99),
                backgroundColor: Colors.white,
                color: MagicBookColors.purple,
              ),
              const SizedBox(height: 24),
              Text(
                controller.processingStage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Your picture is becoming a coloring adventure.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayfulLoadingMascot extends StatelessWidget {
  const _PlayfulLoadingMascot({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final bounce = (animation.value - .5).abs();
        return SizedBox(
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                painter: _SparklePainter(animation.value),
                child: const SizedBox.expand(),
              ),
              Transform.translate(
                offset: Offset(0, -10 + bounce * 18),
                child: Transform.rotate(
                  angle: (animation.value - .5) * .08,
                  child: Image.asset(
                    'assets/images/loading_mascot.png',
                    key: const ValueKey('loadingMascotAsset'),
                    height: 214,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = Paint()..color = const Color(0x1F7654F5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .88),
        width: 150,
        height: 24,
      ),
      shadow,
    );

    final dots = <(Offset, Color, double)>[
      (Offset(size.width * .16, size.height * .22), MagicBookColors.pink, 9),
      (Offset(size.width * .82, size.height * .24), MagicBookColors.yellow, 8),
      (Offset(size.width * .25, size.height * .72), MagicBookColors.mint, 7),
      (Offset(size.width * .76, size.height * .68), MagicBookColors.sky, 10),
      (Offset(size.width * .50, size.height * .08), MagicBookColors.purple, 6),
    ];
    for (var i = 0; i < dots.length; i += 1) {
      final dot = dots[i];
      final phase = (progress + i * .19) % 1;
      final rise = (phase - .5).abs() * 24;
      final paint = Paint()..color = dot.$2.withValues(alpha: .3 + phase * .6);
      canvas.drawCircle(dot.$1.translate(0, -rise), dot.$3, paint);
      _drawStar(
        canvas,
        dot.$1.translate(dot.$3 * 1.8, -rise - 8),
        dot.$2,
        dot.$3,
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, Color color, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i += 1) {
      final angle = -1.57 + i * .628;
      final length = i.isEven ? radius : radius * .45;
      final point = Offset(
        center.dx + length * math.cos(angle),
        center.dy + length * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    canvas.drawPath(
      path..close(),
      Paint()..color = color.withValues(alpha: .72),
    );
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
