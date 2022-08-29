import React, { useState } from 'react';
import KeyCreationStep from '../KeyCreationStep';
import cx from 'classnames';

interface Props {
  mode: 'create' | 'edit';
}

const KeyCreator: React.FC<Props> = ({ mode }) => {
  const [currentStep, setCurrentStep] = useState(3);
  const [keyType, setKeyType] = useState<'website' | 'app'>('website');
  return (
    <div className="">
      <KeyCreationStep
        stepName="Select key type"
        numSteps={5}
        title={
          <h1 className="font-medium text-gray-900">
            <i
              className={cx(
                'fa mr-2 bg-gradient-to-br from-indigo-500 to-fuchsia-500 bg-clip-text [-webkit-background-clip:text;] text-transparent',
                keyType === 'website' ? 'fa-globe' : 'fa-browser',
              )}
            />
            <span className="capitalize">{keyType}</span> key
          </h1>
        }
        currentStep={currentStep}
        index={1}
      >
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Repudiandae quaerat
        </p>
      </KeyCreationStep>
      <KeyCreationStep
        stepName="Select address type"
        numSteps={5}
        title={<h1>Step 2</h1>}
        currentStep={currentStep}
        index={2}
      >
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Repudiandae quaerat
        </p>
      </KeyCreationStep>
      <KeyCreationStep
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
