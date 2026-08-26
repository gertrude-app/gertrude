import type { NextPage } from 'next';
import CollectionIndexPage from '@/components/articles/CollectionIndexPage';
import { createMetadata } from '@/lib/seo';
import { getHelpArticlePath, getHelpUrlSegment } from '@/markdoc/files';
import { getHelpArticles } from '@/markdoc/help';

export const metadata = createMetadata(
  `Help | Gertrude`,
  `Focused answers and step-by-step help for Gertrude apps on Mac, iPhone, and iPad.`,
);

const HelpPage: NextPage = async () => {
  const articles = await getHelpArticles();

  return (
    <CollectionIndexPage
      title="Help"
      description="Focused answers and step-by-step instructions for Gertrude apps and the Apple devices they protect."
      items={articles.map((article) => ({
        href: getHelpArticlePath(article),
        title: article.title,
        description: article.description,
        meta: getHelpUrlSegment(article.platforms) === `mac` ? `Mac` : `iPhone & iPad`,
      }))}
    />
  );
};

export default HelpPage;
