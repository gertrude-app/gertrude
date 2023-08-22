import React from 'react';
import { Button } from '@shared/components';
import type { AppEvent } from '../administrate-store';

interface Props {
  appVersion: string;
  releaseChannel: 'stable' | 'beta' | 'canary';
  emit(event: AppEvent): unknown;
}

const AppVersionBlock: React.FC<Props> = ({ appVersion, emit }) => (
  <div className="p-4 bg-slate-50 dark:bg-black/10 rounded-xl">
    <h3 className="font-semibold text-xl text-slate-600 dark:text-slate-400">
      Running version{` `}
      <span className="font-black text-violet-700 dark:text-violet-400">
        {appVersion}
      </span>
      {` `}
      of Gertrude
    </h3>
    <div className="flex justify-between mt-4">
      <div className="flex space-x-4">
        <Button
          type="button"
          onClick={() => emit({ case: `checkForAppUpdatesClicked` })}
          color="secondary"
          size="small"
        >
          Check for updates
        </Button>
      </div>
      <Button
        type="button"
        onClick={() => emit({ case: `reinstallAppClicked` })}
        color="tertiary"
        size="small"
      >
        Reinstall
      </Button>
    </div>
  </div>
);

export default AppVersionBlock;
