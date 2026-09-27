class WeightRecordModel {
  final String id;
  final double weight;
  final DateTime date;
  final String? note;

  WeightRecordModel({
    required this.id,
    required this.weight,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory WeightRecordModel.fromMap(String id, Map<String, dynamic> map) {
    return WeightRecordModel(
      id: id,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      note: map['note'],
    );
  }
}
