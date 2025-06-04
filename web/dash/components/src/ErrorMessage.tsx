import { ExclamationCircleIcon } from '@heroicons/react/24/solid';
import cx from 'classnames';
import React from 'react';

type Props = {
  className?: string;
  children: React.ReactNode;
};

const ErrorMessage: React.FC<Props> = ({ className, children }) => (
  <div className={cx(`bg-red-50 p-6 rounded-2xl flex space-x-4 items-start`, className)}>
    <ExclamationCircleIcon className="h-8 text-red-500 shrink-0" />
    <div>
      <h3 className="font-bold text-red-600 text-lg">Uh-oh!</h3>
      <p className="text-red-500 font-medium">{children}</p>
    </div>
  </div>
);

export default ErrorMessage;
