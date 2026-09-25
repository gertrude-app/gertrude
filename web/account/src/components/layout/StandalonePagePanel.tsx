import cx from 'clsx';
import React from 'react';

interface Props {
  children: React.ReactNode;
  className?: string;
}

const StandalonePagePanel: React.FC<Props> = ({ children, className }) => (
  <div
    className={cx(
      `relative flex min-h-screen w-full flex-col xs:items-center xs:justify-center xs:[background-image:url(/dot-noise-pattern.svg),url(/bg.svg)] xs:[background-size:1440px_1440px,cover] xs:[background-repeat:repeat,no-repeat]`,
      className,
    )}
  >
    {children}
  </div>
);

export default StandalonePagePanel;
