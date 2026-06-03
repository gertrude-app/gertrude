import cx from 'clsx';
import React from 'react';

interface Props {
  children: React.ReactNode;
  className?: string;
}

const CardContainer: React.FC<Props> = ({ children, className }) => (
  <div
    className={cx(
      `bg-stone-50/50 px-3 @lg/main:px-4 @xl/main:px-3 @3xl/main:px-6 py-4 @xl/main:py-3 @3xl/main:py-6 -mx-3 @lg/main:-mx-4 @xl/main:-mx-3 @3xl/main:-mx-6 @xl/main:rounded-2xl @xl/main:border-x border-y border-stone-200/70 bg-dots`,
      className,
    )}
  >
    {children}
  </div>
);

export default CardContainer;
