import React from 'react';
import cx from 'classnames';

type Props = {
  className?: string;
  children: React.ReactNode;
};

const ErrorMessage: React.FC<Props> = ({ className, children }) => (
  <div className={cx(`flex justify-center`, className)}>
    <div className="antialiased max-w-lg bg-red-100 p-6 rounded-2xl flex items-center shadow-lg shadow-red-300/20">
      <i className="fa-solid fa-exclamation-triangle shrink-0 mr-4 text-xl text-red-400" />
      <p className="font-medium text-red-600">{children}</p>
    </div>
  </div>
);

export default ErrorMessage;
