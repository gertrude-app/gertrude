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
    return request.domain.toLowerCase().replace(/\.$/, ``);
  }
  if (!request.url) {
    return undefined;
  }
  try {
    return new URL(request.url).hostname.toLowerCase().replace(/\.$/, ``);
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
  const host = requestHost(request) ?? ``;
  if (!host && request.ipAddress) {
    return { type: `ipAddress`, ipAddress: request.ipAddress, scope };
  }

  if (domainTools.isIpAddress(host)) {
    return { type: `ipAddress`, ipAddress: host.replace(/^\[|\]$/g, ``), scope };
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
  if (key.type === `ipAddress`) {
    return {
      level: `caution`,
      reason: `This is a direct network address, so it may be hard to tell which service it reaches.`,
    };
  }

  const host =
    key.type === `domain` || key.type === `anySubdomain`
      ? key.domain
      : requestHost(request);
  if (!host) {
    return undefined;
  }
  const registrable = domainTools.registrable(host);
  if (
    key.type === `anySubdomain` &&
    !NAUGHTY_DOMAINS[host] &&
    UNSAFE_DOMAINS.includes(host)
  ) {
    return {
      level: `strongWarning`,
      reason: `This allows every site and service hosted under ${host}, not just the requested address.`,
    };
  }
  const exactWarning =
    NAUGHTY_DOMAINS[host] ?? NAUGHTY_DOMAINS[requestHost(request) ?? ``];
  const warning = exactWarning ?? NAUGHTY_DOMAINS[registrable ?? host];
  if (!warning) {
    return undefined;
  }
  if (!exactWarning && registrable && host !== registrable) {
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

export const updateGroupDecision = (
  group: UnlockDomainGroup,
  decision: UnlockDecision,
  defaultKeychainId?: string,
): UnlockDomainGroup => {
  if (decision === `allow`) return { ...group, decision };
  const request = group.requests[0];
  if (!request) throw new Error(`Unlock request group cannot be empty`);
  const key = keyForUnlockRequest(request);
  return {
    ...group,
    decision,
    key,
    risk: strongestRisk(group.requests, key),
    keychainId: defaultKeychainId,
    comment: undefined,
    expiration: undefined,
  };
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
  planUnlockReview(entries).decidedCount;

const acceptedKeyAction = (
  group: UnlockDomainGroup,
): Extract<UnlockDecisionInput[`action`], { case: `acceptedKey` }> => ({
  case: `acceptedKey`,
  keychainId: group.keychainId,
  key: group.key,
  comment: group.comment?.trim() || undefined,
  expiration: group.expiration,
});

export const decisionsForSubmission = (
  entries: UnlockReviewEntry[],
): UnlockDecisionInput[] => planUnlockReview(entries).decisions;

export const denyAllDecisions = (entries: UnlockReviewEntry[]): UnlockDecisionInput[] => {
  const requestIds = entries.flatMap((entry) =>
    entry.kind === `web`
      ? entry.group.requestIds
      : entry.groups.flatMap((group) => group.requestIds),
  );
  return requestIds.length === 0 ? [] : [{ requestIds, action: { case: `rejected` } }];
};

export type UnlockAddressMatch = `exact` | `subdomains` | `parent`;

export const addressMatchOptions = (
  group: UnlockDomainGroup,
): Array<{ value: UnlockAddressMatch; label: string }> => {
  if (group.key.type !== `domain` && group.key.type !== `anySubdomain`) {
    return [];
  }
  const host = group.originalHost ?? group.target;
  const parent = domainTools.registrable(host);
  return [
    { value: `exact`, label: `Only ${host}` },
    { value: `subdomains`, label: `${host} and its subdomains` },
    ...(parent && parent !== host
      ? [{ value: `parent` as const, label: `${parent} and all its subdomains` }]
      : []),
  ];
};

export const groupAddressMatch = (group: UnlockDomainGroup): UnlockAddressMatch =>
  group.key.type !== `anySubdomain`
    ? `exact`
    : group.key.domain === (group.originalHost ?? group.target)
      ? `subdomains`
      : `parent`;

export const updateGroupKeyAddressMatch = (
  group: UnlockDomainGroup,
  match: UnlockAddressMatch,
): UnlockDomainGroup => {
  if (
    (group.key.type !== `domain` && group.key.type !== `anySubdomain`) ||
    !addressMatchOptions(group).some((option) => option.value === match)
  ) {
    return group;
  }
  const host = group.originalHost ?? group.target;
  const key: SharedKey = {
    ...group.key,
    type: match === `exact` ? `domain` : `anySubdomain`,
    domain: match === `parent` ? (domainTools.registrable(host) ?? host) : host,
  };
  return { ...group, key, risk: strongestRisk(group.requests, key) };
};

export const permissionLabel = (group: UnlockDomainGroup): string =>
  group.key.type === `anySubdomain`
    ? `${group.key.domain} and its subdomains`
    : targetForKey(group.key);

export type UnlockRowState = {
  decision: UnlockDecision;
  coveredBy: UnlockDomainGroup[];
  coveredRequestCount: number;
  preservedApproval?: `longer` | `broader`;
  problem?: string;
};

const scopePermitsRequest = (scope: AppScope, request: UnlockRequestRow): boolean => {
  switch (scope.type) {
    case `unrestricted`:
      return true;
    case `webBrowsers`:
      return request.appCategories.includes(`browser`);
    case `single`:
      return scope.single.type === `identifiedAppSlug`
        ? scope.single.identifiedAppSlug === request.appSlug
        : scope.single.bundleId === request.appBundleId;
  }
};

const domainMatches = (domain: string, host: string): boolean =>
  host === domain || host.endsWith(`.${domain}`);

const keyPermitsRequest = (key: SharedKey, request: UnlockRequestRow): boolean => {
  if (key.type === `skeleton` || !scopePermitsRequest(key.scope, request)) {
    return false;
  }
  const host = requestHost(request) ?? ``;
  switch (key.type) {
    case `domain`:
      return key.domain === host;
    case `anySubdomain`:
      return domainMatches(key.domain, host);
    case `ipAddress`:
      return (
        key.ipAddress === request.ipAddress ||
        key.ipAddress === host.replace(/^\[|\]$/g, ``)
      );
    default:
      return false;
  }
};

const expirationTime = (group: UnlockDomainGroup): number =>
  group.expiration ? new Date(group.expiration).getTime() : Infinity;

const permissionContains = (
  source: UnlockDomainGroup,
  target: UnlockDomainGroup,
): boolean => {
  const a = source.key;
  const b = target.key;
  if (
    a.type === `skeleton` ||
    b.type === `skeleton` ||
    expirationTime(source) < expirationTime(target) ||
    (a.scope.type !== `unrestricted` && scopeIdentity(a.scope) !== scopeIdentity(b.scope))
  ) {
    return false;
  }
  if (a.type === `ipAddress` && b.type === `ipAddress`) {
    return a.ipAddress === b.ipAddress;
  }
  if (a.type === `anySubdomain` && (b.type === `domain` || b.type === `anySubdomain`)) {
    return domainMatches(a.domain, b.domain);
  }
  return a.type === `domain` && b.type === `domain` && a.domain === b.domain;
};

export const planUnlockReview = (
  entries: UnlockReviewEntry[],
  now = Date.now(),
): {
  rows: Map<string, UnlockRowState>;
  decisions: UnlockDecisionInput[];
  decidedCount: number;
  problemCount: number;
} => {
  const records = entries.flatMap((entry) =>
    (entry.kind === `web` ? [entry.group] : entry.groups).map((group) => ({
      group,
      unrestricted: entry.kind === `app` && entry.choice === `unrestricted`,
      decision:
        entry.kind === `web` || entry.choice === `perAddress`
          ? group.decision
          : entry.choice === `deny`
            ? (`deny` as const)
            : entry.choice === `undecided`
              ? (`undecided` as const)
              : (`allow` as const),
    })),
  );
  const invalid = new Map<string, string>();
  const grants = records.flatMap(({ group, decision, unrestricted }) => {
    if (decision !== `allow` || unrestricted) {
      return [];
    }
    if (!(expirationTime(group) > now)) {
      invalid.set(
        group.id,
        `This permission has expired. Choose a future expiration or remove it.`,
      );
      return [];
    }
    if (!group.requests.every((request) => keyPermitsRequest(group.key, request))) {
      invalid.set(
        group.id,
        `This permission does not cover the app that requested this address. Change its scope before submitting.`,
      );
      return [];
    }
    return [group];
  });
  const activeGrants = grants.filter(
    (group, index) =>
      !grants.some(
        (other, otherIndex) =>
          otherIndex !== index &&
          permissionContains(other, group) &&
          (!permissionContains(group, other) || otherIndex < index),
      ),
  );
  const rows = new Map<string, UnlockRowState>();
  const assignedIds = new Map(activeGrants.map((group) => [group.id, [] as string[]]));
  const decisions: UnlockDecisionInput[] = entries.flatMap((entry) =>
    entry.kind === `app` && entry.choice === `unrestricted`
      ? [
          {
            requestIds: entry.groups.flatMap((group) => group.requestIds),
            action: { case: `acceptedApp` as const, scope: entry.scope },
          },
        ]
      : [],
  );
  let decidedCount = 0;

  for (const { group, decision, unrestricted } of records) {
    const ownGrant = activeGrants.find((grant) => grant.id === group.id);
    const containingGrant = grants.includes(group)
      ? activeGrants.find((grant) => permissionContains(grant, group))
      : undefined;
    const providers = unrestricted
      ? []
      : group.requests.flatMap((request) => {
          const provider =
            ownGrant ??
            containingGrant ??
            activeGrants.find((grant) => keyPermitsRequest(grant.key, request));
          if (!provider) {
            return [];
          }
          if (decision !== `deny`) {
            assignedIds.get(provider.id)?.push(request.id);
          }
          return [provider];
        });
    const coveredBy = Array.from(
      new Set(providers.filter((provider) => provider.id !== group.id)),
    );
    const overlappingGrants = ownGrant
      ? activeGrants.filter(
          (other) =>
            other.id !== group.id &&
            group.requests.some((request) => keyPermitsRequest(other.key, request)),
        )
      : [];
    const coveredRequestCount = providers.filter(
      (provider) => provider.id !== group.id,
    ).length;
    const problem =
      decision === `deny` && providers.length > 0
        ? `Deny conflicts with an allowed permission. Allow this request, or narrow or clear the covering permission.`
        : providers.length < group.requestIds.length
          ? invalid.get(group.id)
          : undefined;
    rows.set(group.id, {
      decision,
      coveredBy,
      coveredRequestCount,
      preservedApproval: overlappingGrants.some(
        (other) => expirationTime(other) < expirationTime(group),
      )
        ? `longer`
        : overlappingGrants.length > 0
          ? `broader`
          : undefined,
      problem,
    });
    if (decision === `deny`) {
      decisions.push({ requestIds: group.requestIds, action: { case: `rejected` } });
    }
    decidedCount +=
      decision !== `undecided` ? group.requestIds.length : coveredRequestCount;
  }
  for (const grant of activeGrants) {
    const requestIds = assignedIds.get(grant.id) ?? [];
    if (requestIds.length > 0) {
      decisions.push({ requestIds, action: acceptedKeyAction(grant) });
    }
  }
  const problemCount = Array.from(rows.values()).filter((row) => row.problem).length;
  return {
    rows,
    decisions: problemCount > 0 ? [] : decisions,
    decidedCount,
    problemCount,
  };
};
