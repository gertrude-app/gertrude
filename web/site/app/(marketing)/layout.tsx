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
  const theme = path.includes(`blog`) || isHomePage ? `white` : `violet`;
  const lang = path.includes(`bloquear`) ? `es` : `en`;
  const showAuthButtons =
    path !== `/` && path !== `/contact` && !path.startsWith(`/blog`);
  const isMacPage =
    path === `/mac` || path === `/download-mac-app` || path.startsWith(`/docs`);
  const badge = isMacPage ? `For Mac` : undefined;
  const linkVariant = isMacPage ? `flat` : `default`;
  return (
    <html lang={lang}>
      <GoogleTagManager gtmId="GTM-KRRP8HFW" />
      <body
        className={cx(
          `min-h-screen flex flex-col`,
          isHomePage ? `bg-white` : theme === `violet` ? `bg-violet-500` : `bg-white`,
        )}
      >
        <MainHeader
          theme={theme}
          showAuthButtons={showAuthButtons}
          overlay={isHomePage}
          badge={badge}
          linkVariant={linkVariant}
        />
        <div className="flex-grow">{children}</div>
        <MainFooter />
      </body>
    </html>
  );
};

export default MarketingLayout;
