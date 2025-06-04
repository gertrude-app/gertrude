import React from 'react';
import { EditKey } from '@dash/keys';
import { capitalize } from '@shared/string';
import GradientIcon from '../GradientIcon';
import UserInputText from '../UserInputText';
import KeyCreationStep from './KeyCreationStep';
import KeyTypeOption from './KeyTypeOption';

interface Props {
  mode: `create` | `edit`;
  keyType?: `website` | `app`;
  activeStep: EditKey.Step;
  update(event: EditKey.Event): unknown;
}

const KeyTypeStep: React.FC<Props> = ({ mode, keyType, activeStep, update }) => (
  <KeyCreationStep
    mode={mode}
    activeTitle="Select key type:"
    lookaheadTitle=""
    canAdvance={!!keyType}
    title={
      <h1 className="font-medium text-slate-900 text-lg flex items-center space-x-2">
        <GradientIcon
          icon={keyType === `app` ? `window` : `globe`}
          className="mr-2"
          size="small"
        />
        <UserInputText>{capitalize(keyType ?? `website`)}</UserInputText>
        <span>key</span>
      </h1>
    }
    ownStep={EditKey.Step.SetKeyType}
    activeStep={activeStep}
    update={update}
  >
    <div className="flex flex-col sm:flex-row -mt-4">
      <KeyTypeOption
        icon="globe"
        selected={keyType === `website`}
        onClick={() => update({ type: `setKeyType`, to: `website` })}
        title="Website key"
        description="Grant access to a specific website"
        className="sm:w-1/2 sm:mr-2 mb-3 sm:mb-0"
      />
      <KeyTypeOption
        icon="hamburger"
        selected={keyType === `app`}
        onClick={() => update({ type: `setKeyType`, to: `app` })}
        title="App key"
        description="Grant access to a specific mac application"
        className="sm:w-1/2 sm:ml-2"
      />
    </div>
  </KeyCreationStep>
);

export default KeyTypeStep;
