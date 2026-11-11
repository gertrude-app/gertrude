import { StarIcon } from 'lucide-react';
import React from 'react';
import type { AppStoreRating } from '@/lib/app-store-ratings';
import HomeSectionRails from '@/components/home/HomeSectionRails';
import { appStoreRatings } from '@/lib/app-store-ratings';

const HomeTrustStrip: React.FC = () => (
  <section
    aria-labelledby="app-store-ratings-heading"
    className="border-t border-stone-200/80 bg-white"
  >
    <HomeSectionRails className="px-6 py-10 sm:py-20">
      <h2 id="app-store-ratings-heading" className="sr-only">
        Gertrude App Store ratings
      </h2>
      <div className="mx-auto grid max-w-5xl grid-cols-3 gap-3 sm:gap-6">
        {Object.values(appStoreRatings).map((app) => (
          <AppRating key={app.name} {...app} />
        ))}
      </div>
    </HomeSectionRails>
  </section>
);

export default HomeTrustStrip;

const AppRating: React.FC<AppStoreRating> = ({ name, rating, count, url }) => (
  <a href={url} target="_blank" rel="noreferrer" className="flex flex-col items-center">
    <span className="text-2xl font-semibold sm:text-3xl">{rating}</span>
    <div className="flex gap-0.5 mt-1 mb-2 sm:gap-2">
      <StarIcon fill="currentColor" className="size-3 text-yellow-400 sm:size-7" />
      <StarIcon fill="currentColor" className="size-3 text-yellow-400 sm:size-7" />
      <StarIcon fill="currentColor" className="size-3 text-yellow-400 sm:size-7" />
      <StarIcon fill="currentColor" className="size-3 text-yellow-400 sm:size-7" />
      <StarIcon fill="currentColor" className="size-3 text-yellow-400 sm:size-7" />
    </div>
    <div className="flex items-center gap-2">
      <span className="min-h-8 text-center text-xs font-medium leading-4 text-stone-900 sm:min-h-0 sm:text-base sm:leading-6">
        {name}
      </span>
    </div>
    <span className="text-stone-500 text-xs">
      {count === null ? `New` : `${count} ratings`}
    </span>
  </a>
);
