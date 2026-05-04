import type { AddressType } from './edit';
import { domain } from '.';

export function address(input: string, type: AddressType): boolean {
  switch (type) {
    case `standard`:
    case `strict`:
      return domain.registrable(input) !== null;
    case `ip`:
      return domain.isIpAddress(input);
    case `domainRegex`:
      return domainRegex(input) === null;
  }
}

const MAX_DOMAIN_REGEX_PATTERN_LENGTH = 200;
const DOMAIN_REGEX_CANARY_HOSTNAME = `nothing-to-do-with-anything.invalid`;

export function domainRegex(pattern: string): string | null {
  if (pattern.length > MAX_DOMAIN_REGEX_PATTERN_LENGTH) {
    return `regex pattern too long: ${pattern.length} chars, max ${MAX_DOMAIN_REGEX_PATTERN_LENGTH}`;
  }
  let regex: RegExp;
  try {
    regex = new RegExp(pattern, `i`);
  } catch (err) {
    const msg = err instanceof Error ? err.message : `invalid regular expression`;
    return `invalid regex pattern: ${msg}`;
  }
  if (regex.test(``)) {
    return `regex pattern is too broad: matches the empty string`;
  }
  if (regex.test(DOMAIN_REGEX_CANARY_HOSTNAME)) {
    return `regex pattern is too broad: matches arbitrary hostnames`;
  }
  if (!hasLiteralAlphanumeric(pattern)) {
    return `regex pattern must contain at least one literal alphanumeric character`;
  }
  return null;
}

function hasLiteralAlphanumeric(pattern: string): boolean {
  let i = 0;
  let inClass = false;
  while (i < pattern.length) {
    const c = pattern.charAt(i);
    if (c === `\\`) {
      i += 2;
      continue;
    }
    if (c === `[`) {
      inClass = true;
      i += 1;
      continue;
    }
    if (c === `]`) {
      inClass = false;
      i += 1;
      continue;
    }
    if (!inClass && /[\p{L}\p{N}]/u.test(c)) {
      return true;
    }
    i += 1;
  }
  return false;
}
