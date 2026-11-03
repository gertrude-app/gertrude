import cx from 'clsx';
import React from 'react';

interface Props {
  src: string;
  size?: `small` | `medium` | `large`;
  className?: string;
}

const AppIcon: React.FC<Props> = ({ src, size = `small`, className }) => (
  <span
    aria-hidden="true"
    className={cx(
      `relative inline-flex shrink-0`,
      {
        'size-8 rounded-[9px]': size === `small`,
        'size-11 rounded-xl': size === `medium`,
        'size-12 rounded-xl': size === `large`,
      },
      className,
    )}
  >
    <img
      src={src}
      alt=""
      className="pointer-events-none absolute inset-0 size-full rounded-[inherit] blur-xs opacity-40"
    />
    <img
      src={src}
      alt=""
      className="relative size-full rounded-[inherit] border border-stone-200/70 shadow shadow-stone-300/30"
    />
  </span>
);

export default AppIcon;
