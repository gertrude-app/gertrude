export type Type = 'website' | 'app';
export type AddressType = 'strict' | 'standard' | 'ip' | 'domainRegex';
export type AddressScope = 'webBrowsers' | 'unrestricted' | 'singleApp';
export type AppIdentificationType = 'bundleId' | 'slug';

type AppScope = 'unrestricted' | 'address';

export enum Step {
  None = -1,
  SetKeyType,
  WebsiteKey_SetAddress,
  WebsiteKey_SetAppScope,
  WebsiteKey_Advanced_ChooseApp,
  AppKey_ChooseApp,
  AppKey_SetAppScope,
  AppKey_Advanced_SetAddress,
  Expiration,
  Comment,
}

export type State = {
  id: UUID;
  keychainId: UUID;
  isNew: boolean;
  keyType?: Type;
  unlockRequestAddress?: string;
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
  activeStep: Step;
};

export type Event =
  | { type: 'setKeyType'; to: Type }
  | { type: 'setKeychainId'; to: UUID }
  | { type: 'nextStepClicked' }
  | { type: 'prevStepClicked' }
  | { type: 'setAddressType'; to: AddressType }
  | { type: 'setAddressScope'; to: AddressScope }
  | { type: 'setShowAdvancedAddressOptions'; to: boolean }
  | { type: 'setShowAdvancedAddressScopeOptions'; to: boolean }
  | { type: 'setAppIdentificationType'; to: AppIdentificationType }
  | { type: 'setAppSlug'; to: string | undefined }
  | { type: 'setAppBundleId'; to: string | undefined }
  | { type: 'setAppScope'; to: AppScope }
  | { type: 'setExpirationDate'; to: string | undefined }
  | { type: 'setExpirationTime'; to: string }
  | { type: 'setComment'; to: string | undefined }
  | { type: 'inactiveStepClicked'; step: Step }
  | { type: 'setAddress'; to: string };
