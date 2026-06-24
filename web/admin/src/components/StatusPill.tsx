import React from 'react';

export interface StatusPillStyle {
  label: string;
  className: string;
}

interface StatusPillProps {
  status: string;
  styles: Record<string, StatusPillStyle>;
  fallback: StatusPillStyle;
}

const StatusPill: React.FC<StatusPillProps> = ({ status, styles, fallback }) => {
  const style = styles[status] ?? fallback;
  return (
    <span
      className={`inline-flex items-center px-2 sm:px-2.5 py-0.5 sm:py-1 rounded-full text-[10px] sm:text-xs font-medium whitespace-nowrap ${style.className}`}
    >
      {style.label}
    </span>
  );
};

export default StatusPill;
