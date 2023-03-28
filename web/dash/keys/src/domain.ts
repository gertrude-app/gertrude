import { parseDomain, fromUrl, ParseResultType } from 'parse-domain';
export { fromUrl };

export function sanitizeUserInput(input: string): string {
  return input
    .replace(/^https?:\/\//, ``) // remove protocol
    .replace(/\/.*/, ``) // remove path
    .toLowerCase();
}

export function registrable(input: string): string | null {
  const parsed = parse(input);
  if (parsed) {
    return `${parsed.domain}.${parsed.tld}`;
  }
  return null;
}

export function tld(input: string): string | null {
  const parsed = parse(input);
  if (parsed) {
    return parsed.tld;
  }
  return null;
}

export function subdomain(input: string): string | null {
  const parsed = parse(input);
  if (parsed && parsed.subdomain) {
    return parsed.subdomain;
  }
  return null;
}

export function hostname(input: string): string | null {
  const parsed = parse(input);
  if (!parsed) {
    return null;
  }
  const hostname = `${parsed.domain}.${parsed.tld}`;
  if (parsed.subdomain) {
    return `${parsed.subdomain}.${hostname}`;
  }
  return hostname;
}

export function isIpAddress(input: string): boolean {
  const parseResult = parseDomain(
    input.match(/^https?:\/\//) ? fromUrl(input) : input.replace(/:\d+/, ``),
  );
  switch (parseResult?.type) {
    case ParseResultType.Ip:
      return true;
    default:
      return false;
  }
}

function parse(
  input: string,
): { domain: string; subdomain?: string; tld: string } | null {
  const parseResult = parseDomain(
    input.match(/^https?:\/\//) ? fromUrl(input) : input.replace(/:\d+/, ``),
  );
  switch (parseResult?.type) {
    case ParseResultType.Listed: {
      const { subDomains, domain, topLevelDomains } = parseResult.icann;
      if (typeof domain === `string` && topLevelDomains.length > 0) {
        return {
          domain: domain.toLowerCase(),
          subdomain:
            subDomains.length > 0 ? subDomains.join(`.`).toLowerCase() : undefined,
          tld: topLevelDomains.join(`.`).toLowerCase(),
        };
      }
      break;
    }
  }
  return null;
}
