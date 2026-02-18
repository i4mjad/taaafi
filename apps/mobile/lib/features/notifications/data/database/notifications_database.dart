import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:reboot_app_3/features/notifications/data/models/app_notification.dart';

class NotificationsDatabase {
  static final NotificationsDatabase instance = NotificationsDatabase._init();
  static Database? _database;

  NotificationsDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notifications.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        isRead INTEGER NOT NULL,
        reportId TEXT NOT NULL,
        reportStatus TEXT NOT NULL,
        additionalData TEXT
      )
    ''');
  }

  Future<AppNotification> create(AppNotification notification) async {
    final db = await instance.database;

    await db.insert('notifications', {
      'id': notification.id,
      'title': notification.title,
      'message': notification.message,
      'timestamp': notification.timestamp.millisecondsSinceEpoch,
      'isRead': notification.isRead ? 1 : 0,
      'reportId': notification.reportId,
      'reportStatus': notification.reportStatus,
      'additionalData': notification.additionalData?.toString(),
    });

    return notification;
  }

  Future<AppNotification?> readNotification(String id) async {
    final db = await instance.database;

    final maps = await db.query(
      'notifications',
      columns: [
        'id',
        'title',
        'message',
        'timestamp',
        'isRead',
        'reportId',
        'reportStatus',
        'additionalData'
      ],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _mapToNotification(maps.first);
    } else {
      return null;
    }
  }

  Future<List<AppNotification>> readAllNotifications() async {
    final db = await instance.database;

    final result = await db.query(
      'notifications',
      orderBy: 'timestamp DESC',
    );

    return result.map((json) => _mapToNotification(json)).toList();
  }

  Future<int> update(AppNotification notification) async {
    final db = await instance.database;

    return db.update(
      'notifications',
      {
        'title': notification.title,
        'message': notification.message,
        'timestamp': notification.timestamp.millisecondsSinceEpoch,
        'isRead': notification.isRead ? 1 : 0,
        'reportId': notification.reportId,
        'reportStatus': notification.reportStatus,
        'additionalData': notification.additionalData?.toString(),
      },
      where: 'id = ?',
      whereArgs: [notification.id],
    );
  }

  Future<int> markAsRead(String id) async {
    final db = await instance.database;

    return db.update(
      'notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(String id) async {
    final db = await instance.database;

    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete('notifications');
  }

  Future<int> getUnreadCount() async {
    final db = await instance.database;
    final result = await db
        .rawQuery('SELECT COUNT(*) FROM notifications WHERE isRead = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  AppNotification _mapToNotification(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isRead: (map['isRead'] as int) == 1,
      reportId: map['reportId'] as String,
      reportStatus: map['reportStatus'] as String,
      additionalData: map['additionalData'] != null
          ? {
              'raw': map['additionalData']
            } // Store as simple map since we can't parse reliably
          : null,
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
