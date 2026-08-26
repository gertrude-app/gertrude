import { formatUtcDate } from '@shared/datetime';
import type { NextPage } from 'next';
import CollectionIndexPage from '@/components/articles/CollectionIndexPage';
import { createMetadata } from '@/lib/seo';
import { getArticle, getArticleSlugs, getUpdateArticlePath } from '@/markdoc/files';

export const metadata = createMetadata(
  `Updates | Gertrude`,
  `Product announcements and release notes from Gertrude.`,
);

const UpdatesPage: NextPage = async () => {
  const slugs = await getArticleSlugs(`update`);
  const updates = await Promise.all(slugs.map((slug) => getArticle(slug, `update`)));
  updates.sort((a, b) => Date.parse(b.date) - Date.parse(a.date));

  return (
    <CollectionIndexPage
      title="Updates"
      description="Product announcements and release notes from Gertrude."
      items={updates.map((update) => ({
        href: getUpdateArticlePath(update),
        title: update.title,
        description: update.description,
        meta: <time dateTime={update.date}>{formatUtcDate(update.date)}</time>,
      }))}
    />
  );
};

export default UpdatesPage;
