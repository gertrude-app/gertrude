import React from 'react';
import cx from 'clsx';

interface Props {
  children: React.ReactNode;
  className?: string;
}

const CardContainer: React.FC<Props> = ({ children, className }) => {
  return (
    <div
      className={cx(
        'bg-stone-50/50 p-6 -mx-6 rounded-2xl border border-stone-200/70 bg-dots',
        className,
      )}
    >
      {children}
    </div>
  );
};

export default CardContainer;
