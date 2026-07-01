import { Button } from '@shared/components';
import { posessive } from '@shared/string';
import React from 'react';
import LightPlanTeaser from './LightPlanTeaser';
import ScreenHeader from './ScreenHeader';

export type PodcastsDoneVariant = `active` | `approachingExpiry` | `notEntitled`;

const PodcastsDoneScreen: React.FC<{
  childName: string;
  modelName: string;
  iosVersion: string;
  variant: PodcastsDoneVariant;
  accessEndsAt?: string;
  trialDaysRemaining?: number;
  showSubscribe?: boolean;
  onBackToDashboard: () => void;
  onSubscribe: () => void;
  onMaybeLater: () => void;
}> = (props) => {
  const deviceType = props.modelName.toLowerCase().includes(`ipad`) ? `iPad` : `iPhone`;
  if (props.variant === `notEntitled`) {
    return (
      <PodcastsDoneNotEntitled
        childName={props.childName}
        deviceType={deviceType}
        onSubscribe={props.onSubscribe}
        onMaybeLater={props.onMaybeLater}
      />
    );
  }
  if (props.variant === `approachingExpiry`) {
    return (
      <PodcastsDoneApproachingExpiry
        childName={props.childName}
        deviceType={deviceType}
        accessEndsAt={props.accessEndsAt ?? `soon`}
        onBackToDashboard={props.onBackToDashboard}
        onSubscribe={props.onSubscribe}
      />
    );
  }
  return (
    <PodcastsDoneActive
      childName={props.childName}
      deviceType={deviceType}
      trialDaysRemaining={props.trialDaysRemaining}
      showSubscribe={props.showSubscribe}
      onBackToDashboard={props.onBackToDashboard}
      onSubscribe={props.onSubscribe}
    />
  );
};

export default PodcastsDoneScreen;

const PodcastsDoneNotEntitled: React.FC<{
  childName: string;
  deviceType: string;
  onSubscribe: () => void;
  onMaybeLater: () => void;
}> = ({ childName, deviceType, onSubscribe, onMaybeLater }) => (
  <div>
    <ScreenHeader
      icon="hourglass-end"
      title="Your free trial has ended"
      subtitle={`${posessive(childName)} ${deviceType}`}
    />

    <p className="text-slate-600 mb-5">
      To keep Gertrude Podcasts working on {posessive(childName)} {deviceType}, your
      Gertrude account needs a <b>Light subscription</b>.
    </p>

    <LightPlanTeaser
      className="mb-6"
      priceSize="emphasized"
      extraBullets={[`Includes Gertrude Blocker (iOS supervision) at no extra cost`]}
    />

    <div className="flex justify-end items-center gap-3">
      <Button type="button" color="secondary" onClick={onMaybeLater}>
        Maybe later
      </Button>
      <Button type="button" color="primary" onClick={onSubscribe}>
        Subscribe &rarr;
      </Button>
    </div>
  </div>
);

const PodcastsDoneApproachingExpiry: React.FC<{
  childName: string;
  deviceType: string;
  accessEndsAt: string;
  onBackToDashboard: () => void;
  onSubscribe: () => void;
}> = ({ childName, deviceType, accessEndsAt, onBackToDashboard, onSubscribe }) => (
  <div>
    <ScreenHeader
      icon="hourglass-half"
      title={`${deviceType} connected`}
      subtitle={`${posessive(childName)} ${deviceType}`}
    />

    <p className="text-slate-600 mb-5">
      Gertrude Podcasts is now active on {posessive(childName)} {deviceType}.
    </p>

    <div className="mb-4 rounded-xl border border-amber-200 bg-amber-50 px-5 py-4">
      <p className="text-amber-900 font-semibold">Access ends {accessEndsAt}</p>
      <p className="text-amber-800/90 text-sm mt-1">
        Subscribe to <b>Gertrude Light</b> to keep Gertrude Podcasts going past that date.
      </p>
    </div>

    <LightPlanTeaser
      className="mb-6"
      priceSize="normal"
      extraBullets={[`Includes Gertrude Blocker (iOS supervision) at no extra cost`]}
    />

    <div className="flex justify-end items-center gap-3">
      <Button type="button" color="secondary" onClick={onBackToDashboard}>
        Back to Dashboard
      </Button>
      <Button type="button" color="primary" onClick={onSubscribe}>
        Subscribe to Light &rarr;
      </Button>
    </div>
  </div>
);

const PodcastsDoneActive: React.FC<{
  childName: string;
  deviceType: string;
  trialDaysRemaining?: number;
  showSubscribe?: boolean;
  onBackToDashboard: () => void;
  onSubscribe: () => void;
}> = ({
  childName,
  deviceType,
  trialDaysRemaining,
  showSubscribe,
  onBackToDashboard,
  onSubscribe,
}) => (
  <div>
    <ScreenHeader
      icon="check"
      title={`${deviceType} connected`}
      subtitle={`${posessive(childName)} ${deviceType}`}
    />

    <p className="text-slate-600 mb-5">
      Gertrude Podcasts is now active on {posessive(childName)} {deviceType}.
    </p>

    {trialDaysRemaining !== undefined && (
      <div className="mb-6 rounded-xl border border-slate-200 bg-slate-50 px-5 py-4">
        <p className="text-slate-800 font-semibold">
          You have {trialDaysRemaining} days of free trial.
        </p>
        <p className="text-slate-600 text-sm mt-1">
          Subscribe to <b>Gertrude Light</b> any time to keep Gertrude Podcasts going
          after your trial ends — no waiting for the deadline.
        </p>
      </div>
    )}

    <div className="flex justify-end items-center gap-3">
      {showSubscribe && (
        <Button type="button" color="secondary" onClick={onSubscribe}>
          Subscribe to Light &rarr;
        </Button>
      )}
      <Button type="button" color="primary" onClick={onBackToDashboard}>
        Back to Dashboard
      </Button>
    </div>
  </div>
);
