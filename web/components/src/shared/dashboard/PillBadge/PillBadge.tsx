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
      colors = `bg-green-100 text-green-700`;
      break;
    case `red`:
    case `error`:
      colors = `bg-red-100 text-red-700`;
      break;
    case `yellow`:
    case `warning`:
      colors = `bg-yellow-100 text-yellow-700`;
      break;
    case `blue`:
    case `info`:
      colors = `bg-indigo-100 text-indigo-700`;
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
