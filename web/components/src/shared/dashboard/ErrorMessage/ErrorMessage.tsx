import React from 'react';
import cx from 'classnames';

type Props = {
  className?: string;
  children: React.ReactNode;
};

const ErrorMessage: React.FC<Props> = ({ className, children }) => (
  <div className={cx(`flex justify-center`, className)}>
    <p className="bg-red-100/80 text-red-900 antialiased leading-5 px-8 py-3 rounded-[25px] shadow max-w-lg">
      {children}
    </p>
  </div>
);

export default ErrorMessage;
