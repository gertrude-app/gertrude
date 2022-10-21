import React from 'react';
import type { AppProps } from 'next/app';
import Head from 'next/head';
import Script from 'next/script';
import '../styles/globals.css';

const MyApp: React.FC<AppProps> = ({ Component, pageProps }) => (
  <>
    <Head>
      <title>Gertrude | Real internet safety for macOS</title>
      <meta
        name="description"
        content="Protect your loved ones with aggressive network filtering, plus screen and keystroke monitoring. Remotely supervise and control access from your own computer or phone. Available for macOS Big Sur, Monterey, and Ventura."
      />
      <Script
        src="https://kit.fontawesome.com/597740db7b.js"
        strategy="beforeInteractive"
      ></Script>
    </Head>
    <Component {...pageProps} />
  </>
);

export default MyApp;
