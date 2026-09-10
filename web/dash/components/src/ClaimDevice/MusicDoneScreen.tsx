import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import React from 'react';
import TrialStatusCard, { MusicTrialStatusCard } from '../TrialStatusCard';
import ScreenHeader from './ScreenHeader';

type MusicSubscription =
  { case: `active` } | { case: `trial`; expiresAt: string } | { case: `unavailable` };

const MusicDoneScreen: React.FC<{
  childName: string;
  modelName: string;
  iosVersion: string;
  subscription?: MusicSubscription;
  onManageSettings: () => void;
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

      {props.subscription === undefined && (
        <MusicTrialStatusCard
          status="ready"
          deviceLabel={`${posessive(props.childName)} ${deviceType}`}
          className="mb-6"
        />
      )}

      {props.subscription?.case === `trial` && (
        <MusicTrialStatusCard
          status="active"
          expiresAt={props.subscription.expiresAt}
          className="mb-6"
        />
      )}

      {props.subscription?.case === `unavailable` && (
        <TrialStatusCard className="mb-6" heading="Gertrude Music Needs Attention">
          Gertrude Music isn&rsquo;t currently available on {posessive(props.childName)}
          {` `}
          {deviceType}. Review your plan or billing details to restore access.
        </TrialStatusCard>
      )}

      <div className="mb-6 rounded-xl border border-violet-100 bg-violet-50 px-5 py-4">
        <p className="text-violet-900">
          If {props.childName} still sees the claim code, open Gertrude Music again and it
          should finish connecting.
        </p>
      </div>

      <div className="flex justify-end items-center gap-3">
        {props.subscription?.case === `unavailable` && (
          <Button type="link" to="/settings" color="secondary">
            Manage plan
          </Button>
        )}
        <Button type="button" color="primary" onClick={props.onManageSettings}>
          {deviceType} settings
        </Button>
      </div>
    </div>
  );
};

export default MusicDoneScreen;
