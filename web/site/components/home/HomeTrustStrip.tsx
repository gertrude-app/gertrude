import { StarIcon } from 'lucide-react';
import React from 'react';
import HomeSectionRails from '@/components/home/HomeSectionRails';

const HomeTrustStrip: React.FC = () => (
  <section
    aria-labelledby="app-store-ratings-heading"
    className="border-t border-stone-200/80 bg-white"
  >
    <HomeSectionRails className="px-6 py-20">
      <h2 id="app-store-ratings-heading" className="sr-only">
        Gertrude App Store ratings
      </h2>
      <div className="mx-auto grid max-w-5xl gap-8 sm:grid-cols-3 sm:gap-6">
        <AppRating
          name="Gertrude Blocker"
          rating="4.9"
          detail="130 ratings"
          href="https://apps.apple.com/us/app/gertrude-blocker/id6736368820"
        />
        <AppRating
          name="Gertrude Podcasts"
          rating="4.8"
          detail="26 ratings"
          href="https://apps.apple.com/us/app/gertrude-podcasts/id6753187429"
        />
        <AppRating
          name="Gertrude Music"
          rating="5.0"
          detail="New"
          href="https://apps.apple.com/us/app/gertrude-music/id6782194077"
        />
      </div>
    </HomeSectionRails>
  </section>
);

export default HomeTrustStrip;

interface AppRatingProps {
  name: string;
  rating: string;
  detail: string;
  href: string;
}

const AppRating: React.FC<AppRatingProps> = ({ name, rating, detail, href }) => (
  <a href={href} target="_blank" rel="noreferrer" className="flex flex-col items-center">
    <span className="text-3xl font-semibold">{rating}</span>
    <div className="flex gap-2 mt-1 mb-2">
      <StarIcon fill="currentColor" className="size-7 text-yellow-400" />
      <StarIcon fill="currentColor" className="size-7 text-yellow-400" />
      <StarIcon fill="currentColor" className="size-7 text-yellow-400" />
      <StarIcon fill="currentColor" className="size-7 text-yellow-400" />
      <StarIcon fill="currentColor" className="size-7 text-yellow-400" />
    </div>
    <div className="flex items-center gap-2">
      <span className="font-medium text-stone-900">{name}</span>
    </div>
    <span className="text-stone-500 text-xs">{detail}</span>
  </a>
);
