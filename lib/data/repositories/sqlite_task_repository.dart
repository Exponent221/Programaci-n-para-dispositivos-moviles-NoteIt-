import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/errors/app_exceptions.dart';
import '../../domain/entities/task_entry.dart';
import '../../domain/repositories/task_repository.dart';

/// Implementación de [TaskRepository] con SQLite (`sqflite`).
///
/// Es un singleton ([instance]) para que toda la app comparta una sola
/// conexión a `noteit.db`. Cada operación pasa por [_guard], que registra
/// el error técnico y lo convierte en [DataAccessException].
class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository._internal();

  /// Única instancia de la clase.
  static final SqliteTaskRepository instance =
      SqliteTaskRepository._internal();

  static const String _dbName = 'noteit.db';
  static const int _dbVersion = 1;
  static const String _table = 'tasks';

  Database? _database;

  /// Conexión abierta de forma perezosa en el primer uso.
  Future<Database> get _db async => _database ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  /// Crea la tabla. Las columnas tienen los mismos nombres que los
  /// atributos de [TaskEntry].
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        imagePath TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  /// Ejecuta [action]; si falla, registra el detalle en la consola y lanza
  /// una [DataAccessException] con [userMessage].
  Future<T> _guard<T>(String userMessage, Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      debugPrint('[SqliteTaskRepository] $userMessage\n$error\n$stackTrace');
      throw DataAccessException(userMessage, error);
    }
  }

  @override
  Future<int> insertTask(TaskEntry task) {
    return _guard('No se pudo guardar el pendiente.', () async {
      final db = await _db;
      return db.insert(_table, task.toMap());
    });
  }

  @override
  Future<List<TaskEntry>> getAllTasks() {
    return _guard('No se pudieron cargar los pendientes.', () async {
      final db = await _db;
      final rows = await db.query(_table, orderBy: 'createdAt DESC');
      return rows.map(TaskEntry.fromMap).toList();
    });
  }

  @override
  Future<List<TaskEntry>> getTasksByStatus(int isCompleted) {
    return _guard('No se pudieron cargar los pendientes.', () async {
      final db = await _db;
      final rows = await db.query(
        _table,
        where: 'isCompleted = ?',
        whereArgs: [isCompleted],
        orderBy: 'createdAt DESC',
      );
      return rows.map(TaskEntry.fromMap).toList();
    });
  }

  @override
  Future<void> setCompleted(int id, int isCompleted) {
    return _guard('No se pudo actualizar el estado.', () async {
      final db = await _db;
      final updated = await db.update(
        _table,
        {'isCompleted': isCompleted},
        where: 'id = ?',
        whereArgs: [id],
      );
      if (updated == 0) {
        throw StateError('No existe un pendiente con id $id');
      }
    });
  }

  @override
  Future<void> deleteTask(int id) {
    return _guard('No se pudo eliminar el pendiente.', () async {
      final db = await _db;
      await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    });
  }
}
