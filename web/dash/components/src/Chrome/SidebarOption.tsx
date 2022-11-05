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
      `cursor-pointer transition duration-75 select-none`,
      `bg-violet-500 bg-opacity-0`,
      `focus:outline-none focus:ring-2 focus:ring-inset focus:ring-violet-500/50`,
      isSelected ? `bg-opacity-20` : `hover:bg-opacity-10`,
      collapsed
        ? `py-[1.4em] pl-[1.65em]`
        : `rounded-xl py-[6px] sm:py-[8px] md:py-[12px] px-5 my-3 `,
    )}
  >
    <i
      aria-hidden="true"
      className={cx(
        `fa fa-${icon} mr-2.5 sm:mr-4 text-xl sm:text-2xl leading-none w-7`,
        isSelected
          ? `bg-gradient-to-br from-indigo-500 to-fuchsia-500 text-transparent bg-clip-text [-webkit-background-clip:text;]`
          : `text-violet-300 text-opacity-40`,
      )}
    />
    <h2
      className={cx(
        `text-white text-[18px] sm:text-xl antialiased text-opacity-60 font-bold`,
        collapsed ? `hidden` : `block`,
      )}
    >
      {children}
    </h2>
  </SmartLink>
);

export default SidebarOption;
