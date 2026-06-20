import cx from 'clsx';
import React from 'react';

type LoadingDotsSize = `small` | `medium` | `large`;

interface Props {
  size?: LoadingDotsSize;
}

const sizeClasses: Record<LoadingDotsSize, string> = {
  small: `gap-0.75 [&>span]:h-1.5 [&>span]:w-1.5`,
  medium: `gap-1 [&>span]:h-2 [&>span]:w-2`,
  large: `gap-1.5 [&>span]:h-2.5 [&>span]:w-2.5`,
};

const LoadingDots: React.FC<Props> = ({ size = `medium` }) => (
  <span
    role="status"
    aria-label="Loading"
    className={cx(`inline-flex items-center`, sizeClasses[size])}
  >
    <span className="loading-dots-dot rounded-full bg-stone-500" />
    <span className="loading-dots-dot rounded-full bg-stone-500" />
    <span className="loading-dots-dot rounded-full bg-stone-500" />
  </span>
);

export default LoadingDots;
export type { LoadingDotsSize };
