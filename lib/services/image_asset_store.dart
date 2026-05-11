import 'dart:typed_data';

import 'image_asset_store_stub.dart'
    if (dart.library.io) 'image_asset_store_io.dart'
    as impl;

class ImageAssetStore {
  const ImageAssetStore();

  Future<String?> saveBinaryAsset({
    required String category,
    required String id,
    required Uint8List bytes,
  }) {
    return impl.saveBinaryAsset(category: category, id: id, bytes: bytes);
  }

  Future<Uint8List?> readBinaryAsset(String path) {
    return impl.readBinaryAsset(path);
  }

  Future<void> deleteBinaryAsset(String path) {
    return impl.deleteBinaryAsset(path);
  }
}
