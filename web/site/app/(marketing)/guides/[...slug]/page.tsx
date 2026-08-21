import Markdoc from '@markdoc/markdoc';
import React from 'react';
import type { Metadata, NextPage } from 'next';
import PublishingArticlePage from '@/components/articles/PublishingArticlePage';
import { createMetadata } from '@/lib/seo';
import { components } from '@/markdoc/config';
import { getArticle, getArticleSlugs, getGuideArticlePath } from '@/markdoc/files';

type Params = {
  slug: string[];
};

type PageProps = {
  params: Promise<Params>;
};

export async function generateStaticParams(): Promise<Params[]> {
  const slugs = await getArticleSlugs(`guide`);
  return slugs.map((slug) => ({ slug: slug.split(`/`) }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const article = await getArticle(slug.join(`/`), `guide`);
  return {
    ...createMetadata(
      `${article.title} | Gertrude Guides`,
      article.description,
      article.image,
    ),
    alternates: {
      canonical: getGuideArticlePath(article),
    },
  };
}

const GuideArticlePage: NextPage<PageProps> = async ({ params }) => {
  const { slug } = await params;
  const article = await getArticle(slug.join(`/`), `guide`);

  return (
    <PublishingArticlePage
      article={article}
      backLink={{ href: `/guides`, label: `All guides` }}
    >
      {Markdoc.renderers.react(article.content, React, { components })}
    </PublishingArticlePage>
  );
};

export default GuideArticlePage;
