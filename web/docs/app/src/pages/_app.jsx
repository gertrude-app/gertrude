/* eslint-disable */
import React from 'react';
import Head from 'next/head';
import Favicon from '../../public/favicon.png';

// redirects should mean this is never rendered...
export default function App() {
  return (
    <>
      <Head>
        <title>Gertrude Docs</title>
        <link rel="icon" type="image/png" href={Favicon.src} />
      </Head>
      <h1>
        Docs are now located at:{` `}
        <a href="https://gertrude.app/docs">https://gertrude.app/docs</a>
      </h1>
    </>
  );
}
