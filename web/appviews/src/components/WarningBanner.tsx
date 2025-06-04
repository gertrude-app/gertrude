import React from 'react';
import cx from 'classnames';

interface Props {
  children: React.ReactNode;
  severity: `warning` | `error`;
  withoutBorder?: boolean;
  className?: string;
}

const WarningBanner: React.FC<Props> = ({
  children,
  severity,
  withoutBorder = false,
  className,
}) => (
  <div
    className={cx(
      !withoutBorder &&
        `border-b border-slate-200 dark:border-slate-800 p-3 dark:bg-slate-900 bg-white`,
      className,
    )}
  >
    <div
      className={`p-3 rounded-2xl flex justify-center items-center space-x-4 ${
        severity === `warning`
          ? `bg-yellow-50 dark:bg-yellow-500/10 dark:border border-yellow-500/20 text-yellow-600 dark:text-yellow-100`
          : `bg-red-50 dark:bg-red-500/20 dark:border border-red-500/20 text-red-600 dark:text-red-100`
      }`}
    >
      <i className="fa-solid fa-triangle-exclamation text-lg" />
      <p className="font-medium">{children}</p>
    </div>
  </div>
);

export default WarningBanner;
