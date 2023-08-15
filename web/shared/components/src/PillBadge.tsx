import React from 'react';
import cx from 'classnames';

type Props = {
  className?: string;
  size?: 'large' | 'medium' | 'small';
  type: 'green' | 'ok' | 'warning' | 'yellow' | 'red' | 'error' | 'blue' | 'info';
  children: React.ReactNode;
};

const PillBadge: React.FC<Props> = ({ type, className, children, size }) => {
  let colors = ``;
  switch (type) {
    case `green`:
    case `ok`:
      colors = `bg-green-50 dark:bg-green-500/10 border-green-200 dark:border-green-500/50 text-green-600 dark:text-green-300`;
      break;
    case `red`:
    case `error`:
      colors = `bg-red-50 dark:bg-red-500/10 border-red-200 dark:border-red-500/50 text-red-600 dark:text-red-300`;
      break;
    case `yellow`:
    case `warning`:
      colors = `bg-yellow-50 dark:bg-yellow-500/10 border-yellow-200 dark:border-yellow-500/50 text-yellow-600 dark:text-yellow-300`;
      break;
    case `blue`:
    case `info`:
      colors = `bg-blue-50 dark:bg-blue-500/10 border-blue-200 dark:border-blue-500/50 text-blue-600 dark:text-blue-300`;
      break;
  }

  return (
    <div
      className={cx(
        `max-w-fit border rounded-full flex justify-center`,
        {
          'text-xs px-[12px] py-[2px]': size === `small`,
          'text-base px-6 py-0.5': size === `large`,
          'text-sm px-[14px] py-[2.5px]': size === `medium` || !size,
        },
        colors,
        className,
      )}
    >
      {children}
    </div>
  );
};

export default PillBadge;
