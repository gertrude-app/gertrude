type Request = Pick<
  UnlockRequest,
  'url' | 'domain' | 'ipAddress' | 'appCategories' | 'appBundleId' | 'appSlug'
>;

export function keyForUnlockRequest(request: Request): Key {
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

  const registrable = registrableDomain(value);
  if (UNSAFE_DOMAINS.includes(registrable)) {
    return { type: `domain`, domain: value, scope };
  } else {
    return { type: `anySubdomain`, domain: registrable, scope };
  }
}

export function registrableDomain(input: string): string {
  const domain = input.toLowerCase().replace(/:\d+$/, ``);
  const parts = domain.split(`.`);
  if (parts.length < 3) {
    return domain;
  }
  parts.shift();
  return parts.join(`.`);
}

const UNSAFE_DOMAINS = [
  `google.com`,
  `facebook.com`,
  `twitter.com`,
  `wikipedia.org`,
  `youtube.com`,
];
