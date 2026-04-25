import 'package:share_plus/share_plus.dart';

import '../models/coloring_result.dart';

abstract class ExportService {
  Future<void> saveToGallery(ColoringResult result);

  Future<void> share(ColoringResult result);

  Future<void> print(ColoringResult result);
}

class MobileExportService implements ExportService {
  @override
  Future<void> saveToGallery(ColoringResult result) async {
    // TODO: Persist generated PNG/SVG files after the OpenCV renderer is wired.
  }

  @override
  Future<void> share(ColoringResult result) {
    return SharePlus.instance.share(
      ShareParams(
        title: result.title,
        subject: 'MagicBook coloring page',
        text: 'I made a ${result.title} color-by-number page in MagicBook.',
      ),
    );
  }

  @override
  Future<void> print(ColoringResult result) async {
    // TODO: Create a printable PDF from the generated coloring-page PNG.
  }
}
