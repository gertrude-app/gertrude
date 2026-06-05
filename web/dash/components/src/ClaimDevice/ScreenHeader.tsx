import React from 'react';

const ScreenHeader: React.FC<{
  icon: string;
  title: string;
  subtitle?: string;
  step?: { current: number; total: number };
}> = ({ icon, title, subtitle, step }) => (
  <div className="flex items-start gap-4 mb-6">
    <div className="w-14 h-14 rounded-xl bg-violet-100 flex items-center justify-center flex-shrink-0">
      <i className={`fa-solid fa-${icon} text-violet-600 text-2xl`} />
    </div>
    <div className="flex-1">
      {step && (
        <div className="flex items-center justify-between mb-1">
          <p className="text-sm font-medium text-violet-600">
            Step {step.current} of {step.total}
          </p>
          <ProgressDots current={step.current} total={step.total} />
        </div>
      )}
      <h1 className="text-xl font-bold text-slate-800">{title}</h1>
      {subtitle && <p className="text-slate-500 text-sm mt-1">{subtitle}</p>}
    </div>
  </div>
);

export default ScreenHeader;

export const ProgressDots: React.FC<{
  current: number;
  total: number;
  className?: string;
}> = ({ current, total, className }) => (
  <div className={`flex items-center justify-center gap-2 ${className ?? ``}`}>
    {Array.from({ length: total }, (_, i) => (
      <div
        key={i}
        className={`rounded-full transition-all ${
          i + 1 === current
            ? `w-2.5 h-2.5 bg-violet-600`
            : i + 1 < current
              ? `w-2 h-2 bg-violet-400`
              : `w-2 h-2 bg-slate-200`
        }`}
      />
    ))}
  </div>
);
