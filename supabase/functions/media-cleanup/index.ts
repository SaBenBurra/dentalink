// Dentigo — media-cleanup Edge Function (docs/ADMIN_PANEL.md madde 12)
//
// Bir bucket'taki sahipsiz dosyaları siler. Liste admin_orphan_media (064)
// çağıranın JWT'siyle alınır: yetki (staff.manage) orada kontrol edilir ve her
// 100'lük grup silinmeden hemen önce yeniden listelenir, arada bağlanan dosya
// silinmez. Silme Storage API ile (service_role); adet ve boyut loglanır.
//
//   { bucket: 'post-images' | 'post-videos' | 'avatars' | 'verification-docs' } → { count, bytes, done }
// done false: süre sınırı yüzünden durdu, tekrar çağrılabilir.
// Hata: { error: '<kod>' } (panel src/lib/errors.ts'te Türkçeye çevirir).
//
// Deploy: supabase functions deploy media-cleanup --no-verify-jwt
// (JWT'yi RPC doğrular.)

import { createClient } from 'npm:@supabase/supabase-js@2';

const url = Deno.env.get('SUPABASE_URL')!;
const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

const buckets = ['post-images', 'post-videos', 'avatars', 'verification-docs'];
// Edge Function süre sınırının (150 sn) altında kalsın diye.
const maxBatches = 20;

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, 'Content-Type': 'application/json' } });
const fail = (error: string, status = 400) => json({ error }, status);

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response(null, { headers: cors });
  if (req.method !== 'POST') return fail('method not allowed', 405);

  const caller = createClient(url, anonKey, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
  });
  const { data: me } = await caller.auth.getUser();
  if (!me.user) return fail('not allowed', 401);

  const body = await req.json().catch(() => ({}));
  if (!buckets.includes(body.bucket)) return fail('invalid value');

  let count = 0, bytes = 0, done = false, error: string | undefined;
  for (let i = 0; i < maxBatches; i++) {
    const { data: rows, error: listError } = await caller.rpc('admin_orphan_media', { p_bucket: body.bucket, p_limit: 100 });
    if (listError) {
      error = listError.code === '42501' ? 'not allowed' : 'unexpected';
      break;
    }
    if (!rows.length) {
      done = true;
      break;
    }
    const { data: removed, error: removeError } = await admin.storage.from(body.bucket).remove(rows.map((r) => r.name));
    // Hiçbiri silinmediyse liste küçülmez; döngü boşa dönmesin.
    if (removeError || !removed?.length) {
      error = 'unexpected';
      break;
    }
    const gone = new Set(removed.map((o) => o.name));
    count += gone.size;
    bytes += rows.filter((r) => gone.has(r.name)).reduce((s, r) => s + Number(r.size), 0);
  }

  // Kısmen silinmişse de loglanır.
  if (count > 0) {
    await admin.from('staff_actions').insert({
      actor_id: me.user.id, action: 'media.cleanup', target_type: 'bucket', target_id: body.bucket,
      detail: { count, bytes, done },
    });
  }
  if (error) return fail(error, error === 'not allowed' ? 403 : 500);
  return json({ count, bytes, done });
});
