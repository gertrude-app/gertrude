import cx from 'classnames';
import React from 'react';
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
      `ScrollTop flex items-center SidebarLink`,
      collapsed ? `collapsed justify-center` : `expanded justify-start`,
      `cursor-pointer transition-[background-color] duration-75 select-none rounded-xl`,
      `focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/50`,
      isSelected ? `bg-violet-500/20 hover:bg-violet-500/30` : `hover:bg-violet-500/10`,
    )}
  >
    <Icon
      aria-hidden="true"
      className={cx(
        !collapsed && `mr-2.5 sm:mr-4`,
        `Icon`,
        isSelected ? `fill-purple-400` : `text-violet-500`,
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
