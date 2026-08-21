'use client';

import { GoogleTagManager } from '@next/third-parties/google';
import { usePathname } from 'next/navigation';
import React from 'react';
import type { LogoProduct } from '@/components/Logo';
import MainFooter from '@/components/MainFooter';
import MainHeader from '@/components/MainHeader';

const MarketingLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const path = usePathname();
  const isHomePage = path === `/`;
  const isIOSPage = path === `/iphone-and-ipad`;
  const isMusicPage = path === `/music`;
  const isPublishingPage =
    path === `/refer-a-friend` ||
    [`/resources`, `/help`, `/guides`, `/updates`, `/legal`].some((prefix) =>
      path.startsWith(prefix),
    );
  const theme =
    path.includes(`blog`) || isHomePage || isPublishingPage ? `white` : `violet`;
  const lang = path.includes(`bloquear`) ? `es` : `en`;
  const isMacPage = path === `/mac` || path === `/download-mac-app`;
  let logoProduct: LogoProduct | undefined;
  if (isMacPage) {
    logoProduct = `macos`;
  } else if (isIOSPage) {
    logoProduct = `ios-ipados`;
  } else if (isMusicPage) {
    logoProduct = `music`;
  }
  const linkVariant = isMacPage || isIOSPage || isMusicPage ? `flat` : `default`;
  const overlay = isHomePage || isIOSPage || isMusicPage || path === `/pricing`;
  let bodyBackground = `bg-white`;
  if (isMusicPage) {
    bodyBackground = `bg-slate-950`;
  } else if (isPublishingPage) {
    bodyBackground = `bg-violet-50/50`;
  } else if (theme === `violet` && !isIOSPage) {
    bodyBackground = `bg-violet-500`;
  }
  return (
    <html lang={lang}>
      <GoogleTagManager gtmId="GTM-KRRP8HFW" />
      <body className={`min-h-screen flex flex-col ${bodyBackground}`}>
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
