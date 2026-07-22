import type { StatusPillStyle } from '../components/StatusPill';

export const MUSIC_INSTALL_STATUS_STYLES: Record<string, StatusPillStyle> = {
  paid: { label: `Paid`, className: `bg-green-100 text-green-700` },
  complimentary: { label: `Comp`, className: `bg-rose-100 text-rose-700` },
  connected: { label: `Connected`, className: `bg-violet-100 text-violet-700` },
  unclaimed: { label: `Unclaimed`, className: `bg-slate-100 text-slate-500` },
};

export const UNKNOWN_MUSIC_INSTALL_STATUS_STYLE: StatusPillStyle = {
  label: `Unknown`,
  className: `bg-slate-100 text-slate-500`,
};
