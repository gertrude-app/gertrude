type SingleAppScope =
  | { type: 'bundleId'; bundleId: string }
  | { type: 'identifiedAppSlug'; identifiedAppSlug: string };

type AppScope =
  | { type: `webBrowsers` }
  | { type: `unrestricted` }
  | { type: `single`; single: SingleAppScope };

type Key =
  | { type: 'domain'; domain: string; scope: AppScope }
  | { type: 'anySubdomain'; domain: string; scope: AppScope }
  | { type: 'domainRegex'; pattern: string; scope: AppScope }
  | { type: 'ipAddress'; ipAddress: string; scope: AppScope }
  | { type: 'path'; path: string; scope: AppScope } // deprecated
  | { type: 'skeleton'; scope: SingleAppScope };

type KeyRecord = {
  id: UUID;
  key: Key;
  comment?: string | null;
  expiration?: string | null;
};

type Keychain = {
  id: UUID;
  name: string;
  authorId: UUID;
  description: string | null;
  isPublic: boolean;
  keyRecords: Record<UUID, KeyRecord>;
};

// eslint-disable-next-line @typescript-eslint/no-unused-vars
namespace EditKey {
  export type Mode = 'create' | 'edit';
  export type Type = 'website' | 'app';
  export type AddressType = 'strict' | 'standard' | 'ip' | 'domainRegex';
  export type AddressScope = 'webBrowsers' | 'unrestricted' | 'singleApp';
  export type AppIdentificationType = 'bundleId' | 'slug';
  export type AppScope = 'unrestricted' | 'address';
  export type Step =
    // common
    | 'setKeyType'
    // website key states
    | 'websiteKey_setAddress'
    | 'websiteKey_setAppScope'
    | 'websiteKey_chooseApp' // advanced, rarely used
    // app key states
    | 'appKey_chooseApp'
    | 'appKey_setAppScope'
    | 'appKey_setAddress' // advanced, rarely used
    // common
    | 'expiration'
    | 'comment';

  export type State = {
    id?: UUID;
    mode: Mode;
    keyType?: Type;
    address: string;
    addressType: AddressType;
    addressScope: AddressScope;
    showAdvancedAddressOptions: boolean;
    showAdvancedAddressScopeOptions: boolean;
    appIdentificationType: AppIdentificationType;
    appSlug?: string;
    appBundleId?: string;
    appScope: AppScope;
    expiration?: string;
    comment?: string;
    currentStep?: Step;
  };

  export type Event =
    | { set: 'keyType'; to: Type }
    | { set: 'currentStep'; to: Step | 'next' | 'prev' }
    | { set: 'addressType'; to: AddressType }
    | { set: 'addressScope'; to: AddressScope }
    | { set: 'showAdvancedAddressOptions'; to: boolean }
    | { set: 'showAdvancedAddressScopeOptions'; to: boolean }
    | { set: 'appIdentificationType'; to: AppIdentificationType }
    | { set: 'appSlug'; to: string | undefined }
    | { set: 'appBundleId'; to: string | undefined }
    | { set: 'appScope'; to: AppScope }
    | { set: 'expirationDate'; to: string | undefined }
    | { set: 'expirationTime'; to: string }
    | { set: 'comment'; to: string | undefined }
    | { set: 'currentStep'; to: Step | undefined }
    | { set: 'address'; to: string };
}
