import React from 'react';
import cx from 'classnames';
import { posessive } from '@shared/string';

type Props = {
  children: string;
  className?: string;
};

const UserActivityHeader: React.FC<Props> = ({ children, className }) => (
  <header className={cx(className)} data-test="page-heading">
    <div className="flex items-center">
      <h2 className="text-3xl lg:text-4xl ml-4 md:ml-0 font-bold flex justify-start items-center text-gray-800 mb-2">
        {posessive(children)} Activity
      </h2>
    </div>
  </header>
);

export default UserActivityHeader;
