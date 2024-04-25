import path from 'path';
import React from 'react';
import Markdoc from '@markdoc/markdoc';
import type { Metadata, NextPage } from 'next';
import { components } from '@/markdoc/config';
import { getArticle, getArticlePaths } from '@/markdoc/files';
import Prose from '@/components/articles/Prose';

type Params = {
  slug: string;
};

type PageProps = {
  params: Params;
};

export const dynamicParams = false;

export async function generateStaticParams(): Promise<Params[]> {
  const articlePaths = await getArticlePaths(`docs`);
  return articlePaths.map((postPath) => ({
    slug: path.basename(postPath, path.extname(postPath)),
  }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { title, description, image } = await getArticle(params.slug, `docs`);
  return {
    title: `${title} | Gertrude Internet Filter and Parental Controls`,
    description,
    openGraph: {
      title: `${title} | Gertrude Internet Filter and Parental Controls`,
      description,
      images: [{ url: image ?? `` }],
    },
  };
}

const DocumentationArticle: NextPage<PageProps> = async ({ params: { slug } }) => {
  const { title, content } = await getArticle(slug, `docs`);

  return (
    <div className="flex justify-center">
      <div className="lg:max-w-3xl pt-12 lg:pt-36 relative mx-6 xs:mx-8 pb-20">
        <h1 className="text-4xl font-bold mb-8 mt-2">{title}</h1>
        <Prose>{Markdoc.renderers.react(content, React, { components })}</Prose>
      </div>
    </div>
  );
};

export default DocumentationArticle;
