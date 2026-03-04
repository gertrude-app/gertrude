import React from 'react';

interface Segment {
  label: string;
  value: number;
  gradient: string;
}

interface BreakdownBarProps {
  title: string;
  total: number;
  segments: Segment[];
}

const BreakdownBar: React.FC<BreakdownBarProps> = ({ title, total, segments }) => {
  const percentages = segments.map((segment) =>
    total > 0 ? (segment.value / total) * 100 : 0,
  );

  return (
    <div className="bg-slate-50 rounded-xl p-5 border border-slate-100">
      <div className="flex justify-between items-baseline mb-3">
        <h3 className="font-display font-medium text-slate-900">{title}</h3>
        <span className="text-sm text-slate-500">{total.toLocaleString()} total</span>
      </div>
      <div className="h-4 bg-slate-200 rounded-full overflow-hidden flex">
        {segments.map((segment, index) => (
          <div
            key={segment.label}
            className={`h-full bg-gradient-to-r ${segment.gradient}`}
            style={{ width: `${percentages[index]}%` }}
          />
        ))}
      </div>
      <div className="flex flex-wrap gap-x-4 gap-y-1 mt-3 text-sm">
        {segments.map((segment, index) => (
          <div key={segment.label} className="flex items-center gap-1.5">
            <div
              className={`w-3 h-3 rounded-full bg-gradient-to-r ${segment.gradient} shrink-0`}
            />
            <span className="text-slate-600">
              {segment.label} ({segment.value.toLocaleString()} ·{` `}
              {percentages[index]?.toFixed(1)}%)
            </span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default BreakdownBar;
