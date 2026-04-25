import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../models/picked_image.dart';

abstract class ImagePickService {
  Future<PickedImage?> pickFromGallery();

  Future<PickedImage?> pickFromCamera();
}

class MobileImagePickService implements ImagePickService {
  MobileImagePickService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedImage?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 92,
    );
    return _toPickedImage(file);
  }

  @override
  Future<PickedImage?> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      imageQuality: 92,
    );
    return _toPickedImage(file);
  }

  Future<PickedImage?> _toPickedImage(XFile? file) async {
    if (file == null) {
      return null;
    }
    return PickedImage(
      path: file.path,
      name: file.name,
      bytes: await file.readAsBytes(),
    );
  }
}

class DemoImagePickService implements ImagePickService {
  @override
  Future<PickedImage?> pickFromCamera() async => _demo('camera');

  @override
  Future<PickedImage?> pickFromGallery() async => _demo('gallery');

  PickedImage _demo(String source) {
    return PickedImage(
      path: 'demo://$source/dog',
      name: 'demo-dog.png',
      bytes: Uint8List(0),
    );
  }
}
