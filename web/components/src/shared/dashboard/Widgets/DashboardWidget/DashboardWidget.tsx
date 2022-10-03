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
      `border bg-white p-2 sm:p-4 rounded-2xl shadow-lg`,
      inset && 'bg-gray-100 shadow-inner',
      className,
    )}
  >
    {children}
  </div>
);

export default DashboardWidget;
