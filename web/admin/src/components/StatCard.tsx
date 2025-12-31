import React from 'react';

type HighlightColor = `violet` | `blue` | `green` | `red` | `amber`;

interface StatCardProps {
  label: string;
  value: string | number;
  subvalue?: string;
  highlight?: HighlightColor;
}

const bgClasses: Record<HighlightColor, string> = {
  violet: `bg-gradient-to-br from-brand-violet to-brand-fuchsia`,
  blue: `bg-gradient-to-br from-sky-400 to-blue-500`,
  green: `bg-gradient-to-br from-emerald-400 to-green-500`,
  red: `bg-gradient-to-br from-red-400 to-red-500`,
  amber: `bg-gradient-to-br from-amber-400 to-amber-500`,
};

const StatCard: React.FC<StatCardProps> = ({ label, value, subvalue, highlight }) => {
  const bgClass = highlight
    ? bgClasses[highlight]
    : `bg-slate-50 border border-slate-100`;
  const textClass = highlight ? `text-white` : `text-slate-900`;
  const subClass = highlight ? `text-white/80` : `text-slate-500`;

  return (
    <div className={`rounded-xl p-4 ${bgClass}`}>
      <div className={`text-2xl font-display font-semibold ${textClass}`}>
        {typeof value === `number` ? value.toLocaleString() : value}
      </div>
      {subvalue && <div className={`text-sm ${subClass}`}>{subvalue}</div>}
      <div className={`text-sm mt-1 ${subClass}`}>{label}</div>
    </div>
  );
};

export default StatCard;
