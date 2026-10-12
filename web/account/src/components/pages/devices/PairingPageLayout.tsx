import cx from 'clsx';
import React from 'react';
import StandalonePagePanel from '#/components/layout/StandalonePagePanel';

interface Props {
  children: React.ReactNode;
  className?: string;
}

const PairingPageLayout: React.FC<Props> = ({ children, className }) => (
  <StandalonePagePanel className="bg-stone-50">
    <main
      className={cx(
        `flex min-h-screen w-full flex-col bg-white shadow-stone-500/20 xs:my-8 xs:min-h-0 xs:max-w-[420px] xs:overflow-hidden xs:rounded-2xl xs:border xs:border-stone-200 xs:shadow-2xl`,
        className,
      )}
    >
      {children}
    </main>
  </StandalonePagePanel>
);

export const PairingHeaderBackground: React.FC = () => (
  <div
    aria-hidden="true"
    className="pointer-events-none absolute inset-0 [background-image:url(/dot-noise-pattern.svg),radial-gradient(ellipse_at_center,rgba(196,180,255,0.16)_0%,transparent_75%),url(/bg.svg)] [background-position:center,center,center] [background-size:1440px_1440px,cover,cover] [mask-image:radial-gradient(ellipse_50%_50%_at_center,black_0%,transparent_100%)]"
  />
);

export default PairingPageLayout;
