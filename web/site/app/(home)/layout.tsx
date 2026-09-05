import { GoogleTagManager } from '@next/third-parties/google';
import { GeistSans } from 'geist/font/sans';
import React from 'react';
import HomeHeader from '@/components/home/HomeHeader';

const HomeLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <html lang="en" className={GeistSans.className}>
    <GoogleTagManager gtmId="GTM-KRRP8HFW" />
    <body className="min-h-screen bg-white">
      <HomeHeader />
      {children}
    </body>
  </html>
);

export default HomeLayout;
