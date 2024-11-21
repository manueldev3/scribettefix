import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'notebooks.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notebooks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            date TEXT,
            notebookId INTEGER,
            FOREIGN KEY (notebookId) REFERENCES notebooks (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE dates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            context TEXT,
            tasks TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE flashcards (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            flashcards TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE mock_tests (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            questions TEXT
          )
        ''');

        await db.insert('notebooks', {'name': '(Not Assignment)'});
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('DROP TABLE IF EXISTS dates');
          await db.execute('''
            CREATE TABLE dates (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              context TEXT,
              tasks TEXT
            )
          ''');
        }
      },
    );
  }

  Future<void> insertNotebook(String name) async {
    final db = await database;
    await db.insert('notebooks', {'name': name});
  }

  Future<void> insertDate(
      String context, List<Map<String, dynamic>> tasks) async {
    final db = await database;
    await db.insert('dates', {
      'context': context,
      'tasks': jsonEncode(tasks),
    });
  }

  Future<void> renameNotebook(String oldName, String newName) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE notebooks SET name = ? WHERE name = ?',
      [newName, oldName],
    );
  }

  Future<bool> notebookExists(String notebookName) async {
    final db = await database;
    final result = await db.query(
      'notebooks',
      where: 'name = ?',
      whereArgs: [notebookName],
    );
    return result.isNotEmpty;
  }

  Future<bool> noteExists(String noteName) async {
    final db = await database;
    final result = await db.query(
      'files',
      where: 'title = ?',
      whereArgs: [noteName],
    );
    return result.isNotEmpty;
  }

  Future<void> moveNotebook(String title, int notebookId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE files SET notebookId = ? WHERE title = ?',
      [notebookId, title],
    );
  }

  Future<void> deleteNotebook(String name) async {
    final db = await database;

    int? notebookId = await getNotebookIdByName(name);

    if (notebookId != null) {
      await db.delete(
        'files',
        where: 'notebookId = ?',
        whereArgs: [notebookId],
      );

      await db.delete(
        'notebooks',
        where: 'name = ?',
        whereArgs: [name],
      );
    }
  }

  Future<void> deleteNoteByTitle(String title) async {
    final db = await database;

    await db.rawDelete(
      'DELETE FROM files WHERE title = ?',
      [title],
    );
  }

  Future<List<Map<String, dynamic>>> getNotebooks() async {
    final db = await database;
    return await db.query('notebooks');
  }

  Future<List<Map<String, dynamic>>> getFiles(int notebookId) async {
    final db = await database;
    return await db
        .query('files', where: 'notebookId = ?', whereArgs: [notebookId]);
  }

  Future<void> insertFile({
    required String title,
    required String content,
    required String date,
    required int notebookId,
  }) async {
    final db = await database;
    await db.insert('files', {
      'title': title,
      'content': content,
      'date': date,
      'notebookId': notebookId,
    });
  }

  Future<String?> getArticleContentByTitle(String title) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'files',
      columns: ['content'],
      where: 'title = ?',
      whereArgs: [title],
    );

    if (result.isNotEmpty) {
      return result.first['content'] as String?;
    } else {
      return null;
    }
  }

  Future<void> updateArticleContent(String title, String content) async {
    final db = await database;
    await db.update(
      'files',
      {'content': content},
      where: 'title = ?',
      whereArgs: [title],
    );
  }

  Future<String?> getArticleContentById(int id) async {
    final db = await database;
    var result = await db.query(
      'files',
      columns: ['content'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return result.first['content'] as String?;
    }
    return null;
  }

  Future<void> updateArticle(
      String oldTitle, String newTitle, String content) async {
    final db = await database;

    await db.update(
      'files',
      {
        'title': newTitle,
        'content': content,
      },
      where: 'title = ?',
      whereArgs: [oldTitle],
    );
  }

  Future<List<Map<String, dynamic>>> getDates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('dates');
    return maps.map((map) {
      return {
        'id': map['id'],
        'context': map['context'],
        'tasks': jsonDecode(map['tasks']),
      };
    }).toList();
  }

  Future<void> updateDateTasks(int id, List<Map<String, dynamic>> tasks) async {
    final db = await database;
    await db.update(
      'dates',
      {'tasks': jsonEncode(tasks)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int?> getNotebookIdByName(String name) async {
    final db = await database;

    List<Map<String, dynamic>> result = await db.query(
      'notebooks',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int?;
    } else {
      return null;
    }
  }

  Future<void> saveFlashcards(
      String title, List<Map<String, dynamic>> flashcards) async {
    final db = await database;
    await db.insert(
      'flashcards',
      {
        'title': title,
        'flashcards': jsonEncode(flashcards),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getFlashcards(String title) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'flashcards',
      where: 'title = ?',
      whereArgs: [title],
    );

    if (maps.isNotEmpty) {
      return {
        'title': maps[0]['title'],
        'flashcards': jsonDecode(maps[0]['flashcards']),
      };
    }
    return null;
  }

  Future<void> saveMockTest(
      String title, List<Map<String, dynamic>> questions) async {
    final db = await database;
    await db.insert(
      'mock_tests',
      {
        'title': title,
        'questions': jsonEncode(questions),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getMockTest(String title) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'mock_tests',
      where: 'title = ?',
      whereArgs: [title],
    );

    if (maps.isNotEmpty) {
      return {
        'title': maps[0]['title'],
        'questions': jsonDecode(maps[0]['questions']),
      };
    }
    return null;
  }

  Future<void> updateTaskStatus(int taskId, String newStatus) async {
    List<Map<String, dynamic>> dates = await getDates();

    for (var date in dates) {
      List<dynamic> tasks = date['tasks'];
      int index = tasks.indexWhere((task) => task['id'] == taskId);

      if (index != -1) {
        tasks[index]['status'] = newStatus;
        await updateDateTasks(date['id'], tasks.cast<Map<String, dynamic>>());
        break;
      }
    }
  }
}
