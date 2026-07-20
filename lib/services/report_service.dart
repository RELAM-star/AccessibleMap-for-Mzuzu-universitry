// lib/services/report_service.dart

import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class ReportModel {
  final int? id;
  final String locationName;
  final String issueType;
  final String description;
  final String status;
  final String createdAt;

  ReportModel({
    this.id,
    required this.locationName,
    required this.issueType,
    required this.description,
    this.status = 'pending',
    required this.createdAt,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'],
      locationName: map['location_name'],
      issueType: map['issue_type'],
      description: map['description'],
      status: map['status'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'location_name': locationName,
      'issue_type': issueType,
      'description': description,
      'status': status,
      'created_at': createdAt,
    };
  }

  // For voice readout
  String toVoiceDescription() {
    return 'Report at $locationName. Issue: $issueType. Status: $status.';
  }
}

class ReportService {
  final DatabaseService _db = DatabaseService.instance;

  // Submit a new report
  Future<int> submitReport({
    required String locationName,
    required String issueType,
    required String description,
  }) async {
    final db = await _db.database;
    final report = ReportModel(
      locationName: locationName,
      issueType: issueType,
      description: description,
      status: 'pending',
      createdAt: DateTime.now().toIso8601String(),
    );
    return await db.insert('reports', report.toMap());
  }

  // Get all reports
  Future<List<ReportModel>> getAllReports() async {
    final db = await _db.database;
    final result = await db.query(
      'reports',
      orderBy: 'created_at DESC',
    );
    return result.map((map) => ReportModel.fromMap(map)).toList();
  }

  // Get pending reports only
  Future<List<ReportModel>> getPendingReports() async {
    final db = await _db.database;
    final result = await db.query(
      'reports',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => ReportModel.fromMap(map)).toList();
  }

  // Get reports for a specific location
  Future<List<ReportModel>> getReportsByLocation(String locationName) async {
    final db = await _db.database;
    final result = await db.query(
      'reports',
      where: 'location_name LIKE ?',
      whereArgs: ['%$locationName%'],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => ReportModel.fromMap(map)).toList();
  }

  // Mark report as resolved
  Future<int> resolveReport(int id) async {
    final db = await _db.database;
    return await db.update(
      'reports',
      {'status': 'resolved'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a report
  Future<int> deleteReport(int id) async {
    final db = await _db.database;
    return await db.delete(
      'reports',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Count pending reports
  Future<int> countPendingReports() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reports WHERE status = ?',
      ['pending'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}