'use client';

import { usePathname } from 'next/navigation';
import cx from 'classnames';
import React from 'react';
import MainHeader from '@/components/MainHeader';
import MainFooter from '@/components/MainFooter';

const MarketingLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const path = usePathname();
  const theme = path.includes(`blog`) ? `white` : `violet`;
  return (
    <html lang="en">
      <body
        className={cx(
          `min-h-screen flex flex-col`,
          theme === `violet` ? `bg-violet-500` : `bg-white`,
        )}
      >
        <MainHeader theme={theme} />
        <div className="flex-grow">{children}</div>
        <MainFooter />
      </body>
    </html>
  );
};

export default MarketingLayout;
