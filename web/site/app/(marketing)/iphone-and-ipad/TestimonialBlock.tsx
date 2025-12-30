import React from 'react';
import { ExternalLinkIcon, QuoteIcon, REVIEWS_URL, StarIcon } from './shared';

interface TestimonialBlockProps {
  quote: string;
  author?: string;
}

const TestimonialBlock: React.FC<TestimonialBlockProps> = ({ quote, author }) => (
  <section className="bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900 py-12 sm:py-14 border-y border-slate-700/50">
    <div className="max-w-5xl mx-auto px-4 xs:px-8 sm:px-12 md:px-20">
      <div className="flex items-start gap-4 sm:gap-6">
        <div className="shrink-0 hidden xs:block -mt-1">
          <QuoteIcon className="size-10 sm:size-12 text-violet-400/30" />
        </div>
        <div className="flex-1">
          <p className="text-lg sm:text-xl md:text-2xl text-slate-300 leading-relaxed mb-3 font-serif italic">
            {quote}
          </p>
          <div className="flex items-center gap-3">
            <div className="flex gap-0.5">
              {[...Array(5)].map((_, i) => (
                <StarIcon key={i} className="size-4 text-amber-400" />
              ))}
            </div>
            {author && (
              <a
                href={REVIEWS_URL}
                target="_blank"
                rel="noopener noreferrer"
                className="text-slate-500 text-sm hover:text-slate-400 transition-colors inline-flex items-center gap-1"
              >
                {author}
                <ExternalLinkIcon className="size-3" />
              </a>
            )}
          </div>
        </div>
      </div>
    </div>
  </section>
);

export default TestimonialBlock;
