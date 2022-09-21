import React from 'react';
import SelectMenu from '../../../SelectMenu';
import TextInput from '../../../TextInput';
import Toggle from '../../../Toggle';
import KeyCreationStep from '../KeyCreationStep';
import SubdomainDemo from './SubdomainDemo';
import GradientIcon from './GradientIcon';
import UserInputText from './UserInputText';

interface Props {
  keyType: 'app' | 'website';
  mode: 'edit' | 'create';
  currentStepIndex: number;
  address: string;
  addressType: 'strict' | 'standard' | 'ip' | 'domainRegex';
  showAdvancedAddressOptions: boolean;
  update(event: EditKey.Event): unknown;
}

const AddressStep: React.FC<Props> = ({
  mode,
  keyType,
  currentStepIndex,
  address,
  addressType,
  showAdvancedAddressOptions,
  update,
}) => (
  <KeyCreationStep
    mode={mode}
    update={update}
    // TODO? necessry?
    setCurrentStep={() => {}}
    lookaheadTitle="Website address"
    activeTitle="Select website address:"
    title={
      <h2 className="font-medium text-gray-900 text-lg">
        <GradientIcon icon="unlock" className="mr-2" />
        {keyType === `website` ? `Unlocking ` : `Address `}
        {address.trim() !== `` && <UserInputText>{address}</UserInputText>}
      </h2>
    }
    currentStep={currentStepIndex}
    canAdvance={address.trim() !== ``}
    index={keyType === `website` ? 2 : 7}
  >
    <TextInput
      type="text"
      label="Web address:"
      value={address}
      setValue={(updated) => update({ set: `address`, to: updated })}
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
            update({ set: `showAdvancedAddressOptions`, to: enabled })
          }
        />
      </div>
      <div className="flex items-center justify-end">
        <label className="mr-2 text-gray-600 font-medium">Address type:</label>
        <SelectMenu<EditKey.AddressType>
          options={
            [
              { value: `standard`, display: `Standard` },
              { value: `strict`, display: `Strict` },
              {
                value: showAdvancedAddressOptions && `IP address`,
                display: `IP address`,
              },
              {
                value: showAdvancedAddressOptions && `regular expression`,
                display: `Regular expression`,
              },
            ].filter((x) => typeof x.value === `string`) as {
              value: EditKey.AddressType;
              display: string;
            }[]
          }
          selectedOption={addressType}
          setSelected={(type) => update({ set: `addressType`, to: type })}
          deemphasized
        />
      </div>
      <SubdomainDemo address={address} addressType={addressType} />
    </div>
  </KeyCreationStep>
);

export default AddressStep;
