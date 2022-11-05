import React from 'react';
import cx from 'classnames';
import SmartLink from './SmartLink';

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
      <SmartLink to={props.to} className={className}>
        {children}
      </SmartLink>
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
    <button
      type="button"
      onClick={props.onClick}
      className={cx(`text-left w-full`, className)}
    >
      {children}
    </button>
  );
};

export default Action;
