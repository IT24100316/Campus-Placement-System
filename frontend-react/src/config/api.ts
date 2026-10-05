const configuredApiBase = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5168/api';

// The deployed site is HTTPS, while the configured demo API is HTTP. Route
// those requests through the site's existing /api rewrite to avoid mixed content.
export const API_BASE =
  window.location.protocol === 'https:' && configuredApiBase.startsWith('http://')
    ? new URL(configuredApiBase).pathname.replace(/\/$/, '')
    : configuredApiBase.replace(/\/$/, '');
