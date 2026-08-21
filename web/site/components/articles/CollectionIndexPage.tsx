import { GeistSans } from 'geist/font/sans';
import { ArrowRightIcon, ChevronLeftIcon } from 'lucide-react';
import Link from 'next/link';
import React from 'react';

export interface CollectionIndexItem {
  href: string;
  title: string;
  description: string;
  meta?: React.ReactNode;
}

interface Props {
  title: string;
  description: string;
  items: CollectionIndexItem[];
}

const CollectionIndexPage: React.FC<Props> = ({ title, description, items }) => (
  <main className={`${GeistSans.className} min-h-screen bg-violet-50/50 text-stone-950`}>
    <header className="border-b border-violet-100 bg-gradient-to-b from-violet-50 to-violet-50/50 px-6 py-12 xs:px-8 md:py-16">
      <div className="mx-auto max-w-5xl">
        <Link
          href="/resources"
          className="group inline-flex items-center gap-1 text-sm font-semibold text-violet-700"
        >
          <ChevronLeftIcon className="size-4 transition-transform duration-200 group-hover:-translate-x-0.5" />
          All articles
        </Link>
        <h1 className="mt-5 text-4xl font-semibold tracking-[-0.035em] xs:text-5xl">
          {title}
        </h1>
        <p className="mt-4 max-w-2xl text-lg leading-8 text-stone-600">{description}</p>
      </div>
    </header>
    <div className="px-6 py-10 xs:px-8 md:py-14">
      <div className="mx-auto max-w-5xl border-y border-stone-300">
        {items.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className="group flex items-center gap-6 border-b border-stone-200 py-5 last:border-b-0"
          >
            <span className="min-w-0 flex-1">
              {item.meta && (
                <span className="flex flex-wrap items-center gap-2 text-xs font-semibold uppercase tracking-[0.08em] text-stone-400">
                  {item.meta}
                </span>
              )}
              <span
                className={`${item.meta ? `mt-1.5` : ``} block text-xl font-semibold leading-7 tracking-[-0.015em] text-stone-950 transition-colors duration-200 group-hover:text-violet-700`}
              >
                {item.title}
              </span>
              <span className="mt-2 block max-w-3xl leading-7 text-stone-600">
                {item.description}
              </span>
            </span>
            <ArrowRightIcon className="size-4 shrink-0 text-stone-400 transition-[color,transform] duration-200 group-hover:translate-x-1 group-hover:text-violet-600" />
          </Link>
        ))}
      </div>
    </div>
  </main>
);

export default CollectionIndexPage;
