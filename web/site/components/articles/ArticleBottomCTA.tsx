import { ArrowRightIcon, ExternalLinkIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';
import type { ArticleCTAVariant } from './articleCTAVariant';
import Button from '@/components/Button';
import { PARENTS_APP_URL } from '@/lib/urls';

export type { ArticleCTAVariant } from './articleCTAVariant';

type CTAConfig = {
  name: string;
  description: React.ReactNode;
  detail: string;
  logo?: string;
  primary: {
    label: string;
    href: string;
    external?: boolean;
  };
  secondary?: {
    label: string;
    href: string;
  };
};

const CTA_CONFIG: Record<ArticleCTAVariant, CTAConfig> = {
  mac: {
    name: `Gertrude for Mac`,
    description: (
      <>
        Gertrude for Mac helps you protect your kids online with{` `}
        <strong>strict internet filtering</strong> you can manage from your own computer
        or phone, plus optional screenshot monitoring, keylogging, and app blocking.
      </>
    ),
    detail: `$10/month for your whole family · 21-day free trial`,
    logo: `/article-cta/mac.svg`,
    primary: {
      label: `Start free trial`,
      href: `${PARENTS_APP_URL}/signup`,
    },
    secondary: { label: `Learn about Gertrude for Mac`, href: `/mac` },
  },
  blocker: {
    name: `Gertrude Blocker`,
    description: (
      <>
        Gertrude Blocker closes gaps in Apple’s Screen Time controls by blocking GIF
        search, internet images, and other content inside built-in iPhone and iPad apps.
      </>
    ),
    detail: `Free for users under 18 · Adults can use it with supervised mode for $10/year`,
    logo: `/article-cta/blocker.svg`,
    primary: {
      label: `Download on the App Store`,
      href: `https://apps.apple.com/us/app/gertrude-blocker/id6736368820`,
      external: true,
    },
    secondary: { label: `Learn about Gertrude Blocker`, href: `/iphone-and-ipad` },
  },
  music: {
    name: `Gertrude Music`,
    description: (
      <>
        Gertrude Music gives kids a parent-controlled music app limited to only the
        artists, albums, playlists, and songs you approve. Manage music for your whole
        family from your browser.
      </>
    ),
    detail: `$5/month for your whole family`,
    logo: `/article-cta/music.svg`,
    primary: {
      label: `Download on the App Store`,
      href: `https://apps.apple.com/us/app/gertrude-music/id6782194077`,
      external: true,
    },
    secondary: { label: `Learn about Gertrude Music`, href: `/music` },
  },
  podcasts: {
    name: `Gertrude Podcasts`,
    description: (
      <>
        Gertrude Podcasts gives kids a simple podcast player where every show is
        parent-approved and searching for new content is protected by a PIN.
      </>
    ),
    detail: `$10/year for your whole family · 30-day free trial`,
    logo: `/article-cta/podcasts.svg`,
    primary: {
      label: `Download on the App Store`,
      href: `https://apps.apple.com/us/app/gertrude-podcasts/id6753187429`,
      external: true,
    },
    secondary: { label: `Learn about Gertrude Podcasts`, href: `/#podcasts` },
  },
  explore: {
    name: `Explore Gertrude apps`,
    description: (
      <>
        Gertrude makes focused parental-control apps for safer Macs, iPhones, iPads,
        music, and podcasts. Explore the lineup and choose the tools that fit your family.
      </>
    ),
    detail: `Focused apps · Parent-managed · Built for Apple devices`,
    primary: { label: `Explore Gertrude apps`, href: `/` },
    secondary: { label: `Compare plans`, href: `/pricing` },
  },
};

interface Props {
  variant: ArticleCTAVariant;
}

const ArticleBottomCTA: React.FC<Props> = ({ variant }) => {
  const config = CTA_CONFIG[variant];
  const externalProps = config.primary.external
    ? { target: `_blank`, rel: `noopener noreferrer` }
    : {};

  return (
    <aside className="relative overflow-hidden rounded-[2rem] border border-white bg-white/30 p-2 shadow-[0_2px_4px_rgba(28,25,23,0.05),0_24px_64px_-32px_rgba(76,29,149,0.22)]">
      <div className="relative overflow-hidden rounded-[1.5rem] border-[0.5px] border-violet-600/10 bg-white px-6 py-7 xs:px-8 xs:py-8 shadow shadow-violet-900/5">
        <div
          aria-hidden="true"
          className="absolute -right-20 -top-28 size-72 rounded-full bg-gradient-to-br from-violet-100 to-fuchsia-100 blur-3xl"
        />
        <div className="relative grid items-center gap-7 md:grid-cols-[1fr_auto] md:gap-10">
          <div>
            {config.logo ? (
              <img
                src={config.logo}
                alt={config.name}
                className="h-12 w-auto max-w-full xs:h-14"
              />
            ) : (
              <ExploreBrand />
            )}
            <p className="mt-5 max-w-2xl text-base leading-7 text-stone-700">
              {config.description}
            </p>
            <p className="mt-4 text-sm font-medium text-stone-500">{config.detail}</p>
          </div>
          <div className="flex shrink-0 flex-col items-start gap-3 md:items-stretch">
            <Button
              type="link"
              href={config.primary.href}
              color="primary"
              variant="flat"
              Icon={config.primary.external ? ExternalLinkIcon : ArrowRightIcon}
              iconPosition="right"
              {...externalProps}
            >
              {config.primary.label}
            </Button>
            {config.secondary && (
              <Link
                href={config.secondary.href}
                className="text-center text-sm font-semibold text-violet-700 underline decoration-violet-300 underline-offset-2"
              >
                {config.secondary.label}
              </Link>
            )}
          </div>
        </div>
      </div>
    </aside>
  );
};

export default ArticleBottomCTA;

const ExploreBrand: React.FC = () => (
  <div className="flex flex-col items-start gap-4 sm:flex-row sm:items-center">
    <img
      src="/article-cta/logo-wordmark.svg"
      alt="Gertrude"
      className="h-8 w-auto max-w-full xs:h-9"
    />
    <div className="flex shrink-0 -space-x-2.5">
      {[
        `/app-icons/gertrude.webp`,
        `/app-icons/gertrude.webp`,
        `/app-icons/music.webp`,
        `/app-icons/podcasts.webp`,
      ].map((icon, index) => (
        <img
          key={`${icon}-${index}`}
          src={icon}
          alt=""
          className="relative size-10 rounded-[11px] shadow shadow-violet-950/15 rotate-6 border-[0.5px] border-white"
          style={{ zIndex: 3 - index }}
        />
      ))}
    </div>
  </div>
);
