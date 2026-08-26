import Markdoc from '@markdoc/markdoc';
import React from 'react';
import type { Metadata, NextPage } from 'next';
import PublishingArticlePage from '@/components/articles/PublishingArticlePage';
import { createMetadata } from '@/lib/seo';
import { components } from '@/markdoc/config';
import { getArticle, getArticleSlugs, getUpdateArticlePath } from '@/markdoc/files';

type Params = {
  slug: string;
};

type PageProps = {
  params: Promise<Params>;
};

export async function generateStaticParams(): Promise<Params[]> {
  const slugs = await getArticleSlugs(`update`);
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const article = await getArticle(slug, `update`);
  return {
    ...createMetadata(
      `${article.title} | Gertrude Updates`,
      article.description,
      article.image,
    ),
    alternates: {
      canonical: getUpdateArticlePath(article),
    },
  };
}

const UpdateArticlePage: NextPage<PageProps> = async ({ params }) => {
  const { slug } = await params;
  const article = await getArticle(slug, `update`);

  return (
    <PublishingArticlePage
      article={article}
      backLink={{ href: `/updates`, label: `All updates` }}
    >
      {Markdoc.renderers.react(article.content, React, { components })}
    </PublishingArticlePage>
  );
};

export default UpdateArticlePage;
