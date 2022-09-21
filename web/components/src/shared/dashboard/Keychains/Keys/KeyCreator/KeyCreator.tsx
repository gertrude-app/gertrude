import React from 'react';
import AddressStep from './AddressStep';
import AddressScopeStep from './AddressScopeStep';
import ExpirationStep from './ExpirationStep';
import ChooseAppStep from './ChooseAppStep';
import AppScopeStep from './AppScopeStep';
import KeyTypeStep from './KeyTypeStep';
import CommentStep from './CommentStep';

type Props = EditKey.State & {
  update(event: EditKey.Event): unknown;
  apps: Array<{ slug: string; name: string }>;
};

const KeyCreator: React.FC<Props> = ({
  showAdvancedAddressOptions,
  showAdvancedAddressScopeOptions,
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
  update,
}) => {
  const currentStepIndex = currentStep ? STEP_TYPES.indexOf(currentStep) + 1 : -1;
  return (
    <>
      <KeyTypeStep
        update={update}
        mode={mode}
        currentStepIndex={currentStepIndex}
        keyType={keyType}
      />

      {keyType !== `app` && (
        <AddressStep
          keyType={keyType ?? `website`}
          mode={mode}
          update={update}
          currentStepIndex={currentStepIndex}
          address={address}
          addressType={addressType}
          showAdvancedAddressOptions={showAdvancedAddressOptions}
        />
      )}

      {keyType !== `app` && (
        <AddressScopeStep
          mode={mode}
          update={update}
          currentStepIndex={currentStepIndex}
          addressScope={addressScope}
          showAdvancedAddressScopeOptions={showAdvancedAddressScopeOptions}
          appIdentificationType={appIdentificationType}
          apps={apps}
        />
      )}

      {(keyType === `app` || addressScope === `singleApp`) && (
        <ChooseAppStep
          keyType={keyType ?? `app`}
          update={update}
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
          update={update}
          mode={mode}
          currentStepIndex={currentStepIndex}
          appScope={appScope}
        />
      )}

      {keyType === `app` && appScope === `address` && (
        <AddressStep
          update={update}
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
        update={update}
        currentStepIndex={currentStepIndex}
        expiration={expiration}
      />

      <CommentStep
        mode={mode}
        currentStepIndex={currentStepIndex}
        comment={comment}
        update={update}
      />
    </>
  );
};

export default KeyCreator;

const STEP_TYPES: EditKey.Step[] = [
  `setKeyType`,
  `websiteKey_setAddress`,
  `websiteKey_setAppScope`,
  `websiteKey_chooseApp`,
  `appKey_chooseApp`,
  `appKey_setAppScope`,
  `appKey_setAddress`,
  `expiration`,
  `comment`,
];
