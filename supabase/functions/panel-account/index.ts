// Dentigo — panel-account Edge Function (docs/ADMIN_PANEL.md)
//
// Admin panelinden personel hesabı açar ve şifresini değiştirir. service_role
// yalnızca burada; önce çağıranın staff.manage yetkisi kendi JWT'siyle sorulur.
// Yalnızca @panel.dentigo.invalid hesaplarına dokunur: uygulama kullanıcısının
// şifresini değiştirmek hesabını ele geçirmek olurdu.
//
//   { action: 'create', username, full_name, password, role } → { user_id }
//   { action: 'set_password', user_id, password }             → { ok: true }
// Hata: { error: '<kod>' } (panel src/lib/errors.ts'te Türkçeye çevirir).
//
// Deploy: supabase functions deploy panel-account --no-verify-jwt
// (JWT'yi fonksiyon kendisi doğrular: auth.getUser + has_permission.)

import { createClient } from 'npm:@supabase/supabase-js@2';
import { fullName, isPanelEmail, PANEL_DOMAIN, panelUsername, validPassword } from './input.ts';

const url = Deno.env.get('SUPABASE_URL')!;
const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
const admin = createClient(url, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

// Panel başka bir alan adında; yetki Authorization başlığıyla, origin'le değil.
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
  const { data: allowed, error: permError } = await caller.rpc('has_permission', { p_permission: 'staff.manage' });
  if (permError) return fail('unexpected', 500);
  if (!allowed) return fail('not allowed', 403);

  const body = await req.json().catch(() => ({}));
  if (!validPassword(body.password)) return fail('weak password');

  if (body.action === 'create') {
    const username = panelUsername(body.username);
    const name = fullName(body.full_name);
    if (!username) return fail('invalid username');
    if (!name || typeof body.role !== 'string') return fail('invalid value');

    const { data: created, error } = await admin.auth.admin.createUser({
      email: `${username}${PANEL_DOMAIN}`,
      password: body.password,
      email_confirm: true,
    });
    if (error) return fail(error.code === 'email_exists' ? 'username taken' : 'unexpected', error.code === 'email_exists' ? 409 : 500);
    const id = created.user.id;

    // users.username uygulamayla ortak ve UNIQUE; önek çakışmayı önler. onboarding_completed false: aramada görünmez (054).
    const { error: rowError } = await admin.from('users').insert({ id, full_name: name, username: `panel_${username}` });
    // Çağıranın JWT'siyle: yetki RPC'de bir kez daha kontrol edilir ve staff_actions'a yazılır.
    const { error: roleError } = rowError ? { error: null } : await caller.rpc('set_staff_role', { p_user_id: id, p_role: body.role });
    if (rowError || roleError) {
      await admin.auth.admin.deleteUser(id); // users ve staff satırları cascade ile gider
      if (rowError?.code === '23505') return fail('username taken', 409);
      if (roleError?.code === '23503') return fail('role not found');
      return fail('unexpected', 500);
    }
    return json({ user_id: id });
  }

  if (body.action === 'set_password') {
    if (typeof body.user_id !== 'string') return fail('invalid value');
    const { data: target, error } = await admin.auth.admin.getUserById(body.user_id);
    if (error || !target.user) return fail('not found', 404);
    if (!isPanelEmail(target.user.email)) return fail('not a panel account', 403);

    const { error: updateError } = await admin.auth.admin.updateUserById(body.user_id, { password: body.password });
    if (updateError) return fail('unexpected', 500);
    await admin.from('staff_actions').insert({
      actor_id: me.user.id, action: 'staff.set_password', target_type: 'user', target_id: body.user_id,
    });
    return json({ ok: true });
  }

  return fail('invalid value');
});
