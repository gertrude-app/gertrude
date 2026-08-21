import Markdoc from '@markdoc/markdoc';
import React from 'react';
import type { Metadata, NextPage } from 'next';
import PublishingArticlePage from '@/components/articles/PublishingArticlePage';
import { createMetadata } from '@/lib/seo';
import { components } from '@/markdoc/config';
import { getArticle, getArticleSlugs, getBlogArticlePath } from '@/markdoc/files';

type Params = {
  slug: string;
};

type PageProps = {
  params: Promise<Params>;
};

export async function generateStaticParams(): Promise<Params[]> {
  const slugs = await getArticleSlugs(`blog`);
  return slugs.map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const article = await getArticle(slug, `blog`);
  return {
    ...createMetadata(
      `${article.title} | Gertrude Blog`,
      article.description,
      article.image,
    ),
    alternates: {
      canonical: getBlogArticlePath(article),
    },
  };
}

const BlogArticlePage: NextPage<PageProps> = async ({ params }) => {
  const { slug } = await params;
  const article = await getArticle(slug, `blog`);

  return (
    <PublishingArticlePage
      article={article}
      backLink={{ href: `/blog`, label: `All blog posts` }}
    >
      {Markdoc.renderers.react(article.content, React, { components })}
    </PublishingArticlePage>
  );
};

export default BlogArticlePage;
