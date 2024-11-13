import React from 'react';
import cx from 'classnames';

interface LabeledBtnProps {
  onClick(): unknown;
  disabled: boolean;
  iconClass: string;
  children: React.ReactNode;
}

export const Labeled: React.FC<LabeledBtnProps> = ({
  onClick,
  disabled,
  iconClass,
  children,
}) => (
  <button
    onClick={disabled ? undefined : onClick}
    className={cx(
      `flex-grow py-3 space-x-3.5 flex justify-center items-center flex-row bg-gradient-to-b from-white dark:from-black/50 to-white/20 dark:to-black dark:border-t dark:border-white/40 rounded-xl shadow dark:shadow-black/50 text-black/80`,
      !disabled &&
        `cursor-default hover:scale-[102%] active:scale-[98%] active:shadow hover:shadow-md transition-[transform,box-shadow] duration-100`,
      disabled && `cursor-not-allowed opacity-50 dark:opacity-70`,
    )}
  >
    <i
      className={cx(`fa text-lg shrink-0 text-black/70 dark:text-white/80`, iconClass)}
    />
    <p className="font-medium text-left dark:text-white leading-tight">{children}</p>
  </button>
);

interface WhiteBtnProps {
  children?: React.ReactNode;
  icon?: string;
  onClick(): void;
  pinging?: boolean;
  className?: string;
}

export const White: React.FC<WhiteBtnProps> = ({
  children,
  icon,
  onClick,
  pinging,
  className,
}) => (
  <button
    onClick={onClick}
    className={cx(
      `group bg-gradient-to-b from-white dark:from-black/50 to-white/70 dark:to-black font-medium rounded-xl group transition-[background-color,transform] active:bg-white/60 duration-100 shadow active:scale-95 cursor-default dark:text-white dark:shadow-black/50 dark:border-t dark:border-white/40 flex justify-center items-center relative`,
      children && `px-4 py-1`,
      icon && !children && `w-8 h-8`,
      className,
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

interface VioletBtnProps {
  onClick(): void;
  children: React.ReactNode;
}

export const Violet: React.FC<VioletBtnProps> = ({ onClick, children }) => (
  <button
    onClick={onClick}
    className="bg-gradient-to-b from-violet-400 dark:from-violet-500 to-violet-500 dark:to-violet-700 px-2 py-1 rounded-lg text-white font-medium shadow border-t border-white/40 hover:scale-105 hover:shadow-md transition-[transform,box-shadow] duration-100 cursor-default active:scale-95"
  >
    {children}
  </button>
);
