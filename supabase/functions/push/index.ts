// DentLink — push Edge Function (REL-6)
//
// Migration 027'deki trigger, notifications/messages INSERT'inde
// { kind: 'notification' | 'message', id } gönderir. Fonksiyon satırı okur,
// alıcının cihazlarına FCM HTTP v1 ile push atar, geçersiz token'ları siler.
//
// Sırlar (supabase secrets set):
//   PUSH_WEBHOOK_SECRET       Vault'taki push_webhook_
// secret ile aynı
//   FIREBASE_SERVICE_ACCOUNT  Firebase service account JSON'u (tek satır)
// Deploy: supabase functions deploy push --no-verify-jwt

import { createClient } from 'npm:@supabase/supabase-js@2';
import { importPKCS8, SignJWT } from 'npm:jose@5';

const db = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);
const sa = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT') ?? '{}');

// shortcut: metinler yalnızca TR (users tablosunda dil yok); EN gerekirse users.locale ekle.
// Başlık: aktörün adı. Metin: eylem + alıntı (post başlığı ya da yorum).
// comment_id: yorum/yanıtta yeni yorum, beğenide beğenilen yorum, en iyi cevapta cevap.
type Row = { type: string; comment_id: string | null; post: { title: string } | null; comment: { content: string } | null };
const templates: Record<string, (r: Row) => [string, string | undefined]> = {
  like: (r) => (r.comment_id ? ['yorumunu beğendi', r.comment?.content] : ['gönderini beğendi', r.post?.title]),
  comment: (r) => ['yorum yaptı', r.comment?.content],
  reply: (r) => ['yorumuna yanıt verdi', r.comment?.content],
  follow: () => ['seni takip etmeye başladı', undefined],
  best_answer: (r) => ['cevabını en iyi cevap seçti', r.post?.title],
};

/** Tek satıra indirir, uzunsa kırpar. */
function snippet(text: string, max: number): string {
  const s = text.replace(/\s+/g, ' ').trim();
  return s.length > max ? `${s.slice(0, max).trimEnd()}…` : s;
}

function notificationBody(r: Row): string | null {
  const template = templates[r.type];
  if (!template) return null;
  const [action, quote] = template(r);
  return quote ? `${action}: “${snippet(quote, 80)}”` : action;
}

// threadId (DM): iOS'ta her mesaj ayrı bildirimdir, aynı sohbetinkiler tek yığında durur.
// Android'e DM data-only gider; bildirimi uygulama MessagingStyle ile kendisi çizer
// (lib/core/push/message_notifications.dart).
type Push = { userId: string; title: string; body: string; data: Record<string, string>; threadId?: string };

// Android sohbet bildiriminde listelenen en fazla okunmamış mesaj (FCM data sınırı 4 KB).
const MAX_GROUPED = 8;

async function load(kind: string, id: string): Promise<Push | null> {
  if (kind === 'message') {
    const { data, error } = await db
      .from('messages')
      .select('receiver_id, sender_id, conversation_id, content, sender:users!messages_sender_id_fkey(full_name, avatar_url)')
      .eq('id', id)
      .maybeSingle();
    if (error) throw error;
    if (!data) return null;
    // Android bildirimi sohbetin okunmamış son mesajlarını listeler; her mesajda yeniden çizilip titrer.
    // Okunmamış sayısı için is_read değil sayaç: uygulama sohbeti açınca sayacı sıfırlıyor.
    const { data: conv, error: convError } = await db
      .from('conversations')
      .select('user1_id, user1_unread_count, user2_unread_count')
      .eq('id', data.conversation_id)
      .maybeSingle();
    if (convError) throw convError;
    const unread = conv ? (conv.user1_id === data.receiver_id ? conv.user1_unread_count : conv.user2_unread_count) : 1;
    const { data: recent, error: recentError } = await db
      .from('messages')
      .select('content, created_at')
      .eq('conversation_id', data.conversation_id)
      .eq('sender_id', data.sender_id)
      .is('deleted_at', null)
      .order('created_at', { ascending: false })
      .limit(Math.min(Math.max(unread, 1), MAX_GROUPED));
    if (recentError) throw recentError;
    const messages = (recent ?? []).reverse().map((m) => ({ text: snippet(m.content, 140), at: m.created_at }));
    const sender = data.sender as unknown as { full_name: string; avatar_url: string | null };
    return {
      userId: data.receiver_id,
      title: sender.full_name,
      body: snippet(data.content, 140),
      threadId: data.conversation_id,
      data: {
        type: 'message',
        actor_id: data.sender_id,
        actor_name: sender.full_name,
        actor_avatar: sender.avatar_url ?? '',
        conversation_id: data.conversation_id,
        messages: JSON.stringify(messages),
        unread: String(Math.max(unread, messages.length)),
      },
    };
  }

  const { data, error } = await db
    .from('notifications')
    .select(
      'user_id, actor_id, type, post_id, comment_id, actor:users!notifications_actor_id_fkey(full_name, avatar_url), ' +
        'post:posts!notifications_post_id_fkey(title), comment:comments!notifications_comment_id_fkey(content)',
    )
    .eq('id', id)
    .maybeSingle();
  if (error) throw error;
  const body = data && notificationBody(data as unknown as Row);
  if (!data || !body) return null;
  const actor = data.actor as unknown as { full_name: string; avatar_url: string | null };
  return {
    userId: data.user_id,
    title: actor.full_name,
    body,
    data: {
      type: data.type,
      notification_id: id,
      actor_id: data.actor_id,
      actor_name: actor.full_name,
      actor_avatar: actor.avatar_url ?? '',
      post_id: data.post_id ?? '',
      comment_id: data.comment_id ?? '',
    },
  };
}

let cached: { token: string; exp: number } | null = null;

async function accessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.exp - 60 > now) return cached.token;
  const jwt = await new SignJWT({ scope: 'https://www.googleapis.com/auth/firebase.messaging' })
    .setProtectedHeader({ alg: 'RS256', typ: 'JWT' })
    .setIssuer(sa.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(await importPKCS8(sa.private_key, 'RS256'));
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: jwt }),
  });
  if (!res.ok) throw new Error(`oauth ${res.status}: ${await res.text()}`);
  const json = await res.json();
  cached = { token: json.access_token, exp: now + json.expires_in };
  return cached.token;
}

async function send(push: Push): Promise<void> {
  const { data: tokens, error } = await db.from('push_tokens').select('token, platform').eq('user_id', push.userId);
  if (error) throw error;
  if (!tokens?.length) return;

  const auth = await accessToken();
  await Promise.all(tokens.map(async ({ token, platform }) => {
    const dataOnly = platform === 'android' && push.data.type === 'message';
    const message = dataOnly
      ? { token, data: push.data, android: { priority: 'high' } }
      : {
          token,
          notification: { title: push.title, body: push.body },
          data: push.data,
          android: { priority: 'high' },
          apns: { payload: { aps: { sound: 'default', ...(push.threadId && { 'thread-id': push.threadId }) } } },
        };
    const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${auth}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ message }),
    });
    if (res.ok) return;
    const text = await res.text();
    // Uygulama silinmiş ya da token yenilenmiş: satırı temizle.
    if (res.status === 404 || text.includes('UNREGISTERED') || text.includes('INVALID_ARGUMENT')) {
      await db.from('push_tokens').delete().eq('token', token);
    } else {
      console.error('fcm', res.status, text);
    }
  }));
}

Deno.serve(async (req) => {
  if (req.headers.get('x-push-secret') !== Deno.env.get('PUSH_WEBHOOK_SECRET')) {
    return new Response('forbidden', { status: 403 });
  }
  const { kind, id } = await req.json();
  if ((kind !== 'notification' && kind !== 'message') || typeof id !== 'string') {
    return new Response('bad request', { status: 400 });
  }
  try {
    const push = await load(kind, id);
    if (push) await send(push);
    return new Response('ok');
  } catch (e) {
    console.error(e);
    return new Response('error', { status: 500 });
  }
});
