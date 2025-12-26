class DetectedSound {
  final String name;           // e.g., "Car Horn"
  final String category;       // e.g., "Traffic"
  final double confidence;     // 0.0 to 1.0 (how sure AI is)
  final DateTime timestamp;    // When sound was detected
  final String priority;       // "critical", "important", "normal"

  DetectedSound({
    required this.name,
    required this.category,
    required this.confidence,
    required this.timestamp,
    required this.priority,
  });
}