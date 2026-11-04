import 'package:dentigo/data/models/case_treatment.dart';
import 'package:dentigo/data/models/enums.dart';
import 'package:dentigo/data/models/post_model.dart';
import 'package:dentigo/data/models/tag_model.dart';
import 'package:dentigo/data/models/user_model.dart';
import 'package:dentigo/shared/extensions/treatment_type_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const custom = CaseTreatment(
    slug: 'zirkonya-inley',
    name: 'zirkonya-inley',
    branch: DentalBranch.protetikDisTedavisi,
  );

  test('listedeki tedavinin branşı sunucuda; kullanıcınınki gönderilir', () {
    final listed = CaseTreatment.listed(TreatmentType.yenidenKanalTedavisi);
    expect(listed.listed, TreatmentType.yenidenKanalTedavisi);
    expect(listed.branch, DentalBranch.endodonti);
    expect(listed.toPayload(), {
      'name': 'yeniden-kanal-tedavisi',
      'slug': 'yeniden-kanal-tedavisi',
    });
    expect(custom.listed, isNull);
    expect(custom.toPayload()['branch'], 'protez_uzmani');
  });

  test('serbest etiketler tedavi etiketlerini içermez', () {
    final post = CasePostModel(
      id: 'p',
      userId: 'u',
      title: 't',
      content: 'c',
      treatments: [custom],
      tags: const [
        TagModel(id: '1', name: 'zirkonya-inley', slug: 'zirkonya-inley'),
        TagModel(id: '2', name: 'mta', slug: 'mta'),
      ],
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
      author: UserModel(
        id: 'u',
        username: 'u',
        fullName: 'U',
        title: UserTitle.disHekimi,
        createdAt: DateTime(2024),
      ),
    );
    expect([for (final t in post.freeTags) t.slug], ['mta']);
  });

  test('kullanıcı tedavisinin adı cümle biçiminde', () {
    expect(humanizeTag('zirkonya-inley'), 'Zirkonya inley');
    expect(humanizeTag('implant-ustu'), 'İmplant ustu');
    expect(humanizeTag('ısı'), 'Isı');
    expect(humanizeTag(''), '');
  });
}
