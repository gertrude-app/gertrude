import React from 'react';
import cx from 'classnames';

type Props = {
  className?: string;
  children: React.ReactNode;
};

const DashboardWidget: React.FC<Props> = ({ className, children }) => (
  <div className={cx('border bg-white p-4 rounded-2xl shadow-lg', className)}>
    {children}
  </div>
);

export default DashboardWidget;
