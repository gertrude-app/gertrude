import React from 'react';
import { APP_STORE_URL } from './shared';

const PricingBlock: React.FC = () => (
  <section className="bg-gradient-to-b from-slate-900 to-slate-950 py-20 sm:py-28">
    <div className="max-w-4xl mx-auto px-4 xs:px-8 sm:px-12 md:px-20 text-center">
      <div className="flex justify-center mb-8">
        <div className="relative group">
          <div className="absolute inset-0 bg-gradient-to-br from-violet-500 to-fuchsia-500 rounded-3xl blur-xl opacity-50 group-hover:opacity-70 transition-opacity" />
          <div className="relative bg-gradient-to-br from-violet-500 to-fuchsia-500 rounded-3xl p-1">
            <div className="bg-slate-900 rounded-[20px] p-3">
              <img
                src="/gertrude-icon.png"
                alt="Gertrude"
                className="size-16 sm:size-20 rounded-2xl"
              />
            </div>
          </div>
        </div>
      </div>
      <div className="mb-6">
        <p className="text-slate-400 text-lg sm:text-xl font-medium mb-2">
          Gertrude for iOS is
        </p>
        <h2 className="text-5xl xs:text-6xl sm:text-7xl font-black tracking-tight">
          <span className="text-white">100%</span>
          {` `}
          <span className="bg-gradient-to-r from-green-400 to-emerald-400 bg-clip-text text-transparent">
            Free
          </span>
        </h2>
      </div>
      <p className="text-lg text-slate-400 mb-6 max-w-2xl mx-auto">
        Core blocking features will <b className="text-white/80">always be free</b> for
        child accounts (under 18) and self-supervised devices. No paid subscription
        required, no in-app purchases, no catches.
      </p>
      <p className="text-lg text-slate-400 mb-6 max-w-2xl mx-auto">
        Future updates may add more features with an{` `}
        <b className="text-white/80">optional</b> paid subscription.
      </p>
      <p className="text-lg text-slate-400 mb-10 max-w-2xl mx-auto">
        Adults (over 18) can use Gertrude too, but due to Apple's own rules, it requires
        putting your device in{` `}
        <a
          href="/blog"
          className="text-violet-400 hover:text-violet-300 transition-colors"
        >
          supervised mode
        </a>
        .
      </p>
      <a
        href={APP_STORE_URL}
        target="_blank"
        rel="noopener noreferrer"
        className="inline-flex items-center gap-2 bg-white text-slate-900 font-semibold px-8 py-4 rounded-full hover:bg-slate-100 transition-colors"
      >
        <svg className="size-6" viewBox="0 0 24 24" fill="currentColor">
          <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
        </svg>
        Download on the App Store
      </a>
      <p className="text-slate-500 text-sm mt-8 max-w-lg mx-auto">
        Works with iPhone and iPad running iOS 17+.
      </p>
      <p className="text-slate-400 text-base mt-6 max-w-lg mx-auto">
        Looking for Mac filtering or kid-safe podcasts?{` `}
        <a
          href="/pricing"
          className="text-violet-400 hover:text-violet-300 font-medium transition-colors"
        >
          See all plans
        </a>
        .
      </p>
    </div>
  </section>
);

export default PricingBlock;
