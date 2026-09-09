import { NAUGHTY_DOMAINS, UNSAFE_DOMAINS, domain as domainTools } from '@dash/keys';
import type {
  AppScope,
  DecideUnlockRequests,
  GetPersonUnlockRequests,
  SharedKey,
  SingleAppScope,
} from '@shared/pairql/src/account';

export type UnlockRequestRow = GetPersonUnlockRequests.Output[`requests`][number];
export type UnlockDecisionInput = DecideUnlockRequests.Input[`decisions`][number];
export type UnlockDecision = `undecided` | `allow` | `deny`;
export type UnlockRisk = {
  level: `strongWarning` | `caution`;
  reason: string;
};

export type UnlockDomainGroup = {
  id: string;
  requestIds: string[];
  requests: UnlockRequestRow[];
  target: string;
  originalHost?: string;
  key: SharedKey;
  decision: UnlockDecision;
  risk?: UnlockRisk;
  keychainId?: string;
  comment?: string;
  expiration?: string;
};

export type UnlockWebEntry = {
  kind: `web`;
  id: string;
  group: UnlockDomainGroup;
};

export type UnlockAppChoice =
  `undecided` | `deny` | `requestedAddresses` | `perAddress` | `unrestricted`;

export type UnlockAppEntry = {
  kind: `app`;
  id: string;
  name: string;
  slug?: string;
  bundleId?: string;
  iconHash?: string;
  scope: SingleAppScope;
  choice: UnlockAppChoice;
  groups: UnlockDomainGroup[];
};

export type UnlockReviewEntry = UnlockWebEntry | UnlockAppEntry;

const requestHost = (request: UnlockRequestRow): string | undefined => {
  if (request.domain) {
    return request.domain.toLowerCase();
  }
  if (!request.url) {
    return undefined;
  }
  try {
    return new URL(request.url).hostname.toLowerCase();
  } catch {
    return undefined;
  }
};

const requestScope = (request: UnlockRequestRow): AppScope => {
  if (request.appCategories.includes(`browser`)) {
    return { type: `webBrowsers` };
  }
  if (request.appSlug) {
    return {
      type: `single`,
      single: { type: `identifiedAppSlug`, identifiedAppSlug: request.appSlug },
    };
  }
  if (request.appBundleId) {
    return {
      type: `single`,
      single: { type: `bundleId`, bundleId: request.appBundleId },
    };
  }
  return { type: `webBrowsers` };
};

export const keyForUnlockRequest = (request: UnlockRequestRow): SharedKey => {
  const scope = requestScope(request);
  if (request.ipAddress) {
    return { type: `ipAddress`, ipAddress: request.ipAddress, scope };
  }

  const host = requestHost(request) ?? ``;
  const registrable = domainTools.registrable(host);
  if (registrable && !UNSAFE_DOMAINS.includes(registrable)) {
    return { type: `anySubdomain`, domain: registrable, scope };
  }
  return { type: `domain`, domain: host, scope };
};

const scopeIdentity = (scope: SharedKey[`scope`]): string => {
  if (scope.type === `single`) {
    return scope.single.type === `identifiedAppSlug`
      ? `slug:${scope.single.identifiedAppSlug}`
      : `bundle:${scope.single.bundleId}`;
  }
  return scope.type;
};

const keyIdentity = (key: SharedKey): string => {
  const scope = `scope` in key ? scopeIdentity(key.scope) : ``;
  switch (key.type) {
    case `anySubdomain`:
    case `domain`:
      return `${key.type}:${key.domain}:${scope}`;
    case `ipAddress`:
      return `${key.type}:${key.ipAddress}:${scope}`;
    case `domainRegex`:
      return `${key.type}:${key.pattern}:${scope}`;
    case `path`:
      return `${key.type}:${key.path}:${scope}`;
    case `skeleton`:
      return `${key.type}:${scopeIdentity(key.scope)}`;
  }
};

const warningForRequest = (
  request: UnlockRequestRow,
  key: SharedKey,
): UnlockRisk | undefined => {
  if (request.ipAddress) {
    return {
      level: `caution`,
      reason: `This is a direct network address, so it may be hard to tell which service it reaches.`,
    };
  }

  const host = requestHost(request);
  if (!host) {
    return undefined;
  }
  const registrable = domainTools.registrable(host);
  const exactWarning = NAUGHTY_DOMAINS[host];
  const warning = exactWarning ?? NAUGHTY_DOMAINS[registrable ?? host];
  if (!warning) {
    return undefined;
  }
  if (!exactWarning && registrable && host !== registrable && key.type === `domain`) {
    const prefix = host.slice(0, -(registrable.length + 1));
    const depth = prefix.split(`.`).filter(Boolean).length;
    if (depth > 1) {
      return undefined;
    }
    if (prefix !== `www`) {
      return { level: `caution`, reason: `This address is related to ${registrable}.` };
    }
  }
  return {
    level: warning.level === `deny` ? `strongWarning` : `caution`,
    reason: warning.reason,
  };
};

const strongestRisk = (
  requests: UnlockRequestRow[],
  key: SharedKey,
): UnlockRisk | undefined => {
  const risks = requests.flatMap((request) => {
    const risk = warningForRequest(request, key);
    return risk ? [risk] : [];
  });
  return risks.find((risk) => risk.level === `strongWarning`) ?? risks[0];
};

const targetForKey = (key: SharedKey): string => {
  switch (key.type) {
    case `anySubdomain`:
    case `domain`:
      return key.domain;
    case `ipAddress`:
      return key.ipAddress;
    case `domainRegex`:
      return key.pattern;
    case `path`:
      return key.path;
    case `skeleton`:
      return `All internet access`;
  }
};

const appScope = (key: SharedKey): SingleAppScope | undefined =>
  `scope` in key && key.scope.type === `single` ? key.scope.single : undefined;

const appIdentity = (scope: SingleAppScope): string =>
  scope.type === `identifiedAppSlug`
    ? `slug:${scope.identifiedAppSlug}`
    : `bundle:${scope.bundleId}`;

export const buildUnlockReview = (
  requests: UnlockRequestRow[],
  defaultKeychainId?: string,
): UnlockReviewEntry[] => {
  const grouped = new Map<string, { key: SharedKey; requests: UnlockRequestRow[] }>();
  for (const request of requests) {
    const key = keyForUnlockRequest(request);
    const identity = keyIdentity(key);
    const existing = grouped.get(identity);
    if (existing) {
      existing.requests.push(request);
    } else {
      grouped.set(identity, { key, requests: [request] });
    }
  }

  const domainGroups = Array.from(grouped.values()).map(({ key, requests: members }) => {
    const sorted = [...members].sort((a, b) => {
      if (Boolean(a.requestComment) !== Boolean(b.requestComment)) {
        return a.requestComment ? -1 : 1;
      }
      return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
    });
    const representative = sorted[0];
    if (!representative) {
      throw new Error(`Unlock request group cannot be empty`);
    }
    const risk = strongestRisk(sorted, key);
    return {
      id: keyIdentity(key),
      requestIds: sorted.map((request) => request.id),
      requests: sorted,
      target: targetForKey(key),
      originalHost: requestHost(representative),
      key,
      decision:
        risk?.level === `strongWarning` ? (`deny` as const) : (`undecided` as const),
      risk,
      keychainId: defaultKeychainId,
    };
  });

  const entries: UnlockReviewEntry[] = [];
  const apps = new Map<string, UnlockAppEntry>();
  for (const group of domainGroups) {
    const scope = appScope(group.key);
    if (!scope) {
      entries.push({ kind: `web`, id: `web:${group.id}`, group });
      continue;
    }

    const identity = appIdentity(scope);
    let entry = apps.get(identity);
    if (!entry) {
      const representative = group.requests[0];
      if (!representative) {
        throw new Error(`Unlock request group cannot be empty`);
      }
      entry = {
        kind: `app`,
        id: `app:${identity}`,
        name: representative.appName ?? `Unknown app`,
        slug: representative.appSlug,
        bundleId: representative.appBundleId,
        iconHash: representative.appIconHash,
        scope,
        choice: `undecided`,
        groups: [],
      };
      apps.set(identity, entry);
      entries.push(entry);
    }
    entry.groups.push(group);
  }

  for (const entry of apps.values()) {
    const hasStrongWarning = entry.groups.some(
      (group) => group.risk?.level === `strongWarning`,
    );
    const hasOtherRiskLevel = entry.groups.some(
      (group) => group.risk?.level !== `strongWarning`,
    );
    if (hasStrongWarning && hasOtherRiskLevel) {
      entry.choice = `perAddress`;
    } else if (hasStrongWarning) {
      entry.choice = `perAddress`;
    }
  }

  return entries;
};

export const sanitizeRequestedAddress = (request: UnlockRequestRow): string => {
  if (request.url) {
    try {
      const url = new URL(request.url);
      const path = url.pathname === `/` ? `` : url.pathname;
      return `${url.hostname}${path}`;
    } catch {
      return request.domain ?? request.ipAddress ?? `Unknown address`;
    }
  }
  return request.domain ?? request.ipAddress ?? `Unknown address`;
};

const requestCountForEntry = (entry: UnlockReviewEntry): number =>
  entry.kind === `web`
    ? entry.group.requestIds.length
    : entry.groups.reduce((sum, group) => sum + group.requestIds.length, 0);

export const totalRequestCount = (entries: UnlockReviewEntry[]): number =>
  entries.reduce((sum, entry) => sum + requestCountForEntry(entry), 0);

export const decidedRequestCount = (entries: UnlockReviewEntry[]): number =>
  entries.reduce((sum, entry) => {
    if (entry.kind === `web`) {
      return (
        sum + (entry.group.decision === `undecided` ? 0 : entry.group.requestIds.length)
      );
    }
    if (
      entry.choice === `deny` ||
      entry.choice === `requestedAddresses` ||
      entry.choice === `unrestricted`
    ) {
      return sum + requestCountForEntry(entry);
    }
    if (entry.choice === `perAddress`) {
      return (
        sum +
        entry.groups.reduce(
          (groupSum, group) =>
            groupSum + (group.decision === `undecided` ? 0 : group.requestIds.length),
          0,
        )
      );
    }
    return sum;
  }, 0);

const acceptedKeyAction = (
  group: UnlockDomainGroup,
): Extract<UnlockDecisionInput[`action`], { case: `acceptedKey` }> => ({
  case: `acceptedKey`,
  keychainId: group.keychainId,
  key: group.key,
  comment: group.comment?.trim() || undefined,
  expiration: group.expiration,
});

const decisionForGroup = (group: UnlockDomainGroup): UnlockDecisionInput | undefined => {
  if (group.decision === `undecided`) {
    return undefined;
  }
  return {
    requestIds: group.requestIds,
    action: group.decision === `deny` ? { case: `rejected` } : acceptedKeyAction(group),
  };
};

export const decisionsForSubmission = (
  entries: UnlockReviewEntry[],
): UnlockDecisionInput[] =>
  entries.flatMap((entry) => {
    if (entry.kind === `web`) {
      const decision = decisionForGroup(entry.group);
      return decision ? [decision] : [];
    }

    const requestIds = entry.groups.flatMap((group) => group.requestIds);
    switch (entry.choice) {
      case `undecided`:
        return [];
      case `deny`:
        return [{ requestIds, action: { case: `rejected` as const } }];
      case `unrestricted`:
        return [
          {
            requestIds,
            action: { case: `acceptedApp` as const, scope: entry.scope },
          },
        ];
      case `requestedAddresses`:
        return entry.groups.map((group) => ({
          requestIds: group.requestIds,
          action: acceptedKeyAction(group),
        }));
      case `perAddress`:
        return entry.groups.flatMap((group) => {
          const decision = decisionForGroup(group);
          return decision ? [decision] : [];
        });
      default:
        return [];
    }
  });

export const denyAllDecisions = (entries: UnlockReviewEntry[]): UnlockDecisionInput[] => {
  const requestIds = entries.flatMap((entry) =>
    entry.kind === `web`
      ? entry.group.requestIds
      : entry.groups.flatMap((group) => group.requestIds),
  );
  return requestIds.length === 0 ? [] : [{ requestIds, action: { case: `rejected` } }];
};

export const updateGroupKeyAddressMatch = (
  group: UnlockDomainGroup,
  includeSubdomains: boolean,
): UnlockDomainGroup => {
  if (group.key.type !== `domain` && group.key.type !== `anySubdomain`) {
    return group;
  }
  if (includeSubdomains) {
    const registrable = domainTools.registrable(group.originalHost ?? group.key.domain);
    return registrable
      ? {
          ...group,
          target: registrable,
          key: { ...group.key, type: `anySubdomain`, domain: registrable },
        }
      : group;
  }
  const host = group.originalHost ?? group.key.domain;
  return { ...group, target: host, key: { ...group.key, type: `domain`, domain: host } };
};
