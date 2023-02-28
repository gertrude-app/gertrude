import React from 'react';
import { EditKey, validate } from '@dash/keys';
import { Label, TextInput, Toggle } from '@shared/components';
import { SelectMenu } from '../Forms';
import GradientIcon from '../GradientIcon';
import UserInputText from '../UserInputText';
import KeyCreationStep from './KeyCreationStep';
import AddressTypeHint from './AddressTypeHint';

interface Props {
  keyType: 'app' | 'website';
  mode: 'edit' | 'create';
  activeStep: EditKey.Step;
  address: string;
  addressType: 'strict' | 'standard' | 'ip' | 'domainRegex';
  showAdvancedAddressOptions: boolean;
  unlockRequestSource?: string;
  update(event: EditKey.Event): unknown;
}

const AddressStep: React.FC<Props> = ({
  mode,
  keyType,
  activeStep,
  address,
  addressType,
  showAdvancedAddressOptions,
  update,
  unlockRequestSource,
}) => (
  <KeyCreationStep
    mode={mode}
    update={update}
    lookaheadTitle="Website address"
    activeTitle="Select website address:"
    title={
      <h2 className="font-medium text-gray-900 text-lg max-w-[calc(100%-25px)] overflow-hidden">
        <GradientIcon icon="unlock" className="mr-2" size="small" />
        {keyType === `website` ? `Unlocking ` : `Address `}
        {address.trim() !== `` && <UserInputText>{address}</UserInputText>}
      </h2>
    }
    ownStep={
      keyType === `website`
        ? EditKey.Step.WebsiteKey_SetAddress
        : EditKey.Step.AppKey_Advanced_SetAddress
    }
    activeStep={activeStep}
    canAdvance={validate.address(address, addressType)}
  >
    {unlockRequestSource && (
      <div className="-mt-4 mb-3" data-test="unlock-request-src">
        <Label>For blocked request: </Label>
        <UserInputText small>{unlockRequestSource}</UserInputText>
      </div>
    )}
    <TextInput
      // force a re-render when changing type w/ unlock request
      // present so we can programatically update the value to
      // include or exclude the subdomain from the request,
      // discarding what the TextInput already has in local state
      key={unlockRequestSource ? addressType : `key-address`}
      type="url"
      testId="key-address"
      label="Web address:"
      value={address}
      setValue={(updated) => update({ type: `setAddress`, to: updated })}
      prefix="https://"
      className="mb-7"
    />
    <div className="bg-gray-50 px-2 py-4 rounded-lg">
      <div className="flex justify-start mr-2 items-center ml-2 mb-2">
        <label className="mr-2 text-gray-600">Advanced:</label>
        <Toggle
          enabled={showAdvancedAddressOptions}
          small
          setEnabled={(enabled) =>
            update({ type: `setShowAdvancedAddressOptions`, to: enabled })
          }
        />
      </div>
      <div className="flex items-center justify-end">
        <label className="mr-2 text-gray-600 font-medium">Address type:</label>
        <SelectMenu<EditKey.AddressType>
          testId="address-type"
          options={addressTypeOptions(showAdvancedAddressOptions)}
          selectedOption={addressType}
          setSelected={(type) => update({ type: `setAddressType`, to: type })}
          deemphasized
        />
      </div>
      <AddressTypeHint address={address} type={addressType} />
    </div>
  </KeyCreationStep>
);

export default AddressStep;

// helpers

function addressTypeOptions(
  showAdvanced: boolean,
): Array<{ value: EditKey.AddressType; display: string }> {
  const opts: ReturnType<typeof addressTypeOptions> = [
    { value: `standard`, display: `Standard` },
    { value: `strict`, display: `Strict` },
  ];

  if (showAdvanced) {
    opts.push({ value: `ip`, display: `IP address` });
    opts.push({ value: `domainRegex`, display: `Regular expression` });
  }

  return opts;
}
