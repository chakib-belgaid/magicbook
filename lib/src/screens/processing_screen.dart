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

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _navigated = false;

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
              const _CrayonMascot(),
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
                'This may take a few seconds.',
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

class _CrayonMascot extends StatelessWidget {
  const _CrayonMascot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _CrayonMascotPainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CrayonMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shadow = Paint()..color = const Color(0x227654F5);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + const Offset(0, 58),
        width: 120,
        height: 26,
      ),
      shadow,
    );
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 62, height: 138),
      const Radius.circular(20),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(.18);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRRect(body, Paint()..color = MagicBookColors.purple);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = MagicBookColors.ink,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: center + const Offset(0, 44),
        width: 62,
        height: 14,
      ),
      Paint()..color = const Color(0xFF4D34BC),
    );
    final facePaint = Paint()..color = MagicBookColors.ink;
    canvas.drawCircle(center + const Offset(-12, -8), 4, facePaint);
    canvas.drawCircle(center + const Offset(12, -8), 4, facePaint);
    canvas.drawArc(
      Rect.fromCenter(
        center: center + const Offset(0, 2),
        width: 24,
        height: 18,
      ),
      0,
      3.14,
      false,
      facePaint..strokeWidth = 3,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
