import React from 'react';
import type { EditKey } from '@dash/keys';
import AddressStep from './AddressStep';
import ChooseAppStep from './ChooseAppStep';
import CommentStep from './CommentStep';
import ExpirationStep from './ExpirationStep';
import WebsiteKeyAppScopeStep from './WebsiteKeyAppScopeStep';

type Props = EditKey.State & {
  update(event: EditKey.Event): unknown;
  apps: Array<{ slug: string; name: string }>;
};

const KeyCreator: React.FC<Props> = ({
  showAdvancedAddressOptions,
  showAdvancedAddressScopeOptions,
  address,
  addressType,
  addressScope,
  appIdentificationType,
  expiration,
  comment,
  activeStep,
  apps,
  appBundleId,
  appSlug,
  update,
  isNew,
  unlockRequestAddress,
}) => (
  <div className="min-w-[340px] xs:min-w-[475px] sm:min-w-[550px]">
    <AddressStep
      mode={isNew ? `create` : `edit`}
      update={update}
      activeStep={activeStep}
      address={address}
      addressType={addressType}
      showAdvancedAddressOptions={showAdvancedAddressOptions}
      unlockRequestSource={unlockRequestAddress}
    />

    <WebsiteKeyAppScopeStep
      mode={isNew ? `create` : `edit`}
      update={update}
      activeStep={activeStep}
      addressScope={addressScope}
      showAdvancedAddressScopeOptions={showAdvancedAddressScopeOptions}
      appIdentificationType={appIdentificationType}
      apps={apps}
    />

    {addressScope === `singleApp` && (
      <ChooseAppStep
        update={update}
        mode={isNew ? `create` : `edit`}
        activeStep={activeStep}
        appIdentificationType={appIdentificationType}
        apps={apps}
        appBundleId={appBundleId}
        appSlug={appSlug}
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
