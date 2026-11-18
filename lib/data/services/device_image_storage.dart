import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_exceptions.dart';
import '../../domain/services/image_storage.dart';

/// Gadget 1: cámara y galería con `image_picker`.
///
/// Copia cada foto elegida a `Documentos/images/` con un nombre único, de
/// modo que siga disponible aunque el usuario la borre de su galería.
class DeviceImageStorage implements ImageStorage {
  DeviceImageStorage({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Carpeta donde se guardan las fotos; se obtiene en [init].
  String? _imagesDirPath;

  /// Prepara la carpeta de imágenes. Se llama una vez al iniciar la app,
  /// así [resolve] puede ser síncrono y usarse al dibujar la interfaz.
  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    _imagesDirPath = p.join(docsDir.path, 'images');
  }

  @override
  Future<String?> pickAndSaveImage(ImageOrigin origin) async {
    final source =
        origin == ImageOrigin.camera ? ImageSource.camera : ImageSource.gallery;

    final XFile? picked;
    try {
      picked = await _picker.pickImage(source: source, imageQuality: 85);
    } catch (error) {
      debugPrint('[DeviceImageStorage] Error al abrir ${source.name}: $error');
      throw MediaException(
        origin == ImageOrigin.camera
            ? 'No se pudo abrir la cámara. Revisa los permisos.'
            : 'No se pudo abrir la galería. Revisa los permisos.',
        error,
      );
    }

    if (picked == null) return null; // El usuario canceló.

    try {
      if (_imagesDirPath == null) await init();
      final imagesDir = Directory(_imagesDirPath!);
      if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

      var extension = p.extension(picked.path).toLowerCase();
      if (extension.isEmpty) extension = '.jpg';
      final fileName =
          'task_${DateTime.now().microsecondsSinceEpoch}$extension';
      final destination = p.join(imagesDir.path, fileName);

      await picked.saveTo(destination);
      return destination;
    } catch (error) {
      debugPrint('[DeviceImageStorage] Error al copiar la imagen: $error');
      throw MediaException('No se pudo guardar la foto en el dispositivo.', error);
    }
  }

  /// En iOS la ruta absoluta del contenedor de la app puede cambiar al
  /// actualizarla. Si la ruta guardada ya no existe, se busca el mismo
  /// nombre de archivo en la carpeta de imágenes actual.
  @override
  String? resolve(String? storedPath) {
    if (storedPath == null) return null;
    if (File(storedPath).existsSync()) return storedPath;

    final dir = _imagesDirPath;
    if (dir == null) return null;
    final candidate = p.join(dir, p.basename(storedPath));
    return File(candidate).existsSync() ? candidate : null;
  }

  @override
  Future<void> deleteImage(String? storedPath) async {
    final path = resolve(storedPath);
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (error) {
      debugPrint('[DeviceImageStorage] No se pudo borrar $path: $error');
    }
  }
}
