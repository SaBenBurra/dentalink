// node --test supabase/functions/send-sms/phone.test.ts
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { turkishMobile } from './phone.ts';

test('Türkiye cep numarası kabul edilir', () => {
  assert.equal(turkishMobile('905551234567'), '+905551234567');
  assert.equal(turkishMobile('+905551234567'), '+905551234567');
});

test('yabancı, sabit hat ve eksik numara reddedilir', () => {
  for (const phone of ['4915123456789', '15551234567', '902121234567', '90555123456', '9055512345678', '', undefined, null]) {
    assert.equal(turkishMobile(phone), null);
  }
});
