import { Toaster } from '@gertrude/ui';
import { HeadContent, Scripts, createRootRoute } from '@tanstack/react-router';
import appCss from '../styles.css?url';
import { MockDataProvider } from '#/lib/mock';

export const Route = createRootRoute({
  head: () => ({
    meta: [
      {
        charSet: `utf-8`,
      },
      {
        name: `viewport`,
        content: `width=device-width, initial-scale=1`,
      },
      {
        title: `Gertrude`,
      },
    ],
    links: [
      {
        rel: `stylesheet`,
        href: appCss,
      },
      // favicon:
      {
        rel: `icon`,
        href: `/favicon.png`,
        type: `image/png`,
      },
    ],
  }),
  shellComponent: RootDocument,
});

function RootDocument({ children }: { children: React.ReactNode }): React.ReactElement {
  return (
    <html lang="en">
      <head>
        <HeadContent />
      </head>
      <body>
        <MockDataProvider>
          {children}
          <Toaster />
        </MockDataProvider>
        <Scripts />
      </body>
    </html>
  );
}
