import type { ArticleProduct } from '../../markdoc/files';

export type ArticleCTAVariant = `mac` | `blocker` | `music` | `podcasts` | `explore`;

export function getArticleCTAVariant(
  products: readonly ArticleProduct[],
): ArticleCTAVariant {
  const [product, ...additionalProducts] = products;
  return product && additionalProducts.length === 0 ? product : `explore`;
}
