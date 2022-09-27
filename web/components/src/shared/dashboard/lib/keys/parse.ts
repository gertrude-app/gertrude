export function parse(input: string): Key | null {
  try {
    var parsed = JSON.parse(input);
  } catch {
    return null;
  }

  if (!isPlainObject(parsed)) {
    return null;
  }

  if (!hasType(parsed, KEY_TYPES)) {
    return null;
  }

  if (isDomain(parsed)) {
    return parsed as Key;
  } else if (isSkeleton(parsed)) {
    return parsed as Key;
  } else if (isAnySubdomain(parsed)) {
    return parsed as Key;
  } else if (isIpAddress(parsed)) {
    return parsed as Key;
  } else if (isDomainRegex(parsed)) {
    return parsed as Key;
  } else if (isPath(parsed)) {
    return parsed as Key;
  } else {
    return null;
  }
}

function isPath(input: { type: Key['type']; [k: string]: unknown }): boolean {
  if (input.type !== `path` || !hasValidScope(input)) {
    return false;
  }
  return typeof input.path === `string` && keysAre(input, [`type`, `path`, `scope`]);
}

function isDomainRegex(input: { type: Key['type']; [k: string]: unknown }): boolean {
  if (input.type !== `domainRegex` || !hasValidScope(input)) {
    return false;
  }
  return (
    typeof input.pattern === `string` && keysAre(input, [`type`, `pattern`, `scope`])
  );
}

function isAnySubdomain(input: { type: Key['type']; [k: string]: unknown }): boolean {
  if (input.type !== `anySubdomain` || !hasValidScope(input)) {
    return false;
  }
  return typeof input.domain === `string` && keysAre(input, [`type`, `domain`, `scope`]);
}

function isDomain(input: { type: Key['type']; [k: string]: unknown }): boolean {
  if (input.type !== `domain` || !hasValidScope(input)) {
    return false;
  }
  return typeof input.domain === `string` && keysAre(input, [`type`, `domain`, `scope`]);
}

function isIpAddress(input: { type: Key['type']; [k: string]: unknown }): boolean {
  if (input.type !== `ipAddress` || !hasValidScope(input)) {
    return false;
  }
  return (
    typeof input.ipAddress === `string` && keysAre(input, [`type`, `ipAddress`, `scope`])
  );
}

function isSkeleton(input: { type: Key['type']; [k: string]: unknown }): boolean {
  if (input.type !== `skeleton`) {
    return false;
  }
  return isValidSingleScope(input.scope) && keysAre(input, [`type`, `scope`]);
}

function hasValidScope<T extends Record<string, unknown>>(
  input: T,
): input is { scope: AppScope } & T {
  if (!(`scope` in input)) {
    return false;
  }
  const scope = input.scope;
  if (!isPlainObject(scope)) {
    return false;
  }
  if (!hasType(scope, SCOPE_TYPES)) {
    return false;
  }
  if (scope.type !== `single`) {
    return keysAre(scope, [`type`]);
  }
  return isValidSingleScope(scope.single);
}

function isValidSingleScope(input: unknown): boolean {
  if (!isPlainObject(input)) {
    return false;
  }
  if (!hasType(input, [`bundleId`, `identifiedAppSlug`])) {
    return false;
  }
  if (input.type === `bundleId`) {
    return keysAre(input, [`type`, `bundleId`]) && typeof input.bundleId === `string`;
  }
  return (
    keysAre(input, [`type`, `identifiedAppSlug`]) &&
    typeof input.identifiedAppSlug === `string`
  );
}

function hasType<T extends string, K extends Record<string, unknown>>(
  input: K,
  types: Array<T>,
): input is { type: T } & K {
  if (!(`type` in input)) {
    return false;
  }
  const type = input.type;
  if (typeof type !== `string`) {
    return false;
  }
  if ((types as string[]).includes(type)) {
    return true;
  }
  return false;
}

const KEY_TYPES: Array<Key['type']> = [
  `ipAddress`,
  `domain`,
  `anySubdomain`,
  `domainRegex`,
  `path`,
  `skeleton`,
];

const SCOPE_TYPES: Array<AppScope['type']> = [`webBrowsers`, `unrestricted`, `single`];

export default function isPlainObject(obj: unknown): obj is Record<string, unknown> {
  if (typeof obj !== `object` || obj === null) {
    return false;
  }

  let proto = obj;
  while (Object.getPrototypeOf(proto) !== null) {
    proto = Object.getPrototypeOf(proto);
  }

  return Object.getPrototypeOf(obj) === proto;
}

function keysAre(obj: Record<string, unknown>, keys: string[]): boolean {
  return (
    [...keys, `__typename`].every((key) => key in obj) &&
    Object.keys(obj).length === keys.length + 1
  );
}
