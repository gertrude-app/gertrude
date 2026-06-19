import { Badge, Button } from '@shared/components';
import cx from 'classnames';
import React, { useEffect, useState } from 'react';
import type {
  GetSubscriptionPanel_v2,
  PlanStatus,
  SubscriptionPanelAction,
} from '@dash/types';
import * as copy from './SubscriptionPanelCopy';

interface Props extends GetSubscriptionPanel_v2.Output {
  onAction(action: SubscriptionPanelAction): unknown;
  pendingAction?: SubscriptionPanelAction;
  className?: string;
}

type View = `resting` | `manage` | `compare`;

const SubscriptionPanel: React.FC<Props> = (props) => {
  const { planStatus, primary, secondary, onAction, pendingAction, className } = props;
  const [view, setView] = useState<View>(`resting`);
  const isPending = pendingAction !== undefined;

  useEffect(() => {
    setView(`resting`);
  }, [planStatus.case]);

  const cardClasses = cx(
    `relative p-6 bg-slate-100 rounded-xl border border-slate-200 flex flex-col h-full`,
    className,
  );

  if (view === `compare`) {
    return (
      <div className={cardClasses}>
        <h2 className="font-bold text-xl text-slate-700 leading-tight mb-5">
          Compare plans
        </h2>
        <PlanComparison currentPlan={currentPlan(planStatus)} />
        <SubViewFooter onBack={() => setView(`manage`)} />
      </div>
    );
  }

  if (view === `manage`) {
    const actions = primary ? [primary, ...secondary] : secondary;
    const blurb = copy.manageBlurb(props);
    return (
      <div className={cardClasses}>
        <h2
          className={cx(
            `font-bold text-xl text-slate-700 leading-tight`,
            blurb ? `mb-2` : `mb-5`,
          )}
        >
          Manage plan
        </h2>
        {blurb && <p className="text-slate-500 text-sm leading-snug mb-5">{blurb}</p>}
        <div className="flex flex-col gap-2 px-2">
          {actions.map((action, i) => (
            <Button
              key={`${action.case}-${i}`}
              type="button"
              color={i === 0 && primary ? `primary` : `secondary`}
              size="medium"
              fullWidth
              disabled={isPending}
              onClick={() => onAction(action)}
            >
              {copy.actionLabel(action, props)}
            </Button>
          ))}
        </div>
        <SubViewFooter
          onBack={() => setView(`resting`)}
          onCompare={() => setView(`compare`)}
        />
      </div>
    );
  }

  const badge = copy.badge(props);
  const manageLabel = copy.managePlanText(props);
  return (
    <div className={cardClasses}>
      <Badge type={badge.type} size="large" className="absolute right-3 top-3 border">
        {badge.text}
      </Badge>
      <h2 className="font-bold text-xl text-slate-700 leading-tight pr-28">
        {copy.title(props)}
      </h2>
      <p className="text-slate-500 text-sm leading-snug mt-2">{copy.subtext(props)}</p>
      {manageLabel && (
        <button
          type="button"
          className="mt-3 text-sm cursor-pointer text-blue-700/80 hover:text-blue-800 transition-colors self-start text-left"
          onClick={() => setView(`manage`)}
        >
          {manageLabel}
        </button>
      )}
    </div>
  );
};

const SubViewFooter: React.FC<{ onBack(): void; onCompare?(): void }> = ({
  onBack,
  onCompare,
}) => (
  <div className="mt-auto pt-5 flex items-center justify-between">
    <button
      type="button"
      className="text-sm cursor-pointer text-blue-700/80 hover:text-blue-800 transition-colors"
      onClick={onBack}
    >
      ← Back
    </button>
    {onCompare && (
      <button
        type="button"
        className="text-sm cursor-pointer text-blue-700/80 hover:text-blue-800 transition-colors"
        onClick={onCompare}
      >
        About plans...
      </button>
    )}
  </div>
);

export default SubscriptionPanel;

// — compare view —

type CurrentPlan = `free` | `light` | `full`;

function currentPlan(planStatus: PlanStatus): CurrentPlan {
  switch (planStatus.case) {
    case `free`:
      return `free`;
    case `light`:
      return `light`;
    case `full`:
    case `complimentary`:
    case `fullTrial`:
    case `fullTrialGrace`:
      return `full`;
  }
}

const PLAN_FEATURES: Record<CurrentPlan, { name: string; features: string[] }> = {
  free: {
    name: `Free`,
    features: [
      `Protect iPhones and iPads for kids under 18 with the Gertrude iOS app`,
      // `Control blocking from the Gertrude parents website`,
    ],
  },
  light: {
    name: `Light`,
    features: [
      `Everything in Free`,
      `Supervise and protect iPhones and iPads for adults 18+ with the Gertrude iOS app`,
      `Enable additional supervision-only restrictions`,
    ],
  },
  full: {
    name: `Full`,
    features: [
      `Everything in Light`,
      `Full Mac app protection for the whole family, including internet filtering, screenshots, app blocking, downtime, and more.`,
    ],
  },
};

const PlanComparison: React.FC<{ currentPlan: CurrentPlan }> = ({ currentPlan: cur }) => (
  <div className="flex flex-col gap-4">
    {(Object.keys(PLAN_FEATURES) as CurrentPlan[]).map((tier) => {
      const { name, features } = PLAN_FEATURES[tier];
      const isCurrent = tier === cur;
      return (
        <div key={tier}>
          <div className="flex items-center gap-2">
            <h3 className="font-semibold text-slate-800">{name}</h3>
            {isCurrent && (
              <Badge type="info" size="small" className="uppercase tracking-wide">
                Current
              </Badge>
            )}
          </div>
          <ul className="mt-1 space-y-0.5 text-sm text-slate-600">
            {features.map((f) => (
              <li key={f} className="flex gap-2">
                <span className="text-slate-400 select-none">•</span>
                <span>{f}</span>
              </li>
            ))}
          </ul>
        </div>
      );
    })}
  </div>
);
