import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/task_entry.dart';

/// Etiqueta compartida por la miniatura y la foto del detalle para la
/// animación Hero.
String taskHeroTag(TaskEntry task) => 'task-hero-${task.id}';

/// Tarjeta de la lista: miniatura (o icono), título y estado.
///
/// Es un widget de presentación puro: recibe la ruta de la foto ya
/// resuelta y no sabe nada de la base de datos ni del almacenamiento.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.imagePath,
    required this.onTap,
  });

  final TaskEntry task;

  /// Ruta existente de la foto, o `null` para mostrar un icono.
  final String? imagePath;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = task.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Hero(
                tag: taskHeroTag(task),
                child: TaskThumbnail(path: imagePath),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusRow(done: done, hasNotes: task.notes.isNotEmpty),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila con el icono y el texto del estado.
class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.done, required this.hasNotes});

  final bool done;
  final bool hasNotes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: done ? Colors.greenAccent : theme.colorScheme.secondary,
        ),
        const SizedBox(width: 4),
        Text(done ? 'Completado' : 'Pendiente', style: theme.textTheme.bodySmall),
        if (hasNotes) ...[
          const SizedBox(width: 10),
          const Icon(Icons.notes, size: 16),
        ],
      ],
    );
  }
}

/// Miniatura cuadrada con esquinas redondeadas. Si no hay foto o no se
/// puede abrir, muestra un icono.
class TaskThumbnail extends StatelessWidget {
  const TaskThumbnail({super.key, required this.path, this.size = 64});

  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget placeholder() => Container(
          width: size,
          height: size,
          color: scheme.surfaceContainerHighest,
          child: Icon(Icons.task_alt, color: scheme.onSurfaceVariant),
        );

    final imagePath = path;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imagePath == null
          ? placeholder()
          : Image.file(
              File(imagePath),
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Decodifica a tamaño reducido para no gastar memoria.
              cacheWidth: (size * 3).round(),
              errorBuilder: (_, __, ___) => placeholder(),
            ),
    );
  }
}
