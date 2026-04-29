/* --
      LIST OF Enums
      They cannot be created inside a class.
-- */

enum AppRole { admin, patient , doctor , caregiver }

enum VerificationStatus { pending, approved, rejected, unknown, submitted, underReview }

// Prescription status enum
enum PrescriptionStatus {
  active,
  completed,
  expired,
  cancelled,
  pendingReview,
}

enum TestReportType {
  cbc,
  bloodGlucose,
  lipidProfile,
  thyroid,
  liverFunction,
}

enum TestReportStatus {
  draft,
  finalReport,
}

enum TestMetricFlag {
  low,
  normal,
  high,
  unknown,
}
