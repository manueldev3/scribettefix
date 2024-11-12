import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
      version: 1,
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
    title TEXT,
    date TEXT
  )
''');

        await db.insert('notebooks', {'name': '(Not Assignment)'});
      },
    );
  }

  Future<void> insertNotebook(String name) async {
    final db = await database;
    await db.insert('notebooks', {'name': name});
  }

  Future<void> insertDate(String name, String date) async {
    final db = await database;
    await db.insert('dates', {'title': name, 'date': date});
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
      [notebookId, title], // Bind the notebookId and title to the query
    );
  }

  Future<void> deleteNotebook(String name) async {
    final db = await database;

    // Step 1: Get the ID of the notebook to be deleted
    int? notebookId = await getNotebookIdByName(name);

    if (notebookId != null) {
      // Step 2: Delete all files associated with this notebook
      await db.delete(
        'files',
        where: 'notebookId = ?',
        whereArgs: [notebookId],
      );

      // Step 3: Delete the notebook itself
      await db.delete(
        'notebooks',
        where: 'name = ?',
        whereArgs: [name],
      );
    }
  }

  Future<void> deleteNoteByTitle(String title) async {
    final db = await database;

    // Delete the note from the 'files' table where the title matches
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
      'files', // assuming the table is 'files'
      columns: ['content'], // only select the content field
      where: 'title = ?', // filter by title
      whereArgs: [title],
    );

    if (result.isNotEmpty) {
      return result.first['content'] as String?;
    } else {
      return null; // Return null if no article is found
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

  // Fetch article content by ID
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
      'files', // The table you're working with
      {
        'title': newTitle, // Update the title
        'content': content, // Update the content
      },
      where: 'title = ?', // Find the row by its current title
      whereArgs: [oldTitle], // Provide the old title as the condition
    );
  }

  Future<Map<DateTime, List<String>>> getEventsByDate() async {
    final db = await database;

    // Query to get all rows from the 'dates' table
    final List<Map<String, dynamic>> result = await db.query('dates');

    // Initialize an empty map to hold the DateTime and list of event titles
    Map<DateTime, List<String>> eventsDate = {};

    // Loop through each row in the result
    for (var row in result) {
      // Extract the title and date as a string
      String title = row['title'];
      String dateString = row['date'];

      // Parse the date string into a DateTime object (assuming 'date' is in ISO 8601 format)
      try {
        DateTime eventDate = DateTime.parse(dateString.trim());
        // Check if the date already exists in the map
        if (eventsDate.containsKey(eventDate)) {
          // If it exists, add the event title to the list
          eventsDate[eventDate]!.add(title.trim());
        } else {
          // If the date is not present, create a new entry with a list containing the title
          eventsDate[eventDate] = [title.trim()];
        }
      } catch (e) {}
    }

    return eventsDate;
  }

  Future<int?> getNotebookIdByName(String name) async {
    final db = await database;

    // Query the 'notebooks' table for the notebook with the specified name
    List<Map<String, dynamic>> result = await db.query(
      'notebooks',
      columns: ['id'], // We only need the 'id' column
      where: 'name = ?',
      whereArgs: [name],
    );

    // If the result is not empty, return the id, otherwise return null
    if (result.isNotEmpty) {
      return result.first['id'] as int?;
    } else {
      return null; // Return null if no notebook with the given name is found
    }
  }
}
