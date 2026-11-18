import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/task_entry.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/services/image_storage.dart';
import '../widgets/message_view.dart';
import '../widgets/task_card.dart';

/// Detalle de un pendiente: foto (con Hero), notas y acciones.
///
/// Recibe el [TaskEntry] como argumento de la ruta. Cuando modifica algo
/// regresa con `true` para que la lista se actualice.
class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.repository,
    required this.images,
  });

  final TaskRepository repository;
  final ImageStorage images;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  /// Evita tocar dos veces una acción mientras se ejecuta.
  bool _busy = false;

  /// Marca como completado o regresa a pendientes.
  Future<void> _toggleStatus(TaskEntry task) async {
    await _run(
      () => widget.repository.setCompleted(task.id!, task.completed ? 0 : 1),
      successMessage:
          task.completed ? 'Pendiente reabierto.' : '¡Pendiente completado!',
    );
  }

  /// Pide confirmación, elimina el pendiente y después su foto.
  Future<void> _delete(TaskEntry task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteDialog(title: task.title),
    );
    if (confirmed != true) return;

    await _run(
      () async {
        await widget.repository.deleteTask(task.id!);
        await widget.images.deleteImage(task.imagePath);
      },
      successMessage: 'Pendiente eliminado.',
    );
  }

  /// Ejecuta una modificación. Si sale bien, avisa y regresa con `true`;
  /// si falla, conserva la vista y muestra el error.
  Future<void> _run(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(
        content: Text(error is AppException ? error.message : 'Ocurrió un error.'),
        backgroundColor: Colors.red.shade700,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! TaskEntry || args.id == null) {
      // Protección por si la ruta se abre sin un pendiente válido.
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const MessageView(
          icon: Icons.help_outline,
          message: 'No se encontró el pendiente.',
        ),
      );
    }
    final task = args;
    final theme = Theme.of(context);
    final done = task.completed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: _busy ? null : () => _delete(task),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Hero(
            tag: taskHeroTag(task),
            child: _DetailImage(
              hasImage: task.imagePath != null,
              path: widget.images.resolve(task.imagePath),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(
                        done ? Icons.check_circle : Icons.pending_actions,
                        size: 18,
                        color: done ? Colors.greenAccent : Colors.amber,
                      ),
                      label: Text(done ? 'Completado' : 'Pendiente'),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 16),
                        const SizedBox(width: 4),
                        Text(formatDateTime(task.createdAtDate),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text('Notas', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  task.notes.isEmpty ? 'Sin notas.' : task.notes,
                  style: task.notes.isEmpty
                      ? theme.textTheme.bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic)
                      : theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _toggleStatus(task),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: done ? Colors.blueGrey : Colors.green,
              foregroundColor: Colors.white,
            ),
            icon: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Icon(done ? Icons.undo : Icons.check),
            label: Text(done ? 'Volver a pendientes' : 'Marcar como completado'),
          ),
        ),
      ),
    );
  }
}

/// Diálogo de confirmación para eliminar.
class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar pendiente'),
      content: Text('¿Seguro que quieres eliminar "$title"? '
          'Esta acción no se puede deshacer.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}

/// Foto grande del detalle, o un icono si no hay o no se encuentra.
class _DetailImage extends StatelessWidget {
  const _DetailImage({required this.hasImage, required this.path});

  /// Si el pendiente tenía foto registrada.
  final bool hasImage;

  /// Ruta resuelta; `null` si el archivo no está disponible.
  final String? path;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget placeholder(IconData icon, String label) => Container(
          height: 220,
          width: double.infinity,
          color: scheme.surfaceContainerHighest,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: scheme.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        );

    if (!hasImage) return placeholder(Icons.task_alt, 'Sin foto');
    final imagePath = path;
    if (imagePath == null) {
      return placeholder(Icons.broken_image_outlined, 'No se encontró la foto');
    }
    return Image.file(
      File(imagePath),
      height: 300,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          placeholder(Icons.broken_image_outlined, 'No se pudo abrir la foto'),
    );
  }
}
