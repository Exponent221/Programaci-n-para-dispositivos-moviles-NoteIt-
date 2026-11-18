import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/sqlite_task_repository.dart';
import 'data/services/device_image_storage.dart';
import 'data/services/speech_to_text_service.dart';

/// Punto de entrada y *composition root*.
///
/// Es el único lugar que conoce las implementaciones concretas (SQLite,
/// image_picker, speech_to_text). El resto de la app solo ve los contratos
/// definidos en `domain/`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final imageStorage = DeviceImageStorage();
  try {
    await imageStorage.init();
  } catch (error) {
    // Sin carpeta de documentos las fotos se mostrarán como icono.
    debugPrint('[main] No se pudo preparar la carpeta de imágenes: $error');
  }

  runApp(NoteItApp(
    repository: SqliteTaskRepository.instance,
    images: imageStorage,
    createSpeechService: SpeechToTextService.new,
  ));
}
