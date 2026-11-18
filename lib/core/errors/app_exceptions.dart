/// Excepciones propias de la aplicación.
///
/// Todas separan dos audiencias: [message] es un texto apto para mostrarse
/// al usuario y [cause] conserva el error técnico original para depuración.
/// Así la capa de presentación nunca necesita conocer errores de SQLite,
/// del sistema de archivos o de plugins nativos.
library;

/// Clase base de los errores que la interfaz sabe mostrar.
abstract class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  /// Mensaje en lenguaje natural para el usuario.
  final String message;

  /// Error técnico que originó el fallo (puede ser `null`).
  final Object? cause;

  @override
  String toString() => message;
}

/// Fallo al leer o escribir en la base de datos local.
class DataAccessException extends AppException {
  const DataAccessException(super.message, [super.cause]);
}

/// Fallo al abrir la cámara/galería o al guardar una imagen.
class MediaException extends AppException {
  const MediaException(super.message, [super.cause]);
}
