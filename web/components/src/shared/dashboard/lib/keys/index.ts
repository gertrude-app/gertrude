import * as EditKey from './edit';

export function newKeyState(id: UUID, keychainId: UUID): EditKey.State {
  return {
    id,
    keychainId,
    isNew: true,
    activeStep: EditKey.Step.SetKeyType,
    keyType: undefined,
    address: ``,
    addressType: `standard`,
    addressScope: `webBrowsers`,
    showAdvancedAddressOptions: false,
    showAdvancedAddressScopeOptions: false,
    appIdentificationType: `slug`,
    appScope: `unrestricted`,
    appSlug: undefined,
    appBundleId: undefined,
    expiration: undefined,
    comment: undefined,
  };
}

export function scopeType(key: Key): AppScope['type'] {
  if (key.type === `skeleton`) {
    return `single`;
  }
  return key.scope.type;
}

export function target(key: Key): string {
  switch (key.type) {
    case `ipAddress`:
      return key.ipAddress;
    case `skeleton`:
      return `*`;
    case `anySubdomain`:
      return `*.${key.domain}`;
    case `domain`:
      return key.domain;
    case `domainRegex`:
      return key.pattern;
    case `path`:
      return key.path;
  }
}
