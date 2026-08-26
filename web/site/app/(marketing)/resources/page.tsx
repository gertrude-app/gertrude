import { formatUtcDate } from '@shared/datetime';
import { GeistSans } from 'geist/font/sans';
import { ArrowRightIcon, MonitorIcon, SmartphoneIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import type { NextPage } from 'next';
import { createMetadata } from '@/lib/seo';
import {
  type BlogArticle,
  type GuideArticle,
  type HelpArticle,
  type UpdateArticle,
  getArticle,
  getArticleSlugs,
  getBlogArticlePath,
  getGuideArticlePath,
  getHelpArticlePath,
  getUpdateArticlePath,
} from '@/markdoc/files';

export const metadata = createMetadata(
  `Resources | Gertrude`,
  `Setup guides, troubleshooting help, product updates, and articles for Gertrude families.`,
);

const GUIDE_ORDER = [
  `getting-started-with-gertrude-for-mac`,
  `locking-down-an-iphone`,
  `iphone-lockdown-loopholes`,
  `unblocking-websites-and-apps-on-mac`,
  `keeping-kids-safe-online`,
];

const MAC_HELP_ORDER = [
  `unblock-website-or-app`,
  `run-health-check`,
  `screen-time-filter-conflict`,
  `website-still-broken-after-unblocking`,
];

const MOBILE_HELP_ORDER = [
  `get-connection-code`,
  `use-blocker-over-18`,
  `block-apple-music-artwork`,
  `block-gif-search-in-messages`,
];

const ResourcesPage: NextPage = async () => {
  const [blogSlugs, guideSlugs, helpSlugs, updateSlugs] = await Promise.all([
    getArticleSlugs(`blog`),
    getArticleSlugs(`guide`),
    getArticleSlugs(`help`),
    getArticleSlugs(`update`),
  ]);
  const [blogArticles, guideArticles, helpArticles, updateArticles] = await Promise.all([
    Promise.all(blogSlugs.map((slug) => getArticle(slug, `blog`))),
    Promise.all(guideSlugs.map((slug) => getArticle(slug, `guide`))),
    Promise.all(helpSlugs.map((slug) => getArticle(slug, `help`))),
    Promise.all(updateSlugs.map((slug) => getArticle(slug, `update`))),
  ]);

  const blog = [...blogArticles].sort(byNewestDate);
  const guides = prioritizeArticles(
    guideArticles.filter((article) => !article.noindex),
    GUIDE_ORDER,
  );
  const macHelp = prioritizeArticles(
    helpArticles.filter((article) => article.platforms.includes(`macos`)),
    MAC_HELP_ORDER,
  );
  const mobileHelp = prioritizeArticles(
    helpArticles.filter((article) => !article.platforms.includes(`macos`)),
    MOBILE_HELP_ORDER,
  );
  const updates = [...updateArticles].sort(byNewestDate);
  const latestUpdate = updates[0];
  if (!latestUpdate) throw new Error(`Resources requires at least one update`);

  return (
    <main className={`${GeistSans.className} bg-violet-50/50 text-stone-950`}>
      <header className="border-b border-violet-100 bg-gradient-to-b from-violet-50 to-violet-50/50 px-6 py-12 xs:px-8 md:py-16">
        <div className="mx-auto max-w-7xl">
          <h1 className="text-4xl font-semibold tracking-[-0.035em] xs:text-5xl">
            Resources
          </h1>
          <p className="mt-4 max-w-2xl text-lg leading-8 text-stone-600">
            Setup guides, troubleshooting help, product updates, and articles for Gertrude
            families.
          </p>
        </div>
      </header>

      <div className="px-6 py-10 xs:px-8 md:py-12">
        <div className="mx-auto max-w-7xl">
          <div className="grid items-start gap-14 lg:grid-cols-[minmax(0,1.55fr)_minmax(20rem,0.7fr)] lg:gap-20">
            <div className="grid gap-14">
              <ResourcePanel
                title="Guides"
                href="/guides"
                linkLabel={`All ${guides.length} guides`}
              >
                <div className="divide-y divide-stone-200">
                  {guides.slice(0, 5).map((guide) => (
                    <GuideRow key={guide.slug} article={guide} />
                  ))}
                </div>
              </ResourcePanel>

              <ResourcePanel title="Help" href="/help" linkLabel="All help articles">
                <div className="grid gap-6 md:grid-cols-2 md:gap-0 md:divide-x md:divide-stone-200">
                  <HelpList
                    title="Mac"
                    icon={MonitorIcon}
                    articles={macHelp.slice(0, 4)}
                    href="/help/mac"
                  />
                  <HelpList
                    title="iPhone & iPad"
                    icon={SmartphoneIcon}
                    articles={mobileHelp.slice(0, 4)}
                    href="/help/iphone-ipad"
                  />
                </div>
              </ResourcePanel>

              <ResourcePanel title="Blog" href="/blog" linkLabel="All blog posts">
                <div className="divide-y divide-stone-200">
                  {blog.map((article) => (
                    <BlogRow key={article.slug} article={article} />
                  ))}
                </div>
              </ResourcePanel>
            </div>

            <UpdatesPanel articles={updates.slice(0, 7)} latest={latestUpdate} />
          </div>
        </div>
      </div>
    </main>
  );
};

export default ResourcesPage;

const ResourcePanel: React.FC<{
  title: string;
  href: string;
  linkLabel: string;
  children: React.ReactNode;
}> = ({ title, href, linkLabel, children }) => (
  <section>
    <div className="flex items-center justify-between gap-4 border-b border-stone-300 pb-3">
      <h2 className="text-xl font-semibold tracking-[-0.02em]">{title}</h2>
      <Link
        href={href}
        className="group inline-flex shrink-0 items-center gap-1 text-sm font-semibold text-violet-700"
      >
        {linkLabel}
        <ArrowRightIcon className="size-3.5 transition-transform duration-200 group-hover:translate-x-0.5" />
      </Link>
    </div>
    {children}
  </section>
);

const GuideRow: React.FC<{ article: GuideArticle }> = ({ article }) => (
  <Link
    href={getGuideArticlePath(article)}
    className="group grid gap-2 py-4 sm:grid-cols-[minmax(0,1fr)_8rem] sm:items-center sm:gap-5"
  >
    <span>
      <span className="block font-semibold leading-6 text-stone-900 group-hover:text-violet-700">
        {article.title}
      </span>
      <span className="mt-1 line-clamp-1 block text-sm text-stone-500">
        {article.description}
      </span>
    </span>
    <span className="text-xs font-semibold uppercase tracking-[0.08em] text-stone-400 sm:text-right">
      {getProductLabel(article)}
    </span>
  </Link>
);

const HelpList: React.FC<{
  title: string;
  icon: typeof MonitorIcon;
  articles: HelpArticle[];
  href: string;
}> = ({ title, icon: Icon, articles, href }) => (
  <div className="py-5 md:first:pr-8 md:last:pl-8">
    <div className="flex items-center gap-2 text-sm font-semibold text-stone-700">
      <Icon className="size-4 text-violet-600" strokeWidth={1.8} />
      <h3>{title}</h3>
    </div>
    <div className="mt-3 divide-y divide-stone-200">
      {articles.map((article) => (
        <Link
          key={article.slug}
          href={getHelpArticlePath(article)}
          className="group flex items-start gap-3 py-3 text-sm font-medium leading-5 text-stone-700 first:pt-2 hover:text-violet-700"
        >
          <span>{article.title}</span>
          <ArrowRightIcon className="ml-auto mt-0.5 size-3.5 shrink-0 text-stone-400 transition-transform duration-200 group-hover:translate-x-0.5 group-hover:text-violet-600" />
        </Link>
      ))}
    </div>
    <Link
      href={href}
      className="group mt-3 inline-flex items-center gap-1 text-sm font-semibold text-violet-700"
    >
      More {title} help
      <ArrowRightIcon className="size-3.5 transition-transform duration-200 group-hover:translate-x-0.5" />
    </Link>
  </div>
);

const UpdatesPanel: React.FC<{
  articles: UpdateArticle[];
  latest: UpdateArticle;
}> = ({ articles, latest }) => (
  <aside>
    <div className="flex items-center justify-between gap-4 pb-4">
      <h2 className="text-xl font-semibold tracking-[-0.02em]">Latest updates</h2>
      <Link
        href="/updates"
        className="group inline-flex items-center gap-1 text-sm font-semibold text-violet-700"
      >
        All updates
        <ArrowRightIcon className="size-3.5 transition-transform duration-200 group-hover:translate-x-0.5" />
      </Link>
    </div>
    <div className="relative mt-5 pl-7 before:absolute before:bottom-2 before:left-[5px] before:top-2 before:w-px before:bg-violet-200">
      {articles.map((article) => (
        <UpdateRow
          key={article.slug}
          article={article}
          image={article.slug === latest.slug ? latest.image : undefined}
        />
      ))}
    </div>
  </aside>
);

const UpdateRow: React.FC<{ article: UpdateArticle; image?: string }> = ({
  article,
  image,
}) => (
  <Link
    href={getUpdateArticlePath(article)}
    className="group relative block pb-5 last:pb-0"
  >
    <span className="absolute -left-7 top-1.5 size-[11px] rounded-full bg-violet-300 ring-4 ring-[#f8f6ff] group-hover:bg-violet-600" />
    <time dateTime={article.date} className="block text-sm text-stone-500">
      {formatUtcDate(article.date)}
    </time>
    <span className="mt-1 block font-medium leading-6 text-stone-900 group-hover:text-violet-700">
      {article.title}
    </span>
    {image && (
      <span className="mt-4 block overflow-hidden rounded-xl bg-violet-100">
        <img
          src={image}
          alt=""
          className="aspect-[2/1] w-full object-cover transition-transform duration-300 group-hover:scale-[1.01] motion-reduce:transition-none"
        />
      </span>
    )}
  </Link>
);

const BlogRow: React.FC<{ article: BlogArticle }> = ({ article }) => (
  <Link href={getBlogArticlePath(article)} className="group block py-4">
    <span className="flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.08em] text-stone-400">
      <span>{getBlogCategoryLabel(article)}</span>
      <span>·</span>
      <time dateTime={article.date}>{formatUtcDate(article.date)}</time>
    </span>
    <span className="mt-1.5 block font-semibold leading-6 text-stone-900 group-hover:text-violet-700">
      {article.title}
    </span>
  </Link>
);

function getProductLabel(article: GuideArticle): string {
  if (article.products.includes(`mac`)) return `Mac`;
  if (article.products.includes(`blocker`)) return `iPhone & iPad`;
  return `General`;
}

function getBlogCategoryLabel(article: BlogArticle): string {
  switch (article.category) {
    case `engineering`:
      return `Research`;
    case `mac`:
      return `Mac`;
    case `ios`:
      return `iPhone & iPad`;
  }
}

function prioritizeArticles<T extends GuideArticle | HelpArticle>(
  articles: T[],
  preferredSlugs: string[],
): T[] {
  const preferredOrder = new Map(
    preferredSlugs.map((slug, index) => [slug, index] as const),
  );
  return [...articles].sort((a, b) => {
    const aOrder = preferredOrder.get(a.slug) ?? Number.MAX_SAFE_INTEGER;
    const bOrder = preferredOrder.get(b.slug) ?? Number.MAX_SAFE_INTEGER;
    return aOrder - bOrder || a.title.localeCompare(b.title);
  });
}

function byNewestDate<T extends BlogArticle | UpdateArticle>(a: T, b: T): number {
  return Date.parse(b.date) - Date.parse(a.date);
}
