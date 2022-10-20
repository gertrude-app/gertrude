import React from 'react';
import cx from 'classnames';

interface Props {
  children: React.ReactNode;
  className?: string;
  small?: boolean;
}

const UserInputText: React.FC<Props> = ({ children, small, className }) => (
  <span
    className={cx(
      `inline-block ml-px leading-snug -translate-y-px font-mono bg-violet-100  rounded-lg border-b-2 border-violet-200 text-base font-medium`,
      small ? `py-[1px] px-1.5` : `py-[2px] px-3`,
      className,
    )}
  >
    {children}
  </span>
);

export default UserInputText;
