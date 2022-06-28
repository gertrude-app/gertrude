import React from 'react';
import { Link } from 'react-router-dom';
import cx from 'classnames';

interface CommonProps {
  className?: string;
  color: 'primary-violet' | 'primary-white' | 'secondary-violet' | 'secondary-white';
  children: React.ReactNode;
  small?: boolean;
}

type Props =
  | ({ type: 'button'; onClick(): void } & CommonProps)
  | ({ type: 'link'; to: string } & CommonProps);

const Button: React.FC<Props> = ({ small = false, color, className, ...props }) => {
  let colors = ``;
  switch (color) {
    case `primary-violet`:
      colors = `bg-violet-500 text-white hover:bg-violet-600 border-2 border-violet-500 hover:border-violet-600 ring-white focus:ring-violet-500`;
      break;
    case `primary-white`:
      colors = `bg-white text-violet-500 hover:bg-violet-50 border-2 border-white hover:border-violet-50 ring-violet-500 ring-offset-violet-500 focus:ring-white`;
      break;
    case `secondary-violet`:
      colors = `bg-violet-500 text-white border-2 border-white hover:bg-violet-400 ring-violet-500 focus:ring-white ring-offset-violet-500`;
      break;
    case `secondary-white`:
      colors = `bg-gray-50 text-gray-500 border hover:bg-gray-100 ring-white focus:ring-indigo-400 focus:border-indigo-500`;
      break;
  }
  const classes = cx(
    colors,
    `ring ring-offset-0 focus:ring-offset-4 shadow-sm rounded-lg font-bold [transition:100ms] outline-none block`,
    small ? `text-md px-5 py-2` : `text-lg px-10 py-2.5`,
    className,
    props.type !== `button` && `text-center w-fit`,
  );

  if (props.type === `button`) {
    return (
      <button className={classes} onClick={props.onClick}>
        {props.children}
      </button>
    );
  }
  return (
    <Link className={classes} to={props.to}>
      {props.children}
    </Link>
  );
};

export default Button;
