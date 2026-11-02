import 'enums.dart';

/// Vakanın bir tedavisi (migration 040). Kimliği etiketidir ([slug]): listedeki
/// tedavi ([listed]) de kullanıcının eklediği tedavi de bir etiket.
class CaseTreatment {
  final String slug;

  /// Etiketin adı ("kanal-tedavisi", "zirkonya-inley").
  final String name;
  final DentalBranch branch;

  /// Bu tedavinin seçildiği vaka sayısı; yalnızca tedavi listelerinde dolu.
  final int caseCount;

  const CaseTreatment({
    required this.slug,
    required this.name,
    required this.branch,
    this.caseCount = 0,
  });

  /// Listedeki tedavi: kodu etiketin slug'ı (033).
  factory CaseTreatment.listed(TreatmentType t) =>
      CaseTreatment(slug: t.dbValue, name: t.tag, branch: t.branch);

  /// Listedeki tedaviyse karşılığı; kullanıcının eklediyse null.
  TreatmentType? get listed => TreatmentType.tryFromDbValue(slug);

  /// `create_post`/`update_post` biçimi; listedekinin branşını sunucu bilir.
  Map<String, String> toPayload() => {
    'name': name,
    'slug': slug,
    if (listed == null) 'branch': branch.dbValue,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseTreatment && other.slug == slug && other.branch == branch;

  @override
  int get hashCode => Object.hash(slug, branch);
}
