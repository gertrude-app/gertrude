import React from 'react';
import cx from 'classnames';
import { Link } from 'react-router-dom';

type Props = {
  className?: string;
  children: React.ReactNode;
} & (
  | { type: 'button'; onClick(): unknown }
  | { type: 'external'; href: string; target?: '_blank' | '_self' }
  | { type: 'link'; to: string }
);

const Action: React.FC<Props> = ({ className, children, ...props }) => {
  if (props.type === `link`) {
    return (
      <Link to={props.to} className={className}>
        {children}
      </Link>
    );
  }

  if (props.type === `external`) {
    return (
      <a href={props.href} target={props.target} className={className}>
        {children}
      </a>
    );
  }

  return (
    <button type="button" onClick={props.onClick} className={cx(`text-left`, className)}>
      {children}
    </button>
  );
};

export default Action;
