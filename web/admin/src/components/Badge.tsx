import React from 'react';

interface StatusBadgeProps {
  status: string;
  size?: `sm` | `md`;
}

const statusStyles: Record<string, string> = {
  active: `bg-emerald-50 text-emerald-700 ring-emerald-600/20`,
  onboarded: `bg-sky-50 text-sky-700 ring-sky-600/20`,
  no_action: `bg-slate-50 text-slate-400 ring-slate-300/20 opacity-60`,
  unknown: `bg-slate-50 text-slate-600 ring-slate-500/20`,
};

const statusLabels: Record<string, string> = {
  active: `Active`,
  onboarded: `Onboarded`,
  no_action: `No Action`,
  unknown: `Unknown`,
};

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, size = `sm` }) => {
  const sizeClass =
    size === `md` ? `px-3 py-1.5 text-sm` : `px-2.5 py-1 rounded-lg text-xs`;
  return (
    <span
      className={`inline-flex items-center rounded-lg font-medium ring-1 ring-inset ${sizeClass} ${statusStyles[status] ?? statusStyles.unknown}`}
    >
      {statusLabels[status] ?? status}
    </span>
  );
};

const subscriptionStyles: Record<string, string> = {
  paid: `bg-emerald-50 text-emerald-700 ring-emerald-600/20`,
  trialing: `bg-sky-50 text-sky-700 ring-sky-600/20`,
  trialExpiringSoon: `bg-amber-50 text-amber-700 ring-amber-600/20`,
  overdue: `bg-amber-50 text-amber-700 ring-amber-600/20`,
  unpaid: `bg-red-50 text-red-700 ring-red-600/20`,
  pendingEmailVerification: `bg-slate-50 text-slate-600 ring-slate-500/20`,
  complimentary: `bg-violet-50 text-violet-700 ring-violet-600/20`,
};

const subscriptionLabels: Record<string, string> = {
  paid: `Paid`,
  trialing: `Trial`,
  trialExpiringSoon: `Trial Expiring Soon`,
  overdue: `Overdue`,
  unpaid: `Unpaid`,
  pendingEmailVerification: `Pending`,
  complimentary: `Complimentary`,
};

interface SubscriptionBadgeProps {
  status: string;
  size?: `sm` | `md`;
}

export const SubscriptionBadge: React.FC<SubscriptionBadgeProps> = ({
  status,
  size = `sm`,
}) => {
  const sizeClass =
    size === `md` ? `px-3 py-1.5 text-sm` : `px-2.5 py-1 rounded-lg text-xs`;
  return (
    <span
      className={`inline-flex items-center rounded-lg font-medium ring-1 ring-inset ${sizeClass} ${subscriptionStyles[status] ?? `bg-slate-50 text-slate-600 ring-slate-500/20`}`}
    >
      {subscriptionLabels[status] ?? status}
    </span>
  );
};

export function getSubscriptionLabel(status: string): string {
  return subscriptionLabels[status] ?? status;
}
