import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resume_analyzer/domain/models/models.dart';

/// Service that persists resume analysis history in Firestore.
///
/// Collection structure:
///   users/{uid}/analyses/{analysisId}
///
/// Each document stores the full [ResumeAnalysis] as JSON so the
/// dashboard can reload it after logout → login.
class HistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Reference to the analyses sub-collection for a specific user.
  CollectionReference<Map<String, dynamic>> _col(String uid) {
    return _db.collection('users').doc(uid).collection('analyses');
  }

  /// Save a completed analysis for [uid].
  Future<void> save(String uid, ResumeAnalysis analysis) async {
    await _col(uid).doc(analysis.id).set(analysis.toJson());
  }

  /// Load all analyses for [uid], newest first.
  Future<List<ResumeAnalysis>> loadAll(String uid) async {
    final snapshot = await _col(uid)
        .orderBy('analyzed_at', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return ResumeAnalysis.fromJson(
        data,
        id: doc.id,
        fileName: data['file_name'] as String? ?? '',
        jobDescription: data['job_description'] as String?,
      );
    }).toList();
  }

  /// Delete a specific analysis for [uid].
  Future<void> delete(String uid, String analysisId) async {
    await _col(uid).doc(analysisId).delete();
  }

  /// Delete all analyses for [uid] (clear history).
  Future<void> deleteAll(String uid) async {
    final snapshot = await _col(uid).get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
