import cx from 'clsx';
import React from 'react';

interface Props {
  children: React.ReactNode;
  brandClassName?: string;
  contentClassName?: string;
}

const OnboardingScreen: React.FC<Props> = ({
  children,
  brandClassName,
  contentClassName,
}) => (
  <main className="@container/main relative isolate flex min-h-screen flex-col overflow-hidden bg-white px-5 py-8 sm:px-8 sm:py-10">
    <div
      aria-hidden="true"
      className="pointer-events-none absolute inset-x-0 bottom-0 -z-10 h-3/4 [background-image:url(/dot-noise-pattern.svg),radial-gradient(ellipse_at_bottom,rgba(196,180,255,0.25)_0%,transparent_65%)] [background-position:center,bottom] [background-size:1440px_1440px,cover] [mask-image:linear-gradient(transparent,black)]"
    />
    <header className={cx(`flex justify-center`, brandClassName)}>
      <img src="/logo-wordmark.svg" alt="Gertrude" className="h-auto w-28" />
    </header>
    <div
      className={cx(
        `mx-auto flex w-full flex-grow flex-col justify-center py-8 @2xl/main:py-12`,
        contentClassName,
      )}
    >
      {children}
    </div>
  </main>
);

export default OnboardingScreen;
