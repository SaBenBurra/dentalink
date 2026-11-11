// node --test supabase/functions/panel-account/input.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { fullName, isPanelEmail, panelUsername, validPassword } from './input.ts';

test('kullanıcı adı küçültülür, geçersizi reddedilir', () => {
  assert.equal(panelUsername('  Ahmet.Y '), 'ahmet.y');
  for (const v of ['ab', 'a'.repeat(31), 'ah met', 'ahmet@x', 'çağrı', '', null, 5]) {
    assert.equal(panelUsername(v), null);
  }
});

test('şifre 12–72 karakter', () => {
  assert.equal(validPassword('a'.repeat(12)), true);
  assert.equal(validPassword('a'.repeat(11)), false);
  assert.equal(validPassword('a'.repeat(73)), false);
  assert.equal(validPassword(undefined), false);
});

test('yalnızca panel alan adı panel hesabıdır', () => {
  assert.equal(isPanelEmail('ahmet@panel.dentigo.invalid'), true);
  assert.equal(isPanelEmail('ahmet@gmail.com'), false);
  assert.equal(isPanelEmail('x@panel.dentigo.invalid.evil.com'), false);
  assert.equal(isPanelEmail(null), false);
});

test('ad soyad boşlukları sadeleşir', () => {
  assert.equal(fullName('  Ayşe   Kaya '), 'Ayşe Kaya');
  assert.equal(fullName('A'), null);
});
