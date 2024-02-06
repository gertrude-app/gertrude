import React, { useEffect } from 'react';
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
  let lang: `en` | `es` = `en`;
  let pageTitle = `Gertrude | Mac Internet Filter, Parental Controls and Activity Monitoring`;
  let description = `Protect your kids online with easy-to-use Mac internet filtering, internet blocking, and mac keylogging.`;

  useEffect(storeGoogleClickId, []);

  // docs markdown pages
  if (pageProps.markdoc) {
    const title = pageProps.markdoc.frontmatter.title;
    if (!title) throw new Error(`Missing title in frontmatter for ${path}`);
    lang = title.includes(`Bloquear`) ? `es` : `en`;
    const gertrude =
      lang === `en`
        ? `Gertrude Internet Filter & Parental Controls`
        : `Gertrude Filtro de Internet y Controles Parentales`;
    pageTitle = `${title} | ${gertrude}`;
    description = pageProps.markdoc?.frontmatter.description;
    const tableOfContents = pageProps.markdoc?.content
      ? collectHeadings(pageProps.markdoc.content)
      : [];
    Main = (
      <DocsLayout lang={lang} title={title} tableOfContents={tableOfContents}>
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
        <meta httpEquiv="content-language" content={lang} />
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

function storeGoogleClickId(): void {
  const match = RegExp(`[?&]gclid=([^&]*)`).exec(window.location.search);
  if (!match || !match[1]) {
    return;
  }
  const gclid = match[1].replace(/\+/g, ` `);
  const date = new Date();
  date.setTime(date.getTime() + 90 * 24 * 60 * 60 * 1000); // 90 days
  const domain = window.location.hostname;
  document.cookie = `gclid=${gclid}; expires=${date.toUTCString()}; path=/; domain=${domain}`;
}
