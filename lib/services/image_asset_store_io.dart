import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> saveBinaryAsset({
  required String category,
  required String id,
  required Uint8List bytes,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final assetsDirectory = Directory(
    '${directory.path}${Platform.pathSeparator}flora_certa_assets${Platform.pathSeparator}$category',
  );
  await assetsDirectory.create(recursive: true);

  final file = File('${assetsDirectory.path}${Platform.pathSeparator}$id.bin');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<Uint8List?> readBinaryAsset(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    return null;
  }

  return file.readAsBytes();
}

Future<void> deleteBinaryAsset(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    return;
  }

  await file.delete();
}
