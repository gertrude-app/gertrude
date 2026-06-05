import React from 'react';

const HighlightableCard: React.FC<{
  highlighted: boolean;
  className?: string;
  children: React.ReactNode;
}> = ({ highlighted, className, children }) => (
  <div
    className={`rounded-2xl p-[2px] ${className ?? ``} ${
      highlighted ? `bg-gradient-to-r from-violet-500 to-fuchsia-500` : `bg-slate-100`
    }`}
  >
    <div className={`rounded-[14px] p-5 ${highlighted ? `bg-white` : `bg-slate-50/50`}`}>
      {children}
    </div>
  </div>
);

export default HighlightableCard;
