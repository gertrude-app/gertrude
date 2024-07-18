import React from 'react';
import { GoogleTagManager } from '@next/third-parties/google';
import MainHeader from './OldMainHeader';
import MainFooter from './OldMainFooter';

const OldMarketingLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <html lang="en">
    <head>
      <GoogleTagManager gtmId="GTM-KRRP8HFW" />
      <script src="https://kit.fontawesome.com/597740db7b.js"></script>
    </head>
    <body className="[font-feature-settings:'ss01'] js-focus-visible">
      <main className="overflow-hidden flex flex-col min-h-screen">
        <MainHeader />
        {children}
        <MainFooter />
      </main>
    </body>
  </html>
);

export default OldMarketingLayout;
