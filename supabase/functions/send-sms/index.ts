// Dentigo — send-sms Auth Hook (docs/SUPABASE.md §10)
//
// Auth her telefon kodunda (giriş, kayıt, numara değiştirme) bu fonksiyonu
// çağırır ve kendisi Twilio'ya gitmez. Yalnızca Türkiye cep numaralarına kod
// gider; asıl kısıt budur, istemcideki normalizePhone doğrudan API çağrısını
// durdurmaz.
//
// Sırlar (supabase secrets set):
//   SEND_SMS_HOOK_SECRET      Auth hook sırrı (v1,whsec_…)
//   TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN
//   TWILIO_WHATSAPP_SENDER    +90… ya da Messaging Service SID (MG…)
//   TWILIO_CONTENT_SID        Onaylı OTP şablonu (HX…), kod {{1}} değişkenine gelir
// Deploy: supabase functions deploy send-sms --no-verify-jwt

import { Webhook } from 'npm:standardwebhooks@1';
import { turkishMobile } from './phone.ts';

const webhook = new Webhook(Deno.env.get('SEND_SMS_HOOK_SECRET')!.replace('v1,whsec_', ''));
const accountSid = Deno.env.get('TWILIO_ACCOUNT_SID')!;
const authToken = Deno.env.get('TWILIO_AUTH_TOKEN')!;
const sender = Deno.env.get('TWILIO_WHATSAPP_SENDER')!;
const contentSid = Deno.env.get('TWILIO_CONTENT_SID')!;

const json = (body: unknown) => new Response(JSON.stringify(body), { headers: { 'Content-Type': 'application/json' } });

// Auth hata gövdesini yalnızca 200'de okur, başka durumda her şey 500 olur.
// Hook hata kodu taşıyamaz: istemci mesaja bakar (error_messages.dart).
const fail = (message: string) => json({ error: { http_code: 400, message } });

async function sendWhatsApp(to: string, otp: string): Promise<boolean> {
  const body = new URLSearchParams({
    To: `whatsapp:${to}`,
    ContentSid: contentSid,
    ContentVariables: JSON.stringify({ 1: otp }),
  });
  if (sender.startsWith('MG')) body.set('MessagingServiceSid', sender);
  else body.set('From', `whatsapp:${sender}`);

  const response = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`, {
    method: 'POST',
    headers: { Authorization: `Basic ${btoa(`${accountSid}:${authToken}`)}` },
    body,
  });
  if (!response.ok) console.error('twilio', response.status, await response.text());
  return response.ok;
}

Deno.serve(async (req) => {
  const payload = await req.text();
  let sms: { otp: string; phone?: string };
  try {
    ({ sms } = webhook.verify(payload, Object.fromEntries(req.headers)) as { sms: typeof sms });
  } catch {
    return new Response('unauthorized', { status: 401 });
  }

  // user.phone'a düşme: numara değişiminde eski numaradır, kod yanlış yere gider.
  const to = turkishMobile(sms.phone);
  if (to == null) return fail('phone_not_allowed');

  try {
    return (await sendWhatsApp(to, sms.otp)) ? json({}) : fail('sms_send_failed');
  } catch (e) {
    console.error('twilio', e);
    return fail('sms_send_failed');
  }
});
