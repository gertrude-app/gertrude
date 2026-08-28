import { UNSAFE_DOMAINS } from '@dash/keys';
import { ParseResultType, parseDomain } from 'parse-domain';
import type { KeychainKey, SharedKey } from '#/components/types';
import type { AppScope, SingleAppScope } from '@shared/pairql/src/account';

export type KeyTargetType = `website` | `ipAddress` | `domainRegex`;
export type DomainMatchType = `standard` | `strict`;
export type KeyScopeType = `webBrowsers` | `unrestricted` | `singleApp`;
export type AppIdentificationType = `identifiedAppSlug` | `bundleId`;

export type KeyEditorState = {
  targetType: KeyTargetType;
  address: string;
  domainMatch: DomainMatchType;
  matchingOverridden: boolean;
  scopeType: KeyScopeType;
  appIdentificationType: AppIdentificationType;
  appSlug: string;
  appBundleId: string;
  expiration?: Date;
  comment: string;
};

export type KeyEditorApp = {
  name: string;
  slug: string;
  bundleId?: string;
  appIconUrl?: string;
};

export type KeyEditorSaveData = {
  key: SharedKey;
  comment?: string;
  expiration?: Date;
};

export type DomainDetails = {
  hostname: string;
  registrableDomain: string;
  hasSubdomain: boolean;
};

const domainRegexMaxLength = 200;
const domainRegexCanaryHostname = `nothing-to-do-with-anything.invalid`;

export const newKeyEditorState = (): KeyEditorState => ({
  targetType: `website`,
  address: ``,
  domainMatch: `standard`,
  matchingOverridden: false,
  scopeType: `webBrowsers`,
  appIdentificationType: `identifiedAppSlug`,
  appSlug: ``,
  appBundleId: ``,
  comment: ``,
});

export const changeKeyEditorTargetType = (
  state: KeyEditorState,
  targetType: KeyTargetType,
): KeyEditorState => ({
  ...state,
  targetType,
  address: targetType === state.targetType ? state.address : ``,
  domainMatch: `standard`,
  matchingOverridden: false,
});

export const changeKeyEditorAddress = (
  state: KeyEditorState,
  address: string,
): KeyEditorState => ({
  ...state,
  address,
  domainMatch:
    state.targetType === `website` && !state.matchingOverridden
      ? inferredDomainMatch(address)
      : state.domainMatch,
});

export const changeKeyEditorDomainMatch = (
  state: KeyEditorState,
  domainMatch: DomainMatchType,
): KeyEditorState => ({
  ...state,
  domainMatch,
  matchingOverridden: true,
});

export const keyToEditorState = (record: KeychainKey): KeyEditorState | null => {
  const state = newKeyEditorState();
  const key = record.key;
  state.comment = record.comment ?? ``;
  state.expiration = record.expiration ? new Date(record.expiration) : undefined;
  state.matchingOverridden = true;

  switch (key.type) {
    case `anySubdomain`:
      state.targetType = `website`;
      state.address = key.domain;
      state.domainMatch = `standard`;
      break;
    case `domain`:
      state.targetType = `website`;
      state.address = key.domain;
      state.domainMatch = `strict`;
      break;
    case `ipAddress`:
      state.targetType = `ipAddress`;
      state.address = key.ipAddress;
      break;
    case `domainRegex`:
      state.targetType = `domainRegex`;
      state.address = key.pattern;
      break;
    case `path`:
    case `skeleton`:
      return null;
  }

  switch (key.scope.type) {
    case `webBrowsers`:
      state.scopeType = `webBrowsers`;
      break;
    case `unrestricted`:
      state.scopeType = `unrestricted`;
      break;
    case `single`:
      state.scopeType = `singleApp`;
      setSingleAppScope(state, key.scope.single);
      break;
  }

  return state;
};

const setSingleAppScope = (state: KeyEditorState, scope: SingleAppScope): void => {
  switch (scope.type) {
    case `identifiedAppSlug`:
      state.appIdentificationType = `identifiedAppSlug`;
      state.appSlug = scope.identifiedAppSlug;
      break;
    case `bundleId`:
      state.appIdentificationType = `bundleId`;
      state.appBundleId = scope.bundleId;
      break;
  }
};

const hostnameFromInput = (input: string): string | null => {
  const trimmed = input.trim();
  if (!trimmed) {
    return null;
  }

  try {
    const url = new URL(
      /^[a-z][a-z\d+.-]*:\/\//i.test(trimmed) ? trimmed : `https://${trimmed}`,
    );
    return url.hostname.replace(/\.$/, ``).toLowerCase();
  } catch {
    return null;
  }
};

export const domainDetails = (input: string): DomainDetails | null => {
  const hostname = hostnameFromInput(input);
  if (!hostname) {
    return null;
  }

  const parsed = parseDomain(hostname);
  if (parsed?.type !== ParseResultType.Listed) {
    return null;
  }

  const { domain, subDomains, topLevelDomains } = parsed.icann;
  if (typeof domain !== `string` || topLevelDomains.length === 0) {
    return null;
  }

  return {
    hostname: [subDomains.join(`.`), domain, topLevelDomains.join(`.`)]
      .filter(Boolean)
      .join(`.`)
      .toLowerCase(),
    registrableDomain: `${domain}.${topLevelDomains.join(`.`)}`.toLowerCase(),
    hasSubdomain: subDomains.length > 0,
  };
};

export const inferredDomainMatch = (input: string): DomainMatchType =>
  domainDetails(input)?.hasSubdomain ? `strict` : `standard`;

const targetsCloudflareEch = (hostname: string): boolean =>
  hostname === `cloudflare-ech.com` || hostname.endsWith(`.cloudflare-ech.com`);

const removePort = (input: string): string => {
  if (input.includes(`::`) || (input.match(/:/g) ?? []).length > 2) {
    return input;
  }
  return input.replace(/:\d+$/, ``);
};

const sanitizedIpAddress = (input: string): string => {
  const trimmed = input.trim();
  if (/^https?:\/\//i.test(trimmed)) {
    try {
      return new URL(trimmed).hostname.replace(/^\[|\]$/g, ``);
    } catch {
      return trimmed;
    }
  }
  return removePort(trimmed);
};

export const isIpAddress = (input: string): boolean =>
  parseDomain(sanitizedIpAddress(input))?.type === ParseResultType.Ip;

const hasLiteralAlphanumeric = (pattern: string): boolean => {
  let index = 0;
  let inClass = false;
  while (index < pattern.length) {
    const character = pattern.charAt(index);
    if (character === `\\`) {
      index += 2;
      continue;
    }
    if (character === `[`) {
      inClass = true;
      index += 1;
      continue;
    }
    if (character === `]`) {
      inClass = false;
      index += 1;
      continue;
    }
    if (!inClass && /[\p{L}\p{N}]/u.test(character)) {
      return true;
    }
    index += 1;
  }
  return false;
};

export const domainRegexError = (pattern: string): string | null => {
  if (pattern.length > domainRegexMaxLength) {
    return `The pattern is ${pattern.length} characters; the maximum is ${domainRegexMaxLength}.`;
  }

  let regex: RegExp;
  try {
    regex = new RegExp(pattern, `i`);
  } catch {
    return `Enter a valid regular expression.`;
  }

  if (regex.test(``)) {
    return `This pattern is too broad because it matches an empty hostname.`;
  }
  if (regex.test(domainRegexCanaryHostname)) {
    return `This pattern is too broad because it matches unrelated hostnames.`;
  }
  if (!hasLiteralAlphanumeric(pattern)) {
    return `Include at least one literal letter or number.`;
  }
  return null;
};

const scopeFromState = (state: KeyEditorState): AppScope | null => {
  switch (state.scopeType) {
    case `webBrowsers`:
      return { type: `webBrowsers` };
    case `unrestricted`:
      return { type: `unrestricted` };
    case `singleApp`:
      if (state.appIdentificationType === `identifiedAppSlug`) {
        return state.appSlug
          ? {
              type: `single`,
              single: {
                type: `identifiedAppSlug`,
                identifiedAppSlug: state.appSlug,
              },
            }
          : null;
      }
      return state.appBundleId.trim().length >= 3
        ? {
            type: `single`,
            single: { type: `bundleId`, bundleId: state.appBundleId.trim() },
          }
        : null;
  }
};

export const keyFromEditorState = (state: KeyEditorState): SharedKey | null => {
  const scope = scopeFromState(state);
  if (!scope) {
    return null;
  }

  switch (state.targetType) {
    case `website`: {
      const details = domainDetails(state.address);
      if (!details || targetsCloudflareEch(details.hostname)) {
        return null;
      }
      return state.domainMatch === `standard`
        ? { type: `anySubdomain`, domain: details.registrableDomain, scope }
        : { type: `domain`, domain: details.hostname, scope };
    }
    case `ipAddress`: {
      const ipAddress = sanitizedIpAddress(state.address);
      return isIpAddress(ipAddress) ? { type: `ipAddress`, ipAddress, scope } : null;
    }
    case `domainRegex`: {
      const pattern = state.address.trim();
      return pattern && domainRegexError(pattern) === null
        ? { type: `domainRegex`, pattern, scope }
        : null;
    }
  }
};

export const keyEditorError = (state: KeyEditorState): string | null => {
  if (!state.address.trim()) {
    return null;
  }

  if (state.targetType === `website`) {
    const details = domainDetails(state.address);
    if (!details) {
      return `Enter a complete website address, such as example.com.`;
    }
    if (targetsCloudflareEch(details.hostname)) {
      return `Gertrude blocks cloudflare-ech.com automatically, so no key is needed.`;
    }
  }
  if (state.targetType === `ipAddress` && !isIpAddress(state.address)) {
    return `Enter a valid IPv4 or IPv6 address.`;
  }
  if (state.targetType === `domainRegex`) {
    return domainRegexError(state.address.trim());
  }
  return null;
};

export const broadAccessWarning = (state: KeyEditorState): string | null => {
  const key = keyFromEditorState({ ...state, scopeType: `webBrowsers` });
  if (key?.type !== `anySubdomain` || !UNSAFE_DOMAINS.includes(key.domain)) {
    return null;
  }

  return `This allows every subdomain of ${key.domain}, which may include other services and content. Turn off “Include subdomains” if that isn't what you intend.`;
};
