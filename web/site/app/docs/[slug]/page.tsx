import path from 'path';
import fs from 'fs';
import { glob } from 'glob';
import Markdoc from '@markdoc/markdoc';
import React from 'react';
import matter from 'gray-matter';
import type { RenderableTreeNode } from '@markdoc/markdoc';
import type { Metadata, NextPage } from 'next';
import { components, config } from '../../../markdoc/config';
import Prose from '../../../components/docs/Prose';
import articles from '../articles';

const ARTICLES_PATH = `markdoc/articles`;
const POSTS_DIR = path.join(process.cwd(), ARTICLES_PATH);

type Params = {
  slug: string;
};

type PageProps = {
  params: Params;
};

export const dynamicParams = false;

export async function generateStaticParams(): Promise<Params[]> {
  const articlePaths = await glob(`${POSTS_DIR}/*.md`);
  return articlePaths.map((postPath) => ({
    slug: path.basename(postPath, path.extname(postPath)),
  }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { title, description, image } = await getMarkdownContent(params.slug);
  return {
    title: `${title} | Gertrude Internet Filter and Parental Controls`,
    description,
    openGraph: { description, images: [{ url: image ?? `` }] },
  };
}

const DocumentationArticle: NextPage<PageProps> = async ({ params: { slug } }) => {
  const { renderableContent, title } = await getMarkdownContent(slug);

  return (
    <div className="flex justify-center">
      <div className="lg:max-w-3xl pt-12 lg:pt-36 relative mx-6 xs:mx-8">
        <span className="text-lg text-violet-500 font-medium">
          {articles.find((n) => n.slug === slug)?.title}
        </span>
        <h1 className="text-4xl font-bold mb-8 mt-2">{title}</h1>
        <Prose>{Markdoc.renderers.react(renderableContent, React, { components })}</Prose>
      </div>
    </div>
  );
};

export default DocumentationArticle;

async function getMarkdownContent(slug: string): Promise<{
  renderableContent: RenderableTreeNode;
  plainTextContent: string;
  title: string;
  description: string;
  image?: string;
}> {
  const filePath = path.join(POSTS_DIR, slug + `.md`);
  const source = fs.readFileSync(filePath, `utf-8`);
  const matterResult = matter(source);
  const { title, image, description } = matterResult.data;
  if (typeof title !== `string`) throw new Error(`Missing title in ${slug}.md`);
  if (typeof description !== `string`)
    throw new Error(`Missing description in ${slug}.md`);
  if (typeof image !== `string` && image !== undefined)
    throw new Error(`Invalid image in ${slug}.md`);
  const ast = Markdoc.parse(source);
  const renderableContent = Markdoc.transform(ast, config);
  return { renderableContent, plainTextContent: source, title, description, image };
}
