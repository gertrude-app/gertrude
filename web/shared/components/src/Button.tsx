import React from 'react';
import { Link } from 'react-router-dom';
import cx from 'classnames';

interface CommonProps {
  className?: string;
  color:
    | 'primary-on-violet-bg'
    | 'secondary-on-violet-bg'
    | 'primary'
    | 'secondary'
    | 'tertiary'
    | 'warning';
  children: React.ReactNode;
  fullWidth?: boolean;
  size?: 'small' | 'medium' | 'large';
  disabled?: boolean;
  testId?: string;
}

type Props =
  | ({ type: 'submit' } & CommonProps)
  | ({ type: 'button'; onClick(): void } & CommonProps)
  | ({ type: 'external'; href: string } & CommonProps)
  | ({ type: 'link'; to: string } & CommonProps);

const Button: React.FC<Props> = ({
  size = `medium`,
  fullWidth = false,
  testId,
  color,
  className,
  disabled = false,
  ...props
}) => {
  let colors = ``;
  if (!disabled) {
    switch (color) {
      case `primary-on-violet-bg`:
        colors = `bg-white text-violet-500 hover:bg-violet-50 border-2 border-white hover:border-violet-50 ring-violet-500 ring-offset-violet-500 focus:ring-white`;
        break;
      case `secondary-on-violet-bg`:
        colors = `bg-violet-500 text-white border-2 border-white hover:bg-violet-400 ring-violet-500 focus:ring-white ring-offset-violet-500`;
        break;
      case `primary`:
        colors = `bg-violet-800 border border-violet-800 hover:border-violet-900 text-white hover:bg-violet-900 ring-transparent focus:ring-violet-800`;
        break;
      case `secondary`:
        colors = `bg-violet-100 dark:bg-slate-800/80 border border-violet-100 dark:border-slate-700/70 hover:border-violet-200 dark:hover:bg-slate-700/80 text-violet-600 dark:text-white/80 hover:bg-violet-200 ring-transparent focus:ring-violet-300 dark:focus:ring-indigo-500/70 dark:ring-offset-slate-900`;
        break;
      case `tertiary`:
        colors = `bg-white dark:bg-slate-900 text-gray-600 dark:text-slate-300 border dark:border-slate-700 hover:bg-gray-50 dark:hover:bg-slate-800 ring-transparent focus:ring-indigo-400/50 focus:border-indigo-200 dark:ring-offset-slate-900`;
        break;
      case `warning`:
        colors = `bg-red-50 text-red-600 border-red-100 border hover:text-red-700 hover:bg-red-100 ring-transparent focus:ring-red-500 focus:border-red-500`;
        break;
    }
  } else {
    colors = `bg-gray-50 dark:bg-black/50 text-gray-400 dark:text-slate-600 border border-gray-200 dark:border-slate-800 cursor-not-allowed ring-transparent focus:ring-gray-200`;
  }

  const rendersAsButton = props.type === `button` || props.type === `submit`;
  let sizeClass = ``;
  switch (size) {
    case `small`:
      sizeClass = `text-base px-4 py-1.5 font-semibold`;
      break;
    case `medium`:
      sizeClass = `text-base px-5 py-3 sm:py-2.5`;
      break;
    default:
      sizeClass = `text-lg px-10 py-2.5`;
      break;
  }
  const classes = cx(
    colors,
    `ring ring-offset-0 focus:ring-offset-2 rounded-lg font-bold [transition:100ms] outline-none block`,
    sizeClass,
    className,
    fullWidth ? `w-full` : `w-fit`,
    !rendersAsButton && `text-center`,
  );

  if (rendersAsButton) {
    return (
      <button
        type={props.type}
        className={classes}
        disabled={disabled}
        {...(testId ? { 'data-test': testId } : {})}
        {...(props.type === `button`
          ? { onClick: disabled ? () => {} : props.onClick }
          : {})}
      >
        {props.children}
      </button>
    );
  }

  if (props.type === `external`) {
    return (
      <a
        className={classes}
        {...(testId ? { 'data-test': testId } : {})}
        {...(disabled
          ? { onClick: (event) => event.preventDefault() }
          : { href: props.href })}
      >
        {props.children}
      </a>
    );
  }

  return (
    <Link
      className={classes}
      to={disabled ? `#` : props.to}
      {...(testId ? { 'data-test': testId } : {})}
      onClick={
        disabled
          ? (event: React.MouseEvent<HTMLAnchorElement, MouseEvent>) =>
              event.preventDefault()
          : () => {}
      }
    >
      {props.children}
    </Link>
  );
};

export default Button;
