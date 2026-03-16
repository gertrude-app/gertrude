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
  active: `Mac: Active`,
  onboarded: `Mac: Onboarded`,
  no_action: `Mac: None`,
  unknown: `Unknown`,
};

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, size = `sm` }) => {
  const sizeClass =
    size === `md` ? `px-3 py-1.5 text-sm` : `px-2.5 py-1 rounded-lg text-xs`;
  return (
    <span
      className={`inline-flex items-center rounded-lg font-medium ring-1 ring-inset ${sizeClass} ${
        statusStyles[status] ?? statusStyles.unknown
      }`}
    >
      {statusLabels[status] ?? status}
    </span>
  );
};

const planBadgeStyles: Record<string, Record<string, string>> = {
  full: {
    paid: `bg-violet-50 text-violet-700 ring-violet-600/20`,
    trialing: `bg-violet-50 text-violet-600 ring-violet-500/20`,
    trialExpiringSoon: `bg-violet-50 text-violet-600 ring-violet-500/20`,
    trialExpired: `bg-orange-50 text-orange-700 ring-orange-600/20`,
    overdue: `bg-amber-50 text-amber-700 ring-amber-600/20`,
    unpaid: `bg-red-50 text-red-700 ring-red-600/20`,
    complimentary: `bg-violet-50 text-violet-700 ring-violet-600/20`,
  },
  light: {
    paid: `bg-sky-50 text-sky-700 ring-sky-600/20`,
    trialingFull: `bg-violet-50 text-violet-600 ring-violet-500/20`,
    trialExpired: `bg-orange-50 text-orange-700 ring-orange-600/20`,
    overdue: `bg-amber-50 text-amber-700 ring-amber-600/20`,
    unpaid: `bg-red-50 text-red-700 ring-red-600/20`,
  },
  free: {
    free: `bg-slate-50 text-slate-400 ring-slate-300/20`,
    unpaid: `bg-slate-50 text-slate-400 ring-slate-300/20`,
  },
};

const billingLabels: Record<string, string> = {
  paid: `Paid`,
  trialing: `Trial`,
  trialExpiringSoon: `Trial Soon`,
  trialingFull: `Trialing Full`,
  trialExpired: `Trial Expired`,
  overdue: `Overdue`,
  unpaid: `Unpaid`,
  complimentary: `Complimentary`,
  free: `Free`,
};

interface PlanBadgeProps {
  planCase: string;
  status: string;
  size?: `sm` | `md`;
}

export const PlanBadge: React.FC<PlanBadgeProps> = ({
  planCase,
  status,
  size = `sm`,
}) => {
  const tierStyles = planBadgeStyles[planCase] ?? planBadgeStyles.free;
  const style = tierStyles?.[status] ?? `bg-slate-50 text-slate-600 ring-slate-500/20`;
  const tierLabel = planCase === `free` ? `` : planCase === `light` ? `Light` : `Full`;
  const isLapsed = planCase === `free` && status === `unpaid`;
  const statusLabel = isLapsed ? `Lapsed` : (billingLabels[status] ?? status);
  const label = tierLabel ? `${tierLabel} · ${statusLabel}` : statusLabel;
  const sizeClass =
    size === `md` ? `px-3 py-1.5 text-sm` : `px-2.5 py-1 rounded-lg text-xs`;
  return (
    <span
      className={`inline-flex items-center rounded-lg font-medium ring-1 ring-inset ${sizeClass} ${style}`}
    >
      {label}
    </span>
  );
};
