import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class PendingLocalOp {
  final int id;
  final String entity;
  final String op;
  final String refId;
  final Map<String, dynamic> payload;

  const PendingLocalOp({
    required this.id,
    required this.entity,
    required this.op,
    required this.refId,
    required this.payload,
  });
}

class LocalDataStore {
  static const _dbName = 'ahvi_local_sync.db';
  static const _dbVersion = 3;
  static const _wardrobeTable = 'wardrobe_cache';
  static const _boardsTable = 'boards_cache';
  static const _chatThreadsTable = 'chat_threads_cache';
  static const _profileTable = 'profile_cache';
  static const _opsTable = 'pending_local_ops';

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    _db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_wardrobeTable (
            user_id TEXT NOT NULL,
            id TEXT NOT NULL,
            data_json TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (user_id, id)
          )
        ''');
        await db.execute('''
          CREATE TABLE $_boardsTable (
            user_id TEXT NOT NULL,
            id TEXT NOT NULL,
            occasion TEXT,
            data_json TEXT NOT NULL,
            raw_json TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (user_id, id)
          )
        ''');
        await db.execute('''
          CREATE TABLE $_chatThreadsTable (
            user_id TEXT NOT NULL,
            id TEXT NOT NULL,
            title TEXT,
            last_message TEXT,
            module TEXT,
            data_json TEXT NOT NULL,
            raw_json TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            PRIMARY KEY (user_id, id)
          )
        ''');
        await db.execute('''
          CREATE TABLE $_profileTable (
            user_id TEXT NOT NULL PRIMARY KEY,
            data_json TEXT NOT NULL,
            raw_json TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_opsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            entity TEXT NOT NULL,
            op TEXT NOT NULL,
            ref_id TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_chatThreadsTable (
              user_id TEXT NOT NULL,
              id TEXT NOT NULL,
              title TEXT,
              last_message TEXT,
              module TEXT,
              data_json TEXT NOT NULL,
              raw_json TEXT NOT NULL,
              updated_at TEXT NOT NULL,
              PRIMARY KEY (user_id, id)
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_profileTable (
              user_id TEXT NOT NULL PRIMARY KEY,
              data_json TEXT NOT NULL,
              raw_json TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<Database> _database() async {
    await init();
    return _db!;
  }

  Future<void> cacheWardrobeItems(
    String userId,
    List<Map<String, dynamic>> items,
  ) async {
    final db = await _database();
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final item in items) {
      final id = (item['id'] ?? '').toString();
      if (id.isEmpty) continue;
      batch.insert(
        _wardrobeTable,
        {
          'user_id': userId,
          'id': id,
          'data_json': jsonEncode(item),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertWardrobeItem(String userId, Map<String, dynamic> item) async {
    final db = await _database();
    final id = (item['id'] ?? '').toString();
    if (id.isEmpty) return;
    await db.insert(
      _wardrobeTable,
      {
        'user_id': userId,
        'id': id,
        'data_json': jsonEncode(item),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteWardrobeItem(String userId, String id) async {
    final db = await _database();
    await db.delete(
      _wardrobeTable,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  Future<List<Map<String, dynamic>>> loadWardrobeItems(String userId) async {
    final db = await _database();
    final rows = await db.query(
      _wardrobeTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return rows
        .map((r) => Map<String, dynamic>.from(jsonDecode((r['data_json'] as String?) ?? '{}')))
        .toList();
  }

  Future<void> cacheBoards(
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    final db = await _database();
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      final id = (row['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final data = Map<String, dynamic>.from(row['data'] ?? const {});
      final raw = Map<String, dynamic>.from(row['raw'] ?? const {});
      batch.insert(
        _boardsTable,
        {
          'user_id': userId,
          'id': id,
          'occasion': (data['occasion'] ?? '').toString().toLowerCase(),
          'data_json': jsonEncode(data),
          'raw_json': jsonEncode(raw),
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> loadBoards(
    String userId, {
    String? occasion,
  }) async {
    final db = await _database();
    final where = StringBuffer('user_id = ?');
    final args = <Object>[userId];
    if (occasion != null && occasion.isNotEmpty) {
      where.write(' AND occasion = ?');
      args.add(occasion.toLowerCase());
    }
    final rows = await db.query(
      _boardsTable,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );

    return rows.map((r) {
      final id = (r['id'] ?? '').toString();
      final data = Map<String, dynamic>.from(jsonDecode((r['data_json'] as String?) ?? '{}'));
      final raw = Map<String, dynamic>.from(jsonDecode((r['raw_json'] as String?) ?? '{}'));
      return {'id': id, 'data': data, 'raw': raw};
    }).toList();
  }

  Future<void> deleteBoard(String userId, String id) async {
    final db = await _database();
    await db.delete(
      _boardsTable,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  Future<void> cacheChatThreads(
    String userId,
    List<Map<String, dynamic>> rows,
  ) async {
    final db = await _database();
    final batch = db.batch();
    final now = DateTime.now().toIso8601String();
    for (final row in rows) {
      final id = (row['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final data = Map<String, dynamic>.from(row['data'] ?? const {});
      final raw = Map<String, dynamic>.from(row['raw'] ?? const {});
      final updatedAt =
          (raw[r'$updatedAt'] ?? data['updatedAt'] ?? now).toString();
      batch.insert(
        _chatThreadsTable,
        {
          'user_id': userId,
          'id': id,
          'title': (data['title'] ?? '').toString(),
          'last_message': (data['lastMessage'] ?? '').toString(),
          'module': (data['module'] ?? '').toString(),
          'data_json': jsonEncode(data),
          'raw_json': jsonEncode(raw),
          'updated_at': updatedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> loadChatThreads(
    String userId, {
    int limit = 50,
  }) async {
    final db = await _database();
    final rows = await db.query(
      _chatThreadsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
      limit: limit,
    );

    return rows.map((r) {
      final id = (r['id'] ?? '').toString();
      final data = Map<String, dynamic>.from(
        jsonDecode((r['data_json'] as String?) ?? '{}'),
      );
      final raw = Map<String, dynamic>.from(
        jsonDecode((r['raw_json'] as String?) ?? '{}'),
      );
      return {'id': id, 'data': data, 'raw': raw};
    }).toList();
  }

  Future<void> deleteChatThread(String userId, String id) async {
    final db = await _database();
    await db.delete(
      _chatThreadsTable,
      where: 'user_id = ? AND id = ?',
      whereArgs: [userId, id],
    );
  }

  Future<void> cacheUserProfile(
    String userId, {
    required Map<String, dynamic> data,
    required Map<String, dynamic> raw,
  }) async {
    final db = await _database();
    await db.insert(
      _profileTable,
      {
        'user_id': userId,
        'data_json': jsonEncode(data),
        'raw_json': jsonEncode(raw),
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> loadUserProfile(String userId) async {
    final db = await _database();
    final rows = await db.query(
      _profileTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final data = Map<String, dynamic>.from(
      jsonDecode((row['data_json'] as String?) ?? '{}'),
    );
    final raw = Map<String, dynamic>.from(
      jsonDecode((row['raw_json'] as String?) ?? '{}'),
    );
    return {'id': userId, 'data': data, 'raw': raw};
  }

  Future<void> deleteUserProfile(String userId) async {
    final db = await _database();
    await db.delete(
      _profileTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> addPendingOp({
    required String userId,
    required String entity,
    required String op,
    required String refId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await _database();
    await db.insert(_opsTable, {
      'user_id': userId,
      'entity': entity,
      'op': op,
      'ref_id': refId,
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<PendingLocalOp>> pendingOps(String userId) async {
    final db = await _database();
    final rows = await db.query(
      _opsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
    return rows
        .map(
          (r) => PendingLocalOp(
            id: (r['id'] as int?) ?? 0,
            entity: (r['entity'] as String?) ?? '',
            op: (r['op'] as String?) ?? '',
            refId: (r['ref_id'] as String?) ?? '',
            payload: Map<String, dynamic>.from(
              jsonDecode((r['payload_json'] as String?) ?? '{}'),
            ),
          ),
        )
        .toList();
  }

  Future<void> deletePendingOp(int id) async {
    final db = await _database();
    await db.delete(_opsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePendingOpPayload(int id, Map<String, dynamic> payload) async {
    final db = await _database();
    await db.update(
      _opsTable,
      {'payload_json': jsonEncode(payload)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePendingOpsByRef({
    required String userId,
    required String entity,
    required String refId,
    String? op,
  }) async {
    final db = await _database();
    final where = StringBuffer('user_id = ? AND entity = ? AND ref_id = ?');
    final args = <Object>[userId, entity, refId];
    if (op != null && op.isNotEmpty) {
      where.write(' AND op = ?');
      args.add(op);
    }
    await db.delete(
      _opsTable,
      where: where.toString(),
      whereArgs: args,
    );
  }

  Future<void> clearUserBackupData(String userId) async {
    final db = await _database();
    await db.delete(
      _wardrobeTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    await db.delete(
      _boardsTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
