import React from 'react';
import cx from 'classnames';
import { posessive } from '@dash/utils';

type Props = {
  children: string;
  className?: string;
};

const UserActivityHeader: React.FC<Props> = ({ children, className }) => (
  <header className={cx(className)} data-test="page-heading">
    <div className="flex justify-center items-center">
      <h1 className="text-4xl font-bold flex justify-start items-center text-gray-800 mb-3">
        {posessive(children)} Activity
      </h1>
    </div>
    <hr className="h-1 bg-gradient-to-r from-indigo-500 to-fuchsia-500" />
  </header>
);

export default UserActivityHeader;
