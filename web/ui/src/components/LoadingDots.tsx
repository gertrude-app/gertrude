import cx from 'clsx';
import React from 'react';

type LoadingDotsSize = `xsmall` | `small` | `medium` | `large`;
type LoadingDotsVariant = `default` | `inverted`;

interface Props {
  size?: LoadingDotsSize;
  variant?: LoadingDotsVariant;
  className?: string;
  dotClassName?: string;
  ariaHidden?: boolean;
  ariaLabel?: string;
}

const sizeClasses: Record<LoadingDotsSize, string> = {
  xsmall: `gap-0.5 [&>span]:h-1.25 [&>span]:w-1.25`,
  small: `gap-0.75 [&>span]:h-1.5 [&>span]:w-1.5`,
  medium: `gap-1 [&>span]:h-2 [&>span]:w-2`,
  large: `gap-1.5 [&>span]:h-2.5 [&>span]:w-2.5`,
};

const variantClasses: Record<LoadingDotsVariant, string> = {
  default: `bg-stone-500`,
  inverted: `bg-white`,
};

const LoadingDots: React.FC<Props> = ({
  size = `medium`,
  variant = `default`,
  className,
  dotClassName,
  ariaHidden,
  ariaLabel = `Loading`,
}) => (
  <span
    role={ariaHidden ? undefined : `status`}
    aria-hidden={ariaHidden ? true : undefined}
    aria-label={ariaHidden ? undefined : ariaLabel}
    className={cx(`inline-flex items-center`, sizeClasses[size], className)}
  >
    <span
      className={cx(
        `loading-dots-dot rounded-full`,
        variantClasses[variant],
        dotClassName,
      )}
    />
    <span
      className={cx(
        `loading-dots-dot rounded-full`,
        variantClasses[variant],
        dotClassName,
      )}
    />
    <span
      className={cx(
        `loading-dots-dot rounded-full`,
        variantClasses[variant],
        dotClassName,
      )}
    />
  </span>
);

export default LoadingDots;
export type { LoadingDotsSize, LoadingDotsVariant };
