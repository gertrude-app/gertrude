import { Html, Head, Main, NextScript } from 'next/document';
import type { DocumentContext } from 'next/document';

const Document: React.FC<{ ctx: DocumentContext }> = (ctx) => {
  const pagePath: string = (ctx as any)?.__NEXT_DATA__?.page ?? ``;
  const lang = pagePath.includes(`bloquear`) ? `es` : `en`;
  return (
    <Html lang={lang} className="[font-feature-settings:'ss01'] js-focus-visible">
      <Head />
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
};

export default Document;
