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
export type UnlockKey = Extract<
  SharedKey,
  { type: `domain` | `anySubdomain` | `ipAddress` }
>;
export type UnlockRisk = {
  level: `strongWarning` | `caution`;
  reason: string;
};

export type UnlockDomainGroup = {
  id: string;
  requestIds: string[];
  requests: UnlockRequestRow[];
  target: string;
  key: UnlockKey;
  decision: UnlockDecision;
  risk?: UnlockRisk;
  keychainId?: string;
  comment?: string;
  expiration?: string;
  edited?: boolean;
};

export type UnlockWebEntry = {
  kind: `web`;
  id: string;
  group: UnlockDomainGroup;
};

export type UnlockAppEntry = {
  kind: `app`;
  id: string;
  name: string;
  bundleId?: string;
  iconHash?: string;
  scope: SingleAppScope;
  unrestricted: boolean;
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

export const keyForUnlockRequest = (request: UnlockRequestRow): UnlockKey => {
  const scope = requestScope(request);
  const host = requestHost(request) ?? ``;
  if (!host && request.ipAddress) {
    return { type: `ipAddress`, ipAddress: request.ipAddress, scope };
  }

  if (domainTools.isIpAddress(host)) {
    return { type: `ipAddress`, ipAddress: host.replace(/^\[|\]$/g, ``), scope };
  }
  return { type: `domain`, domain: host.replace(/^www\./, ``), scope };
};

const scopeIdentity = (scope: AppScope): string => {
  if (scope.type === `single`) {
    return scope.single.type === `identifiedAppSlug`
      ? `slug:${scope.single.identifiedAppSlug}`
      : `bundle:${scope.single.bundleId}`;
  }
  return scope.type;
};

const keyIdentity = (key: UnlockKey): string => {
  const scope = scopeIdentity(key.scope);
  switch (key.type) {
    case `anySubdomain`:
    case `domain`:
      return `${key.type}:${key.domain}:${scope}`;
    case `ipAddress`:
      return `${key.type}:${key.ipAddress}:${scope}`;
  }
};

const warningForRequest = (
  request: UnlockRequestRow,
  key: UnlockKey,
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
  key: UnlockKey,
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
  if (decision === `allow`) return { ...group, decision, edited: true };
  const request = group.requests[0];
  if (!request) throw new Error(`Unlock request group cannot be empty`);
  const key = keyForUnlockRequest(request);
  return {
    ...group,
    decision,
    edited: true,
    key,
    risk: strongestRisk(group.requests, key),
    keychainId: defaultKeychainId,
    comment: undefined,
    expiration: undefined,
  };
};

const targetForKey = (key: UnlockKey): string => {
  switch (key.type) {
    case `anySubdomain`:
    case `domain`:
      return key.domain;
    case `ipAddress`:
      return key.ipAddress;
  }
};

const appScope = (key: UnlockKey): SingleAppScope | undefined =>
  key.scope.type === `single` ? key.scope.single : undefined;

const appIdentity = (scope: SingleAppScope): string =>
  scope.type === `identifiedAppSlug`
    ? `slug:${scope.identifiedAppSlug}`
    : `bundle:${scope.bundleId}`;

export const buildUnlockReview = (
  requests: UnlockRequestRow[],
  defaultKeychainId?: string,
): UnlockReviewEntry[] => {
  const grouped = new Map<string, { key: UnlockKey; requests: UnlockRequestRow[] }>();
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
        bundleId: representative.appBundleId,
        iconHash: representative.appIconHash,
        scope,
        unrestricted: false,
        groups: [],
      };
      apps.set(identity, entry);
      entries.push(entry);
    }
    entry.groups.push(group);
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

const acceptedKeyAction = (
  group: UnlockDomainGroup,
): Extract<UnlockDecisionInput[`action`], { case: `acceptedKey` }> => ({
  case: `acceptedKey`,
  keychainId: group.keychainId,
  key: group.key,
  comment: group.comment?.trim() || undefined,
  expiration: group.expiration,
});

export const denyAllDecisions = (entries: UnlockReviewEntry[]): UnlockDecisionInput[] => {
  const requestIds = entries.flatMap((entry) =>
    entry.kind === `web`
      ? entry.group.requestIds
      : entry.groups.flatMap((group) => group.requestIds),
  );
  return requestIds.length === 0 ? [] : [{ requestIds, action: { case: `rejected` } }];
};

export type UnlockAddressMatch = `exact` | `subdomains` | `parent`;

const subdomainPermissionLabel = (host: string): string => `${host} and its subdomains`;

export const addressMatchOptions = (
  group: UnlockDomainGroup,
): Array<{ value: UnlockAddressMatch; label: string; domain: string }> => {
  if (group.key.type !== `domain` && group.key.type !== `anySubdomain`) {
    return [];
  }
  const host = group.target;
  const parent = domainTools.registrable(host);
  return [
    {
      value: `exact`,
      label: `Only ${host}`,
      domain: host,
    },
    {
      value: `subdomains`,
      label: subdomainPermissionLabel(host),
      domain: host,
    },
    ...(parent && parent !== host
      ? [
          {
            value: `parent` as const,
            label: `${parent} and all its subdomains`,
            domain: parent,
          },
        ]
      : []),
  ];
};

export const groupAddressMatch = (group: UnlockDomainGroup): UnlockAddressMatch =>
  group.key.type !== `anySubdomain`
    ? `exact`
    : group.key.domain === group.target
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
  const host = group.target;
  const key: UnlockKey = {
    ...group.key,
    type: match === `exact` ? `domain` : `anySubdomain`,
    domain: match === `parent` ? (domainTools.registrable(host) ?? host) : host,
  };
  return { ...group, key, edited: true, risk: strongestRisk(group.requests, key) };
};

export const permissionLabel = (group: UnlockDomainGroup): string => {
  switch (group.key.type) {
    case `domain`:
      return group.key.domain;
    case `anySubdomain`:
      return subdomainPermissionLabel(group.key.domain);
    default:
      return targetForKey(group.key);
  }
};

export type UnlockRowState = {
  decision: UnlockDecision;
  coveredBy: UnlockDomainGroup[];
  coveredRequestCount: number;
  overlaps: boolean;
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

const exactDomainMatches = (domain: string, host: string): boolean =>
  host === domain || host === `www.${domain}` || domain === `www.${host}`;

const domainMatches = (domain: string, host: string): boolean =>
  exactDomainMatches(domain, host) || host.endsWith(`.${domain}`);

const keyPermitsRequest = (key: UnlockKey, request: UnlockRequestRow): boolean => {
  if (!scopePermitsRequest(key.scope, request)) {
    return false;
  }
  const host = requestHost(request) ?? ``;
  switch (key.type) {
    case `domain`:
      return exactDomainMatches(key.domain, host);
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

export const reconcileUnlockReview = (
  entries: UnlockReviewEntry[],
  requests: UnlockRequestRow[],
  defaultKeychainId?: string,
): UnlockReviewEntry[] => {
  const previousGroups = new Map(
    entries.flatMap((entry) =>
      (entry.kind === `web` ? [entry.group] : entry.groups).map(
        (group) => [group.id, group] as const,
      ),
    ),
  );
  const merge = (group: UnlockDomainGroup): UnlockDomainGroup => {
    const previous = previousGroups.get(group.id);
    return previous
      ? { ...previous, requests: group.requests, requestIds: group.requestIds }
      : group;
  };
  return buildUnlockReview(requests, defaultKeychainId).map((entry) => {
    if (entry.kind === `web`) return { ...entry, group: merge(entry.group) };
    const previous = entries.find((old) => old.id === entry.id);
    return {
      ...entry,
      unrestricted: previous?.kind === `app` && previous.unrestricted,
      groups: entry.groups.map(merge),
    };
  });
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
      unrestricted: entry.kind === `app` && entry.unrestricted,
      decision: group.decision,
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
  const rows = new Map<string, UnlockRowState>();
  const assignedIds = new Map(grants.map((group) => [group.id, [...group.requestIds]]));
  const decisions: UnlockDecisionInput[] = entries.flatMap((entry) =>
    entry.kind === `app` && entry.unrestricted
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
    const providers = unrestricted
      ? []
      : group.requests.flatMap((request) => {
          const provider = grants.find(
            (grant) => grant.id !== group.id && keyPermitsRequest(grant.key, request),
          );
          if (!provider) return [];
          if (decision === `undecided`) assignedIds.get(provider.id)?.push(request.id);
          return [provider];
        });
    const coveredBy = decision === `allow` ? [] : Array.from(new Set(providers));
    const coveredRequestCount = decision === `undecided` ? providers.length : 0;
    const problem = unrestricted
      ? undefined
      : decision === `deny` && providers.length > 0
        ? `You denied this request, but your ${coveredBy.length === 1 ? `approval` : `approvals`} of ${coveredBy.map(permissionLabel).join(`, `)} would still allow it. Narrow or clear ${coveredBy.length === 1 ? `that broader approval` : `those broader approvals`} to keep this request denied.`
        : invalid.get(group.id);
    rows.set(group.id, {
      decision: unrestricted ? `allow` : decision,
      coveredBy,
      coveredRequestCount,
      overlaps: decision === `allow` && providers.length > 0,
      problem,
    });
    if (!unrestricted && decision === `deny`) {
      decisions.push({ requestIds: group.requestIds, action: { case: `rejected` } });
    }
    decidedCount +=
      unrestricted || decision !== `undecided`
        ? group.requestIds.length
        : coveredRequestCount;
  }
  for (const grant of grants) {
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
