import Link from 'next/link';
import React from 'react';
import Logo from '@/components/Logo';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { PARENTS_APP_URL } from '@/lib/urls';

const linkGroups = [
  {
    label: `Apps`,
    links: [
      { label: `Gertrude for Mac`, href: `/mac` },
      { label: `Gertrude Blocker`, href: `/iphone-and-ipad` },
      { label: `Gertrude Music`, href: `/music` },
      { label: `Gertrude Podcasts`, href: `/#podcasts` },
    ],
  },
  {
    label: `Support`,
    links: [
      { label: `Help center`, href: `/help` },
      { label: `Setup guides`, href: `/guides` },
      { label: `Updates`, href: `/updates` },
      { label: `Contact us`, href: `/contact` },
    ],
  },
  {
    label: `Legal`,
    links: [
      { label: `Terms of service`, href: `/legal/terms` },
      { label: `Blocker privacy`, href: `/legal/privacy/blocker` },
      { label: `Music privacy`, href: `/legal/privacy/music` },
      { label: `Podcasts privacy`, href: `/legal/privacy/podcasts` },
    ],
  },
];

const linkClasses = `inline-block rounded-sm py-1 text-sm leading-6 text-stone-400 outline-none transition-colors duration-150 hover:text-stone-50 focus-visible:ring-2 focus-visible:ring-violet-400 focus-visible:ring-offset-4 focus-visible:ring-offset-stone-950 motion-reduce:transition-none`;

const HomeFooter: React.FC = () => (
  <footer data-home-header-theme="dark-static" className="bg-stone-950 text-stone-400">
    <HomeSectionRails inverted className="pb-8">
      <div className="border-t border-white/10">
        <div className="grid gap-10 px-6 pt-12 sm:px-8 sm:pt-14 lg:grid-cols-[1fr_2fr] lg:gap-20 lg:px-10 xl:px-12">
          <div>
            <Link href="/" aria-label="Gertrude home" className={linkClasses}>
              <Logo type="inverted" size={28} wordmarkSrc="/logo-wordmark-on-dark.svg" />
            </Link>
            <p className="mt-4 max-w-xs text-sm leading-6">
              Real internet safety, accountability, and curated media for Apple devices.
            </p>
          </div>
          <nav
            aria-label="Footer"
            className="grid grid-cols-2 gap-x-8 gap-y-8 xs:grid-cols-3 sm:gap-x-12"
          >
            {linkGroups.map((group) => (
              <div
                key={group.label}
                className={group.label === `Legal` ? `col-span-2 xs:col-span-1` : ``}
              >
                <h2 className="mb-3 text-sm font-medium text-stone-200">{group.label}</h2>
                <ul
                  className={
                    group.label === `Legal`
                      ? `grid grid-cols-2 gap-x-8 gap-y-1 xs:block xs:space-y-1`
                      : `space-y-1`
                  }
                >
                  {group.links.map((link) => (
                    <li key={link.href}>
                      <Link href={link.href} className={linkClasses}>
                        {link.label}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </nav>
        </div>
        <div className="mt-12 flex flex-col gap-4 border-t border-white/10 px-6 pt-6 sm:flex-row sm:items-center sm:justify-between sm:px-8 lg:px-10 xl:px-12">
          <p className="text-xs leading-6">© {new Date().getFullYear()} NetRivet Inc.</p>
          <div className="flex flex-wrap items-center gap-x-6 gap-y-2">
            <a href={PARENTS_APP_URL} className={linkClasses}>
              Log in
            </a>
            <a href={`${PARENTS_APP_URL}/signup?v=new_site`} className={linkClasses}>
              Create account
            </a>
          </div>
        </div>
      </div>
    </HomeSectionRails>
  </footer>
);

export default HomeFooter;
