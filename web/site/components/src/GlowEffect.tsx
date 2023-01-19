import React from 'react';
import cx from 'classnames';

interface Props {
  className?: string;
}

const GlowEffect: React.FC<Props> = ({ className }) => {
  return (
    <div className={cx(`w-176 h-176 absolute bg-fuchsia-radial-gradient`, className)} />
  );
};

export default GlowEffect;
