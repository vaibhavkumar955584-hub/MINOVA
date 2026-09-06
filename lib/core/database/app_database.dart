import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('minesafe_compliance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb ||
        filePath == inMemoryDatabasePath ||
        Platform.environment.containsKey('FLUTTER_TEST')) {
      path = inMemoryDatabasePath;
    } else {
      try {
        final dbPath = await getApplicationDocumentsDirectory();
        path = join(dbPath.path, filePath);
      } catch (_) {
        path = inMemoryDatabasePath;
      }
    }

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Users Table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        employee_id TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL,
        designation TEXT NOT NULL,
        assigned_mine_id TEXT NOT NULL,
        assigned_mine_name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        preferred_language TEXT DEFAULT 'en',
        manager_id TEXT
      )
    ''');

    // 2. Mines Table
    await db.execute('''
      CREATE TABLE mines (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        state TEXT NOT NULL
      )
    ''');

    // 3. Inspections Table
    await db.execute('''
      CREATE TABLE inspections (
        client_uuid TEXT PRIMARY KEY,
        server_id TEXT,
        mine_id TEXT NOT NULL,
        mine_name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_designation TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        submitted_at TEXT,
        updated_at TEXT NOT NULL,
        version INTEGER DEFAULT 1,
        latitude REAL,
        longitude REAL,
        accuracy REAL,
        location_source TEXT DEFAULT 'manual',
        zone_id TEXT,
        zone_name TEXT,
        checklist_json TEXT NOT NULL,
        global_evidence_json TEXT,
        signature_base64 TEXT,
        signature_hash TEXT,
        signed_at TEXT,
        integrity_hash TEXT,
        sync_error TEXT
      )
    ''');

    // 4. Incidents Table
    await db.execute('''
      CREATE TABLE incidents (
        client_uuid TEXT PRIMARY KEY,
        server_id TEXT,
        mine_id TEXT NOT NULL,
        mine_name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        user_designation TEXT NOT NULL,
        type TEXT NOT NULL,
        severity TEXT NOT NULL,
        people_affected INTEGER DEFAULT 0,
        affected_person_details TEXT,
        description TEXT NOT NULL,
        immediate_action_taken TEXT NOT NULL,
        medical_attention_required INTEGER DEFAULT 0,
        equipment_involved TEXT,
        notify_authority_immediately INTEGER DEFAULT 1,
        authority_alert_status TEXT DEFAULT 'queued',
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        submitted_at TEXT,
        updated_at TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        accuracy REAL,
        location_source TEXT DEFAULT 'manual',
        zone_id TEXT,
        zone_name TEXT,
        evidence_json TEXT,
        signature_base64 TEXT,
        signature_hash TEXT,
        signed_at TEXT,
        integrity_hash TEXT,
        sync_error TEXT
      )
    ''');

    // 5. Attendances Table
    await db.execute('''
      CREATE TABLE attendances (
        client_uuid TEXT PRIMARY KEY,
        server_id TEXT,
        mine_id TEXT NOT NULL,
        mine_name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        shift_name TEXT NOT NULL,
        muster_location TEXT NOT NULL,
        expected_headcount INTEGER DEFAULT 0,
        actual_headcount INTEGER DEFAULT 0,
        entries_json TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        submitted_at TEXT,
        updated_at TEXT NOT NULL,
        signature_base64 TEXT,
        signature_hash TEXT,
        integrity_hash TEXT,
        sync_error TEXT
      )
    ''');

    // 6. Observations Table
    await db.execute('''
      CREATE TABLE observations (
        client_uuid TEXT PRIMARY KEY,
        server_id TEXT,
        mine_id TEXT NOT NULL,
        mine_name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        entry_type TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        voice_note_path TEXT,
        voice_transcription TEXT,
        ch4_percent REAL,
        co_ppm INTEGER,
        o2_percent REAL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        submitted_at TEXT,
        updated_at TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        accuracy REAL,
        location_source TEXT DEFAULT 'manual',
        zone_id TEXT,
        zone_name TEXT,
        evidence_json TEXT,
        signature_base64 TEXT,
        signature_hash TEXT,
        integrity_hash TEXT,
        sync_error TEXT
      )
    ''');

    // 7. Documents Table
    await db.execute('''
      CREATE TABLE documents (
        client_uuid TEXT PRIMARY KEY,
        server_id TEXT,
        mine_id TEXT NOT NULL,
        mine_name TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        document_number TEXT,
        associated_contractor TEXT,
        issue_date TEXT,
        expiry_date TEXT,
        remarks TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        submitted_at TEXT,
        updated_at TEXT NOT NULL,
        files_json TEXT NOT NULL,
        integrity_hash TEXT,
        sync_error TEXT
      )
    ''');

    // 8. Evidence Table
    await db.execute('''
      CREATE TABLE evidence (
        id TEXT PRIMARY KEY,
        evidence_id TEXT UNIQUE,
        report_client_uuid TEXT NOT NULL,
        report_id TEXT,
        local_file_path TEXT NOT NULL,
        local_path TEXT,
        file_type TEXT NOT NULL,
        media_type TEXT,
        file_size INTEGER NOT NULL,
        sha256_hash TEXT NOT NULL,
        sha256 TEXT,
        captured_at TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        location_source TEXT,
        zone_name TEXT,
        caption TEXT,
        file_name TEXT,
        mime_type TEXT,
        storage_path TEXT,
        download_url TEXT,
        secure_url TEXT,
        storage_provider TEXT,
        width INTEGER,
        height INTEGER,
        duration INTEGER,
        upload_status TEXT DEFAULT 'pending',
        upload_attempts INTEGER DEFAULT 0,
        last_upload_error TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 9. Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        client_uuid TEXT NOT NULL UNIQUE,
        record_type TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        max_retries INTEGER DEFAULT 5,
        state TEXT DEFAULT 'pending',
        queued_at TEXT NOT NULL,
        last_attempt_at TEXT,
        next_retry_at TEXT,
        error_message TEXT,
        error_stage TEXT,
        error_code TEXT,
        is_retryable INTEGER DEFAULT 1
      )
    ''');

    // 10. Correction Requests Table
    await db.execute('''
      CREATE TABLE correction_requests (
        id TEXT PRIMARY KEY,
        record_client_uuid TEXT NOT NULL,
        record_type TEXT NOT NULL,
        requested_by_user_id TEXT NOT NULL,
        requested_by_user_name TEXT NOT NULL,
        reason TEXT NOT NULL,
        requested_changes_json TEXT NOT NULL,
        status TEXT DEFAULT 'pendingReview',
        requested_at TEXT NOT NULL,
        reviewed_at TEXT,
        reviewed_by_user_id TEXT,
        reviewer_comments TEXT
      )
    ''');

    // 11. Audit Events Table
    await db.execute('''
      CREATE TABLE audit_events (
        id TEXT PRIMARY KEY,
        record_client_uuid TEXT NOT NULL,
        event_type TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_role TEXT NOT NULL,
        description TEXT NOT NULL,
        previous_state_json TEXT,
        new_state_json TEXT,
        integrity_hash TEXT,
        timestamp TEXT NOT NULL
      )
    ''');

    // Create Indexes
    await db.execute(
      'CREATE INDEX idx_inspections_status ON inspections(status)',
    );
    await db.execute('CREATE INDEX idx_incidents_status ON incidents(status)');
    await db.execute(
      'CREATE INDEX idx_attendances_status ON attendances(status)',
    );
    await db.execute(
      'CREATE INDEX idx_observations_status ON observations(status)',
    );
    await db.execute('CREATE INDEX idx_documents_status ON documents(status)');
    await db.execute('CREATE INDEX idx_sync_queue_state ON sync_queue(state)');
    await db.execute(
      'CREATE INDEX idx_audit_record ON audit_events(record_client_uuid)',
    );
    await _createEvidenceIndexes(db);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE evidence ADD COLUMN file_name TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN mime_type TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN storage_path TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN download_url TEXT');
      await db.execute(
        "ALTER TABLE evidence ADD COLUMN upload_status TEXT DEFAULT 'pending'",
      );
      await db.execute(
        'ALTER TABLE evidence ADD COLUMN upload_attempts INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE evidence ADD COLUMN last_upload_error TEXT',
      );
      await db.execute(
        'UPDATE evidence SET file_name = local_file_path WHERE file_name IS NULL',
      );
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE users ADD COLUMN manager_id TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE evidence ADD COLUMN evidence_id TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN report_id TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN local_path TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN media_type TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN sha256 TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN storage_provider TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN secure_url TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN width INTEGER');
      await db.execute('ALTER TABLE evidence ADD COLUMN height INTEGER');
      await db.execute('ALTER TABLE evidence ADD COLUMN duration INTEGER');
      await db.execute('ALTER TABLE evidence ADD COLUMN created_at TEXT');
      await db.execute('ALTER TABLE evidence ADD COLUMN updated_at TEXT');
      await db.execute(
        'UPDATE evidence SET evidence_id = id, report_id = report_client_uuid, local_path = local_file_path, media_type = file_type, sha256 = sha256_hash, secure_url = download_url, storage_provider = \'cloudinary\', created_at = captured_at, updated_at = captured_at WHERE evidence_id IS NULL',
      );
      await _createEvidenceIndexes(db);
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE documents ADD COLUMN issue_date TEXT');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('ALTER TABLE sync_queue ADD COLUMN error_stage TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE sync_queue ADD COLUMN error_code TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE sync_queue ADD COLUMN is_retryable INTEGER DEFAULT 1');
      } catch (_) {}
    }
  }

  Future<void> _createEvidenceIndexes(Database db) async {
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_evidence_evidence_id ON evidence(evidence_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_evidence_report_id ON evidence(report_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_evidence_upload_status ON evidence(upload_status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_evidence_sha256 ON evidence(sha256)',
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
