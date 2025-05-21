enum AnalysisType {
  title,
  description,
  image,
  price,
  category
}

class AnalysisResult {
  final AnalysisType type;
  final bool isCompliant;
  final double confidenceScore;
  final String details;
  final Map<String, dynamic> additionalData;

  AnalysisResult({
    required this.type,
    required this.isCompliant,
    required this.confidenceScore,
    this.details = '',
    this.additionalData = const {},
  });

  factory AnalysisResult.fromMap(Map<String, dynamic> map) {
    return AnalysisResult(
      type: AnalysisType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type'],
        orElse: () => AnalysisType.description,
      ),
      isCompliant: map['isCompliant'] ?? false,
      confidenceScore: map['confidenceScore']?.toDouble() ?? 0.0,
      details: map['details'] ?? '',
      additionalData: Map<String, dynamic>.from(map['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'isCompliant': isCompliant,
      'confidenceScore': confidenceScore,
      'details': details,
      'additionalData': additionalData,
    };
  }
} 