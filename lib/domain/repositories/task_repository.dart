import '../entities/task_entry.dart';
import '../entities/task_filter.dart';

/// Contrato de persistencia de pendientes.
///
/// Las pantallas dependen de esta abstracción y no de SQLite (principio de
/// inversión de dependencias). Gracias a ello, en las pruebas se usa un
/// repositorio falso en memoria y la base de datos podría cambiarse sin
/// tocar la interfaz.
///
/// Toda implementación debe lanzar `DataAccessException` cuando falle.
abstract interface class TaskRepository {
  /// Guarda un pendiente nuevo y devuelve su `id`.
  Future<int> insertTask(TaskEntry task);

  /// Todos los pendientes, del más reciente al más antiguo.
  Future<List<TaskEntry>> getAllTasks();

  /// Pendientes con el estado indicado (`0` o `1`), del más reciente al
  /// más antiguo.
  Future<List<TaskEntry>> getTasksByStatus(int isCompleted);

  /// Cambia el estado del pendiente [id] al valor indicado (`0` o `1`).
  Future<void> setCompleted(int id, int isCompleted);

  /// Elimina el pendiente [id].
  Future<void> deleteTask(int id);
}

/// Consulta derivada que traduce un [TaskFilter] a la operación adecuada.
///
/// Es una extensión para no obligar a cada implementación a repetirla
/// (las implementaciones solo cubren las operaciones básicas).
extension TaskRepositoryQueries on TaskRepository {
  Future<List<TaskEntry>> getTasks(TaskFilter filter) {
    return switch (filter) {
      TaskFilter.pending => getTasksByStatus(0),
      TaskFilter.completed => getTasksByStatus(1),
      TaskFilter.all => getAllTasks(),
    };
  }
}
