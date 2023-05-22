import React from 'react';
import cx from 'classnames';
import type { HeroIcon } from '@dash/types';
import SmartLink from '../SmartLink';

interface Props {
  Icon: HeroIcon;
  children: string;
  collapsed: boolean;
  to: string;
  isSelected: boolean;
  onClick?: () => unknown;
}

const SidebarOption: React.FC<Props> = ({
  Icon,
  children,
  collapsed,
  to,
  isSelected,
  onClick,
}) => (
  <SmartLink
    to={to}
    onClick={onClick}
    className={cx(
      `ScrollTop flex justify-start items-center`,
      `cursor-pointer transition duration-75 select-none rounded-xl`,
      `focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/50`,
      collapsed
        ? `py-[1.2em] my-[0.3em] pl-[1em] flex justify-center items-center`
        : `py-[10px] sm:py-[12px] md:py-[12px] px-5  my-1.5 md:my-3`,
      isSelected ? `bg-violet-500/20 hover:bg-violet-500/30` : `hover:bg-violet-500/10`,
    )}
  >
    <Icon
      aria-hidden="true"
      className={cx(
        `mr-2.5 sm:mr-4 text-xl sm:text-2xl leading-none w-7`,
        isSelected ? `text-violet-400` : `text-violet-500`,
      )}
    />
    <h2
      className={cx(
        `text-[18px] sm:text-xl antialiased font-bold`,
        collapsed ? `hidden` : `block`,
        isSelected ? `text-violet-200` : `text-indigo-200/70`,
      )}
    >
      {children}
    </h2>
  </SmartLink>
);

export default SidebarOption;
