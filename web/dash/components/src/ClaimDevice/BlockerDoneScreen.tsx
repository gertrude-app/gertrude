import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import React from 'react';
import ScreenHeader from './ScreenHeader';

const BlockerDoneScreen: React.FC<{
  childName: string;
  modelName: string;
  iosVersion: string;
  onManageSettings: () => void;
}> = (props) => {
  const deviceType = props.modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;
  return (
    <div>
      <ScreenHeader
        icon="shield-halved"
        title={`${deviceType} connected`}
        subtitle={`${posessive(props.childName)} ${deviceType} · iOS ${props.iosVersion}`}
      />

      <p className="text-slate-600 mb-5">
        Gertrude Blocker is now installed on {posessive(props.childName)} {deviceType}.
      </p>

      <div className="mb-6 rounded-xl border border-violet-100 bg-violet-50 px-5 py-4">
        <p className="text-violet-900 font-semibold">
          Manage what&rsquo;s blocked from the settings screen.
        </p>
      </div>

      <div className="flex justify-end">
        <Button type="button" color="primary" onClick={props.onManageSettings}>
          {deviceType} settings
        </Button>
      </div>
    </div>
  );
};

export default BlockerDoneScreen;
