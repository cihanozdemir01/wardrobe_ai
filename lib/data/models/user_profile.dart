class UserProfile {
  final String name;
  final int age;
  final String gender;
  final double height; // in cm
  final double weight; // in kg
  final String workStyle; // e.g., Ofis, Serbest, Hibrit, Öğrenci
  final String stylePreference; // e.g., Klasik, Casual, Smart Casual, Spor

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.workStyle,
    required this.stylePreference,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'workStyle': workStyle,
      'stylePreference': stylePreference,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      age: json['age'] ?? 25,
      gender: json['gender'] ?? 'Belirtilmedi',
      height: (json['height'] ?? 170.0).toDouble(),
      weight: (json['weight'] ?? 70.0).toDouble(),
      workStyle: json['workStyle'] ?? 'Serbest',
      stylePreference: json['stylePreference'] ?? 'Casual',
    );
  }

  UserProfile copyWith({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? workStyle,
    String? stylePreference,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      workStyle: workStyle ?? this.workStyle,
      stylePreference: stylePreference ?? this.stylePreference,
    );
  }
}
