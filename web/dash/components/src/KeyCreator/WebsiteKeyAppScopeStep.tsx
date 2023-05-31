import React from 'react';
import { EditKey } from '@dash/keys';
import { Toggle } from '@shared/components';
import { SelectableListItem } from '../Forms';
import UserInputText from '../UserInputText';
import GradientIcon from '../GradientIcon';
import KeyCreationStep from './KeyCreationStep';

interface Props {
  mode: 'edit' | 'create';
  activeStep: EditKey.Step;
  addressScope: 'webBrowsers' | 'unrestricted' | 'singleApp';
  showAdvancedAddressScopeOptions: boolean;
  appIdentificationType: 'bundleId' | 'slug';
  apps: Array<{ slug: string; name: string }>;
  update(event: EditKey.Event): unknown;
}

const WebsiteKeyAppScopeStep: React.FC<Props> = ({
  mode,
  activeStep,
  showAdvancedAddressScopeOptions,
  addressScope,
  update,
}) => (
  <KeyCreationStep
    mode={mode}
    update={update}
    activeTitle="Select affected apps:"
    lookaheadTitle="Affected apps"
    title={
      <h2 className="font-medium text-slate-900 text-lg flex items-center space-x-2">
        <Title addressScope={addressScope} />
      </h2>
    }
    activeStep={activeStep}
    ownStep={EditKey.Step.WebsiteKey_SetAppScope}
    canAdvance
  >
    <div>
      <h2 className="font-medium">Unlocked for:</h2>
      <div className="flex justify-end mr-2 items-center">
        <label className="mr-2 text-slate-600">Advanced:</label>
        <Toggle
          enabled={showAdvancedAddressScopeOptions}
          small
          setEnabled={(enabled) =>
            update({ type: `setShowAdvancedAddressScopeOptions`, to: enabled })
          }
        />
      </div>
      <div className="mt-3 space-y-0.5">
        <SelectableListItem
          title={`Web browsers`}
          description={`Applies to all browsers, like Chrome, Safari, Firefox, etc.`}
          selected={addressScope === `webBrowsers`}
          onClick={() => update({ type: `setAddressScope`, to: `webBrowsers` })}
          badges={[{ text: `Most common`, color: `green` }]}
        />
        <SelectableListItem
          title="All apps"
          description="Permits access for every app (including browsers). Use for sites you're sure you trust."
          selected={addressScope === `unrestricted`}
          onClick={() => update({ type: `setAddressScope`, to: `unrestricted` })}
        />
        {showAdvancedAddressScopeOptions && (
          <SelectableListItem
            title="Single app"
            description="Unlock this site for one specific app you choose."
            selected={addressScope === `singleApp`}
            onClick={() => update({ type: `setAddressScope`, to: `singleApp` })}
            badges={[
              { text: `Most safe`, color: `green` },
              { text: `Advanced`, color: `yellow` },
            ]}
          />
        )}
      </div>
    </div>
  </KeyCreationStep>
);

export default WebsiteKeyAppScopeStep;

const Title: React.FC<{
  addressScope: 'webBrowsers' | 'unrestricted' | 'singleApp';
}> = ({ addressScope }) => {
  switch (addressScope) {
    case `webBrowsers`:
      return (
        <>
          <GradientIcon icon="google-chrome" className="mr-2" size="small" />
          <span>For</span>
          <UserInputText>all web browsers</UserInputText>
        </>
      );
    case `unrestricted`:
      return (
        <>
          <GradientIcon icon="lightning-bolt" className="mr-2" size="small" />
          <span>For</span>
          <UserInputText>all apps</UserInputText>
        </>
      );
    case `singleApp`:
      return (
        <>
          <GradientIcon icon="location" className="mr-2" size="small" />
          <span>For</span>
          <UserInputText>a single app</UserInputText>
        </>
      );
  }
};
