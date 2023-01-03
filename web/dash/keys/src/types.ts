// TODO: this should all be pulled in from pairql codegen
export type SingleAppScope =
  | { type: 'bundleId'; bundleId: string }
  | { type: 'identifiedAppSlug'; identifiedAppSlug: string };

export type AppScope =
  | { type: `webBrowsers` }
  | { type: `unrestricted` }
  | { type: `single`; single: SingleAppScope };

export type Key =
  | { type: 'domain'; domain: string; scope: AppScope }
  | { type: 'anySubdomain'; domain: string; scope: AppScope }
  | { type: 'domainRegex'; pattern: string; scope: AppScope }
  | { type: 'ipAddress'; ipAddress: string; scope: AppScope }
  | { type: 'path'; path: string; scope: AppScope } // deprecated
  | { type: 'skeleton'; scope: SingleAppScope };

export type KeyRecord = {
  id: UUID;
  keychainId: UUID;
  key: Key;
  comment?: string | null;
  expiration?: string | null;
};

export type Keychain = {
  id: UUID;
  name: string;
  authorId: UUID;
  description: string | null;
  isPublic: boolean;
  numKeys: number;
};
