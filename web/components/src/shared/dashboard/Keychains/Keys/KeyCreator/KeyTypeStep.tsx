import React from 'react';
import { capitalize } from '../../../lib/string';
import KeyCreationStep from '../KeyCreationStep';
import KeyTypeOption from '../KeyTypeOption';
import GradientIcon from './GradientIcon';
import UserInputText from './UserInputText';

interface Props {
  mode: 'create' | 'edit';
  keyType?: 'website' | 'app';
  currentStepIndex: number;
  update(event: EditKey.Event): unknown;
}

const KeyTypeStep: React.FC<Props> = ({ mode, keyType, currentStepIndex, update }) => (
  <KeyCreationStep
    mode={mode}
    setCurrentStep={() => {}}
    activeTitle="Select key type:"
    lookaheadTitle=""
    canAdvance={!!keyType}
    title={
      <h1 className="font-medium text-gray-900 text-lg">
        <GradientIcon icon={keyType === `app` ? `window` : `globe`} className="mr-2" />
        <UserInputText>{capitalize(keyType ?? `website`)}</UserInputText> key
      </h1>
    }
    currentStep={currentStepIndex}
    index={1}
    update={update}
  >
    <div className="flex flex-col sm:flex-row -mt-4">
      <KeyTypeOption
        icon="earth-americas"
        selected={keyType === `website`}
        onClick={() => update({ set: `keyType`, to: `website` })}
        title="Website key"
        description="Grant access to a specific website"
        className="sm:w-1/2 sm:mr-2 mb-3 sm:mb-0"
      />
      <KeyTypeOption
        icon="hamburger"
        selected={keyType === `app`}
        onClick={() => update({ set: `keyType`, to: `app` })}
        title="App key"
        description="Grant access to a specific mac application"
        className="sm:w-1/2 sm:ml-2"
      />
    </div>
  </KeyCreationStep>
);

export default KeyTypeStep;
