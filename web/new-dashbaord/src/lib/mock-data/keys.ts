export type Key = {
  domain: string;
  addressType: `standard` | `strict` | `ipAddress` | `regExp`;
  scope:
    | {
        type: `allApps`;
      }
    | {
        type: `webBrowsers`;
      }
    | {
        type: `singleApp`;
        bundleId: string;
      };
  expiration?: Date;
  note?: string;
};

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
