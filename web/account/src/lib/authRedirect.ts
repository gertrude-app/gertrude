import { type IOSConnectFlow, appForConnectFlow } from '#/lib/gertrudeApps';

export type AuthRedirect = `/${string}`;

export type AuthRedirectSearch = {
  redirect?: AuthRedirect;
};

const accountBaseUrl = new URL(`https://account.invalid`);

const authPages = [
  `/login`,
  `/signup`,
  `/signout`,
  `/otp`,
  `/verify-signup-email`,
  `/reset-password`,
  `/link-expired`,
];

const isAuthPage = (pathname: string): boolean =>
  authPages.some((page) => pathname === page || pathname.startsWith(`${page}/`));

export const authRedirectForPath = (path: string): AuthRedirect | undefined => {
  if (!path.startsWith(`/`) || path.startsWith(`//`) || path.includes(`\\`)) {
    return undefined;
  }

  try {
    const url = new URL(path, accountBaseUrl);
    if (url.origin !== accountBaseUrl.origin) return undefined;
    if (isAuthPage(url.pathname.replace(/\/+$/, ``))) return undefined;
    return `${url.pathname}${url.search}${url.hash}` as AuthRedirect;
  } catch {
    return undefined;
  }
};

export const validateAuthRedirectSearch = (
  search: Record<string, unknown>,
): AuthRedirectSearch => {
  const redirect =
    typeof search[`redirect`] === `string`
      ? authRedirectForPath(search[`redirect`])
      : undefined;
  return redirect ? { redirect } : {};
};

export type AuthSearch = AuthRedirectSearch & {
  modelName?: string;
  modelIdentifier?: string;
  ref?: string;
  v?: string;
};

const attributionParam = (value: unknown): string | undefined =>
  typeof value === `string` && /^[\w-]{1,64}$/.test(value) ? value : undefined;

export const validateAuthSearch = (search: Record<string, unknown>): AuthSearch => {
  const modelName =
    typeof search[`modelName`] === `string`
      ? search[`modelName`].trim().slice(0, 60)
      : ``;
  const modelIdentifier =
    typeof search[`modelIdentifier`] === `string` &&
    /^(iPhone|iPad)\d+,\d+$/.test(search[`modelIdentifier`])
      ? search[`modelIdentifier`]
      : undefined;
  const ref = attributionParam(search[`ref`]);
  const v = attributionParam(search[`v`]);
  return {
    ...validateAuthRedirectSearch(search),
    ...(modelName ? { modelName } : {}),
    ...(modelName && modelIdentifier ? { modelIdentifier } : {}),
    ...(ref ? { ref } : {}),
    ...(v ? { v } : {}),
  };
};

export const authPageHref = (page: `/login` | `/signup`, search: AuthSearch): string => {
  const params = new URLSearchParams();
  if (search.redirect) params.set(`redirect`, search.redirect);
  if (search.modelName) params.set(`modelName`, search.modelName);
  if (search.modelIdentifier) params.set(`modelIdentifier`, search.modelIdentifier);
  if (search.ref) params.set(`ref`, search.ref);
  if (search.v) params.set(`v`, search.v);
  const query = params.toString();
  return query ? `${page}?${query}` : page;
};

export type ConnectingDevice = {
  app: ReturnType<typeof appForConnectFlow>;
  deviceName?: string;
  modelIdentifier?: string;
};

export const connectingDeviceFor = (search: AuthSearch): ConnectingDevice | undefined => {
  const flow = search.redirect?.match(
    /^\/connect\/(blockerConnect|blockerSupervise|podcasts|music)\/\d{6}(?:[?#]|$)/,
  )?.[1] as IOSConnectFlow | undefined;
  return flow
    ? {
        app: appForConnectFlow(flow),
        deviceName: search.modelName,
        modelIdentifier: search.modelIdentifier,
      }
    : undefined;
};

export const pairingReturnPath = (): AuthRedirect | undefined => {
  const path = sessionStorage.getItem(`pairingReturnPath`);
  return path &&
    /^\/connect\/(blockerConnect|blockerSupervise|podcasts|music)\/\d{6}$/.test(path)
    ? (path as AuthRedirect)
    : undefined;
};

export type PostAuthLocation = { to: `/people` };

export const postAuthLocation = (
  redirect: AuthRedirect | undefined,
): PostAuthLocation => ({ to: (redirect ?? `/people`) as `/people` });
