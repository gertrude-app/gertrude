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
      colors = `bg-green-200 text-green-800`;
      break;
    case `red`:
    case `error`:
      colors = `bg-red-200 text-red-800`;
      break;
    case `yellow`:
    case `warning`:
      colors = `bg-yellow-200 text-yellow-800`;
      break;
    case `blue`:
    case `info`:
      colors = `bg-indigo-200 text-indigo-800`;
      break;
  }

  return (
    <div
      className={cx(
        `rounded-full max-w-fit`,
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
