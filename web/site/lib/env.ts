export function getPublicVars(): { formsEndpoint: string; turnstileSitekey: string } {
  const endpoint = process.env.NEXT_PUBLIC_FORMS_ENDPOINT;
  if (!endpoint) {
    throw new Error(`Missing NEXT_PUBLIC_FORMS_ENDPOINT`);
  }
  const sitekey = process.env.NEXT_PUBLIC_TURNSTILE_SITEKEY;
  if (!sitekey) {
    throw new Error(`Missing NEXT_PUBLIC_TURNSTILE_SITEKEY`);
  }
  return { formsEndpoint: endpoint, turnstileSitekey: sitekey };
}
