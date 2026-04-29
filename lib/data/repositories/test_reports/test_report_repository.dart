import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:mindheal/features/test_reports/models/test_report_model.dart';
import 'package:mindheal/utils/constants/enums.dart';
import 'package:mindheal/utils/exceptions/firebase_exceptions.dart';
import 'package:mindheal/utils/exceptions/format_exceptions.dart';

class TestReportRepository extends GetxController {
  static TestReportRepository get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _testReportsCollection => _firestore.collection('TestReports');

  Future<void> createTestReport(TestReportModel report) async {
    try {
      await _testReportsCollection.doc(report.id).set(report.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Failed to create test report.';
    }
  }

  Future<void> updateTestReport(TestReportModel report) async {
    try {
      await _testReportsCollection.doc(report.id).update(report.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } catch (e) {
      throw 'Failed to update test report.';
    }
  }

  Future<TestReportModel> getReportById(String reportId) async {
    try {
      final doc = await _testReportsCollection.doc(reportId).get();
      if (!doc.exists) throw 'Test report not found';
      return TestReportModel.fromDocument(doc);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch test report.';
    }
  }

  Future<List<TestReportModel>> getPatientReports(String patientId) async {
    try {
      final querySnapshot = await _testReportsCollection
          .where('patientId', isEqualTo: patientId)
          .orderBy('reportDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => TestReportModel.fromDocument(doc)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch patient test reports.';
    }
  }

  Future<List<TestReportModel>> getDoctorReports(String doctorId) async {
    try {
      final querySnapshot = await _testReportsCollection
          .where('doctorId', isEqualTo: doctorId)
          .orderBy('reportDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => TestReportModel.fromDocument(doc)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch doctor test reports.';
    }
  }

  Future<List<TestReportModel>> getReportsForPatientIds(List<String> patientIds) async {
    if (patientIds.isEmpty) return [];

    try {
      final List<TestReportModel> reports = [];
      const batchSize = 10;

      for (var index = 0; index < patientIds.length; index += batchSize) {
        final batchIds = patientIds.sublist(
          index,
          index + batchSize > patientIds.length ? patientIds.length : index + batchSize,
        );

        final querySnapshot = await _testReportsCollection
            .where('patientId', whereIn: batchIds)
            .orderBy('reportDate', descending: true)
            .get();

        reports.addAll(
          querySnapshot.docs.map((doc) => TestReportModel.fromDocument(doc)),
        );
      }

      reports.sort((a, b) => b.reportDate.compareTo(a.reportDate));
      return reports;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch caregiver test reports.';
    }
  }

  Future<List<TestReportModel>> getReportsByPatientAndType({
    required String patientId,
    required TestReportType reportType,
  }) async {
    try {
      final querySnapshot = await _testReportsCollection
          .where('patientId', isEqualTo: patientId)
          .where('reportType', isEqualTo: reportType.name)
          .orderBy('reportDate', descending: false)
          .get();

      return querySnapshot.docs.map((doc) => TestReportModel.fromDocument(doc)).toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to fetch filtered test reports.';
    }
  }

  Stream<List<TestReportModel>> streamPatientReports(String patientId) {
    return _testReportsCollection
        .where('patientId', isEqualTo: patientId)
        .orderBy('reportDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TestReportModel.fromDocument(doc)).toList());
  }

  Future<void> updateReportStatus(String reportId, TestReportStatus status) async {
    try {
      await _testReportsCollection.doc(reportId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to update test report status.';
    }
  }

  Future<String> uploadReportAttachment({
    required String filePath,
    required String reportId,
    String? fileName,
  }) async {
    try {
      final sanitizedFileName = fileName ?? filePath.split(Platform.pathSeparator).last;
      final ref = _storage.ref('test_reports/$reportId/$sanitizedFileName');
      await ref.putFile(File(filePath));
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw 'Failed to upload report attachment.';
    }
  }
}
