import type { HelpArticle } from './files';
import { getArticle, getArticleSlugs, getHelpUrlSegment } from './files';

export async function getHelpArticles(
  device?: `mac` | `iphone-ipad`,
): Promise<HelpArticle[]> {
  const slugs = await getArticleSlugs(`help`);
  const articles = await Promise.all(slugs.map((slug) => getArticle(slug, `help`)));
  return articles
    .filter((article) => !device || getHelpUrlSegment(article.platforms) === device)
    .sort((a, b) => a.title.localeCompare(b.title));
}
