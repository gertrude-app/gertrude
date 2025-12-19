import fs from 'fs';
import path from 'path';
import Markdoc from '@markdoc/markdoc';
import { glob } from 'glob';
import matter from 'gray-matter';
import type { RenderableTreeNode } from '@markdoc/markdoc';
import { config } from './config';

const DOCS_ARTICLES_PATH = `markdoc/articles/docs`;
const BLOG_ARTICLES_PATH = `markdoc/articles/blog`;
export const DOCS_ARTICLES_DIR = path.join(process.cwd(), DOCS_ARTICLES_PATH);
export const BLOG_ARTICLES_DIR = path.join(process.cwd(), BLOG_ARTICLES_PATH);

type ArticleType = `docs` | `blog`;

export interface Article {
  type: ArticleType;
  content: RenderableTreeNode;
  title: string;
  slug: string;
  description: string;
  image?: string;
}

export interface DocsArticle extends Article {
  type: `docs`;
}

export interface BlogArticle extends Article {
  type: `blog`;
  date: string;
  category: `engineering` | `mac` | `ios`;
}

type ArticleOfType<T extends ArticleType> = T extends `docs` ? DocsArticle : BlogArticle;

// returns all paths by default unless certain slugs are specified
export async function getArticlePaths(
  category: `docs` | `blog`,
  slugs?: string[],
): Promise<string[]> {
  const dirPath = category === `docs` ? DOCS_ARTICLES_DIR : BLOG_ARTICLES_DIR;
  const articlePaths = await glob(`${dirPath}/*.md`);
  if (slugs) {
    return articlePaths.filter((p) => slugs.some((s) => p.includes(`/${s}.md`)));
  }
  return articlePaths;
}

export async function getArticleSlugs(category: `docs` | `blog`): Promise<string[]> {
  const filePaths = await getArticlePaths(category);
  return filePaths.map((p) => path.basename(p, `.md`));
}

// if type === 'docs', you get a `DocsArticle`, if type === 'blog', you get a `BlogArticle`
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
  const { title, description, image, date, category } = matterResult.data;
  const ast = Markdoc.parse(rawText);
  const content = Markdoc.transform(ast, config);

  if (!title || typeof title !== `string`) throw new Error(`Missing title in ${slug}.md`);
  if (!description || typeof description !== `string`)
    throw new Error(`Missing description in ${slug}.md`);

  if (type === `docs`) {
    if (typeof date === `string`)
      throw new Error(
        `Unnecessary date in ${slug}.md\nDocumentation articles do not need a date`,
      );
    if (typeof category === `string`)
      throw new Error(
        `Unnecessary category in ${slug}.md\n Documentation articles do not need a category`,
      );
    return {
      content,
      title,
      description,
      image,
      slug,
    } as ArticleOfType<T>;
  }

  if (!date || typeof date !== `string`) throw new Error(`Missing date in ${slug}.md`);
  if (
    !category ||
    typeof category !== `string` ||
    ![`engineering`, `mac`, `ios`].includes(category)
  )
    throw new Error(`Missing or invalid category in ${slug}.md`);
  return {
    content,
    title,
    description,
    image,
    date,
    category,
    slug,
  } as ArticleOfType<T>;
}
