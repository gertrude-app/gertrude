import Markdoc from '@markdoc/markdoc';
import { notFound } from 'next/navigation';
import React from 'react';
import type { Metadata, NextPage } from 'next';
import PublishingArticlePage from '@/components/articles/PublishingArticlePage';
import { createMetadata } from '@/lib/seo';
import { components } from '@/markdoc/config';
import {
  type HelpArticle,
  getArticle,
  getArticleSlugs,
  getHelpArticlePath,
  getHelpUrlSegment,
} from '@/markdoc/files';

type Params = {
  device: string;
  slug: string;
};

type PageProps = {
  params: Promise<Params>;
};

export async function generateStaticParams(): Promise<Params[]> {
  const slugs = await getArticleSlugs(`help`);
  const articles = await Promise.all(slugs.map((slug) => getArticle(slug, `help`)));
  return articles.map((article) => ({
    device: getHelpUrlSegment(article.platforms),
    slug: article.slug,
  }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { device, slug } = await params;
  const article = await loadHelpArticle(device, slug);
  return {
    ...createMetadata(
      `${article.title} | Gertrude Help`,
      article.description,
      article.image,
    ),
    alternates: {
      canonical: getHelpArticlePath(article),
    },
  };
}

const HelpArticlePage: NextPage<PageProps> = async ({ params }) => {
  const { device, slug } = await params;
  const article = await loadHelpArticle(device, slug);

  return (
    <PublishingArticlePage
      article={article}
      backLink={{
        href: `/help/${getHelpUrlSegment(article.platforms)}`,
        label:
          getHelpUrlSegment(article.platforms) === `mac`
            ? `All Mac help`
            : `All iPhone & iPad help`,
      }}
    >
      {Markdoc.renderers.react(article.content, React, { components })}
    </PublishingArticlePage>
  );
};

export default HelpArticlePage;

async function loadHelpArticle(device: string, slug: string): Promise<HelpArticle> {
  const article = await getArticle(slug, `help`);
  if (getHelpUrlSegment(article.platforms) !== device) notFound();
  return article;
}
