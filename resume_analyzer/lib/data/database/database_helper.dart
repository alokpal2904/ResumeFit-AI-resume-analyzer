import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/resume_history_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('resume_analyzer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);
    
    print('=============================================');
    print('SQLite Database Path: $path');
    print('=============================================');

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE resume_history (
  id $idType,
  title $textType,
  summary $textType,
  score $realType,
  createdAt $textType
  )
''');
  }

  Future<ResumeHistoryModel> create(ResumeHistoryModel resume) async {
    final db = await instance.database;
    await db.insert('resume_history', resume.toMap());
    return resume;
  }

  Future<ResumeHistoryModel?> readResume(String id) async {
    final db = await instance.database;

    final maps = await db.query(
      'resume_history',
      columns: ['id', 'title', 'summary', 'score', 'createdAt'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ResumeHistoryModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<List<ResumeHistoryModel>> readAllResumes() async {
    final db = await instance.database;
    final result = await db.query('resume_history', orderBy: 'createdAt DESC');
    return result.map((json) => ResumeHistoryModel.fromMap(json)).toList();
  }

  Future<int> update(ResumeHistoryModel resume) async {
    final db = await instance.database;

    return db.update(
      'resume_history',
      resume.toMap(),
      where: 'id = ?',
      whereArgs: [resume.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await instance.database;

    return await db.delete(
      'resume_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
