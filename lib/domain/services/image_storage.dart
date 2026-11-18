/// Origen de una foto. Se define aquí, y no se usa `ImageSource` de
/// `image_picker`, para que el dominio no dependa de un paquete concreto.
enum ImageOrigin { camera, gallery }

/// Contrato del gadget de cámara/galería y del almacenamiento de fotos.
///
/// Las implementaciones deben lanzar `MediaException` si no pueden abrir
/// el origen o guardar la imagen.
abstract interface class ImageStorage {
  /// Abre la cámara o la galería, guarda una copia persistente de la foto
  /// y devuelve su ruta. Devuelve `null` si el usuario cancela.
  Future<String?> pickAndSaveImage(ImageOrigin origin);

  /// Devuelve una ruta existente para la foto guardada en [storedPath], o
  /// `null` si no hay foto o el archivo ya no está disponible.
  String? resolve(String? storedPath);

  /// Borra la foto si existe. No lanza errores: un archivo huérfano no
  /// debe impedir otras operaciones.
  Future<void> deleteImage(String? storedPath);
}
