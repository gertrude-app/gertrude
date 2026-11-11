import { GoogleTagManager } from '@next/third-parties/google';
import { GeistSans } from 'geist/font/sans';
import React from 'react';
import HomeFooter from '@/components/home/HomeFooter';
import HomeHeader from '@/components/home/HomeHeader';

const HomeLayout: React.FC<{ children: React.ReactNode }> = ({ children }) => (
  <html
    lang="en"
    className={`${GeistSans.className} scroll-smooth motion-reduce:scroll-auto`}
    data-scroll-behavior="smooth"
  >
    <GoogleTagManager gtmId="GTM-KRRP8HFW" />
    <body className="min-h-screen bg-white">
      <HomeHeader />
      {children}
      <HomeFooter />
    </body>
  </html>
);

export default HomeLayout;
