import Head from 'next/head';
import type { AppProps } from 'next/app';
import { slugifyWithCounter } from '@sindresorhus/slugify';
import Layout from '@/components/Layout';
import 'focus-visible';
import '../styles/tailwind.css';
import Favicon from '../../public/favicon.png';

function getNodeText(node: Node): string {
  let text = ``;
  for (const child of node.children ?? []) {
    if (typeof child === `string`) {
      text += child;
    }
    text += getNodeText(child);
  }
  return text;
}

type Node = {
  name: string;
  attributes: { id?: string };
  children?: Node[];
};

export type Section = {
  title: string;
  id?: string;
  children?: Section[];
};

function collectHeadings(
  nodes: Array<Node | string>,
  slugify = slugifyWithCounter(),
): Section[] {
  const sections: Array<Section> = [];

  for (const node of nodes) {
    if (typeof node === `string`) {
      continue;
    }
    if (node.name === `h2` || node.name === `h3`) {
      const title = getNodeText(node);
      if (title) {
        const id = slugify(title);
        node.attributes.id = id;
        if (node.name === `h3`) {
          if (!sections[sections.length - 1]) {
            throw new Error(
              `Cannot add \`h3\` to table of contents without a preceding \`h2\``,
            );
          }
          sections[sections.length - 1].children?.push({
            ...node.attributes,
            title,
          });
        } else {
          sections.push({ ...node.attributes, title, children: [] });
        }
      }
    }

    sections.push(...collectHeadings(node.children ?? [], slugify));
  }

  return sections;
}

type MarkDoc = {
  frontmatter: {
    title: string;
    description: string;
    pageTitle: string;
  };
  content: Array<Node | string>;
};

const App: React.FC<AppProps<{ markdoc?: MarkDoc }>> = ({ Component, pageProps }) => {
  const title = pageProps.markdoc?.frontmatter.title ?? `Gertrude Docs`;

  const pageTitle =
    pageProps.markdoc?.frontmatter.pageTitle ||
    `${pageProps.markdoc?.frontmatter.title} - Docs`;

  const description = pageProps.markdoc?.frontmatter.description;

  const tableOfContents = pageProps.markdoc?.content
    ? collectHeadings(pageProps.markdoc.content)
    : [];

  return (
    <>
      <Head>
        <title>{`${pageTitle} | Gertrude`}</title>
        <link rel="icon" type="image/png" href={Favicon.src} />
        {description && <meta name="description" content={description} />}
      </Head>
      <Layout title={title} tableOfContents={tableOfContents}>
        <Component {...pageProps} />
      </Layout>
    </>
  );
};

export default App;
