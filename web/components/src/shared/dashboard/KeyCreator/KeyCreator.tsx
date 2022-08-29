import React, { useState } from 'react';
import KeyCreationStep from '../KeyCreationStep';
import cx from 'classnames';
import KeyTypeOption from '../KeyTypeOption';
import TextInput from '../TextInput';

interface Props {
  mode: 'create' | 'edit';
}

const KeyCreator: React.FC<Props> = ({ mode }) => {
  const [currentStep, setCurrentStep] = useState(1);
  const [keyType, setKeyType] = useState<'website' | 'app'>(`website`);
  const [addressType, setAddressType] = useState<
    'standard' | 'strict' | 'regular expression' | 'IP address'
  >(`standard`);
  const [address, setAddress] = useState(`khanacademy.org`);

  return (
    <div className="">
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Select key type"
        numSteps={5}
        title={
          <h1 className="font-medium text-gray-900 text-lg">
            <i
              className={cx(
                `fa-solid mr-2 bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text;] text-transparent`,
                keyType === `website` ? `fa-earth-americas` : `fa-hamburger`,
              )}
            />
            <span className="capitalize">{keyType}</span> key
          </h1>
        }
        currentStep={currentStep}
        index={1}
      >
        <div className="flex flex-col sm:flex-row">
          <KeyTypeOption
            icon={`earth-americas`}
            selected={keyType === `website`}
            onClick={() => setKeyType(`website`)}
            title="Website key"
            description="Grant access to a specific website"
            className="sm:w-1/2 sm:mr-2 mb-3 sm:mb-0"
          />
          <KeyTypeOption
            icon={`hamburger`}
            selected={keyType === `app`}
            onClick={() => setKeyType(`app`)}
            title="App key"
            description="Grant access to a specific mac application"
            className="sm:w-1/2 sm:ml-2"
          />
        </div>
      </KeyCreationStep>
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Select address type"
        numSteps={5}
        title={
          <h2 className="font-medium text-gray-900 text-lg">
            <span className="capitalize">{addressType}</span> address:{` `}
            <span className="font-mono bg-violet-100 py-1 px-3 rounded-lg border-b-2 border-violet-200 text-base font-medium">
              {address}
            </span>
          </h2>
        }
        currentStep={currentStep}
        index={2}
      >
        <TextInput
          type={'text'}
          label={'Web address:'}
          value={address}
          setValue={setAddress}
        />
      </KeyCreationStep>
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Select scope"
        numSteps={5}
        title={<h1>Step 3</h1>}
        currentStep={currentStep}
        index={3}
      >
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Repudiandae quaerat
        </p>
      </KeyCreationStep>
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Miscellaneous"
        numSteps={5}
        title={<h1>Step 4</h1>}
        currentStep={currentStep}
        index={4}
      >
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Repudiandae quaerat
        </p>
      </KeyCreationStep>
      <KeyCreationStep
        mode={mode}
        setCurrentStep={setCurrentStep}
        stepName="Summary"
        numSteps={5}
        title={<h1>Step 5</h1>}
        currentStep={currentStep}
        index={5}
      >
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Repudiandae quaerat
        </p>
      </KeyCreationStep>
    </div>
  );
};

export default KeyCreator;
