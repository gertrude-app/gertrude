import cx from 'clsx';
import React from 'react';

export type SpacerProps = Omit<React.HTMLAttributes<HTMLDivElement>, `children`> & {
  children?: never;
};

const Spacer: React.FC<SpacerProps> = ({ className, ...props }) => (
  <div
    {...props}
    aria-hidden={props[`aria-hidden`] ?? true}
    className={cx(`min-h-0 min-w-0 flex-grow`, className)}
  />
);

export default Spacer;
