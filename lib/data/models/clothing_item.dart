class ClothingItem {
  final String id;
  final String imagePath; // Local path or network URL
  final String category; // Tişört, Gömlek, Pantolon, Şort, Ceket, Mont, Ayakkabı, Aksesuar
  final String color;
  final String pattern; // Desen (Düz, Çizgili, Kareli, Baskılı vb.)
  final String fabricType; // Kumaş türü (Pamuk, Keten, Denim, Deri, Yün vb.)
  final String season; // İlkbahar, Yaz, Sonbahar, Kış, Mevsimsiz
  final String style; // Klasik, Casual, Smart Casual, Spor
  final int usageCount;
  final DateTime? lastWorn;

  ClothingItem({
    required this.id,
    required this.imagePath,
    required this.category,
    required this.color,
    required this.pattern,
    required this.fabricType,
    required this.season,
    required this.style,
    this.usageCount = 0,
    this.lastWorn,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'category': category,
      'color': color,
      'pattern': pattern,
      'fabricType': fabricType,
      'season': season,
      'style': style,
      'usageCount': usageCount,
      'lastWorn': lastWorn?.toIso8601String(),
    };
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] ?? '',
      imagePath: json['imagePath'] ?? '',
      category: json['category'] ?? 'Tişört',
      color: json['color'] ?? 'Siyah',
      pattern: json['pattern'] ?? 'Düz',
      fabricType: json['fabricType'] ?? 'Pamuk',
      season: json['season'] ?? 'Yaz',
      style: json['style'] ?? 'Casual',
      usageCount: json['usageCount'] ?? 0,
      lastWorn: json['lastWorn'] != null ? DateTime.parse(json['lastWorn']) : null,
    );
  }

  ClothingItem copyWith({
    String? id,
    String? imagePath,
    String? category,
    String? color,
    String? pattern,
    String? fabricType,
    String? season,
    String? style,
    int? usageCount,
    DateTime? lastWorn,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      color: color ?? this.color,
      pattern: pattern ?? this.pattern,
      fabricType: fabricType ?? this.fabricType,
      season: season ?? this.season,
      style: style ?? this.style,
      usageCount: usageCount ?? this.usageCount,
      lastWorn: lastWorn ?? this.lastWorn,
    );
  }
}
