import fs from 'fs';
import path from 'path';
import Markdoc from '@markdoc/markdoc';
import { glob } from 'glob';
import matter from 'gray-matter';
import type { RenderableTreeNode } from '@markdoc/markdoc';
import { config } from './config';

const ARTICLE_PATHS = {
  blog: `markdoc/articles/blog`,
  program: `markdoc/articles/programs`,
  help: `markdoc/articles/help`,
  guide: `markdoc/articles/guides`,
  update: `markdoc/articles/updates`,
  legal: `markdoc/articles/legal`,
} as const;

export type PublishingArticleType = `help` | `guide` | `update` | `legal`;
export type ArticleType = `blog` | `program` | PublishingArticleType;
export type ArticleProduct = `mac` | `blocker` | `music` | `podcasts`;
export type ArticlePlatform = `macos` | `ios` | `ipados`;
export type UpdateWeight = `brief` | `featured`;

export interface Article {
  type: ArticleType;
  content: RenderableTreeNode;
  title: string;
  slug: string;
  description: string;
  image?: string;
  updated?: string;
}

export interface BlogArticle extends Article {
  type: `blog`;
  date: string;
  category: `engineering` | `mac` | `ios`;
  products: ArticleProduct[];
  platforms: ArticlePlatform[];
}

export interface ProgramArticle extends Article {
  type: `program`;
  date: string;
  category: `engineering` | `mac` | `ios`;
  products: ArticleProduct[];
  platforms: ArticlePlatform[];
}

export interface PublishingArticle extends Article {
  type: PublishingArticleType;
  products: ArticleProduct[];
  platforms: ArticlePlatform[];
}

export interface HelpArticle extends PublishingArticle {
  type: `help`;
  platforms: [ArticlePlatform, ...ArticlePlatform[]];
}

export interface GuideArticle extends PublishingArticle {
  type: `guide`;
}

export interface UpdateArticle extends PublishingArticle {
  type: `update`;
  date: string;
  weight: UpdateWeight;
}

export interface LegalArticle extends PublishingArticle {
  type: `legal`;
}

interface PublishingMetadata {
  title: string;
  description: string;
  image?: string;
  updated?: string;
  products: ArticleProduct[];
  platforms: ArticlePlatform[];
}

interface HelpMetadata extends PublishingMetadata {
  platforms: [ArticlePlatform, ...ArticlePlatform[]];
}

interface UpdateMetadata extends PublishingMetadata {
  date: string;
  weight: UpdateWeight;
}

type PublishingMetadataOfType<T extends PublishingArticleType> = T extends `help`
  ? HelpMetadata
  : T extends `update`
    ? UpdateMetadata
    : PublishingMetadata;

type ArticleOfType<T extends ArticleType> = T extends `blog`
  ? BlogArticle
  : T extends `program`
    ? ProgramArticle
    : T extends `help`
      ? HelpArticle
      : T extends `guide`
        ? GuideArticle
        : T extends `update`
          ? UpdateArticle
          : LegalArticle;

const ARTICLE_PRODUCTS: ArticleProduct[] = [`mac`, `blocker`, `music`, `podcasts`];
const ARTICLE_PLATFORMS: ArticlePlatform[] = [`macos`, `ios`, `ipados`];
const UPDATE_WEIGHTS: UpdateWeight[] = [`brief`, `featured`];
const SHARED_PUBLISHING_FIELDS = [
  `title`,
  `description`,
  `image`,
  `updated`,
  `products`,
  `platforms`,
];

// returns all paths by default unless certain slugs are specified
export async function getArticlePaths(
  type: ArticleType,
  slugs?: string[],
): Promise<string[]> {
  const dirPath = path.join(process.cwd(), ARTICLE_PATHS[type]);
  const articlePaths = await glob(`${dirPath}/**/*.md`);
  if (slugs) {
    return articlePaths.filter((articlePath) =>
      slugs.includes(articleSlugFromPath(dirPath, articlePath)),
    );
  }
  return articlePaths;
}

export async function getArticleSlugs(type: ArticleType): Promise<string[]> {
  const dirPath = path.join(process.cwd(), ARTICLE_PATHS[type]);
  const filePaths = await getArticlePaths(type);
  return filePaths.map((articlePath) => articleSlugFromPath(dirPath, articlePath));
}

function articleSlugFromPath(dirPath: string, articlePath: string): string {
  return path
    .relative(dirPath, articlePath)
    .replace(/\.md$/, ``)
    .split(path.sep)
    .join(`/`);
}

export function validatePublishingMetadata<T extends PublishingArticleType>(
  type: T,
  metadata: Record<string, unknown>,
  slug: string,
): PublishingMetadataOfType<T> {
  const allowedFields =
    type === `update`
      ? [...SHARED_PUBLISHING_FIELDS, `date`, `weight`]
      : SHARED_PUBLISHING_FIELDS;
  const unexpectedFields = Object.keys(metadata).filter(
    (field) => !allowedFields.includes(field),
  );
  if (unexpectedFields.length > 0) {
    throw new Error(
      `Unexpected metadata in ${slug}.md: ${unexpectedFields.sort().join(`, `)}`,
    );
  }

  const sharedMetadata: PublishingMetadata = {
    title: requiredString(metadata, `title`, slug),
    description: requiredString(metadata, `description`, slug),
    image: optionalString(metadata, `image`, slug),
    updated: optionalDate(metadata, `updated`, slug),
    products: optionalEnumArray(metadata, `products`, ARTICLE_PRODUCTS, slug),
    platforms: optionalEnumArray(metadata, `platforms`, ARTICLE_PLATFORMS, slug),
  };

  if (type === `help`) {
    if (sharedMetadata.platforms.length === 0) {
      throw new Error(`Help article ${slug}.md must have at least one platform`);
    }
    if (
      sharedMetadata.platforms.includes(`macos`) &&
      sharedMetadata.platforms.some((platform) => platform !== `macos`)
    ) {
      throw new Error(`Help article ${slug}.md cannot mix Mac and mobile platforms`);
    }
    return {
      ...sharedMetadata,
      platforms: sharedMetadata.platforms as [ArticlePlatform, ...ArticlePlatform[]],
    } as PublishingMetadataOfType<T>;
  }

  if (type !== `update`) {
    return sharedMetadata as PublishingMetadataOfType<T>;
  }

  const date = requiredString(metadata, `date`, slug);
  if (Number.isNaN(Date.parse(date))) {
    throw new Error(`Invalid date in ${slug}.md: ${date}`);
  }

  return {
    ...sharedMetadata,
    date,
    weight: requiredEnum(metadata, `weight`, UPDATE_WEIGHTS, slug),
  } as PublishingMetadataOfType<T>;
}

export function getHelpUrlSegment(
  platforms: [ArticlePlatform, ...ArticlePlatform[]],
): `mac` | `iphone-ipad` {
  return platforms.includes(`macos`) ? `mac` : `iphone-ipad`;
}

export function getHelpArticlePath(
  article: Pick<HelpArticle, `platforms` | `slug`>,
): string {
  return `/help/${getHelpUrlSegment(article.platforms)}/${article.slug}`;
}

export function getBlogArticlePath(article: Pick<BlogArticle, `slug`>): string {
  return `/blog/${article.slug}`;
}

export function getProgramArticlePath(article: Pick<ProgramArticle, `slug`>): string {
  return `/${article.slug}`;
}

export function getGuideArticlePath(article: Pick<GuideArticle, `slug`>): string {
  return `/guides/${article.slug}`;
}

export function getUpdateArticlePath(article: Pick<UpdateArticle, `slug`>): string {
  return `/updates/${article.slug}`;
}

export function getLegalArticlePath(article: Pick<LegalArticle, `slug`>): string {
  return `/legal/${article.slug}`;
}

export async function getArticle<T extends ArticleType>(
  slug: string,
  type: T,
): Promise<ArticleOfType<T>> {
  const [filePath] = await getArticlePaths(type, [slug]);
  if (!filePath) {
    throw new Error(`Article not found: ${slug}`);
  }
  const rawText = fs.readFileSync(filePath, `utf-8`);
  const matterResult = matter(rawText);
  const metadata = matterResult.data as Record<string, unknown>;
  const ast = Markdoc.parse(rawText);
  const content = Markdoc.transform(ast, config);

  if (type !== `blog` && type !== `program`) {
    return {
      type,
      content,
      slug,
      ...validatePublishingMetadata(type, metadata, slug),
    } as ArticleOfType<T>;
  }

  const { title, description, image, date, updated, category } = metadata;
  if (!title || typeof title !== `string`) throw new Error(`Missing title in ${slug}.md`);
  if (!description || typeof description !== `string`)
    throw new Error(`Missing description in ${slug}.md`);

  if (!date || typeof date !== `string`) throw new Error(`Missing date in ${slug}.md`);
  if (
    updated !== undefined &&
    (typeof updated !== `string` || Number.isNaN(Date.parse(updated)))
  ) {
    throw new Error(`Invalid updated date in ${slug}.md`);
  }
  if (
    !category ||
    typeof category !== `string` ||
    ![`engineering`, `mac`, `ios`].includes(category)
  )
    throw new Error(`Missing or invalid category in ${slug}.md`);
  const blogCategory = category as BlogArticle[`category`] | ProgramArticle[`category`];
  return {
    type,
    content,
    title,
    description,
    image,
    date,
    updated,
    category: blogCategory,
    slug,
    ...getCategoryAssociations(blogCategory),
  } as ArticleOfType<T>;
}

function getCategoryAssociations(
  category: BlogArticle[`category`] | ProgramArticle[`category`],
): Pick<BlogArticle, `products` | `platforms`> {
  switch (category) {
    case `mac`:
      return { products: [`mac`], platforms: [`macos`] };
    case `ios`:
      return { products: [`blocker`], platforms: [`ios`, `ipados`] };
    case `engineering`:
      return { products: [], platforms: [] };
  }
}

function requiredString(
  metadata: Record<string, unknown>,
  field: string,
  slug: string,
): string {
  const value = metadata[field];
  if (typeof value !== `string` || value.trim() === ``) {
    throw new Error(`Missing or invalid ${field} in ${slug}.md`);
  }
  return value;
}

function optionalString(
  metadata: Record<string, unknown>,
  field: string,
  slug: string,
): string | undefined {
  const value = metadata[field];
  if (value === undefined) return undefined;
  if (typeof value !== `string` || value.trim() === ``) {
    throw new Error(`Invalid ${field} in ${slug}.md`);
  }
  return value;
}

function optionalDate(
  metadata: Record<string, unknown>,
  field: string,
  slug: string,
): string | undefined {
  const value = optionalString(metadata, field, slug);
  if (value !== undefined && Number.isNaN(Date.parse(value))) {
    throw new Error(`Invalid ${field} in ${slug}.md`);
  }
  return value;
}

function requiredEnum<T extends string>(
  metadata: Record<string, unknown>,
  field: string,
  allowedValues: T[],
  slug: string,
): T {
  const value = metadata[field];
  if (typeof value !== `string` || !allowedValues.includes(value as T)) {
    throw new Error(
      `Missing or invalid ${field} in ${slug}.md; expected one of: ${allowedValues.join(`, `)}`,
    );
  }
  return value as T;
}

function optionalEnumArray<T extends string>(
  metadata: Record<string, unknown>,
  field: string,
  allowedValues: T[],
  slug: string,
): T[] {
  const value = metadata[field];
  if (value === undefined) return [];
  if (!Array.isArray(value) || value.length === 0) {
    throw new Error(`Invalid ${field} in ${slug}.md; expected a non-empty array`);
  }
  if (
    value.some(
      (entry) => typeof entry !== `string` || !allowedValues.includes(entry as T),
    )
  ) {
    throw new Error(
      `Invalid ${field} in ${slug}.md; expected values from: ${allowedValues.join(`, `)}`,
    );
  }
  if (new Set(value).size !== value.length) {
    throw new Error(`Duplicate ${field} in ${slug}.md`);
  }
  return value as T[];
}
