import 'package:dentigo/data/models/support_model.dart';
import 'package:flutter_test/flutter_test.dart';

final _t0 = DateTime(2026, 11, 9, 10);

SupportThread _thread(
  SupportStatus status, {
  DateTime? userRead,
  DateTime? staffRead,
}) => SupportThread(
  id: 't',
  status: status,
  lastMessageAt: _t0,
  userReadAt: userRead,
  staffReadAt: staffRead,
);

SupportMessage _msg(bool fromStaff) => SupportMessage(
  id: fromStaff ? 's' : 'u',
  fromStaff: fromStaff,
  content: 'x',
  createdAt: _t0,
);

void main() {
  group('SupportThread.hasUnread', () {
    test('ekip cevabı görülmediyse okunmamış', () {
      expect(_thread(SupportStatus.answered).hasUnread, isTrue);
      expect(
        _thread(
          SupportStatus.answered,
          userRead: _t0.subtract(const Duration(minutes: 1)),
        ).hasUnread,
        isTrue,
      );
    });

    test('görüldüyse ya da ekip bekleniyorsa okunmamış değil', () {
      expect(_thread(SupportStatus.answered, userRead: _t0).hasUnread, isFalse);
      expect(_thread(SupportStatus.open).hasUnread, isFalse);
      expect(_thread(SupportStatus.resolved).hasUnread, isFalse);
    });
  });

  group('supportNoteOf', () {
    test('sohbet ya da mesaj yoksa not yok', () {
      expect(supportNoteOf(null, const []), isNull);
      expect(supportNoteOf(_thread(SupportStatus.open), const []), isNull);
    });

    test('son mesaj kullanıcınınsa: alındı, ekip okuyunca okudu', () {
      expect(
        supportNoteOf(_thread(SupportStatus.open), [_msg(false)]),
        SupportNote.received,
      );
      expect(
        supportNoteOf(_thread(SupportStatus.open, staffRead: _t0), [
          _msg(false),
        ]),
        SupportNote.seen,
      );
    });

    test('son mesaj ekibinse not yok, çözüldüyse kapanış notu', () {
      expect(
        supportNoteOf(_thread(SupportStatus.answered), [_msg(true)]),
        isNull,
      );
      expect(
        supportNoteOf(_thread(SupportStatus.resolved), [_msg(true)]),
        SupportNote.resolved,
      );
    });
  });

  test('personel adı join içinden gelir, kullanıcı mesajında yok', () {
    final staff = SupportMessage.fromJson({
      'id': '1',
      'from_staff': true,
      'content': 'Bakıyoruz',
      'created_at': '2026-11-09T10:00:00Z',
      'sender': {'full_name': 'Umut'},
    });
    final user = SupportMessage.fromJson({
      'id': '2',
      'from_staff': false,
      'content': 'Merhaba',
      'created_at': '2026-11-09T10:00:00Z',
      'sender': {'full_name': 'Ahmet'},
    });
    expect(staff.staffName, 'Umut');
    expect(user.staffName, isNull);
  });
}
