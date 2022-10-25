type Request = Pick<
  UnlockRequest,
  'url' | 'domain' | 'ipAddress' | 'appCategories' | 'appBundleId' | 'appSlug'
>;

export function keyForUnlockRequest(request: Request): Key {
  let scope: Key['scope'] = { type: `webBrowsers` };
  let type: `domain` | `ipAddress` = `domain`;
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

  switch (type) {
    case `domain`:
      return { type, domain: value, scope };
    case `ipAddress`:
      return { type, ipAddress: value, scope };
  }
}
