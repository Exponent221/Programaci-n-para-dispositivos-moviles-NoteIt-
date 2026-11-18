/// Resultado de preparar el reconocimiento de voz.
enum SpeechInitResult {
  /// Permisos concedidos y reconocedor disponible.
  ready,

  /// El usuario negó el permiso, pero se puede volver a pedir.
  permissionDenied,

  /// El permiso está bloqueado; solo se puede activar desde Ajustes.
  permissionPermanentlyDenied,

  /// El dispositivo no tiene un servicio de reconocimiento de voz.
  unavailable,
}

/// Recibe el texto reconocido en la sesión de dictado actual.
typedef SpeechResultCallback = void Function(String sessionText, bool isFinal);

/// Contrato del gadget de micrófono con transcripción.
///
/// Cada formulario crea su propia instancia porque guarda el estado de una
/// sesión de dictado.
abstract interface class SpeechService {
  /// `true` mientras el micrófono está escuchando.
  bool get isListening;

  /// Pide permisos y comprueba el reconocedor. Puede llamarse varias veces.
  Future<SpeechInitResult> initSpeech();

  /// Inicia una sesión de dictado.
  ///
  /// [onResult] recibe solo el texto de esta sesión (parcial o final);
  /// quien llama decide cómo unirlo con el texto previo. [onDone] se llama
  /// una única vez cuando la escucha termina por cualquier motivo.
  Future<void> startListening({
    required SpeechResultCallback onResult,
    required void Function() onDone,
  });

  /// Detiene la escucha y conserva lo reconocido hasta el momento.
  Future<void> stopListening();

  /// Abre los ajustes de la app para que el usuario active el permiso.
  Future<bool> openSettings();

  /// Cancela cualquier escucha sin notificar a la pantalla.
  Future<void> dispose();
}
