'use client';

import { GoogleTagManager } from '@next/third-parties/google';
import cx from 'classnames';
import { usePathname } from 'next/navigation';
import React from 'react';
import MainFooter from '@/components/MainFooter';
import MainHeader from '@/components/MainHeader';

const MarketingLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const path = usePathname();
  const isHomePage = path === `/`;
  const isIOSPage = path === `/iphone-and-ipad`;
  const isMusicPage = path === `/music`;
  const theme = path.includes(`blog`) || isHomePage ? `white` : `violet`;
  const lang = path.includes(`bloquear`) ? `es` : `en`;
  const isMacPage =
    path === `/mac` || path === `/download-mac-app` || path.startsWith(`/docs`);
  const logoProduct = isMacPage
    ? `macos`
    : isIOSPage
      ? `ios-ipados`
      : isMusicPage
        ? `music`
        : undefined;
  const linkVariant = isMacPage || isIOSPage || isMusicPage ? `flat` : `default`;
  const overlay = isHomePage || isIOSPage || isMusicPage || path === `/pricing`;
  return (
    <html lang={lang}>
      <GoogleTagManager gtmId="GTM-KRRP8HFW" />
      <body
        className={cx(
          `min-h-screen flex flex-col`,
          isHomePage || isIOSPage
            ? `bg-white`
            : isMusicPage
              ? `bg-slate-950`
              : theme === `violet`
                ? `bg-violet-500`
                : `bg-white`,
        )}
      >
        <MainHeader
          theme={theme}
          overlay={overlay}
          logoProduct={logoProduct}
          linkVariant={linkVariant}
          darkAppsDropdown={isMusicPage}
          compactNavigation={isMusicPage}
        />
        <div className="flex-grow">{children}</div>
        <MainFooter />
      </body>
    </html>
  );
};

export default MarketingLayout;
