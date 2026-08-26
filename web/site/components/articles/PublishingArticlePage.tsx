import { formatUtcDate } from '@shared/datetime';
import { GeistSans } from 'geist/font/sans';
import { ChevronLeftIcon, MonitorIcon, SmartphoneIcon, TabletIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import type {
  ArticlePlatform,
  ArticleProduct,
  BlogArticle,
  GuideArticle,
  HelpArticle,
  LegalArticle,
  ProgramArticle,
  UpdateArticle,
} from '@/markdoc/files';
import ArticleBottomCTA from './ArticleBottomCTA';
import Prose from './Prose';
import { getArticleCTAVariant } from './articleCTAVariant';

type Article =
  | BlogArticle
  | GuideArticle
  | HelpArticle
  | LegalArticle
  | ProgramArticle
  | UpdateArticle;

interface Props {
  article: Article;
  backLink?: {
    href: string;
    label: string;
  };
  children: React.ReactNode;
}

const PLATFORM_LABELS: Record<ArticlePlatform, string> = {
  macos: `macOS`,
  ios: `iOS`,
  ipados: `iPadOS`,
};

const PLATFORM_ICONS: Record<ArticlePlatform, typeof MonitorIcon> = {
  macos: MonitorIcon,
  ios: SmartphoneIcon,
  ipados: TabletIcon,
};

const PRODUCT_DETAILS: Record<
  ArticleProduct,
  { label: string; icon: string; href: string }
> = {
  mac: { label: `Gertrude for Mac`, icon: `/app-icons/gertrude.webp`, href: `/mac` },
  blocker: {
    label: `Gertrude Blocker`,
    icon: `/gertrude-icon.png`,
    href: `/iphone-and-ipad`,
  },
  podcasts: {
    label: `Gertrude Podcasts`,
    icon: `/app-icons/podcasts.webp`,
    href: `/#podcasts`,
  },
  music: { label: `Gertrude Music`, icon: `/app-icons/music.webp`, href: `/music` },
};

const PublishingArticlePage: React.FC<Props> = ({ article, backLink, children }) => (
  <article className={`${GeistSans.className} bg-violet-50/50`}>
    <header className="relative overflow-hidden border-b border-violet-100 bg-gradient-to-b from-violet-50 to-violet-50/50 py-16 md:py-24">
      <div
        aria-hidden="true"
        className="absolute -right-32 -top-48 size-128 rounded-full bg-fuchsia-200/40 blur-3xl"
      />
      <div className="relative mx-auto max-w-4xl px-6 xs:px-8">
        {backLink && (
          <Link
            href={backLink.href}
            className="inline-flex items-center gap-1 text-sm font-semibold text-violet-600 transition-colors duration-200 hover:text-violet-800"
          >
            <ChevronLeftIcon className="size-4" />
            {backLink.label}
          </Link>
        )}
        {(article.type === `blog` ||
          article.type === `program` ||
          article.type === `update`) && (
          <time
            dateTime={article.date}
            className="mt-9 block text-sm font-semibold text-stone-500"
          >
            {formatUtcDate(article.date)}
          </time>
        )}
        <h1
          className={`${article.type === `blog` || article.type === `program` || article.type === `update` ? `mt-3` : `mt-9`} text-4xl font-semibold leading-[1.08] tracking-[-0.025em] text-stone-950 xs:text-5xl md:text-6xl`}
        >
          {article.title}
        </h1>
        <p className="mt-6 max-w-2xl text-lg leading-8 text-stone-600 xs:text-xl">
          {article.description}
        </p>
        {(article.platforms.length > 0 || article.products.length > 0) && (
          <dl className="mt-9 flex flex-wrap gap-x-8 gap-y-5">
            {article.platforms.length > 0 && (
              <div className="flex flex-wrap items-center gap-2">
                <dt className="mr-1 text-[11px] font-semibold uppercase tracking-[0.13em] text-stone-500">
                  {article.platforms.length === 1 ? `Platform` : `Platforms`}
                </dt>
                <dd className="flex flex-wrap gap-2">
                  {article.platforms.map((platform) => {
                    const PlatformIcon = PLATFORM_ICONS[platform];
                    return (
                      <span
                        key={platform}
                        className="inline-flex items-center gap-2 rounded-xl border border-stone-200 bg-white px-2.5 py-1.5 text-sm font-medium text-stone-800 shadow-[inset_0_1px_0_rgba(255,255,255,0.9),0_1px_2px_rgba(28,25,23,0.08)]"
                      >
                        <PlatformIcon
                          className="size-4 text-stone-500"
                          strokeWidth={1.8}
                        />
                        {PLATFORM_LABELS[platform]}
                      </span>
                    );
                  })}
                </dd>
              </div>
            )}
            {article.products.length > 0 && (
              <div className="flex flex-wrap items-center gap-2">
                <dt className="mr-1 text-[11px] font-semibold uppercase tracking-[0.13em] text-stone-500">
                  {article.products.length === 1 ? `App` : `Apps`}
                </dt>
                <dd className="flex flex-wrap gap-2">
                  {article.products.map((product) => {
                    const details = PRODUCT_DETAILS[product];
                    return (
                      <Link
                        key={product}
                        href={details.href}
                        className="inline-flex items-center gap-2 rounded-xl border border-stone-200 bg-white py-1.5 pl-1.5 pr-2.5 text-sm font-medium text-stone-800 shadow-[inset_0_1px_0_rgba(255,255,255,0.9),0_1px_2px_rgba(28,25,23,0.08)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-violet-400 focus-visible:ring-offset-2 focus-visible:ring-offset-violet-50"
                      >
                        <img
                          src={details.icon}
                          alt=""
                          className="m-0 size-5 rounded-[5px] shadow-sm"
                        />
                        {details.label}
                      </Link>
                    );
                  })}
                </dd>
              </div>
            )}
          </dl>
        )}
      </div>
    </header>
    <div className="mx-auto max-w-4xl px-6 py-14 xs:px-8 md:py-20">
      <Prose>{children}</Prose>
      {article.type !== `legal` && (
        <div className="mt-20">
          <ArticleBottomCTA variant={getArticleCTAVariant(article.products)} />
        </div>
      )}
    </div>
  </article>
);

export default PublishingArticlePage;
