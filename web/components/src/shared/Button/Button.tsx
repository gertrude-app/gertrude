import React from 'react';
import { Link } from 'react-router-dom';
import cx from 'classnames';

interface CommonProps {
  className?: string;
  color:
    | 'primary-violet'
    | 'primary-white'
    | 'secondary-violet'
    | 'secondary-white'
    | 'secondary-warning';
  children: React.ReactNode;
  fullWidth?: boolean;
  small?: boolean;
  disabled?: boolean;
}

type Props =
  | ({ type: 'submit' } & CommonProps)
  | ({ type: 'button'; onClick(): void } & CommonProps)
  | ({ type: 'external'; href: string } & CommonProps)
  | ({ type: 'link'; to: string } & CommonProps);

const Button: React.FC<Props> = ({
  small = false,
  fullWidth = false,
  color,
  className,
  disabled = false,
  ...props
}) => {
  let colors = ``;
  if (!disabled) {
    switch (color) {
      case `primary-violet`:
        colors = `bg-violet-800 text-white hover:bg-violet-900 ring-transparent focus:ring-violet-800`;
        break;
      case `primary-white`:
        colors = `bg-white text-violet-500 hover:bg-violet-50 border-2 border-white hover:border-violet-50 ring-violet-500 ring-offset-violet-500 focus:ring-white`;
        break;
      case `secondary-violet`:
        colors = `bg-violet-500 text-white border-2 border-white hover:bg-violet-400 ring-violet-500 focus:ring-white ring-offset-violet-500`;
        break;
      case `secondary-white`:
        colors = `bg-gray-50 text-gray-500 border hover:bg-gray-100 ring-transparent focus:ring-indigo-400 focus:border-indigo-500`;
        break;
      case `secondary-warning`:
        colors = `bg-red-50 text-red-600 border-red-100 border hover:text-red-700 hover:bg-red-100 ring-transparent focus:ring-red-500 focus:border-red-500`;
        break;
    }
  } else {
    colors = `bg-gray-50 text-gray-400 border border-gray-200 cursor-not-allowed ring-transparent focus:ring-gray-200`;
  }

  const rendersAsButton = props.type === `button` || props.type === `submit`;
  const classes = cx(
    colors,
    `ring ring-offset-0 focus:ring-offset-4 shadow-sm rounded-lg font-bold [transition:100ms] outline-none block`,
    small ? `text-md px-5 py-2` : `text-lg px-10 py-2.5`,
    className,
    fullWidth ? `w-full` : `w-fit`,
    !rendersAsButton && `text-center`,
  );

  if (rendersAsButton) {
    return (
      <button
        type={props.type}
        className={classes}
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
      <a className={classes} href={disabled ? '' : props.href}>
        {props.children}
      </a>
    );
  }

  return (
    <Link className={classes} to={disabled ? '' : props.to}>
      {props.children}
    </Link>
  );
};

export default Button;
