import '../models/coloring_result.dart';

abstract class GalleryStorageService {
  Future<List<ColoringResult>> loadWorks();

  Future<void> saveWork(ColoringResult result);
}

class InMemoryGalleryStorageService implements GalleryStorageService {
  final List<ColoringResult> _works = <ColoringResult>[];

  @override
  Future<List<ColoringResult>> loadWorks() async => List.unmodifiable(_works);

  @override
  Future<void> saveWork(ColoringResult result) async {
    final existing = _works.indexWhere((work) => work.id == result.id);
    if (existing == -1) {
      _works.insert(0, result);
    } else {
      _works[existing] = result;
    }
  }
}
