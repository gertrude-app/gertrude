import React from 'react';
import cx from 'classnames';

interface WhiteButtonProps {
  children?: React.ReactNode;
  icon?: string;
  onClick(): void;
  pinging?: boolean;
}

const WhiteButton: React.FC<WhiteButtonProps> = ({
  children,
  icon,
  onClick,
  pinging,
}) => (
  <button
    onClick={onClick}
    className={cx(
      `group bg-gradient-to-b from-white dark:from-black/50 to-white/70 dark:to-black font-medium rounded-xl group transition-[background-color,transform] active:bg-white/60 duration-100 shadow active:scale-95 cursor-default dark:text-white dark:shadow-black/50 dark:border-t dark:border-white/40 flex justify-center items-center relative`,
      children && `px-4 py-1`,
      icon && !children && `w-8 h-8`,
    )}
  >
    {pinging && (
      <>
        <div className="absolute w-2 h-2 bg-red-400 top-0 right-0 rounded-full" />
        <div className="absolute w-3 h-3 bg-red-400 -top-0.5 -right-0.5 rounded-full animate-ping" />
      </>
    )}
    <span
      className={cx(
        `transition-transform duration-200 flex space-x-2 items-center`,
        children && `group-hover:scale-105`,
        icon && !children && `group-hover:scale-110`,
      )}
    >
      {icon && <i className={icon} />}
      {children && <span>{children}</span>}
    </span>
  </button>
);

export default WhiteButton;
