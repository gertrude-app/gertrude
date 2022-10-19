import React from 'react';
import cx from 'classnames';

interface Props {
  children: React.ReactNode;
  className?: string;
}

const UserInputText: React.FC<Props> = ({ children, className }) => (
  <span
    className={cx(
      'inline-block ml-px -translate-y-px font-mono bg-violet-100 py-[2px] px-3 rounded-lg border-b-2 border-violet-200 text-base font-medium',
      className,
    )}
  >
    {children}
  </span>
);

export default UserInputText;
