import React from 'react';
import Head from 'next/head';
import Script from 'next/script';
import { useRouter } from 'next/router';
import type { AppProps } from 'next/app';
import type { MarkDoc } from '../markdoc/headings';
import { collectHeadings } from '../markdoc/headings';
import Favicon from '../public/favicon.png';
import OgImage from '../public/og-image.jpg';
import DocsLayout from '../docs/Layout';
import '../styles/globals.css';

const App: React.FC<AppProps<{ markdoc?: MarkDoc }>> = ({ Component, pageProps }) => {
  let Main: JSX.Element = <Component {...pageProps} />;
  const router = useRouter();
  const ogImage = pageProps.markdoc?.frontmatter.image ?? OgImage.src;
  const path = router.asPath === `/` ? `` : router.asPath;
  const canonicalUrl = (`https://gertrude.app` + path).split(`?`)[0];
  let pageTitle = `Gertrude | Mac Internet Filter, Parental Controls and Activity Monitoring`;
  let description = `Protect your kids online with easy-to-use Mac internet filtering, internet blocking, and mac keylogging.`;

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
        <link rel="canonical" href={canonicalUrl} />
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
