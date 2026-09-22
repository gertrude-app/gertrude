import cx from 'clsx';
import React from 'react';

type Props = {
  children: number | string;
  size?: `default` | `compact`;
  shade?: `light` | `dark`;
  className?: string;
};

const CountBadge: React.FC<Props> = ({
  children,
  size = `default`,
  shade = `dark`,
  className,
}) => (
  <span
    className={cx(
      `inline-flex shrink-0 items-center justify-center rounded-full font-medium tabular-nums`,
      size === `compact`
        ? `min-w-4 px-1 text-[10px] leading-4`
        : `min-w-5 px-1.5 text-xs leading-5`,
      shade === `light`
        ? `bg-stone-100 text-stone-700`
        : `bg-stone-200/70 text-stone-600`,
      className,
    )}
  >
    {children}
  </span>
);

export default CountBadge;
