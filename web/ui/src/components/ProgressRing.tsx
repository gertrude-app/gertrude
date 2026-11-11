import cx from 'clsx';
import React from 'react';

interface Props {
  progress: number;
  className?: string;
}

const ProgressRing: React.FC<Props> = ({ progress, className }) => {
  const radius = 5;
  const circumference = 2 * Math.PI * radius;
  const clamped = Math.min(1, Math.max(0, progress));

  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 14 14"
      className={cx(`size-3.5 -rotate-90 rounded-full bg-white`, className)}
    >
      <circle
        cx="7"
        cy="7"
        r={radius}
        fill="none"
        strokeWidth="2.5"
        className="stroke-stone-200"
      />
      <circle
        cx="7"
        cy="7"
        r={radius}
        fill="none"
        strokeWidth="2.5"
        strokeLinecap="round"
        strokeDasharray={circumference}
        strokeDashoffset={circumference * (1 - clamped)}
        className="stroke-violet-500 transition-[stroke-dashoffset] duration-300 motion-reduce:transition-none"
      />
    </svg>
  );
};

export default ProgressRing;
