/// Etiket modeli — Supabase `tags` tablosuyla eşleşir.
class TagModel {
  final String id;
  final String name;
  final String slug;
  final int usageCount;

  const TagModel({
    required this.id,
    required this.name,
    required this.slug,
    this.usageCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TagModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
