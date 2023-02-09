import React from 'react';
import Head from 'next/head';
import Script from 'next/script';
import type { AppProps } from 'next/app';
import type { MarkDoc } from '../markdoc/headings';
import { collectHeadings } from '../markdoc/headings';
import Favicon from '../public/favicon.png';
import OgImage from '../public/og-image.jpg';
import DocsLayout from '../docs/Layout';
import '../styles/globals.css';

const App: React.FC<AppProps<{ markdoc?: MarkDoc }>> = ({ Component, pageProps }) => {
  let Main: JSX.Element = <Component {...pageProps} />;

  const ogImage = pageProps.markdoc?.frontmatter.image ?? OgImage.src;
  let pageTitle = `Gertrude | Real internet safety for macOS`;
  let description = `Protect your loved ones with aggressive network filtering, plus screen and keystroke monitoring. Remotely supervise and control access from your own computer or phone. Available for macOS Big Sur, Monterey, and Ventura.`;

  // docs markdown pages
  if (pageProps.markdoc) {
    const title = pageProps.markdoc.frontmatter.title ?? `Gertrude Docs`;
    pageTitle = pageProps.markdoc.frontmatter.pageTitle
      ? `${title} | Gertrude Docs`
      : title;

    description = pageProps.markdoc?.frontmatter.description;
    const tableOfContents = pageProps.markdoc?.content
      ? collectHeadings(pageProps.markdoc.content)
      : [];
    Main = (
      <DocsLayout title={title} tableOfContents={tableOfContents}>
        {Main}
      </DocsLayout>
    );
  }

  return (
    <>
      <Head>
        <title>{pageTitle}</title>
        <meta name="description" content={description} />
        <meta name="og:image" content={ogImage} />
        <link rel="icon" type="image/png" href={Favicon.src} />
      </Head>
      <Script
        src="https://kit.fontawesome.com/597740db7b.js"
        strategy="beforeInteractive"
      ></Script>
      {Main}
    </>
  );
};

export default App;
