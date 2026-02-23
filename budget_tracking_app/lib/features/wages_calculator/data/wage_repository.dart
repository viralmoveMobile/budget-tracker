import 'package:budget_tracking_app/features/expenses/data/local/database_helper.dart';
import '../domain/wage_models.dart';

class WageRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final String userId;
  final int profileType;

  WageRepository(this.userId, {this.profileType = 0});

  // Jobs
  Future<List<WageJob>> getJobs() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'wage_jobs',
      where: 'userId = ? AND profileType = ?',
      whereArgs: [userId, profileType],
    );
    return result.map((json) => WageJob.fromMap(json)).toList();
  }

  Future<void> addJob(WageJob job) async {
    final db = await _dbHelper.database;
    await db.insert('wage_jobs',
        job.copyWith(userId: userId, profileType: profileType).toMap());
  }

  Future<void> updateJob(WageJob job) async {
    final db = await _dbHelper.database;
    await db.update(
      'wage_jobs',
      job.copyWith(userId: userId, profileType: profileType).toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [job.id, userId],
    );
  }

  Future<void> deleteJob(String id) async {
    final db = await _dbHelper.database;
    await db.delete('wage_jobs',
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }

  // Work Entries
  Future<List<WorkEntry>> getEntries(String jobId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'work_entries',
      where: 'jobId = ? AND userId = ?',
      whereArgs: [jobId, userId],
      orderBy: 'date DESC',
    );
    return result.map((json) => WorkEntry.fromMap(json)).toList();
  }

  Future<void> addEntry(WorkEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert('work_entries', entry.copyWith(userId: userId).toMap());
  }

  Future<void> updateEntry(WorkEntry entry) async {
    final db = await _dbHelper.database;
    await db.update(
      'work_entries',
      entry.copyWith(userId: userId).toMap(),
      where: 'id = ? AND userId = ?',
      whereArgs: [entry.id, userId],
    );
  }

  Future<void> deleteEntry(String id) async {
    final db = await _dbHelper.database;
    await db.delete('work_entries',
        where: 'id = ? AND userId = ?', whereArgs: [id, userId]);
  }
}
