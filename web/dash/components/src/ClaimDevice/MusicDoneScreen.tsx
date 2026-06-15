import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import React from 'react';
import ScreenHeader from './ScreenHeader';

const MusicDoneScreen: React.FC<{
  childName: string;
  modelName: string;
  iosVersion: string;
  onBackToDashboard: () => void;
}> = (props) => {
  const deviceType = props.modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;
  return (
    <div>
      <ScreenHeader
        icon="music"
        title={`${deviceType} connected`}
        subtitle={`${posessive(props.childName)} ${deviceType} · iOS ${props.iosVersion}`}
      />

      <p className="text-slate-600 mb-5">
        Gertrude Music is now connected on {posessive(props.childName)} {deviceType}.
      </p>

      <div className="mb-6 rounded-xl border border-violet-100 bg-violet-50 px-5 py-4">
        <p className="text-violet-900 font-semibold">
          Approved music will appear in the Music app.
        </p>
        <p className="text-violet-800/90 text-sm mt-1">
          If {props.childName} still sees the claim code, open Gertrude Music again and it
          should finish connecting.
        </p>
      </div>

      <div className="flex justify-end">
        <Button type="button" color="primary" onClick={props.onBackToDashboard}>
          Back to Dashboard
        </Button>
      </div>
    </div>
  );
};

export default MusicDoneScreen;
