import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteit/domain/entities/task_entry.dart';
import 'package:noteit/domain/repositories/task_repository.dart';
import 'package:noteit/domain/services/image_storage.dart';
import 'package:noteit/presentation/screens/home_screen.dart';

/// Repositorio en memoria. Funciona porque [HomeScreen] depende de la
/// abstracción [TaskRepository] y no de SQLite.
class FakeTaskRepository implements TaskRepository {
  FakeTaskRepository(this.tasks);

  final List<TaskEntry> tasks;

  @override
  Future<int> insertTask(TaskEntry task) async {
    tasks.add(task);
    return tasks.length;
  }

  @override
  Future<List<TaskEntry>> getAllTasks() async => List.of(tasks);

  @override
  Future<List<TaskEntry>> getTasksByStatus(int isCompleted) async =>
      tasks.where((t) => t.isCompleted == isCompleted).toList();

  @override
  Future<void> setCompleted(int id, int isCompleted) async {}

  @override
  Future<void> deleteTask(int id) async {}
}

/// Almacenamiento de imágenes que nunca tiene fotos.
class FakeImageStorage implements ImageStorage {
  @override
  Future<String?> pickAndSaveImage(ImageOrigin origin) async => null;

  @override
  String? resolve(String? storedPath) => null;

  @override
  Future<void> deleteImage(String? storedPath) async {}
}

Future<void> pumpHome(WidgetTester tester, List<TaskEntry> tasks) async {
  await tester.pumpWidget(MaterialApp(
    home: HomeScreen(
      repository: FakeTaskRepository(tasks),
      images: FakeImageStorage(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('muestra solo los pendientes no completados', (tester) async {
    await pumpHome(tester, [
      const TaskEntry(
          id: 1, title: 'Tarea de Cálculo', createdAt: '2026-11-01T10:00:00'),
      const TaskEntry(
          id: 2,
          title: 'Lavar ropa',
          isCompleted: 1,
          createdAt: '2026-11-02T10:00:00'),
    ]);

    expect(find.text('Tarea de Cálculo'), findsOneWidget);
    expect(find.text('Lavar ropa'), findsNothing);
  });

  testWidgets('muestra un mensaje cuando no hay pendientes', (tester) async {
    await pumpHome(tester, []);

    expect(find.textContaining('Nada pendiente'), findsOneWidget);
  });
}
