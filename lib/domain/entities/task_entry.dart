/// Un pendiente de la escuela, la casa o el trabajo.
///
/// Es inmutable: cualquier cambio de estado se hace en el repositorio y la
/// interfaz vuelve a consultar los datos. Los nombres de los atributos
/// coinciden con las columnas de la tabla `tasks`, por lo que [toMap] y
/// [TaskEntry.fromMap] son la única traducción necesaria hacia SQLite.
class TaskEntry {
  const TaskEntry({
    this.id,
    required this.title,
    this.notes = '',
    this.imagePath,
    this.isCompleted = 0,
    required this.createdAt,
  });

  /// Crea un pendiente nuevo: limpia los textos, lo marca como pendiente
  /// y registra la fecha actual en formato ISO 8601.
  factory TaskEntry.create({
    required String title,
    String notes = '',
    String? imagePath,
  }) {
    return TaskEntry(
      title: title.trim(),
      notes: notes.trim(),
      imagePath: imagePath,
      createdAt: DateTime.now().toIso8601String(),
    );
  }

  /// Reconstruye un pendiente a partir de una fila de la base de datos.
  factory TaskEntry.fromMap(Map<String, dynamic> map) {
    return TaskEntry(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      imagePath: map['imagePath'] as String?,
      isCompleted: map['isCompleted'] as int? ?? 0,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  /// Clave primaria autoincremental; `null` antes de guardarse.
  final int? id;

  /// Único campo obligatorio para el usuario.
  final String title;

  /// Notas escritas o dictadas (vacío por defecto).
  final String notes;

  /// Ruta de la foto guardada o `null` si no tiene.
  final String? imagePath;

  /// Estado: `0` pendiente, `1` completado (SQLite no tiene booleanos).
  final int isCompleted;

  /// Fecha y hora de creación en ISO 8601.
  final String createdAt;

  /// Versión booleana de [isCompleted] para la interfaz.
  bool get completed => isCompleted == 1;

  /// [createdAt] convertido a `DateTime` (época 0 si es inválido).
  DateTime get createdAtDate =>
      DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Convierte el pendiente en una fila para SQLite.
  ///
  /// Omite `id` cuando es `null` para que SQLite lo genere.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'notes': notes,
      'imagePath': imagePath,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
    };
  }
}
