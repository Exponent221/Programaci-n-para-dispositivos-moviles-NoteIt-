/// Criterios con los que se puede consultar la lista de pendientes.
enum TaskFilter {
  /// Solo los que faltan por hacer (filtro inicial).
  pending,

  /// Solo los marcados como completados.
  completed,

  /// Todos, sin importar su estado.
  all,
}
