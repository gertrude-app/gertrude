import React from 'react';
import type { EditKey } from '@dash/keys';
import AddressStep from './AddressStep';
import WebsiteKeyAppScopeStep from './WebsiteKeyAppScopeStep';
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
  activeStep,
  apps,
  appBundleId,
  appSlug,
  update,
  isNew,
}) => (
  <div className="min-w-[340px] xs:min-w-[475px] sm:min-w-[550px]">
    <KeyTypeStep
      update={update}
      mode={isNew ? `create` : `edit`}
      activeStep={activeStep}
      keyType={keyType}
    />

    {keyType !== `app` && (
      <AddressStep
        keyType={keyType ?? `website`}
        mode={isNew ? `create` : `edit`}
        update={update}
        activeStep={activeStep}
        address={address}
        addressType={addressType}
        showAdvancedAddressOptions={showAdvancedAddressOptions}
      />
    )}

    {keyType !== `app` && (
      <WebsiteKeyAppScopeStep
        mode={isNew ? `create` : `edit`}
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
        mode={isNew ? `create` : `edit`}
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
        mode={isNew ? `create` : `edit`}
        activeStep={activeStep}
        appScope={appScope}
      />
    )}

    {keyType === `app` && appScope === `address` && (
      <AddressStep
        update={update}
        keyType={keyType}
        mode={isNew ? `create` : `edit`}
        activeStep={activeStep}
        address={address}
        addressType={addressType}
        showAdvancedAddressOptions={showAdvancedAddressOptions}
      />
    )}

    <ExpirationStep
      mode={isNew ? `create` : `edit`}
      update={update}
      activeStep={activeStep}
      expiration={expiration}
    />

    <CommentStep
      mode={isNew ? `create` : `edit`}
      activeStep={activeStep}
      comment={comment}
      update={update}
    />
  </div>
);

export default KeyCreator;
