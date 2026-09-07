import cx from 'classnames';
import React from 'react';

const TrialStatusCard: React.FC<{
  heading: React.ReactNode;
  children: React.ReactNode;
  className?: string;
}> = ({ heading, children, className }) => (
  <div
    className={cx(`rounded-xl border border-slate-200 bg-slate-50 px-5 py-4`, className)}
  >
    <p className="font-semibold text-slate-800">{heading}</p>
    <div className="mt-1 text-sm text-slate-600">{children}</div>
  </div>
);

export default TrialStatusCard;
