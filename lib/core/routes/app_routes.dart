/// Nombres de las rutas de la aplicación.
///
/// Centralizarlos evita cadenas repetidas (y errores de dedo) en cada
/// llamada a `Navigator.pushNamed`.
abstract final class AppRoutes {
  /// Lista de pendientes (pantalla inicial).
  static const String home = '/';

  /// Detalle de un pendiente. Recibe un `TaskEntry` como argumento.
  static const String detail = '/detail';

  /// Formulario para crear un pendiente.
  static const String create = '/create';
}
