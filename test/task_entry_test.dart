import 'package:flutter_test/flutter_test.dart';
import 'package:noteit/domain/entities/task_entry.dart';

void main() {
  group('TaskEntry', () {
    test('create aplica trim y valores iniciales', () {
      final task = TaskEntry.create(title: '  Tarea de Física  ');

      expect(task.id, isNull);
      expect(task.title, 'Tarea de Física');
      expect(task.notes, '');
      expect(task.imagePath, isNull);
      expect(task.isCompleted, 0);
      expect(DateTime.tryParse(task.createdAt), isNotNull);
    });

    test('toMap omite id nulo y fromMap reconstruye el objeto', () {
      final original = TaskEntry.create(
        title: 'Lavar ropa',
        notes: 'Separar colores',
        imagePath: '/tmp/foto.jpg',
      );
      final map = original.toMap();
      expect(map.containsKey('id'), isFalse);

      final restored = TaskEntry.fromMap({...map, 'id': 7, 'isCompleted': 1});
      expect(restored.id, 7);
      expect(restored.title, 'Lavar ropa');
      expect(restored.notes, 'Separar colores');
      expect(restored.imagePath, '/tmp/foto.jpg');
      expect(restored.completed, isTrue);
      expect(restored.createdAt, original.createdAt);
    });
  });
}
