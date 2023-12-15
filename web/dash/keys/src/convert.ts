import type {
  AppScope,
  Key,
  SharedKey,
  SingleAppScope,
  UnlockRequestCreateKeyData,
} from '@dash/types';
import * as EditKey from './edit';
import * as domain from './domain';
import { keyForUnlockRequest, newKeyState } from '.';

export function unlockRequestToState(
  keyRecordId: UUID,
  keychainId: UUID,
  request: UnlockRequestCreateKeyData,
): EditKey.State {
  const key = keyForUnlockRequest(request);
  return {
    ...toState({ id: keyRecordId, keychainId, key }),
    unlockRequestAddress: request.url ?? request.domain ?? request.ipAddress,
  };
}

export function toState(keyRecord: Key): EditKey.State {
  const state = newKeyState(keyRecord.id, keyRecord.keychainId);
  const key = keyRecord.key;
  state.activeStep = EditKey.Step.None;
  state.isNew = false;
  state.comment = keyRecord.comment ?? undefined;
  state.expiration = keyRecord.expiration ?? undefined;

  if (key.type === `skeleton`) {
    return toSkeleton(key, state);
  }

  if (key.type === `path`) {
    return state; // deprecated
  }

  if (key.scope.type === `unrestricted`) {
    state.addressScope = `unrestricted`;
    state.keyType = `website`;
    setAddressFields(key, state);
    return state;
  }

  if (key.scope.type === `webBrowsers`) {
    state.addressScope = `webBrowsers`;
    state.keyType = `website`;
    setAddressFields(key, state);
    return state;
  }

  state.addressScope = `singleApp`;
  state.keyType = `app`;
  if (key.scope.single.type === `bundleId`) {
    state.appBundleId = key.scope.single.bundleId;
    state.appIdentificationType = `bundleId`;
  } else {
    state.appSlug = key.scope.single.identifiedAppSlug;
  }
  setAddressFields(key, state);
  return state;
}

export function toKeyRecord(state?: EditKey.State): Key | null {
  if (!state?.keyType) {
    return null;
  }
  return state.keyType === `website`
    ? websiteKeyToKeyRecord(state)
    : appKeyToKeyRecord(state);
}

function setAddressFields(key: SharedKey, state: EditKey.State): void {
  if (key.type === `domain`) {
    state.addressType = `strict`;
    state.address = key.domain;
  } else if (key.type === `anySubdomain`) {
    state.addressType = `standard`;
    state.address = key.domain;
  } else if (key.type === `domainRegex`) {
    state.addressType = `domainRegex`;
    state.address = key.pattern;
    state.showAdvancedAddressOptions = true;
  } else if (key.type === `ipAddress`) {
    state.addressType = `ip`;
    state.address = key.ipAddress;
    state.showAdvancedAddressOptions = true;
  }
}

function toSkeleton(key: SharedKey, state: EditKey.State): EditKey.State {
  state.keyType = `app`;
  state.appScope = `unrestricted`;
  state.addressScope = `singleApp`;
  if (key.scope.type === `bundleId`) {
    state.appIdentificationType = `bundleId`;
    state.appBundleId = key.scope.bundleId;
  } else if (key.scope.type === `identifiedAppSlug`) {
    state.appIdentificationType = `slug`;
    state.appSlug = key.scope.identifiedAppSlug;
  }
  return state;
}

function websiteKeyToKeyRecord(state: EditKey.State): Key | null {
  const address = domain.sanitizeUserInput(state.address);
  const tmpScope: AppScope = { type: `webBrowsers` };
  let key: SharedKey = { type: `domain`, domain: ``, scope: tmpScope };

  switch (state.addressType) {
    case `standard`:
    case `strict`:
      if (!domainValid(address)) return null;
      key = {
        type: state.addressType === `standard` ? `anySubdomain` : `domain`,
        domain: domain.removePort(address),
        scope: tmpScope,
      };
      break;

    case `ip`:
      if (!domain.isIpAddress(address)) return null;
      key = { type: `ipAddress`, ipAddress: domain.removePort(address), scope: tmpScope };
      break;

    case `domainRegex`:
      if (!domainValid(address) || !address.includes(`*`)) return null;
      key = { type: `domainRegex`, pattern: address, scope: tmpScope };
      break;
  }

  const scope = appScope(state);
  if (!scope) {
    return null;
  }

  key.scope = scope;
  return {
    id: state.id,
    keychainId: state.keychainId,
    key,
    comment: state.comment,
    expiration: state.expiration,
  };
}

function appKeyToKeyRecord(state: EditKey.State): Key | null {
  if (state.appScope === `unrestricted`) {
    const single = singleAppScope(state);
    if (!single) return null;
    return {
      id: state.id,
      keychainId: state.keychainId,
      key: { type: `skeleton`, scope: single },
      comment: state.comment,
      expiration: state.expiration,
    };
  } else {
    return websiteKeyToKeyRecord(state);
  }
}

function appScope(state: EditKey.State): AppScope | null {
  if (state.keyType === `website`) {
    switch (state.addressScope) {
      case `webBrowsers`:
        return { type: `webBrowsers` };
      case `unrestricted`:
        return { type: `unrestricted` };
      case `singleApp`: {
        const single = singleAppScope(state);
        if (!single) {
          return null;
        }
        return { type: `single`, single };
      }
    }
  } else {
    switch (state.appScope) {
      case `unrestricted`:
        return { type: `unrestricted` };
      case `address`:
        return appScope({ ...state, keyType: `website` });
    }
  }
}

function singleAppScope(state: EditKey.State): SingleAppScope | null {
  switch (state.appIdentificationType) {
    case `slug`:
      if (!state.appSlug) return null;
      return { type: `identifiedAppSlug`, identifiedAppSlug: state.appSlug };
    case `bundleId`:
      if (!state.appBundleId || state.appBundleId.length < 3) return null;
      return { type: `bundleId`, bundleId: state.appBundleId };
  }
}

function domainValid(domain: string): boolean {
  return domain.length > 3 && domain.includes(`.`);
}
