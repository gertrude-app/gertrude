import type { MetadataRoute } from 'next';
import { getArticle, getArticleSlugs } from '@/markdoc/files';

export const dynamic = `force-static`;

const BASE_URL = `https://gertrude.app`;

const STATIC_ROUTES = [
  ``,
  `/mac`,
  `/iphone-and-ipad`,
  `/music`,
  `/pricing`,
  `/download-mac-app`,
  `/blog`,
  `/contact`,
  `/docs/getting-started`,
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
      const { date } = await getArticle(slug, `blog`);
      return {
        url: `${BASE_URL}/blog/${slug}`,
        lastModified: new Date(date),
      };
    }),
  );

  const docsSlugs = await getArticleSlugs(`docs`);
  const docsEntries: MetadataRoute.Sitemap = docsSlugs.map((slug) => ({
    url: `${BASE_URL}/docs/${slug}`,
    lastModified: now,
  }));

  return [...staticEntries, ...blogEntries, ...docsEntries];
}
