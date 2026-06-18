import 'clothing_item.dart';

class Combination {
  final String id;
  final List<ClothingItem> items;
  final int harmonyScore; // 0-100 Uyum Skoru
  final String seasonSuitability; // e.g., Çok Uygun, Orta Uygun
  final String formalityLevel; // e.g., Resmi, Smart Casual, Spor
  final String type; // İş Kombini, Günlük Kombin, Akşam Kombini, Hafta Sonu Kombini
  final String description; // Description of why they match

  Combination({
    required this.id,
    required this.items,
    required this.harmonyScore,
    required this.seasonSuitability,
    required this.formalityLevel,
    required this.type,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((i) => i.toJson()).toList(),
      'harmonyScore': harmonyScore,
      'seasonSuitability': seasonSuitability,
      'formalityLevel': formalityLevel,
      'type': type,
      'description': description,
    };
  }

  factory Combination.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<ClothingItem> parsedItems = itemsList.map((i) => ClothingItem.fromJson(i)).toList();

    return Combination(
      id: json['id'] ?? '',
      items: parsedItems,
      harmonyScore: json['harmonyScore'] ?? 80,
      seasonSuitability: json['seasonSuitability'] ?? 'Uyumlu',
      formalityLevel: json['formalityLevel'] ?? 'Casual',
      type: json['type'] ?? 'Günlük Kombin',
      description: json['description'] ?? '',
    );
  }
}
