import { formatUtcDate } from '@shared/datetime';
import type { NextPage } from 'next';
import CollectionIndexPage from '@/components/articles/CollectionIndexPage';
import { createMetadata } from '@/lib/seo';
import {
  type BlogArticle,
  getArticle,
  getArticleSlugs,
  getBlogArticlePath,
} from '@/markdoc/files';

export const metadata = createMetadata(
  `Blog | Gertrude`,
  `Research and practical writing about internet safety, parental controls, and the ideas behind Gertrude.`,
);

const CATEGORY_LABELS: Record<BlogArticle[`category`], string> = {
  engineering: `Research`,
  mac: `Mac`,
  ios: `iPhone & iPad`,
};

const BlogPage: NextPage = async () => {
  const slugs = await getArticleSlugs(`blog`);
  const articles = await Promise.all(slugs.map((slug) => getArticle(slug, `blog`)));
  articles.sort((a, b) => Date.parse(b.date) - Date.parse(a.date));

  return (
    <CollectionIndexPage
      title="Blog"
      description="Research and practical writing about internet safety, parental controls, and the ideas behind Gertrude."
      items={articles.map((article) => ({
        href: getBlogArticlePath(article),
        title: article.title,
        description: article.description,
        meta: (
          <>
            <span>{CATEGORY_LABELS[article.category]}</span>
            <span aria-hidden="true">·</span>
            <time dateTime={article.date}>{formatUtcDate(article.date)}</time>
          </>
        ),
      }))}
    />
  );
};

export default BlogPage;
