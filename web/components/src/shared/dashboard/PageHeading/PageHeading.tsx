import React from 'react';
import cx from 'classnames';

type Props = {
  children: React.ReactNode;
  icon: string;
  className?: string;
};

const PageHeading: React.FC<Props> = ({ children, icon, className }) => (
  <header className={cx(className)}>
    <div className="flex justify-start items-center mb-3">
      <div className="flex justify-center items-center w-12 h-12 bg-gradient-to-br from-indigo-500 to-fuchsia-500 rounded-full mr-3">
        <i className={`fas fa-${icon} text-2xl text-gray-50`} />
      </div>
      <h1 className="text-4xl font-bold flex justify-start items-center text-gray-800">
        {children}
      </h1>
    </div>
    <hr className="h-1 bg-gradient-to-r from-indigo-500 to-fuchsia-500" />
  </header>
);

export default PageHeading;
