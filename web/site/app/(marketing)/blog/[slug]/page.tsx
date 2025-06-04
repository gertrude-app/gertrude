import path from 'path';
import Markdoc from '@markdoc/markdoc';
import cx from 'classnames';
import { ChevronLeftIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import type { Metadata, NextPage } from 'next';
import PageBottomCTA from '@/components/PageBottomCTA';
import Prose from '@/components/articles/Prose';
import { createMetadata } from '@/lib/seo';
import { components } from '@/markdoc/config';
import { getArticle, getArticlePaths } from '@/markdoc/files';

type Params = {
  slug: string;
};

type PageProps = {
  params: Params;
};

export async function generateStaticParams(): Promise<Params[]> {
  const articlePaths = await getArticlePaths(`blog`);
  return articlePaths.map((postPath) => ({
    slug: path.basename(postPath, path.extname(postPath)),
  }));
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { title, description, image } = await getArticle(params.slug, `blog`);
  return createMetadata(title, description, image);
}

const BlogArticle: NextPage<PageProps> = async ({ params: { slug } }) => {
  const { title, content, category } = await getArticle(slug, `blog`);

  return (
    <div className="flex flex-col items-center">
      <section className="self-stretch p-8 bg-fuchsia-50 sm:rounded-3xl sm:m-8">
        <Link
          href="/blog"
          className="flex items-center gap-2 text-violet-500 hover:text-violet-700 transition-colors duration-200 w-fit"
        >
          <ChevronLeftIcon />
          <span className="text-lg font-medium">Back to blog</span>
        </Link>
      </section>
      <div className="max-w-[calc(100vw-48px)] xs:max-w-[calc(100vw-64px)] md+:max-w-3xl pt-12 md:pt-28 relative mx-6 xs:mx-8 pb-32">
        <span
          className={cx(
            `capitalize text-lg font-medium`,
            category === `engineering` ? `text-fuchsia-500` : `text-violet-500`,
          )}
        >
          {category.replace(`-`, ` `)}
        </span>
        <h1
          className="text-4xl font-bold mb-8 mt-2 break-words"
          dangerouslySetInnerHTML={{ __html: title }}
        />
        <Prose>{Markdoc.renderers.react(content, React, { components })}</Prose>
        <PageBottomCTA clickId="blog-cta" />
      </div>
    </div>
  );
};

export default BlogArticle;
