import React from 'react';
import { BlockedIcon, FeatureItem } from './shared';

const GifBlockingBlock: React.FC = () => (
  <section className="bg-slate-900 py-20 sm:py-28 lg:py-32">
    <div className="max-w-7xl mx-auto px-4 xs:px-8 sm:px-12 md:px-20">
      <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
        <div>
          <div className="inline-flex items-center gap-2 bg-violet-500/20 px-3 py-1.5 rounded-full text-violet-300 text-sm font-medium mb-6">
            <svg
              className="size-4"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth={2}
            >
              <rect x="3" y="3" width="18" height="18" rx="2" />
              <circle cx="8.5" cy="8.5" r="1.5" fill="currentColor" />
              <path d="M21 15l-5-5L5 21" />
            </svg>
            GIF Blocking
          </div>
          <h2 className="text-3xl xs:text-4xl md:text-5xl font-bold text-white mb-6 leading-tight">
            Block GIF Searches in iMessage #images
          </h2>
          <p className="text-lg xs:text-xl text-slate-300 leading-relaxed mb-8">
            The #images GIF search feature in iMessage lets kids search for and share
            explicit, violent, or inappropriate GIFs. Gertrude completely blocks this
            search functionality in the Messages app while keeping texting working
            normally.
          </p>
          <ul className="space-y-2 mb-8 ml-4">
            <FeatureItem text="Blocks #images GIF search in Messages" />
            <FeatureItem text="Also blocks GIFs in WhatsApp, Signal, and GroupMe" />
            <FeatureItem text="Texting and photos still work normally" />
          </ul>
        </div>
        <div className="flex justify-center">
          <div className="relative">
            <div className="absolute inset-0 bg-gradient-to-r from-violet-500 to-fuchsia-500 rounded-3xl blur-2xl opacity-30" />
            <div className="relative bg-slate-800 rounded-3xl p-8 border border-slate-700">
              <div className="flex items-center gap-4 mb-6">
                <div className="size-12 rounded-xl bg-gradient-to-br from-green-400 to-green-600 flex items-center justify-center">
                  <svg
                    className="size-6 text-white"
                    viewBox="0 0 24 24"
                    fill="currentColor"
                  >
                    <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z" />
                  </svg>
                </div>
                <div>
                  <div className="text-white font-semibold">Messages</div>
                  <div className="text-slate-400 text-sm">#images blocked</div>
                </div>
              </div>
              <div className="grid grid-cols-4 gap-3">
                {[...Array(12)].map((_, i) => (
                  <div
                    key={i}
                    className="aspect-square bg-slate-700 rounded-lg flex items-center justify-center p-3"
                  >
                    <BlockedIcon className="size-6 text-red-400/60" />
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </section>
);

export default GifBlockingBlock;
