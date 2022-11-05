import { Head, Html, Main, NextScript } from 'next/document';

const Document: React.FC = () => (
  <Html
    data-theme="dark"
    className="dark antialiased [font-feature-settings:'ss01']"
    lang="en"
  >
    <Head />
    <body className="bg-white dark:bg-slate-900">
      <Main />
      <NextScript />
    </body>
  </Html>
);

export default Document;
