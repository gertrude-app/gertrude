import { Button } from '@shared/components';
import React from 'react';
import type { TeaserPlan } from './PlanTeaser';
import PlanTeaser from './PlanTeaser';
import ScreenHeader from './ScreenHeader';

const PlanGateScreen: React.FC<{
  icon: string;
  title?: string;
  subtitle?: string;
  message: React.ReactNode;
  plan?: TeaserPlan;
  extraBullets?: string[];
  priceSize?: `normal` | `emphasized`;
  checkoutCancelled?: boolean;
  error?: string;
  primaryLabel: string;
  isWorking?: boolean;
  onPrimary: () => void;
  secondary?: {
    label: string;
    onClick: () => void;
  };
}> = ({
  icon,
  title = `Subscribe to Continue`,
  subtitle,
  message,
  plan,
  extraBullets,
  priceSize,
  checkoutCancelled = false,
  error,
  primaryLabel,
  isWorking = false,
  onPrimary,
  secondary,
}) => (
  <div>
    <ScreenHeader icon={icon} title={title} subtitle={subtitle} />

    <p className="text-slate-600 mb-5">{message}</p>

    <PlanTeaser
      className="mb-6"
      plan={plan}
      priceSize={priceSize}
      extraBullets={extraBullets}
    />

    {checkoutCancelled && (
      <div className="bg-amber-50 border border-amber-200 rounded-lg px-4 py-3 mb-6 text-sm text-amber-700">
        Checkout was cancelled. You can try again when you're ready.
      </div>
    )}

    {error && <p className="mb-4 text-sm text-red-600">{error}</p>}

    <div className="flex justify-end items-center gap-3">
      {secondary && (
        <Button type="button" color="secondary" onClick={secondary.onClick}>
          {secondary.label}
        </Button>
      )}
      <Button type="button" color="primary" onClick={onPrimary} disabled={isWorking}>
        {isWorking ? `Redirecting...` : primaryLabel}
      </Button>
    </div>
  </div>
);

export default PlanGateScreen;
