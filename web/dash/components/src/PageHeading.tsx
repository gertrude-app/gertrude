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
  <header className={cx(`md:mt-3`, className)} data-test="page-heading">
    <div className="flex justify-start items-center">
      <GradientIcon icon={icon} size="large" className="mr-3" />
      <h1 className="text-4xl font-bold flex justify-start items-center text-slate-800">
        {children}
      </h1>
    </div>
  </header>
);

export default PageHeading;
