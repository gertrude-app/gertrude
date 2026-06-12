export type GertrudeIOSApp = `blocker` | `podcasts`;

export const APP_META: Record<GertrudeIOSApp, { name: string; iconSrc: string }> = {
  blocker: {
    name: `Gertrude Blocker`,
    iconSrc: `/gertrude-blocker-app-icon.png`,
  },
  podcasts: {
    name: `Gertrude AM`,
    iconSrc: `/gertrude-am-app-icon.png`,
  },
};

export const CLAIM_PENDING_QUERY_KEY: Record<GertrudeIOSApp, string> = {
  blocker: `claimPendingSupervision`,
  podcasts: `claimPendingAmDevice`,
};

export const CLAIM_REDIRECT_ROUTE: Record<GertrudeIOSApp, string> = {
  blocker: `claim-pending-supervision`,
  podcasts: `claim-pending-am`,
};

const CLAIM_FUNNEL_PATH_SEGMENT: Record<GertrudeIOSApp, string> = {
  blocker: `supervise-device`,
  podcasts: `claim-am-device`,
};

export function detectClaimFunnelPath(
  pathname: string,
): { app: GertrudeIOSApp; claimCode: string } | null {
  const entries = Object.entries(CLAIM_FUNNEL_PATH_SEGMENT) as [GertrudeIOSApp, string][];
  for (const [app, segment] of entries) {
    const match = pathname.match(new RegExp(`^/${segment}/(\\d+)(/|$)`));
    if (match?.[1]) {
      return { app, claimCode: match[1] };
    }
  }
  return null;
}

export function detectClaimPending(
  params: URLSearchParams,
): { app: GertrudeIOSApp; claimCode: string } | null {
  const entries = Object.entries(CLAIM_PENDING_QUERY_KEY) as [GertrudeIOSApp, string][];
  for (const [app, key] of entries) {
    const claimCode = params.get(key);
    if (claimCode) {
      return { app, claimCode };
    }
  }
  return null;
}
