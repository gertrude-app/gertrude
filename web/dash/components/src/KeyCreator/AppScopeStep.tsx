import React from 'react';
import { EditKey } from '@dash/keys';
import { Label } from '@shared/components';
import { SelectableListItem } from '../Forms';
import GradientIcon from '../GradientIcon';
import UserInputText from '../UserInputText';
import KeyCreationStep from './KeyCreationStep';

interface Props {
  mode: 'edit' | 'create';
  activeStep: EditKey.Step;
  appScope: 'unrestricted' | 'address';
  update(event: EditKey.Event): unknown;
}

const AppScopeStep: React.FC<Props> = ({ mode, update, activeStep, appScope }) => (
  <KeyCreationStep
    mode={mode}
    update={update}
    lookaheadTitle="Select app internet access"
    activeTitle="Select app internet access"
    title={
      <h2 className="font-medium text-slate-900 text-lg space-x-2 flex items-center">
        <GradientIcon
          icon={appScope === `unrestricted` ? `unlock` : `location`}
          size="small"
          className="mr-2"
        />
        {appScope === `unrestricted` ? (
          <span className="flex items-center space-x-2">
            <UserInputText>Unrestricted</UserInputText>
            <span>
              internet <span className="hidden sm:inline">access</span>
            </span>
          </span>
        ) : (
          <span>
            To access <UserInputText>one address</UserInputText>
          </span>
        )}
      </h2>
    }
    ownStep={EditKey.Step.AppKey_SetAppScope}
    activeStep={activeStep}
  >
    <Label>Key grants application:</Label>
    <div className="space-y-0.5 mt-3">
      <SelectableListItem
        title="Unrestricted internet access"
        description="Allows this app unrestricted network requests. Only for narrowly-focused apps that you trust."
        selected={appScope === `unrestricted`}
        onClick={() => update({ type: `setAppScope`, to: `unrestricted` })}
        badges={[{ text: `Most common`, color: `green` }]}
      />
      <SelectableListItem
        title="Access to a specific address"
        description="Allow this application to access a specific address."
        selected={appScope === `address`}
        onClick={() => update({ type: `setAppScope`, to: `address` })}
        badges={[
          { text: `Most safe`, color: `green` },
          { text: `Advanced`, color: `yellow` },
        ]}
      />
    </div>
  </KeyCreationStep>
);

export default AppScopeStep;
