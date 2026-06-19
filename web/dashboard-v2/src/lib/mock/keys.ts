import type { Key } from './types';

export function defaultKeyFromDomain(domain: string): Key {
  const hasSubdomain = domain.split(`.`).length > 2;
  return {
    domain,
    addressType: hasSubdomain ? `strict` : `standard`,
    scope: {
      type: `allApps`,
    },
  };
}
