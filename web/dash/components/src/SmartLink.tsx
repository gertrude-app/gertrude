import React from 'react';
import { Link } from 'react-router-dom';

type SmartLinkProps = {
  to: string;
  openInNewTab?: boolean;
  onClick?: () => unknown;
  className?: string;
  children: React.ReactNode;
};

const SmartLink: React.FC<SmartLinkProps> = ({ openInNewTab, ...props }) => {
  if (typeof props.to === `string` && props.to.startsWith(`http`)) {
    return (
      <a
        href={props.to}
        onClick={props.onClick}
        className={props.className}
        target={openInNewTab ? `_blank` : undefined}
        rel="noreferrer"
      >
        {props.children}
      </a>
    );
  }
  return <Link {...props} />;
};

export default SmartLink;
