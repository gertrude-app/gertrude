import React from 'react';
import AddressStep from './AddressStep';
import AddressScopeStep from './AddressScopeStep';
import ExpirationStep from './ExpirationStep';
import ChooseAppStep from './ChooseAppStep';
import AppScopeStep from './AppScopeStep';
import KeyTypeStep from './KeyTypeStep';
import CommentStep from './CommentStep';

const STEP_TYPES = [
  `setKeyType`,

  // website key states
  `websiteKey_setAddress`,
  `websiteKey_setAppScope`,
  `websiteKey_chooseApp`, // advanced, rarely used

  // app key states
  `appKey_chooseApp`,
  `appKey_setAppScope`,
  `appKey_setAddress`, // advanced, rarely used

  `expiration`,
  `comment`,
] as const;

type StepType = typeof STEP_TYPES[number];

interface Props {
  mode: 'create' | 'edit';
  keyType?: 'website' | 'app';
  address: string;
  addressType: 'strict' | 'standard' | 'ip' | 'domainRegex';
  addressScope: 'webBrowsers' | 'unrestricted' | 'singleApp';
  showAdvancedAddressOptions: boolean;
  showAdvancedAddressScopeOptions: boolean;
  appIdentificationType: 'bundleId' | 'slug';
  appSlug?: string;
  appBundleId?: string;
  appScope: 'unrestricted' | 'address';
  expiration?: Date;
  comment?: string;
  apps: Array<{ slug: string; name: string }>;
  currentStep?: StepType;
}

const KeyCreator: React.FC<Props> = ({
  showAdvancedAddressOptions,
  keyType,
  address,
  addressType,
  addressScope,
  appIdentificationType,
  appScope,
  expiration,
  comment,
  mode,
  currentStep,
  apps,
  appBundleId,
  appSlug,
}) => {
  const currentStepIndex = currentStep ? STEP_TYPES.indexOf(currentStep) + 1 : -1;
  return (
    <div className="">
      <KeyTypeStep mode={mode} currentStepIndex={currentStepIndex} keyType={keyType} />

      {keyType !== `app` && (
        <AddressStep
          keyType={keyType ?? `website`}
          mode={mode}
          currentStepIndex={currentStepIndex}
          address={address}
          addressType={addressType}
          showAdvancedAddressOptions={showAdvancedAddressOptions}
        />
      )}

      {keyType !== `app` && (
        <AddressScopeStep
          mode={mode}
          currentStepIndex={currentStepIndex}
          addressScope={addressScope}
          showAdvancedAddressOptions={showAdvancedAddressOptions}
          appIdentificationType={appIdentificationType}
          apps={apps}
        />
      )}

      {(keyType === `app` || addressScope === `singleApp`) && (
        <ChooseAppStep
          keyType={keyType ?? `app`}
          mode={mode}
          currentStepIndex={currentStepIndex}
          appIdentificationType={appIdentificationType}
          apps={apps}
          appBundleId={appBundleId}
          appSlug={appSlug}
        />
      )}

      {keyType === `app` && (
        <AppScopeStep
          mode={mode}
          currentStepIndex={currentStepIndex}
          appScope={appScope}
        />
      )}

      {keyType === `app` && appScope === `address` && (
        <AddressStep
          keyType={keyType}
          mode={mode}
          currentStepIndex={currentStepIndex}
          address={address}
          addressType={addressType}
          showAdvancedAddressOptions={showAdvancedAddressOptions}
        />
      )}

      <ExpirationStep
        mode={mode}
        currentStepIndex={currentStepIndex}
        expiration={expiration}
      />

      <CommentStep mode={mode} currentStepIndex={currentStepIndex} comment={comment} />
    </div>
  );
};

export default KeyCreator;
