import React from 'react';
import cx from 'classnames';
import { Logo } from '@shared/components';
import Link from 'next/link';
import type { NextPage } from 'next';
import { getArticle, getArticleSlugs } from '../../../markdoc/files';

export const metadata = {
  title: `Blog | Gertrude Internet Filter and Parental Controls`,
  description: `TODO: Add description`,
  openGraph: {
    title: `Blog | Gertrude Internet Filter and Parental Controls`,
    description: `TODO: Add description`,
    images: [
      {
        url: `/og-images/main.jpg`,
        width: 1200,
        height: 630,
        alt: `Gertrude | Mac Internet Filter, Parental Controls and Activity Monitoring`,
      },
    ],
  },
};

const Blog: NextPage = async () => {
  const slugs = await getArticleSlugs(`blog`);
  const articles = await Promise.all(slugs.map((slug) => getArticle(slug, `blog`)));

  return (
    <div>
      <section className="py-16 md:py-32 lg:py-40 flex items-center justify-center bg-white bg-gradient-to-b from-white to-fuchsia-100 rounded-b-3xl">
        <Logo
          iconOnly
          size={200}
          className="-ml-[52px] md:-ml-[32px] lg:ml-0 -mt-[16px] md:-mt-[20px] scale-[50%] md:scale-[70%] lg:scale-100"
        />
        <h1 className="font-axiforma -ml-12 md:-ml-6 lg:ml-0 text-7xl md:text-8xl lg:text-9xl text-slate-900 font-semibold">
          Blog
        </h1>
      </section>
      <section className="bg-white flex flex-col items-center px-8 sm:px-12 md:px-20 py-20">
        <div className="flex flex-col">
          {articles
            .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
            .map((article, index) => {
              const formatedDate = new Date(article.date).toLocaleDateString(`en-us`, {
                year: `numeric`,
                month: `long`,
                day: `numeric`,
              });
              return (
                <div className="flex items-start gap-4" key={article.title}>
                  <div className="w-52 lg:flex flex-col items-end justify-center hidden">
                    <span className="text-lg text-slate-500 mt-[30px]">
                      {formatedDate}
                    </span>
                  </div>
                  <div className="hidden xs:flex flex-col items-center justify-start self-stretch w-4 group relative shrink-0">
                    <div
                      className={cx(
                        `absolute h-full border border-dashed border-slate-300`,
                        index === 0 && `!h-[calc(100%-36px)] bottom-0`,
                        index === articles.length - 1 && `!h-9 top-0`,
                      )}
                    />
                    <div className="absolute w-4 h-4 border-2 border-slate-300 bg-white rounded-full top-[35px]" />
                  </div>
                  <Link
                    href={`/blog/${article.slug}`}
                    className={cx(
                      `w-auto md:w-152 mb-10 p-3 -m-3 rounded-xl transition-colors duration-200 flex flex-col items-start`,
                      article.category === `engineering`
                        ? `hover:bg-fuchsia-50`
                        : `hover:bg-violet-50`,
                    )}
                  >
                    <div className="flex items-center gap-2">
                      <span
                        className={cx(
                          `capitalize font-medium text-sm px-3 py-0.5 rounded-full`,
                          article.category === `engineering`
                            ? `bg-fuchsia-100 text-fuchsia-600`
                            : `bg-violet-100 text-violet-600`,
                        )}
                      >
                        {article.category.replace(`-`, ` `)}
                      </span>
                      <span className="text-sm xs:text-base text-slate-500 block lg:hidden">
                        {formatedDate}
                      </span>
                    </div>
                    <h2
                      className={`text-xl xs:text-2xl font-medium mt-1 mb-2`}
                      dangerouslySetInnerHTML={{ __html: article.title }}
                    />
                    <p className="text-slate-500">{article.description}</p>
                  </Link>
                </div>
              );
            })}
        </div>
      </section>
    </div>
  );
};

export default Blog;
