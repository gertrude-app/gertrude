import path from 'path';
import React from 'react';
import { ArrowRightIcon, ChevronLeftIcon } from 'lucide-react';
import Link from 'next/link';
import cx from 'classnames';
import Markdoc from '@markdoc/markdoc';
import { Logo } from '@shared/components';
import type { Metadata, NextPage } from 'next';
import { getArticle, getArticlePaths } from '@/markdoc/files';
import { components } from '@/markdoc/config';
import Prose from '@/components/articles/Prose';
import { createMetadata } from '@/lib/seo';
import FancyLink from '@/components/FancyLink';

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

// 👍 monday jared, redirects rewrites, then commit maybe
// see list in things app

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
        <h1 className="text-4xl font-bold mb-8 mt-2 break-words">{title}</h1>
        <Prose>{Markdoc.renderers.react(content, React, { components })}</Prose>
        <div className="mt-16 p-8 sm:p-12 bg-gradient-to-br from-violet-500 to-fuchsia-500 rounded-3xl flex flex-col items-center">
          <Link href="/">
            <Logo type="inverted" />
          </Link>
          <p className="mt-8 text-center text-white sm:text-lg">
            The Gertrude mac app helps you <b>protect your kids</b> online with{` `}
            <b>strict internet filtering</b> that you can manage from your{` `}
            <b>own computer or phone,</b> plus remote monitoring of screenshots and
            keylogging. $5/mo, with a 60 day free trial.
          </p>
          <FancyLink
            type="link"
            href="https://parents.gertrude.app/signup"
            color="primary"
            inverted
            className="mt-8"
            Icon={ArrowRightIcon}
          >
            Start free trial
          </FancyLink>
        </div>
      </div>
    </div>
  );
};

export default BlogArticle;
