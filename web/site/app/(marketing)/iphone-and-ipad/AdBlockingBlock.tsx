import React from 'react';
import { BlockedIcon, FeatureItem } from './shared';

const AdBlockingBlock: React.FC = () => (
  <section className="bg-gradient-to-b from-violet-500 to-fuchsia-500 pt-20 pb-12 sm:pt-28 sm:pb-20 lg:py-32">
    <div className="max-w-7xl mx-auto px-4 xs:px-8 sm:px-12 md:px-20">
      <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
        <div>
          <div className="inline-flex items-center gap-2 bg-white/20 px-3 py-1.5 rounded-full text-white text-sm font-medium mb-6">
            <svg
              className="size-4"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth={2}
            >
              <rect x="3" y="3" width="18" height="18" rx="2" />
              <line x1="9" y1="3" x2="9" y2="21" />
            </svg>
            Ad Blocking
          </div>
          <h2 className="text-3xl xs:text-4xl md:text-5xl font-bold text-white mb-6 leading-tight">
            Block Ads on iPhone & iPad
          </h2>
          <p className="text-lg xs:text-xl text-white/80 leading-relaxed mb-8">
            Gertrude blocks the most common ad providers both on the web and within apps.
            No matter where your child browses or what apps they use, most intrusive and
            inappropriate ads are stopped before they ever appear.
          </p>
          <ul className="space-y-2 mb-8 ml-4">
            <FeatureItem inverted text="Blocks ads in Safari and other browsers" />
            <FeatureItem inverted text="Blocks in-app ads across all applications" />
            <FeatureItem inverted text="Less inappropriate content, fewer distractions" />
          </ul>
        </div>
        <div className="flex justify-center">
          <div className="relative">
            <div className="absolute inset-0 bg-black/20 rounded-3xl blur-2xl" />
            <div className="relative bg-slate-900/80 backdrop-blur-sm rounded-3xl p-8 border border-slate-700/50 min-w-[280px] sm:min-w-[320px]">
              <div className="flex items-center justify-center mb-6">
                <div className="relative">
                  <div className="size-28 rounded-2xl bg-gradient-to-br from-violet-400 to-fuchsia-400 flex items-center justify-center shadow-xl">
                    <div className="bg-white/20 rounded-lg px-3 py-2">
                      <span className="text-white text-2xl font-black tracking-tight">
                        AD
                      </span>
                    </div>
                  </div>
                  <div className="absolute -top-2 -right-2 size-8 bg-red-500 rounded-full flex items-center justify-center shadow-lg">
                    <svg
                      className="size-5 text-white"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth={3}
                    >
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                  </div>
                </div>
              </div>
              <div className="space-y-2">
                {[
                  `doubleclick.net`,
                  `googlesyndication.com`,
                  `facebook-ads.com`,
                  `adservice.google.com`,
                ].map((domain, i) => (
                  <div
                    key={i}
                    className="flex items-center gap-2 bg-slate-800 rounded-lg px-3 py-2"
                  >
                    <BlockedIcon className="size-4 text-red-400 shrink-0" />
                    <span className="text-slate-300 text-xs font-mono truncate">
                      {domain}
                    </span>
                  </div>
                ))}
                <div className="text-center pt-1">
                  <span className="text-slate-400 text-xs">+ many more</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
);

export default AdBlockingBlock;
