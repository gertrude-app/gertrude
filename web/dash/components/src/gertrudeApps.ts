export type GertrudeIOSApp = `blocker` | `podcasts` | `music`;

export type ClaimIntent = `blockerSupervise` | `blockerConnect` | `podcasts` | `music`;

export const APP_META: Record<GertrudeIOSApp, { name: string; iconSrc: string }> = {
  blocker: {
    name: `Gertrude Blocker`,
    iconSrc: `/gertrude-blocker-app-icon.png`,
  },
  podcasts: {
    name: `Gertrude AM`,
    iconSrc: `/gertrude-am-app-icon.png`,
  },
  music: {
    name: `Gertrude Music`,
    iconSrc: `/gertrude-music-app-icon.png`,
  },
};

const CLAIM_INTENT_APP: Record<ClaimIntent, GertrudeIOSApp> = {
  blockerSupervise: `blocker`,
  blockerConnect: `blocker`,
  podcasts: `podcasts`,
  music: `music`,
};

export function claimIntentApp(intent: ClaimIntent): GertrudeIOSApp {
  return CLAIM_INTENT_APP[intent];
}

export const CLAIM_PENDING_QUERY_KEY: Record<ClaimIntent, string> = {
  blockerSupervise: `claimPendingSupervision`,
  blockerConnect: `claimPendingBlocker`,
  podcasts: `claimPendingAmDevice`,
  music: `claimPendingMusicDevice`,
};

export const CLAIM_REDIRECT_ROUTE: Record<ClaimIntent, string> = {
  blockerSupervise: `claim-pending-supervision`,
  blockerConnect: `claim-pending-blocker`,
  podcasts: `claim-pending-am`,
  music: `claim-pending-music`,
};

const CLAIM_FUNNEL_PATH_SEGMENT: Record<ClaimIntent, string> = {
  blockerSupervise: `supervise-device`,
  blockerConnect: `claim-blocker-device`,
  podcasts: `claim-am-device`,
  music: `claim-music-device`,
};

export function claimFunnelPath(intent: ClaimIntent, claimCode: string): string {
  return `/${CLAIM_FUNNEL_PATH_SEGMENT[intent]}/${claimCode}/claim`;
}

export function detectClaimFunnelPath(
  pathname: string,
): { intent: ClaimIntent; claimCode: string } | null {
  const entries = Object.entries(CLAIM_FUNNEL_PATH_SEGMENT) as [ClaimIntent, string][];
  for (const [intent, segment] of entries) {
    const match = pathname.match(new RegExp(`^/${segment}/(\\d+)(/|$)`));
    if (match?.[1]) {
      return { intent, claimCode: match[1] };
    }
  }
  return null;
}

export function detectClaimPending(
  params: URLSearchParams,
): { intent: ClaimIntent; claimCode: string } | null {
  const entries = Object.entries(CLAIM_PENDING_QUERY_KEY) as [ClaimIntent, string][];
  for (const [intent, key] of entries) {
    const claimCode = params.get(key);
    if (claimCode) {
      return { intent, claimCode };
    }
  }
  return null;
}
