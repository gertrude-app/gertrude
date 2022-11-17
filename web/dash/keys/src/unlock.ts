import type { UnlockRequestCreateKeyData } from '@dash/types';
import type { Key } from './types';
import * as domain from './domain';

export function keyForUnlockRequest(request: UnlockRequestCreateKeyData): Key {
  let scope: Key['scope'] = { type: `webBrowsers` };
  let type: 'domain' | 'ipAddress' | 'anySubdomain' = `domain`;
  let value = ``;

  if (request.url && !request.domain) {
    value = request.url.split(`/`)[2] ?? ``;
  } else if (request.domain) {
    value = request.domain;
  } else if (request.ipAddress) {
    type = `ipAddress`;
    value = request.ipAddress;
  }

  if (!request.appCategories.includes(`browser`)) {
    if (request.appSlug) {
      scope = {
        type: `single`,
        single: { type: `identifiedAppSlug`, identifiedAppSlug: request.appSlug },
      };
    } else {
      scope = {
        type: `single`,
        single: { type: `bundleId`, bundleId: request.appBundleId ?? `` },
      };
    }
  }

  if (type === `ipAddress`) {
    return { type, ipAddress: value, scope };
  }

  const registrable = domain.registrable(value);
  if (!registrable || UNSAFE_DOMAINS.includes(registrable)) {
    return { type: `domain`, domain: value, scope };
  } else {
    return { type: `anySubdomain`, domain: registrable, scope };
  }
}

const UNSAFE_DOMAINS = [
  `google.com`,
  `facebook.com`,
  `twitter.com`,
  `wikipedia.org`,
  `youtube.com`,
  `cloudfront.net`,
  `amazonaws.com`,
];
