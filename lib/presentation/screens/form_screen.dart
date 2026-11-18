import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/errors/app_exceptions.dart';
import '../../domain/entities/task_entry.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/services/image_storage.dart';
import '../../domain/services/speech_service.dart';
import '../widgets/dictation_button.dart';

/// Formulario para crear un pendiente con foto y dictado opcionales.
///
/// Regresa con `true` solo si el pendiente se guardó correctamente.
class FormScreen extends StatefulWidget {
  const FormScreen({
    super.key,
    required this.repository,
    required this.images,
    required this.createSpeechService,
  });

  final TaskRepository repository;
  final ImageStorage images;

  /// Fábrica del servicio de voz: cada formulario necesita su propia
  /// instancia porque guarda el estado de la sesión de dictado.
  final SpeechService Function() createSpeechService;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  late final SpeechService _speech = widget.createSpeechService();

  String? _imagePath;
  bool _pickingImage = false;
  bool _isListening = false;
  bool _isSaving = false;
  bool _saved = false;

  /// Texto que tenían las notas al empezar la sesión de dictado actual.
  String _textBeforeDictation = '';

  @override
  void dispose() {
    _speech.dispose(); // Detiene la escucha al salir del formulario.
    // Si se sale sin guardar, la foto copiada ya no se usará.
    if (!_saved) widget.images.deleteImage(_imagePath);
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- Foto

  Future<void> _pickImage(ImageOrigin origin) async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final path = await widget.images.pickAndSaveImage(origin);
      // `null` significa que el usuario canceló: se conserva la anterior.
      if (path != null && mounted) {
        final previous = _imagePath;
        setState(() => _imagePath = path);
        await widget.images.deleteImage(previous);
      }
    } on MediaException catch (error) {
      _showSnack(error.message, isError: true);
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _removeImage() async {
    final previous = _imagePath;
    setState(() => _imagePath = null);
    await widget.images.deleteImage(previous);
  }

  // ------------------------------------------------------------- Dictado

  Future<void> _toggleDictation() async {
    if (_isListening) {
      await _speech.stopListening();
      return;
    }

    final result = await _speech.initSpeech();
    if (!mounted) return;
    if (result != SpeechInitResult.ready) {
      _showSpeechProblem(result);
      return;
    }

    // Se conserva el texto previo; esta sesión solo sustituye su fragmento.
    final current = _notesController.text;
    final needsSpace =
        current.isNotEmpty && !current.endsWith(' ') && !current.endsWith('\n');
    _textBeforeDictation = needsSpace ? '$current ' : current;

    setState(() => _isListening = true);
    try {
      await _speech.startListening(
        onResult: _onSpeechResult,
        onDone: () {
          if (mounted) setState(() => _isListening = false);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isListening = false);
      _showSnack('No se pudo iniciar el dictado.', isError: true);
    }
  }

  /// Escribe en las notas el texto previo más lo dictado en esta sesión y
  /// deja el cursor al final para que el usuario pueda corregir.
  void _onSpeechResult(String sessionText, bool isFinal) {
    if (!mounted) return;
    final text = _textBeforeDictation + sessionText;
    _notesController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// Explica por qué no se puede dictar; el usuario siempre puede escribir.
  void _showSpeechProblem(SpeechInitResult result) {
    switch (result) {
      case SpeechInitResult.permissionDenied:
        _showSnack(
          'Sin permiso de micrófono. Puedes seguir escribiendo tus notas.',
          isError: true,
        );
      case SpeechInitResult.permissionPermanentlyDenied:
        _showSnack(
          'El micrófono está bloqueado. Actívalo en Ajustes o escribe tus notas.',
          isError: true,
          action: SnackBarAction(
            label: 'Ajustes',
            onPressed: _speech.openSettings,
          ),
        );
      case SpeechInitResult.unavailable:
        _showSnack(
          'El reconocimiento de voz no está disponible en este dispositivo.',
          isError: true,
        );
      case SpeechInitResult.ready:
        break;
    }
  }

  // ------------------------------------------------------------- Guardar

  Future<void> _save() async {
    if (_isSaving) return; // Impide envíos duplicados.
    if (!_formKey.currentState!.validate()) return;
    if (_isListening) await _speech.stopListening();
    if (!mounted) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.insertTask(TaskEntry.create(
        title: _titleController.text,
        notes: _notesController.text,
        imagePath: _imagePath,
      ));
      _saved = true;
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Pendiente guardado.')),
      );
      Navigator.pop(context, true);
    } catch (error) {
      // Se conservan los datos del formulario para reintentar.
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnack(
        error is AppException ? error.message : 'No se pudo guardar el pendiente.',
        isError: true,
      );
    }
  }

  void _showSnack(String message,
      {bool isError = false, SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : null,
        action: action,
      ));
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final busy = _isSaving || _pickingImage;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo pendiente')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Título *',
                hintText: 'Ej. Ejercicio 3 de Cálculo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Escribe un título para el pendiente.'
                  : null,
            ),
            const SizedBox(height: 8),
            _PhotoPicker(
              imagePath: _imagePath,
              loading: _pickingImage,
              enabled: !busy,
              onPick: _pickImage,
              onRemove: _removeImage,
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _notesController,
                    enabled: !_isSaving,
                    minLines: 4,
                    maxLines: 10,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Notas (opcional)',
                      hintText: 'Escribe o dicta las indicaciones…',
                      helperText: _isListening
                          ? 'Escuchando… pulsa detener para corregir el texto.'
                          : 'Puedes editar la transcripción cuando quieras.',
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DictationButton(
                  isListening: _isListening,
                  enabled: !_isSaving,
                  onPressed: _toggleDictation,
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: busy ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Guardando…' : 'Guardar pendiente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vista previa de la foto con los botones *Tomar foto* y *Galería*.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.imagePath,
    required this.loading,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final String? imagePath;
  final bool loading;
  final bool enabled;
  final ValueChanged<ImageOrigin> onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = imagePath;

    final Widget preview;
    if (loading) {
      preview = const Center(child: CircularProgressIndicator());
    } else if (path == null) {
      preview = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined,
              size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('Foto opcional', style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      );
    } else {
      preview = Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(path), fit: BoxFit.cover),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filledTonal(
              tooltip: 'Quitar foto',
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            color: scheme.surfaceContainerHighest,
            child: preview,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? () => onPick(ImageOrigin.camera) : null,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Tomar foto'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: enabled ? () => onPick(ImageOrigin.gallery) : null,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
