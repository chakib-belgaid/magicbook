import 'package:flutter/foundation.dart';

import '../models/coloring_job.dart';
import '../models/coloring_result.dart';
import '../models/complexity_preset.dart';
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
  List<ColoringResult> _works = <ColoringResult>[];

  ColoringJob get job => _job;

  int get tabIndex => _tabIndex;

  String get processingStage => _processingStage;

  int? get selectedPaletteNumber => _selectedPaletteNumber;

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
}
