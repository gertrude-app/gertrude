import React from 'react';
import { Button } from '@shared/components';
import type { AppEvent, Screen, ViewAction } from '../administrate-store';
import type { FilterState } from '../../lib/shared-types';
import FilterStatusBlock from '../subcomponents/FilterStatusBlock';
import HealthCheckPreviewBlock from '../subcomponents/HealthCheckPreviewBlock';
import AppVersionBlock from '../subcomponents/AppVersionBlock';
import UserBlock from '../subcomponents/UserBlock';

interface Props {
  filterState: FilterState;
  failingChecksCount: number;
  appVersion: string;
  userName: string;
  releaseChannel: 'stable' | 'beta' | 'canary';
  keystrokeMonitoringEnabled: boolean;
  screenshotMonitoringEnabled: boolean;
  filterSuspensionDurationInSeconds: string;
  quitting: boolean;
  setScreen(screen: Screen): void;
  emit(event: AppEvent): unknown;
  dispatch(action: ViewAction): unknown;
}

const HomeScreen: React.FC<Props> = ({
  setScreen,
  filterState,
  failingChecksCount,
  appVersion,
  userName,
  keystrokeMonitoringEnabled,
  screenshotMonitoringEnabled,
  filterSuspensionDurationInSeconds,
  emit,
  dispatch,
  quitting,
  releaseChannel,
}) => (
  <div className="flex flex-col justify-between h-full p-4">
    <div className="flex flex-col space-y-4">
      <div className="flex space-x-4">
        <FilterStatusBlock
          dispatch={dispatch}
          emit={emit}
          filterState={filterState}
          filterSuspensionDurationInSeconds={filterSuspensionDurationInSeconds}
        />
        <HealthCheckPreviewBlock
          failingChecksCount={failingChecksCount}
          setScreen={setScreen}
        />
      </div>
      <AppVersionBlock
        releaseChannel={releaseChannel}
        emit={emit}
        appVersion={appVersion}
      />
      <UserBlock
        emit={emit}
        keystrokeMonitoringEnabled={keystrokeMonitoringEnabled}
        screenshotMonitoringEnabled={screenshotMonitoringEnabled}
        userName={userName}
      />
    </div>
    <footer className="mt-4 flex justify-between items-end">
      <div />
      {/* TODO: <DebugButton /> */}
      <Button
        disabled={quitting}
        type="button"
        onClick={() => emit({ case: `quitAppClicked` })}
        color="warning"
      >
        {quitting ? `Quitting...` : `Quit app`}
      </Button>
    </footer>
  </div>
);

export default HomeScreen;
