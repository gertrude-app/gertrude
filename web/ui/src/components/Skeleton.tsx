import cx from 'clsx';
import React from 'react';

export type SkeletonRadius = `small` | `medium` | `large` | `full`;

export interface SkeletonProps extends Omit<
  React.ComponentPropsWithoutRef<`div`>,
  `children`
> {
  radius?: SkeletonRadius;
}

const radiusClasses: Record<SkeletonRadius, string> = {
  small: `rounded`,
  medium: `rounded-md`,
  large: `rounded-xl`,
  full: `rounded-full`,
};

const Skeleton: React.FC<SkeletonProps> = ({
  radius = `medium`,
  className,
  ...props
}) => (
  <div
    {...props}
    aria-hidden="true"
    className={cx(`skeleton bg-stone-200/80`, radiusClasses[radius], className)}
  />
);

export default Skeleton;
