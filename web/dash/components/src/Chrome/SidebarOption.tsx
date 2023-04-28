import React from 'react';
import cx from 'classnames';
import SmartLink from '../SmartLink';

interface Props {
  icon: string;
  children: string;
  collapsed: boolean;
  to: string;
  isSelected: boolean;
  onClick?: () => unknown;
}

const SidebarOption: React.FC<Props> = ({
  icon,
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
      `bg-violet-500 bg-opacity-0`,
      `focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/50`,
      isSelected ? `bg-opacity-20` : `hover:bg-opacity-10`,
      collapsed
        ? `py-[1.2em] my-[0.3em] pl-[1.1em] flex justify-center items-center`
        : `py-[6px] sm:py-[8px] md:py-[12px] px-5 my-3 `,
    )}
  >
    <i
      aria-hidden="true"
      className={cx(
        `fa fa-${icon} mr-2.5 sm:mr-4 text-xl sm:text-2xl leading-none w-7`,
        isSelected ? `text-violet-400` : `text-violet-300 text-opacity-40`,
      )}
    />
    <h2
      className={cx(
        `text-slate-300/80 text-[18px] sm:text-xl antialiased font-bold`,
        collapsed ? `hidden` : `block`,
      )}
    >
      {children}
    </h2>
  </SmartLink>
);

export default SidebarOption;
