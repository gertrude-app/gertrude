export type AddressType = `strict` | `standard` | `ip` | `domainRegex`;
export type AddressScope = `webBrowsers` | `unrestricted` | `singleApp`;
export type AppIdentificationType = `bundleId` | `slug`;

export enum Step {
  None = -1,
  SetAddress,
  SetAppScope,
  Advanced_ChooseApp,
  Expiration,
  Comment,
}

export type State = {
  id: UUID;
  keychainId: UUID;
  isNew: boolean;
  unlockRequestAddress?: string;
  address: string;
  addressType: AddressType;
  addressScope: AddressScope;
  showAdvancedAddressOptions: boolean;
  showAdvancedAddressScopeOptions: boolean;
  appIdentificationType: AppIdentificationType;
  appSlug?: string;
  appBundleId?: string;
  expiration?: string;
  comment?: string;
  activeStep: Step;
};

export type Event =
  | { type: `setKeychainId`; to: UUID }
  | { type: `nextStepClicked` }
  | { type: `prevStepClicked` }
  | { type: `setAddressType`; to: AddressType }
  | { type: `setAddressScope`; to: AddressScope }
  | { type: `setShowAdvancedAddressOptions`; to: boolean }
  | { type: `setShowAdvancedAddressScopeOptions`; to: boolean }
  | { type: `setAppIdentificationType`; to: AppIdentificationType }
  | { type: `setAppSlug`; to: string | undefined }
  | { type: `setAppBundleId`; to: string | undefined }
  | { type: `setExpirationDate`; to: string | undefined }
  | { type: `setExpirationTime`; to: string }
  | { type: `setComment`; to: string | undefined }
  | { type: `inactiveStepClicked`; step: Step }
  | { type: `setAddress`; to: string };
