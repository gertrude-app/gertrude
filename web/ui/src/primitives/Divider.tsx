import cx from 'clsx';
import React from 'react';

export type DividerOrientation = `horizontal` | `vertical`;

export type DividerProps = Omit<React.HTMLAttributes<HTMLDivElement>, `children`> & {
  children?: never;
  orientation?: DividerOrientation;
};

const Divider: React.FC<DividerProps> = ({
  orientation = `horizontal`,
  className,
  ...props
}) => (
  <div
    {...props}
    aria-hidden={props[`aria-hidden`] ?? true}
    className={cx(
      `shrink-0 bg-stone-200`,
      orientation === `horizontal` ? `h-px w-full` : `w-px self-stretch`,
      className,
    )}
  />
);

export default Divider;
