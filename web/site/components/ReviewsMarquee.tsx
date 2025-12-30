'use client';

import cx from 'classnames';
import React, { useEffect, useRef, useState } from 'react';

interface Review {
  title: string;
  body: string;
  author: string;
  date?: string;
  showStars?: boolean;
}

interface ReviewsMarqueeProps {
  title: string;
  subtitle: string;
  reviews: Review[][];
  appStoreUrl?: string;
  rating?: string;
}

const ReviewsMarquee: React.FC<ReviewsMarqueeProps> = ({
  title,
  subtitle,
  reviews,
  appStoreUrl,
  rating,
}) => (
  <section className="relative bg-gradient-to-b from-violet-50 via-slate-50 to-violet-50 pt-14 pb-20 sm:pt-20 sm:pb-32 overflow-hidden">
    <div className="absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-violet-300 to-transparent" />
    <div className="absolute inset-x-0 bottom-0 h-px bg-gradient-to-r from-transparent via-violet-300 to-transparent" />
    <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
      <h2 className="text-4xl sm:text-5xl font-bold tracking-tight text-slate-900 text-center">
        {title}
      </h2>
      {rating && appStoreUrl ? (
        <a
          href={appStoreUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="mt-5 flex flex-col xs:flex-row items-center justify-center gap-2 xs:gap-3 group"
        >
          <div className="flex">
            {[...Array(5)].map((_, i) => (
              <svg
                key={i}
                viewBox="0 0 20 20"
                aria-hidden="true"
                className="h-6 w-6 fill-violet-500"
              >
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
            ))}
          </div>
          <span className="text-lg font-semibold text-slate-600 group-hover:text-violet-700 transition-colors inline-flex items-center gap-2">
            {rating} stars on the App Store
            <svg
              className="size-5 text-violet-400 group-hover:text-violet-600 transition-colors"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6M15 3h6v6M10 14L21 3" />
            </svg>
          </span>
        </a>
      ) : (
        <p className="mt-2 text-lg text-slate-600 sm:text-center">{subtitle}</p>
      )}
      <div className="relative -mx-4 mt-16 grid h-[49rem] max-h-[150vh] grid-cols-1 items-start gap-8 overflow-hidden px-4 sm:mt-20 md:grid-cols-2 lg:grid-cols-3">
        <div className="pointer-events-none absolute inset-x-0 top-0 z-10 h-32 bg-gradient-to-b from-violet-50 via-violet-50/80 to-transparent" />
        <div className="pointer-events-none absolute inset-x-0 bottom-0 z-10 h-32 bg-gradient-to-t from-violet-50 via-violet-50/80 to-transparent" />
        {reviews.map((column, columnIndex) => (
          <ReviewColumn key={columnIndex} reviews={column} columnIndex={columnIndex} />
        ))}
      </div>
    </div>
  </section>
);

interface ReviewColumnProps {
  reviews: Review[];
  columnIndex: number;
}

const ReviewColumn: React.FC<ReviewColumnProps> = ({ reviews, columnIndex }) => {
  const columnRef = useRef<HTMLDivElement>(null);
  const [columnHeight, setColumnHeight] = useState(0);
  const duration = `${(columnHeight + reviews.length * 32) * 18}ms`;

  useEffect(() => {
    if (columnRef.current) {
      setColumnHeight(columnRef.current.scrollHeight);
    }
  }, [reviews]);

  return (
    <div
      ref={columnRef}
      className={cx(
        `animate-marquee space-y-8 py-4`,
        columnIndex === 1 && `hidden md:block`,
        columnIndex === 2 && `hidden lg:block`,
      )}
      style={{ '--marquee-duration': duration } as React.CSSProperties}
    >
      {[...reviews, ...reviews].map((review, index) => (
        <ReviewCard
          key={index}
          review={review}
          index={index}
          ariaHidden={index >= reviews.length}
        />
      ))}
    </div>
  );
};

interface ReviewCardProps {
  review: Review;
  index: number;
  ariaHidden?: boolean;
}

const ReviewCard: React.FC<ReviewCardProps> = ({ review, index, ariaHidden }) => {
  const showStars = review.showStars !== false;
  return (
    <figure
      className="animate-fade-in rounded-2xl bg-white p-6 opacity-0 shadow-lg shadow-violet-900/5 border border-slate-100 hover:border-violet-200 hover:shadow-violet-200/50 transition-all duration-300"
      aria-hidden={ariaHidden}
      style={{ animationDelay: `${(index % 5) * 0.1}s` }}
    >
      <div className="text-slate-900">
        {showStars && <StarRating />}
        <p className={cx(`text-lg font-semibold leading-6`, showStars && `mt-4`)}>
          "{review.title}"
        </p>
        <p className="mt-3 text-base leading-7 text-slate-700">{review.body}</p>
      </div>
      <p className="mt-4 text-sm text-slate-500">
        <span className="font-medium text-slate-600">{review.author}</span>
        {review.date && <span className="text-slate-400 ml-2">· {review.date}</span>}
      </p>
    </figure>
  );
};

const StarRating: React.FC = () => (
  <div className="flex">
    {[...Array(5)].map((_, i) => (
      <StarIcon key={i} />
    ))}
  </div>
);

const StarIcon: React.FC = () => (
  <svg viewBox="0 0 20 20" aria-hidden="true" className="h-5 w-5 fill-violet-500">
    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
  </svg>
);

export default ReviewsMarquee;
