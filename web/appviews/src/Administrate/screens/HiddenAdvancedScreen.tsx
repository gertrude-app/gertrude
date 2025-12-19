import { Button, SelectMenu, TextInput, Toggle } from '@shared/components';
import { typesafe } from '@shared/ts-utils';
import React, { useState } from 'react';
import type { AdvancedAction, AdvancedState } from '../administrate-store';

type Props = {
  emit(action: AdvancedAction): unknown;
} & AdvancedState;

// TODO: this whole screen is not great, needs reworked
// @see https://github.com/gertrude-app/project/issues/156
const HiddenAdvancedScreen: React.FC<Props> = ({
  emit,
  pairqlEndpointDefault,
  pairqlEndpointOverride,
  websocketEndpointDefault,
  websocketEndpointOverride,
  appcastEndpointDefault,
  appcastEndpointOverride,
  appVersions,
  webviewDebugging,
}) => {
  const [pqlOverride, setPqlOverride] = useState(pairqlEndpointOverride ?? ``);
  const [wsOverride, setWsOverride] = useState(websocketEndpointOverride ?? ``);
  const [appcastOverride, setAppcastOverride] = useState(appcastEndpointOverride ?? ``);
  const [version, setVersion] = useState(``);
  const versionOptions = appVersions
    ? typesafe
        .objectEntries(appVersions)
        .map(([value, display]) => ({ display, value }))
        .sort((a, b) => b.value.localeCompare(a.value))
    : null;
  return (
    <div className="flex flex-col items-stretch h-full p-6 space-y-5">
      <div className="pb-8 flex justify-between items-start">
        {versionOptions ? (
          <div className="flex space-x-2 items-end">
            <Button
              size="small"
              disabled={version === ``}
              onClick={() =>
                emit({ case: `forceUpdateToSpecificVersionClicked`, version })
              }
              type="button"
              color="tertiary"
            >
              Force update to:
            </Button>
            <SelectMenu
              size="small"
              options={[{ display: `choose version...`, value: `` }, ...versionOptions]}
              selectedOption={version}
              setSelected={setVersion}
            />
          </div>
        ) : (
          <div className="text-gray-400 italic">Loading app versions...</div>
        )}
        <Button
          className="h-12"
          onClick={() => emit({ case: `deleteAllDeviceStorageClicked` })}
          type="button"
          color="warning"
        >
          Purge all device storage
        </Button>
      </div>
      <div className="flex items-end gap-x-2">
        <TextInput
          label="API PairQL endpoint override:"
          type="url"
          value={pqlOverride}
          placeholder={pairqlEndpointDefault}
          setValue={setPqlOverride}
        />
        <Button
          className="h-12"
          disabled={pqlOverride.trim() === ``}
          onClick={() => emit({ case: `pairqlEndpointSet`, url: pqlOverride.trim() })}
          type="button"
          color="secondary"
        >
          Set
        </Button>
        <Button
          className="h-12"
          disabled={pairqlEndpointOverride === undefined}
          onClick={() => emit({ case: `pairqlEndpointSet`, url: undefined })}
          type="button"
          color="secondary"
        >
          Clear
        </Button>
      </div>
      <div className="flex items-end gap-x-2">
        <TextInput
          label="Websocket endpoint override:"
          type="url"
          value={wsOverride}
          placeholder={websocketEndpointDefault}
          setValue={setWsOverride}
        />
        <Button
          className="h-12"
          disabled={wsOverride.trim() === ``}
          onClick={() => emit({ case: `websocketEndpointSet`, url: wsOverride.trim() })}
          type="button"
          color="secondary"
        >
          Set
        </Button>
        <Button
          className="h-12"
          disabled={websocketEndpointOverride === undefined}
          onClick={() => emit({ case: `websocketEndpointSet`, url: undefined })}
          type="button"
          color="secondary"
        >
          Clear
        </Button>
      </div>
      <div className="flex items-end gap-x-2">
        <TextInput
          label="Sparkle Appcast endpoint override:"
          type="url"
          value={appcastOverride}
          placeholder={appcastEndpointDefault}
          setValue={setAppcastOverride}
        />
        <Button
          className="h-12"
          disabled={appcastOverride.trim() === ``}
          onClick={() =>
            emit({ case: `appcastEndpointSet`, url: appcastOverride.trim() })
          }
          type="button"
          color="secondary"
        >
          Set
        </Button>
        <Button
          className="h-12"
          disabled={appcastEndpointOverride === undefined}
          onClick={() => emit({ case: `appcastEndpointSet`, url: undefined })}
          type="button"
          color="secondary"
        >
          Clear
        </Button>
      </div>
      <div className="flex justify-between items-center pt-2">
        <div className="mr-3">
          <h3 className="font-medium text-slate-700 leading-tight">
            Webview debugging enabled:
          </h3>
          <p className="text-slate-500 text-sm mt-1">
            Restart app to debug menu bar, use environment variable for onboarding
          </p>
        </div>
        <Toggle
          enabled={webviewDebugging}
          setEnabled={(enabled) => emit({ case: `setWebviewDebugging`, enabled })}
        />
      </div>
    </div>
  );
};

export default HiddenAdvancedScreen;
