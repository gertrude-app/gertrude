import React from 'react';
import cx from 'classnames';

type Props = {
  className?: string;
  children: React.ReactNode;
  inset?: boolean;
};

const DashboardWidget: React.FC<Props> = ({ className, children, inset = false }) => (
  <div
    className={cx(
      `border-[0.5px] border-slate-100 bg-white p-3 sm:p-4 rounded-3xl shadow-lg shadow-slate-300/50`,
      inset && `bg-slate-100 shadow-inner`,
      className,
    )}
  >
    {children}
  </div>
);

export default DashboardWidget;
