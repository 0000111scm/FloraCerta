import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<XFile?> pickFromCamera() {
    return _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 95,
      maxWidth: 2048,
      maxHeight: 2048,
    );
  }

  Future<XFile?> pickFromGallery() {
    return _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
      maxWidth: 2048,
      maxHeight: 2048,
    );
  }

  Future<List<XFile>> pickMultipleFromGallery({int maxImages = 5}) async {
    final files = await _picker.pickMultiImage(
      imageQuality: 95,
      maxWidth: 2048,
      maxHeight: 2048,
      limit: maxImages,
    );
    return files;
  }
}
