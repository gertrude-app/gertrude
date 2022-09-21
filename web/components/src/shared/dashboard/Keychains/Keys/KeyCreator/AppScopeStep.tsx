import React from 'react';
import SelectableListItem from '../../../SelectableListItem';
import Label from '../../../TextInput/Label';
import KeyCreationStep from '../KeyCreationStep';
import GradientIcon from './GradientIcon';
import UserInputText from './UserInputText';

interface Props {
  mode: 'edit' | 'create';
  currentStepIndex: number;
  appScope: 'unrestricted' | 'address';
  update(event: EditKey.Event): unknown;
}

const AppScopeStep: React.FC<Props> = ({ mode, update, currentStepIndex, appScope }) => {
  return (
    <KeyCreationStep
      mode={mode}
      update={update}
      setCurrentStep={() => {}}
      lookaheadTitle="Select app internet access"
      activeTitle="Select app internet access"
      title={
        <h2 className="font-medium text-gray-900 text-lg space-x-2">
          <GradientIcon icon={appScope === `unrestricted` ? `unlock` : `location`} />
          {appScope === `unrestricted` ? (
            <span>
              <UserInputText>Unrestricted</UserInputText> internet{` `}
              <span className="hidden sm:inline">access</span>
            </span>
          ) : (
            <span>
              To access <UserInputText>one address</UserInputText>
            </span>
          )}
        </h2>
      }
      currentStep={currentStepIndex}
      index={6}
    >
      <Label>Key grants application:</Label>
      <div className="space-y-0.5 mt-3">
        <SelectableListItem
          title="Unrestricted internet access"
          description="Allows this app unrestricted network requests. Only for narrowly-focused apps that you trust."
          selected={appScope === `unrestricted`}
          onClick={() => update({ set: `appScope`, to: `unrestricted` })}
          badges={[{ text: `Most common`, color: `green` }]}
        />
        <SelectableListItem
          title="Access to a specific address"
          description="Allow this application to access a specific address."
          selected={appScope === `address`}
          onClick={() => update({ set: `appScope`, to: `address` })}
          badges={[
            { text: `Most safe`, color: `green` },
            { text: `Advanced`, color: `yellow` },
          ]}
        />
      </div>
    </KeyCreationStep>
  );
};

export default AppScopeStep;
