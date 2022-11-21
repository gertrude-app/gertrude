import React from 'react';
import cx from 'classnames';
import type { IconType } from './GradientIcon';
import GradientIcon from './GradientIcon';

type Props = {
  children: React.ReactNode;
  icon: IconType;
  className?: string;
};

const PageHeading: React.FC<Props> = ({ children, icon, className }) => (
  <header className={cx(className)} data-test="page-heading">
    <div className="flex justify-start items-center mb-3">
      <GradientIcon icon={icon} size="large" className="mr-3" />
      <h1 className="text-4xl font-bold flex justify-start items-center text-gray-800">
        {children}
      </h1>
    </div>
    <hr className="h-1 bg-gradient-to-r from-indigo-500 to-fuchsia-500" />
  </header>
);

export default PageHeading;
