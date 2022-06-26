import React from 'react';
import type { AppProps } from 'next/app';
import Script from 'next/script';
import '../styles/globals.css';

const MyApp: React.FC<AppProps> = ({ Component, pageProps }) => {
  return (
    <>
      <Script
        src="https://kit.fontawesome.com/667d25f59d.js"
        strategy="beforeInteractive"
      ></Script>
      <Component {...pageProps} />
    </>
  );
}

export default MyApp;
