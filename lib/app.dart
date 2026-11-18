import 'package:flutter/material.dart';

import 'core/routes/app_routes.dart';
import 'domain/repositories/task_repository.dart';
import 'domain/services/image_storage.dart';
import 'domain/services/speech_service.dart';
import 'presentation/screens/detail_screen.dart';
import 'presentation/screens/form_screen.dart';
import 'presentation/screens/home_screen.dart';

/// Widget raíz: tema oscuro y mapa de rutas nombradas.
///
/// Recibe las dependencias como abstracciones y las entrega a cada
/// pantalla por su constructor. No sabe si los datos vienen de SQLite o de
/// un repositorio falso, lo que permite probar la interfaz por separado.
class NoteItApp extends StatelessWidget {
  const NoteItApp({
    super.key,
    required this.repository,
    required this.images,
    required this.createSpeechService,
  });

  final TaskRepository repository;
  final ImageStorage images;
  final SpeechService Function() createSpeechService;

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark();

    return MaterialApp(
      title: 'NoteIt!',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: Colors.amber,
          onPrimary: Colors.black,
          secondary: Colors.tealAccent,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
        ),
      ),
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home: (_) =>
            HomeScreen(repository: repository, images: images),
        AppRoutes.detail: (_) =>
            DetailScreen(repository: repository, images: images),
        AppRoutes.create: (_) => FormScreen(
              repository: repository,
              images: images,
              createSpeechService: createSpeechService,
            ),
      },
    );
  }
}
