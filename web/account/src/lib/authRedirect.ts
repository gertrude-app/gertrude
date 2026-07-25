export type AuthRedirect = `/${string}`;

export type AuthRedirectSearch = {
  redirect?: AuthRedirect;
};

const accountBaseUrl = new URL(`https://account.invalid`);

export const authRedirectForPath = (path: string): AuthRedirect | undefined => {
  if (!path.startsWith(`/`) || path.startsWith(`//`) || path.includes(`\\`)) {
    return undefined;
  }

  try {
    const url = new URL(path, accountBaseUrl);
    if (url.origin !== accountBaseUrl.origin) return undefined;
    return `${url.pathname}${url.search}${url.hash}` as AuthRedirect;
  } catch {
    return undefined;
  }
};

export const validateAuthRedirectSearch = (
  search: Record<string, unknown>,
): AuthRedirectSearch => {
  const redirect =
    typeof search.redirect === `string`
      ? authRedirectForPath(search.redirect)
      : undefined;
  return redirect ? { redirect } : {};
};

export type PostAuthLocation = { href: AuthRedirect };

export const postAuthLocation = (
  redirect: AuthRedirect | undefined,
): PostAuthLocation => ({ href: redirect ?? `/people` });
