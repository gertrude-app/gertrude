import type { MetadataRoute } from 'next';
import {
  getArticle,
  getArticleSlugs,
  getGuideArticlePath,
  getHelpArticlePath,
  getLegalArticlePath,
  getUpdateArticlePath,
} from '@/markdoc/files';

export const dynamic = `force-static`;

const BASE_URL = `https://gertrude.app`;

const STATIC_ROUTES = [
  ``,
  `/mac`,
  `/iphone-and-ipad`,
  `/music`,
  `/pricing`,
  `/refer-a-friend`,
  `/download-mac-app`,
  `/resources`,
  `/blog`,
  `/guides`,
  `/updates`,
  `/help`,
  `/help/mac`,
  `/help/iphone-ipad`,
  `/contact`,
];

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const now = new Date();

  const staticEntries: MetadataRoute.Sitemap = STATIC_ROUTES.map((route) => ({
    url: `${BASE_URL}${route}`,
    lastModified: now,
  }));

  const blogSlugs = await getArticleSlugs(`blog`);
  const blogEntries: MetadataRoute.Sitemap = await Promise.all(
    blogSlugs.map(async (slug) => {
      const { date, updated } = await getArticle(slug, `blog`);
      return {
        url: `${BASE_URL}/blog/${slug}`,
        lastModified: new Date(updated ?? date),
      };
    }),
  );

  const helpSlugs = await getArticleSlugs(`help`);
  const helpEntries: MetadataRoute.Sitemap = await Promise.all(
    helpSlugs.map(async (slug) => {
      const article = await getArticle(slug, `help`);
      return {
        url: `${BASE_URL}${getHelpArticlePath(article)}`,
        lastModified: article.updated ? new Date(article.updated) : now,
      };
    }),
  );

  const guideSlugs = await getArticleSlugs(`guide`);
  const guideArticles = await Promise.all(
    guideSlugs.map((slug) => getArticle(slug, `guide`)),
  );
  const guideEntries: MetadataRoute.Sitemap = guideArticles
    .filter((article) => !article.noindex)
    .map((article) => ({
      url: `${BASE_URL}${getGuideArticlePath(article)}`,
      lastModified: article.updated ? new Date(article.updated) : now,
    }));

  const updateSlugs = await getArticleSlugs(`update`);
  const updateEntries: MetadataRoute.Sitemap = await Promise.all(
    updateSlugs.map(async (slug) => {
      const article = await getArticle(slug, `update`);
      return {
        url: `${BASE_URL}${getUpdateArticlePath(article)}`,
        lastModified: new Date(article.updated ?? article.date),
      };
    }),
  );

  const legalSlugs = await getArticleSlugs(`legal`);
  const legalEntries: MetadataRoute.Sitemap = await Promise.all(
    legalSlugs.map(async (slug) => {
      const article = await getArticle(slug, `legal`);
      return {
        url: `${BASE_URL}${getLegalArticlePath(article)}`,
        lastModified: article.updated ? new Date(article.updated) : now,
      };
    }),
  );

  return [
    ...staticEntries,
    ...blogEntries,
    ...helpEntries,
    ...guideEntries,
    ...updateEntries,
    ...legalEntries,
  ];
}
