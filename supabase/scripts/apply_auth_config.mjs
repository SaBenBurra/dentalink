// Auth ayarlarını Management API ile uygular (docs/SUPABASE.md §10).
// node --env-file=supabase/.env.local supabase/scripts/apply_auth_config.mjs

import { readFileSync } from 'node:fs';

const env = process.env;
const ref = readFileSync('supabase/.temp/project-ref', 'utf8').trim();
const url = `https://api.supabase.com/v1/projects/${ref}/config/auth`;
const headers = {
  Authorization: `Bearer ${env.SUPABASE_ACCESS_TOKEN}`,
  'Content-Type': 'application/json',
};

const subject = 'Dentigo doğrulama kodun: {{ .Token }}';
const template = `<h2>Dentigo</h2>
<p>Doğrulama kodun / Your verification code:</p>
<p style="font-size:28px;font-weight:700;letter-spacing:4px">{{ .Token }}</p>
<p>Kod 10 dakika geçerlidir. Bu isteği sen yapmadıysan bu e-postayı yok say.<br>
The code is valid for 10 minutes. If you didn't request it, ignore this email.</p>`;

const config = {
  external_email_enabled: true,
  external_phone_enabled: true,
  mailer_otp_length: 6,
  mailer_otp_exp: 600,
  mailer_secure_email_change_enabled: false,
  mailer_subjects_magic_link: subject,
  mailer_subjects_confirmation: subject,
  mailer_subjects_email_change: subject,
  mailer_templates_magic_link_content: template,
  mailer_templates_confirmation_content: template,
  mailer_templates_email_change_content: template,
  sms_otp_length: 6,
  sms_otp_exp: 600,
  sms_max_frequency: 60,
  sms_template: 'Dentigo doğrulama kodun: {{ .Code }}',
};

if (env.TWILIO_ACCOUNT_SID) {
  Object.assign(config, {
    sms_provider: 'twilio',
    sms_twilio_account_sid: env.TWILIO_ACCOUNT_SID,
    sms_twilio_auth_token: env.TWILIO_AUTH_TOKEN,
    sms_twilio_message_service_sid: env.TWILIO_WHATSAPP_SENDER,
    sms_twilio_content_sid: env.TWILIO_CONTENT_SID,
  });
}

// Twilio'ya artık send-sms gider. Önce fonksiyonu deploy et (SUPABASE.md §10).
// sms_autoconfirm açıkken kod gönderilmez, hook da çalışmaz.
if (env.SEND_SMS_HOOK_SECRET) {
  Object.assign(config, {
    sms_autoconfirm: false,
    hook_send_sms_enabled: true,
    hook_send_sms_uri: `https://${ref}.supabase.co/functions/v1/send-sms`,
    hook_send_sms_secrets: env.SEND_SMS_HOOK_SECRET,
  });
}

if (env.SENDGRID_API_KEY) {
  Object.assign(config, {
    smtp_host: 'smtp.sendgrid.net',
    smtp_port: '587',
    smtp_user: 'apikey',
    smtp_pass: env.SENDGRID_API_KEY,
    smtp_admin_email: env.SMTP_SENDER,
    smtp_sender_name: 'Dentigo',
    mailer_notifications_email_changed_enabled: true,
    mailer_notifications_phone_changed_enabled: true,
  });
}

const response = await fetch(url, { method: 'PATCH', headers, body: JSON.stringify(config) });
if (!response.ok) {
  console.error(response.status, await response.text());
  process.exit(1);
}
const saved = await response.json();
for (const key of ['external_email_enabled', 'mailer_otp_length', 'sms_otp_exp', 'sms_provider', 'hook_send_sms_enabled', 'smtp_host']) {
  console.log(key, '=', saved[key]);
}
