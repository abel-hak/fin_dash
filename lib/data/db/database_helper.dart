import 'dart:async';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sms_transaction_app/data/models/raw_sms_event.dart';
import 'package:sms_transaction_app/data/models/parsed_tx.dart';

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
  
  // Reset the database instance (useful after schema changes)
  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'sms_transactions.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to parsed_tx table
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN transaction_id TEXT NULL');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN timestamp TEXT NULL');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN recipient TEXT NULL');
    }
    if (oldVersion < 3) {
      // Add budgets table
      await db.execute('''
        CREATE TABLE budgets(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          limit_amount REAL NOT NULL,
          period TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
      
      // Add goals table
      await db.execute('''
        CREATE TABLE goals(
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          target_amount REAL NOT NULL,
          current_amount REAL NOT NULL DEFAULT 0,
          deadline TEXT NOT NULL,
          icon_name TEXT NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add receipt-related columns to parsed_tx table
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN receipt_link TEXT NULL');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN has_receipt INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN data_source TEXT NULL');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN payer_account TEXT NULL');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN merchant_account TEXT NULL');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN service_charge REAL NULL');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN vat REAL NULL');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN total_amount REAL NULL');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN payment_method TEXT NULL');
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN branch TEXT NULL');
    }
    if (oldVersion < 5) {
      // Add reason/description column to parsed_tx table
      await db.execute('ALTER TABLE parsed_tx ADD COLUMN reason TEXT NULL');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create raw_sms_event table
    await db.execute('''
      CREATE TABLE raw_sms_event(
        id TEXT PRIMARY KEY,
        sender TEXT,
        body TEXT,
        provider_ts INTEGER,
        received_ts INTEGER,
        handled INTEGER
      )
    ''');

    // Create parsed_tx table
    await db.execute('''
      CREATE TABLE parsed_tx(
        id TEXT PRIMARY KEY,
        sender TEXT,
        amount REAL,
        currency TEXT,
        occurred_at TEXT,
        merchant TEXT,
        account_alias TEXT NULL,
        balance REAL NULL,
        channel TEXT,
        confidence REAL,
        fingerprint TEXT,
        status TEXT CHECK(status IN ('pending','approved','synced')),
        created_at TEXT,
        transaction_id TEXT NULL,
        timestamp TEXT NULL,
        recipient TEXT NULL,
        receipt_link TEXT NULL,
        has_receipt INTEGER DEFAULT 0,
        data_source TEXT NULL,
        payer_account TEXT NULL,
        merchant_account TEXT NULL,
        service_charge REAL NULL,
        vat REAL NULL,
        total_amount REAL NULL,
        payment_method TEXT NULL,
        branch TEXT NULL,
        reason TEXT NULL
      )
    ''');
  }

  // Raw SMS Event methods
  Future<int> insertRawSmsEvent(RawSmsEvent event) async {
    final db = await database;
    return await db.insert('raw_sms_event', event.toMap());
  }

  Future<List<RawSmsEvent>> getUnhandledRawSmsEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'raw_sms_event',
      where: 'handled = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) => RawSmsEvent.fromMap(maps[i]));
  }

  Future<int> updateRawSmsEvent(RawSmsEvent event) async {
    final db = await database;
    return await db.update(
      'raw_sms_event',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteRawSmsEvent(String id) async {
    final db = await database;
    return await db.delete(
      'raw_sms_event',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Parsed Transaction methods
  Future<int> insertParsedTransaction(ParsedTransaction transaction) async {
    final db = await database;
    return await db.insert('parsed_tx', transaction.toMap());
  }

  Future<List<ParsedTransaction>> getParsedTransactions({
    TransactionStatus? status,
    String? sender,
  }) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (status != null && sender != null) {
      whereClause = 'status = ? AND sender = ?';
      whereArgs = [status.toString().split('.').last, sender];
    } else if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status.toString().split('.').last];
    } else if (sender != null) {
      whereClause = 'sender = ?';
      whereArgs = [sender];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'parsed_tx',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'occurred_at DESC',
    );
    
    return List.generate(maps.length, (i) => ParsedTransaction.fromMap(maps[i]));
  }

  Future<int> updateParsedTransaction(ParsedTransaction transaction) async {
    final db = await database;
    return await db.update(
      'parsed_tx',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> updateTransactionStatus(String id, TransactionStatus status) async {
    final db = await database;
    return await db.update(
      'parsed_tx',
      {'status': status.toString().split('.').last},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> transactionExists(String fingerprint) async {
    final db = await database;
    final result = await db.query(
      'parsed_tx',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Get a single transaction by ID (efficient query)
  Future<ParsedTransaction?> getTransactionById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'parsed_tx',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      return null;
    }
    
    return ParsedTransaction.fromMap(maps.first);
  }

  // Get transactions with pagination
  Future<List<ParsedTransaction>> getParsedTransactionsPaginated({
    TransactionStatus? status,
    String? sender,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (status != null && sender != null) {
      whereClause = 'status = ? AND sender = ?';
      whereArgs = [status.toString().split('.').last, sender];
    } else if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status.toString().split('.').last];
    } else if (sender != null) {
      whereClause = 'sender = ?';
      whereArgs = [sender];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'parsed_tx',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'occurred_at DESC',
      limit: limit,
      offset: offset,
    );
    
    return List.generate(maps.length, (i) => ParsedTransaction.fromMap(maps[i]));
  }

  // Get transaction count for a specific status
  Future<int> getTransactionCount({TransactionStatus? status}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status.toString().split('.').last];
    }
    
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM parsed_tx${whereClause != null ? ' WHERE $whereClause' : ''}',
      whereArgs,
    );
    
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Delete old synced transactions (cleanup)
  Future<int> deleteOldSyncedTransactions({int daysOld = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final cutoffDateStr = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(cutoffDate);
    
    return await db.delete(
      'parsed_tx',
      where: 'status = ? AND created_at < ?',
      whereArgs: ['synced', cutoffDateStr],
    );
  }

  // Budget CRUD methods
  Future<int> insertBudget(Map<String, dynamic> budget) async {
    final db = await database;
    return await db.insert('budgets', budget);
  }

  Future<List<Map<String, dynamic>>> getBudgets({bool? isActive}) async {
    final db = await database;
    if (isActive != null) {
      return await db.query(
        'budgets',
        where: 'is_active = ?',
        whereArgs: [isActive ? 1 : 0],
        orderBy: 'created_at DESC',
      );
    }
    return await db.query('budgets', orderBy: 'created_at DESC');
  }

  Future<int> updateBudget(String id, Map<String, dynamic> budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBudget(String id) async {
    final db = await database;
    return await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Goal CRUD methods
  Future<int> insertGoal(Map<String, dynamic> goal) async {
    final db = await database;
    return await db.insert('goals', goal);
  }

  Future<List<Map<String, dynamic>>> getGoals({bool? isActive}) async {
    final db = await database;
    if (isActive != null) {
      return await db.query(
        'goals',
        where: 'is_active = ?',
        whereArgs: [isActive ? 1 : 0],
        orderBy: 'created_at DESC',
      );
    }
    return await db.query('goals', orderBy: 'created_at DESC');
  }

  Future<int> updateGoal(String id, Map<String, dynamic> goal) async {
    final db = await database;
    return await db.update(
      'goals',
      goal,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGoal(String id) async {
    final db = await database;
    return await db.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateGoalProgress(String id, double amount) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE goals SET current_amount = current_amount + ? WHERE id = ?',
      [amount, id],
    );
  }
}
