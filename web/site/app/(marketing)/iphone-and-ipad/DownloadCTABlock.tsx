import React from 'react';
import { APP_STORE_URL, ExternalLinkIcon } from './shared';

const DownloadCTABlock: React.FC = () => (
  <section className="bg-gradient-to-r from-emerald-700 to-emerald-600 py-10 sm:py-12">
    <div className="max-w-4xl mx-auto px-4 xs:px-8 sm:px-12 md:px-20">
      <div className="flex flex-col sm:flex-row items-center justify-center gap-6 sm:gap-8">
        <a
          href={APP_STORE_URL}
          target="_blank"
          rel="noopener noreferrer"
          className="transition-transform duration-200 hover:scale-105"
        >
          <img
            src="/download-on-app-store.svg"
            alt="Download on the App Store"
            width={168}
            height={56}
            className="h-12 sm:h-14"
          />
        </a>
        <div className="text-center sm:text-left">
          <p className="text-white font-semibold text-lg sm:text-xl mb-1">
            Get Gertrude Now!
          </p>
          <a
            href={APP_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="text-white/70 text-sm hover:text-white transition-colors inline-flex items-center gap-1"
          >
            Search &ldquo;Gertrude Blocker&rdquo; in the App Store
            <ExternalLinkIcon className="size-3" />
          </a>
        </div>
      </div>
    </div>
  </section>
);

export default DownloadCTABlock;
