import React, { useState } from 'react';
import KeyCreationStep from '../KeyCreationStep';

const KeyCreator: React.FC = () => {
  const [currentStep, setCurrentStep] = useState(3);
  return (
    <div className="">
      <KeyCreationStep
        numSteps={5}
        title={<h1>Step 1</h1>}
        currentStep={currentStep}
        index={1}
      >
        <p>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Repudiandae quaerat
        </p>
      </KeyCreationStep>
      <KeyCreationStep
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
