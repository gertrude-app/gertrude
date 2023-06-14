import React from 'react';
import cx from 'classnames';

type Props = {
  className?: string;
  small?: boolean;
  type: 'green' | 'ok' | 'warning' | 'yellow' | 'red' | 'error' | 'blue' | 'info';
  children: React.ReactNode;
};

const PillBadge: React.FC<Props> = ({ type, className, children, small }) => {
  let colors = ``;

  switch (type) {
    case `green`:
    case `ok`:
      colors = `bg-green-50 border-green-200 text-green-600`;
      break;
    case `red`:
    case `error`:
      colors = `bg-red-50 border-red-200 text-red-600`;
      break;
    case `yellow`:
    case `warning`:
      colors = `bg-yellow-50 border-yellow-200 text-yellow-600`;
      break;
    case `blue`:
    case `info`:
      colors = `bg-blue-50 border-blue-200 text-blue-600`;
      break;
  }

  return (
    <div
      className={cx(
        `rounded-full max-w-fit border`,
        small ? `text-sm px-[16px] pt-[3px] pb-[4px]` : `px-6 py-0.5`,
        colors,
        className,
      )}
    >
      {children}
    </div>
  );
};

export default PillBadge;
