import React from 'react';
import AddressStep from './AddressStep';
import WebsiteKeyAppScopeStep from './WebsiteKeyAppScopeStep';
import ExpirationStep from './ExpirationStep';
import ChooseAppStep from './ChooseAppStep';
import AppScopeStep from './AppScopeStep';
import KeyTypeStep from './KeyTypeStep';
import CommentStep from './CommentStep';
import * as EditKey from '../../../lib/keys/edit';

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
  activeStep,
  apps,
  appBundleId,
  appSlug,
  update,
}) => (
  <>
    <KeyTypeStep update={update} mode={mode} activeStep={activeStep} keyType={keyType} />

    {keyType !== `app` && (
      <AddressStep
        keyType={keyType ?? `website`}
        mode={mode}
        update={update}
        activeStep={activeStep}
        address={address}
        addressType={addressType}
        showAdvancedAddressOptions={showAdvancedAddressOptions}
      />
    )}

    {keyType !== `app` && (
      <WebsiteKeyAppScopeStep
        mode={mode}
        update={update}
        activeStep={activeStep}
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
        activeStep={activeStep}
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
        activeStep={activeStep}
        appScope={appScope}
      />
    )}

    {keyType === `app` && appScope === `address` && (
      <AddressStep
        update={update}
        keyType={keyType}
        mode={mode}
        activeStep={activeStep}
        address={address}
        addressType={addressType}
        showAdvancedAddressOptions={showAdvancedAddressOptions}
      />
    )}

    <ExpirationStep
      mode={mode}
      update={update}
      activeStep={activeStep}
      expiration={expiration}
    />

    <CommentStep mode={mode} activeStep={activeStep} comment={comment} update={update} />
  </>
);

export default KeyCreator;
