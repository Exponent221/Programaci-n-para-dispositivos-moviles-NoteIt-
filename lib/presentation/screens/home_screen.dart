import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../domain/entities/task_entry.dart';
import '../../domain/entities/task_filter.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/services/image_storage.dart';
import '../widgets/message_view.dart';
import '../widgets/task_card.dart';

/// Textos e iconos de cada filtro. Viven en presentación porque el
/// dominio no debe conocer detalles de la interfaz.
extension TaskFilterLabels on TaskFilter {
  String get title => switch (this) {
        TaskFilter.pending => 'Mis pendientes',
        TaskFilter.completed => 'Completados',
        TaskFilter.all => 'Todos',
      };

  IconData get icon => switch (this) {
        TaskFilter.pending => Icons.pending_actions,
        TaskFilter.completed => Icons.check_circle_outline,
        TaskFilter.all => Icons.list_alt,
      };

  String get emptyMessage => switch (this) {
        TaskFilter.pending =>
          '¡Nada pendiente!\nPulsa + para anotar tu primer pendiente.',
        TaskFilter.completed => 'Aún no has completado ningún pendiente.',
        TaskFilter.all =>
          'No hay pendientes guardados.\nPulsa + para crear uno.',
      };
}

/// Pantalla principal: lista de pendientes con filtros en el Drawer.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository, required this.images});

  final TaskRepository repository;
  final ImageStorage images;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TaskFilter _filter = TaskFilter.pending;

  /// Consulta en curso. Se guarda en el estado para que `FutureBuilder`
  /// no repita la consulta en cada redibujado.
  late Future<List<TaskEntry>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = widget.repository.getTasks(_filter);
  }

  /// Lanza una consulta nueva con el filtro activo.
  void _refresh() {
    // Las llaves son necesarias: con `=>` el closure devolvería el Future
    // asignado y `setState` lanzaría una excepción sin redibujar.
    setState(() {
      _tasksFuture = widget.repository.getTasks(_filter);
    });
  }

  void _selectFilter(TaskFilter filter) {
    Navigator.pop(context); // Cierra el Drawer.
    if (filter == _filter) return;
    _filter = filter;
    _refresh();
  }

  /// Abre [route] y recarga la lista solo si la otra pantalla avisa que
  /// hubo cambios (devuelve `true`).
  Future<void> _openAndRefresh(String route, {Object? arguments}) async {
    final changed =
        await Navigator.pushNamed(context, route, arguments: arguments);
    if (changed == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('NoteIt! · ${_filter.title}')),
      drawer: _FilterDrawer(selected: _filter, onSelected: _selectFilter),
      body: FutureBuilder<List<TaskEntry>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          // 1. Cargando.
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. Error, con opción de reintentar.
          if (snapshot.hasError) {
            return MessageView(
              icon: Icons.error_outline,
              message: snapshot.error.toString(),
              action: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            );
          }
          // 3. Lista vacía según el filtro.
          final tasks = snapshot.data ?? const <TaskEntry>[];
          if (tasks.isEmpty) {
            return MessageView(icon: _filter.icon, message: _filter.emptyMessage);
          }
          // 4. Lista con datos.
          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return TaskCard(
                key: ValueKey(task.id),
                task: task,
                imagePath: widget.images.resolve(task.imagePath),
                onTap: () => _openAndRefresh(AppRoutes.detail, arguments: task),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAndRefresh(AppRoutes.create),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}

/// Menú lateral para elegir el filtro de la lista.
class _FilterDrawer extends StatelessWidget {
  const _FilterDrawer({required this.selected, required this.onSelected});

  final TaskFilter selected;
  final ValueChanged<TaskFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onPrimary = theme.colorScheme.onPrimary;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.edit_note, size: 48, color: onPrimary),
                Text('NoteIt!',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: onPrimary)),
                Text('Escuela · Casa · Trabajo',
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: onPrimary)),
              ],
            ),
          ),
          for (final filter in TaskFilter.values)
            ListTile(
              leading: Icon(filter.icon),
              title: Text(filter.title),
              selected: filter == selected,
              onTap: () => onSelected(filter),
            ),
        ],
      ),
    );
  }
}
