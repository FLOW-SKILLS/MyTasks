import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class Task {
  final int? id;
  String text;
  bool completed;
  int position;
  String createdAt;

  Task({
    this.id,
    required this.text,
    this.completed = false,
    required this.position,
    String? createdAt,
  }) : createdAt = createdAt ?? _now();

  static String _now() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'completed': completed ? 1 : 0,
      'position': position,
      'createdAt': createdAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      text: map['text'] as String,
      completed: (map['completed'] as int) == 1,
      position: map['position'] as int,
      createdAt: (map['createdAt'] as String?) ?? _now(),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'mytasks.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            completed INTEGER NOT NULL DEFAULT 0,
            position INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE tasks ADD COLUMN createdAt TEXT NOT NULL DEFAULT ''");
        }
      },
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final maps = await db.query('tasks', orderBy: 'position ASC');
    return maps.map((m) => Task.fromMap(m)).toList();
  }

  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePositions(List<Task> tasks) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < tasks.length; i++) {
      batch.update(
        'tasks',
        {'position': i},
        where: 'id = ?',
        whereArgs: [tasks[i].id],
      );
    }
    await batch.commit(noResult: true);
  }
}