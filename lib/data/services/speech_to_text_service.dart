import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/services/speech_service.dart';

//Gadget 2: micrófono con transcripción usando `speech_to_text`.
//Usé de preferencia español de México, si no está instalado, usa otra variante de
//español y, como último recurso, el idioma del sistema.
class SpeechToTextService implements SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;
  String? _localeId;

  //Callback de la sesión actual y bandera para avisar una sola vez.
  void Function()? _onDone;
  bool _doneNotified = true;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<SpeechInitResult> initSpeech() async {
    if (_initialized) return SpeechInitResult.ready;

    //1. Solo se piden los permisos que necesita esta acción.
    final permissions = <Permission>[
      Permission.microphone,
      if (defaultTargetPlatform == TargetPlatform.iOS) Permission.speech,
    ];
    for (final permission in permissions) {
      final status = await permission.request();
      if (status.isPermanentlyDenied || status.isRestricted) {
        return SpeechInitResult.permissionPermanentlyDenied;
      }
      if (!status.isGranted && !status.isLimited) {
        return SpeechInitResult.permissionDenied;
      }
    }

    //2. Comprueba que el dispositivo tenga reconocedor de voz.
    try {
      _initialized = await _speech.initialize(
        onStatus: _handleStatus,
        onError: _handleError,
      );
    } catch (error) {
      debugPrint('[SpeechToTextService] Error al inicializar: $error');
      _initialized = false;
    }
    if (!_initialized) return SpeechInitResult.unavailable;

    //3. Elige el idioma.
    _localeId = await _pickSpanishLocale();
    return SpeechInitResult.ready;
  }

  //Busca `es_MX`, si no existe, cualquier `es_*`, si no, `null`
  //(idioma del sistema).
  Future<String?> _pickSpanishLocale() async {
    try {
      final locales = await _speech.locales();
      String normalize(String id) => id.replaceAll('-', '_').toLowerCase();

      for (final locale in locales) {
        if (normalize(locale.localeId) == 'es_mx') return locale.localeId;
      }
      for (final locale in locales) {
        if (normalize(locale.localeId).startsWith('es')) return locale.localeId;
      }
    } catch (error) {
      debugPrint('[SpeechToTextService] No se pudieron leer los idiomas: $error');
    }
    return null;
  }

  @override
  Future<void> startListening({
    required SpeechResultCallback onResult,
    required void Function() onDone,
  }) async {
    if (!_initialized) {
      throw StateError('Llama a initSpeech() antes de dictar.');
    }
    _onDone = onDone;
    _doneNotified = false;

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) =>
            onResult(result.recognizedWords, result.finalResult),
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenFor: const Duration(minutes: 1),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          listenMode: ListenMode.dictation,
          cancelOnError: true,
        ),
      );
    } catch (error) {
      debugPrint('[SpeechToTextService] Error al iniciar el dictado: $error');
      _notifyDone();
      rethrow;
    }
  }

  @override
  Future<void> stopListening() async {
    try {
      if (_speech.isListening) await _speech.stop();
    } finally {
      _notifyDone();
    }
  }

  @override
  Future<bool> openSettings() => openAppSettings();

  @override
  Future<void> dispose() async {
    _onDone = null;
    _doneNotified = true;
    if (_speech.isListening) await _speech.cancel();
  }

  void _handleStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _notifyDone();
    }
  }

  void _handleError(SpeechRecognitionError error) {
    debugPrint('[SpeechToTextService] Error de reconocimiento: ${error.errorMsg}');
    _notifyDone();
  }

  //Avisa a la pantalla que terminó la escucha, una sola vez por sesión
  //(el plugin puede reportar varios estados de fin seguidos).
  void _notifyDone() {
    if (_doneNotified) return;
    _doneNotified = true;
    final callback = _onDone;
    _onDone = null;
    callback?.call();
  }
}
