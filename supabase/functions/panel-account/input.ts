// Panel hesabı alan adı. .invalid'e posta gidemez: şifre sıfırlama bağlantısını kimse alamaz.
// Paneldeki Login.tsx'teki panelEmail ile aynı olmalı.
export const PANEL_DOMAIN = '@panel.dentigo.invalid';

export const isPanelEmail = (email: unknown) => typeof email === 'string' && email.endsWith(PANEL_DOMAIN);

/** Küçük harf a-z, rakam, . _ -; 3–30. Geçersizse null. */
export function panelUsername(value: unknown): string | null {
  const s = typeof value === 'string' ? value.trim().toLowerCase() : '';
  return /^[a-z0-9._-]{3,30}$/.test(s) ? s : null;
}

// 2FA yok; şifre tek koruma. 72: bcrypt sınırı.
export const validPassword = (value: unknown): value is string =>
  typeof value === 'string' && value.length >= 12 && value.length <= 72;

export function fullName(value: unknown): string | null {
  const s = typeof value === 'string' ? value.trim().replace(/\s+/g, ' ') : '';
  return s.length >= 2 && s.length <= 80 ? s : null;
}
