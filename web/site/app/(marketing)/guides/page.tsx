import type { NextPage } from 'next';
import CollectionIndexPage from '@/components/articles/CollectionIndexPage';
import { createMetadata } from '@/lib/seo';
import {
  type GuideArticle,
  getArticle,
  getArticleSlugs,
  getGuideArticlePath,
} from '@/markdoc/files';

export const metadata = createMetadata(
  `Guides | Gertrude`,
  `Step-by-step guides for protecting Macs, iPhones, and iPads and making thoughtful internet-safety choices for your family.`,
);

const GuidesPage: NextPage = async () => {
  const slugs = await getArticleSlugs(`guide`);
  const allGuides = await Promise.all(slugs.map((slug) => getArticle(slug, `guide`)));
  const guides = allGuides.filter((guide) => !guide.noindex);
  guides.sort((a, b) => a.title.localeCompare(b.title));

  return (
    <CollectionIndexPage
      title="Guides"
      description="Step-by-step guidance for protecting devices and making thoughtful internet-safety choices for your family."
      items={guides.map((guide) => ({
        href: getGuideArticlePath(guide),
        title: guide.title,
        description: guide.description,
        meta: getGuideProductLabel(guide),
      }))}
    />
  );
};

export default GuidesPage;

function getGuideProductLabel(article: GuideArticle): string {
  if (article.platforms.includes(`macos`)) return `Mac`;
  if (article.platforms.includes(`ios`) || article.platforms.includes(`ipados`)) {
    return `iPhone & iPad`;
  }
  return `General`;
}
