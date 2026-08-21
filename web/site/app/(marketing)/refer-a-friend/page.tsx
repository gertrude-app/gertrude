import Markdoc from '@markdoc/markdoc';
import React from 'react';
import type { Metadata, NextPage } from 'next';
import PublishingArticlePage from '@/components/articles/PublishingArticlePage';
import { createMetadata } from '@/lib/seo';
import { components } from '@/markdoc/config';
import { getArticle, getProgramArticlePath } from '@/markdoc/files';

export async function generateMetadata(): Promise<Metadata> {
  const article = await getArticle(`refer-a-friend`, `program`);
  return {
    ...createMetadata(article.title, article.description, article.image),
    alternates: {
      canonical: getProgramArticlePath(article),
    },
  };
}

const ReferAFriendPage: NextPage = async () => {
  const article = await getArticle(`refer-a-friend`, `program`);

  return (
    <PublishingArticlePage
      article={article}
      backLink={{ href: `/mac`, label: `Gertrude for Mac` }}
    >
      {Markdoc.renderers.react(article.content, React, { components })}
    </PublishingArticlePage>
  );
};

export default ReferAFriendPage;
