abstract interface class FaceRecognitionService {
  Future<FaceMatchResult> verifyFace({required String captureId});
}

abstract interface class LivenessDetectionService {
  Future<LivenessResult> verifyLiveness({required String captureId});
}

abstract interface class FaceEnrollmentService {
  Future<EnrollmentResult> enrollSamples({required List<String> sampleIds});
}

abstract interface class LocationVerificationService {
  Future<LocationVerificationResult> verifyAssignedLocation();
}

class FaceMatchResult {
  const FaceMatchResult({required this.verified, required this.score});
  final bool verified;
  final double score;
}

class LivenessResult {
  const LivenessResult({required this.verified, required this.score});
  final bool verified;
  final double score;
}

class EnrollmentResult {
  const EnrollmentResult({required this.saved, required this.qualityScore});
  final bool saved;
  final double qualityScore;
}

class LocationVerificationResult {
  const LocationVerificationResult({
    required this.verified,
    required this.site,
    required this.distanceMeters,
  });

  final bool verified;
  final String site;
  final int distanceMeters;
}

