/// Rozet modeli — Supabase `badges` + `user_badges` tablosuyla eşleşir.
class BadgeModel {
  final String id;
  final String name;
  final String description;

  /// Material Icons kod noktası veya ismi (ör. 'star', 'verified', 'emoji_events')
  final String iconName;
  final DateTime earnedAt;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['icon_url'] as String, // DB'deki icon_url'i iconName'e mapliyoruz
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }


  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is BadgeModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
