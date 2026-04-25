import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/coloring_job.dart';
import '../models/coloring_region.dart';
import '../models/coloring_result.dart';
import '../models/complexity_preset.dart';
import '../models/drawing_mode.dart';
import '../models/drawing_stroke.dart';
import '../models/picked_image.dart';
import '../services/coloring_pipeline_service.dart';
import '../services/export_service.dart';
import '../services/gallery_storage_service.dart';
import '../services/image_pick_service.dart';

class MagicBookController extends ChangeNotifier {
  MagicBookController({
    required ImagePickService imagePickService,
    required ColoringPipelineService pipelineService,
    required GalleryStorageService galleryStorageService,
    required ExportService exportService,
  }) : _imagePickService = imagePickService,
       _pipelineService = pipelineService,
       _galleryStorageService = galleryStorageService,
       _exportService = exportService;

  final ImagePickService _imagePickService;
  final ColoringPipelineService _pipelineService;
  final GalleryStorageService _galleryStorageService;
  final ExportService _exportService;

  ColoringJob _job = ColoringJob.initial();
  int _tabIndex = 0;
  String _processingStage = 'Ready';
  int? _selectedPaletteNumber;
  DrawingMode _drawingMode = DrawingMode.rightColor;
  Color? _selectedDrawingColor;
  int? _selectedDrawingRegionId;
  double _brushSize = 18;
  DrawingStroke? _activeStroke;
  final List<DrawingStroke> _drawingStrokes = <DrawingStroke>[];
  List<ColoringResult> _works = <ColoringResult>[];

  ColoringJob get job => _job;

  int get tabIndex => _tabIndex;

  String get processingStage => _processingStage;

  int? get selectedPaletteNumber => _selectedPaletteNumber;

  DrawingMode get drawingMode => _drawingMode;

  Color? get selectedDrawingColor => _selectedDrawingColor;

  int? get selectedDrawingRegionId => _selectedDrawingRegionId;

  double get brushSize => _brushSize;

  List<DrawingStroke> get drawingStrokes {
    final activeStroke = _activeStroke;
    return List.unmodifiable([..._drawingStrokes, ?activeStroke]);
  }

  int get drawingTotalSamples {
    return drawingStrokes.fold<int>(
      0,
      (total, stroke) => total + stroke.totalSamples,
    );
  }

  int get drawingCorrectSamples {
    return drawingStrokes.fold<int>(
      0,
      (total, stroke) => total + stroke.correctSamples,
    );
  }

  double get drawingAccuracy {
    final total = drawingTotalSamples;
    if (total == 0) {
      return 1;
    }
    return drawingCorrectSamples / total;
  }

  int get drawingScorePercent => (drawingAccuracy * 100).round();

  List<ColoringResult> get works => List.unmodifiable(_works);

  ColoringResult? get currentResult => _job.result;

  bool get canCreate =>
      _job.inputImagePath != null &&
      _job.status != ColoringJobStatus.processing;

  void setTabIndex(int index) {
    _tabIndex = index;
    notifyListeners();
  }

  void setPreset(ComplexityPreset preset) {
    _job = _job.copyWith(preset: preset, clearError: true);
    notifyListeners();
  }

  Future<void> choosePhoto() async {
    final image = await _imagePickService.pickFromGallery();
    if (image == null) {
      return;
    }
    _job = _job.copyWith(
      inputImage: image,
      status: ColoringJobStatus.imageSelected,
      progress: 0,
      clearResult: true,
      clearError: true,
    );
    notifyListeners();
  }

  void useDemoPhoto() {
    _job = _job.copyWith(
      inputImage: PickedImage(
        path: 'demo://gallery/dog',
        name: 'demo-dog.png',
        bytes: Uint8List(0),
      ),
      status: ColoringJobStatus.imageSelected,
      progress: 0,
      clearResult: true,
      clearError: true,
    );
    notifyListeners();
  }

  Future<void> createColoring() async {
    final input = _job.inputImagePath;
    if (input == null || _job.status == ColoringJobStatus.processing) {
      return;
    }

    _processingStage = 'Loading image';
    _job = _job.copyWith(
      status: ColoringJobStatus.processing,
      progress: 0,
      clearResult: true,
      clearError: true,
    );
    notifyListeners();

    try {
      final result = await _pipelineService.generate(
        inputImagePath: input,
        inputImageBytes: _job.inputImage?.bytes,
        inputImageName: _job.inputImage?.name,
        preset: _job.preset,
        onProgress: (progress, stageLabel) {
          _processingStage = stageLabel;
          _job = _job.copyWith(progress: progress);
          notifyListeners();
        },
      );
      _selectedPaletteNumber = result.palette.first.number;
      _selectedDrawingColor = result.palette.first.color;
      _selectedDrawingRegionId = null;
      _activeStroke = null;
      _drawingStrokes.clear();
      _job = _job.copyWith(
        status: ColoringJobStatus.completed,
        progress: 1,
        result: result,
      );
      await _galleryStorageService.saveWork(result);
      _works = await _galleryStorageService.loadWorks();
      notifyListeners();
    } catch (error) {
      _job = _job.copyWith(
        status: ColoringJobStatus.failed,
        errorMessage: error.toString(),
      );
      notifyListeners();
    }
  }

  void selectPaletteNumber(int number) {
    _selectedPaletteNumber = number;
    final result = _job.result;
    if (result != null) {
      for (final entry in result.palette) {
        if (entry.number == number) {
          _selectedDrawingColor = entry.color;
          break;
        }
      }
    }
    notifyListeners();
  }

  void setDrawingMode(DrawingMode mode) {
    if (_drawingMode == mode) {
      return;
    }
    _drawingMode = mode;
    _activeStroke = null;
    if (mode != DrawingMode.zoneColor) {
      _selectedDrawingRegionId = null;
    }
    notifyListeners();
  }

  void selectDrawingColor(Color color, {int? paletteNumber}) {
    _selectedDrawingColor = color;
    if (paletteNumber != null) {
      _selectedPaletteNumber = paletteNumber;
    }
    notifyListeners();
  }

  void setBrushSize(double size) {
    _brushSize = size.clamp(8, 34);
    notifyListeners();
  }

  void beginDrawing(Offset normalizedPoint) {
    final result = _job.result;
    final color = _selectedDrawingColor;
    if (result == null || color == null) {
      return;
    }

    var selectedRegionId = _selectedDrawingRegionId;
    final touchedRegion = _regionAt(normalizedPoint, result);
    if (_drawingMode == DrawingMode.zoneColor && touchedRegion != null) {
      selectedRegionId = touchedRegion.id;
      _selectedDrawingRegionId = selectedRegionId;
    }

    final sample = _evaluateDrawingSample(
      normalizedPoint,
      result,
      selectedRegionId,
      color,
    );
    _activeStroke = DrawingStroke(
      points: sample.shouldRender ? <Offset>[normalizedPoint] : <Offset>[],
      color: color,
      brushSize: _brushSize,
      mode: _drawingMode,
      selectedRegionId: selectedRegionId,
      totalSamples: 1,
      correctSamples: sample.isCorrect ? 1 : 0,
    );
    notifyListeners();
  }

  void updateDrawing(Offset normalizedPoint) {
    final result = _job.result;
    final color = _selectedDrawingColor;
    final activeStroke = _activeStroke;
    if (result == null || color == null || activeStroke == null) {
      return;
    }

    final sample = _evaluateDrawingSample(
      normalizedPoint,
      result,
      activeStroke.selectedRegionId,
      color,
    );
    _activeStroke = activeStroke.copyWith(
      points: [
        ...activeStroke.points,
        if (sample.shouldRender) normalizedPoint,
      ],
      totalSamples: activeStroke.totalSamples + 1,
      correctSamples: activeStroke.correctSamples + (sample.isCorrect ? 1 : 0),
    );
    notifyListeners();
  }

  void endDrawing() {
    final activeStroke = _activeStroke;
    if (activeStroke == null) {
      return;
    }
    _drawingStrokes.add(activeStroke);
    _activeStroke = null;
    notifyListeners();
  }

  void undoDrawingStroke() {
    _activeStroke = null;
    if (_drawingStrokes.isNotEmpty) {
      _drawingStrokes.removeLast();
    }
    notifyListeners();
  }

  void resetDrawing() {
    _activeStroke = null;
    _drawingStrokes.clear();
    _selectedDrawingRegionId = null;
    notifyListeners();
  }

  void showDrawingHint() {
    final result = _job.result;
    if (result == null || result.regions.isEmpty) {
      return;
    }
    final regions = [...result.regions]
      ..sort((a, b) => b.area.compareTo(a.area));
    final hintedRegion = regions.first;
    _selectedDrawingRegionId = hintedRegion.id;
    _selectedPaletteNumber = hintedRegion.paletteNumber;
    _selectedDrawingColor = _paletteColorFor(hintedRegion, result);
    notifyListeners();
  }

  void colorRegion(int regionId) {
    final result = _job.result;
    if (result == null) {
      return;
    }
    final updatedIds = {...result.coloredRegionIds, regionId};
    _job = _job.copyWith(result: result.copyWith(coloredRegionIds: updatedIds));
    notifyListeners();
  }

  Future<void> saveCurrentResult() async {
    final result = _job.result;
    if (result == null) {
      return;
    }
    await _exportService.saveToGallery(result);
  }

  Future<void> shareCurrentResult() async {
    final result = _job.result;
    if (result == null) {
      return;
    }
    await _exportService.share(result);
  }

  Future<void> printCurrentResult() async {
    final result = _job.result;
    if (result == null) {
      return;
    }
    await _exportService.print(result);
  }

  _DrawingSample _evaluateDrawingSample(
    Offset point,
    ColoringResult result,
    int? selectedRegionId,
    Color selectedColor,
  ) {
    final region = _regionAt(point, result);
    return switch (_drawingMode) {
      DrawingMode.rightColor => _rightColorSample(region, selectedColor),
      DrawingMode.zoneColor => _zoneColorSample(region, selectedRegionId),
      DrawingMode.freeDraw => _freeDrawSample(region, result, selectedColor),
    };
  }

  _DrawingSample _rightColorSample(ColoringRegion? region, Color color) {
    final isCorrect =
        region != null &&
        _sameColor(_paletteColorFor(region, _job.result), color);
    return _DrawingSample(shouldRender: isCorrect, isCorrect: isCorrect);
  }

  _DrawingSample _zoneColorSample(
    ColoringRegion? region,
    int? selectedRegionId,
  ) {
    final isCorrect = region != null && region.id == selectedRegionId;
    return _DrawingSample(shouldRender: isCorrect, isCorrect: isCorrect);
  }

  _DrawingSample _freeDrawSample(
    ColoringRegion? region,
    ColoringResult result,
    Color color,
  ) {
    final isCorrect =
        region != null && _sameColor(_paletteColorFor(region, result), color);
    return _DrawingSample(shouldRender: true, isCorrect: isCorrect);
  }

  ColoringRegion? _regionAt(Offset point, ColoringResult result) {
    for (final region in result.regions.reversed) {
      if (_pathFor(region.contour).contains(point)) {
        return region;
      }
    }
    return null;
  }

  Color? _paletteColorFor(ColoringRegion region, ColoringResult? result) {
    if (result == null) {
      return null;
    }
    for (final entry in result.palette) {
      if (entry.number == region.paletteNumber) {
        return entry.color;
      }
    }
    return null;
  }

  bool _sameColor(Color? first, Color second) {
    return first != null && first.toARGB32() == second.toARGB32();
  }

  Path _pathFor(List<Offset> normalizedPoints) {
    final path = Path();
    for (var i = 0; i < normalizedPoints.length; i += 1) {
      final point = normalizedPoints[i];
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }
}

class _DrawingSample {
  const _DrawingSample({required this.shouldRender, required this.isCorrect});

  final bool shouldRender;
  final bool isCorrect;
}
