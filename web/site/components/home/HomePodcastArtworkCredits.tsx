import React from 'react';
import { podcastScreenshotArtwork } from '@/lib/home-podcast-artwork';

const HomePodcastArtworkCredits: React.FC<{
  isDark: boolean;
}> = ({ isDark }) => (
  <details
    className={`mx-auto mt-6 max-w-3xl text-xs leading-6 transition-colors duration-700 ${
      isDark ? `text-stone-400` : `text-stone-600`
    }`}
  >
    <summary className="mx-auto w-fit cursor-pointer rounded-sm text-[11px] leading-5 opacity-70 decoration-current/40 underline-offset-4 transition-opacity hover:opacity-100 hover:underline focus-visible:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-violet-400">
      Podcast artwork credits
    </summary>
    <div className="mt-5">
      <p>
        These podcasts and LibriVox audiobook feeds illustrate a family-chosen library.
        Some are completed archives. Inclusion does not imply endorsement by their
        creators, or a recommendation for every age or episode.
      </p>
      <ul className="mt-4 space-y-2">
        {podcastScreenshotArtwork.map((show) => (
          <li key={show.source}>
            <a href={show.source} className={linkClass}>
              {show.title}
            </a>
            {` · Cover credited to ${show.credit} · `}
            <a href={show.licenseUrl} className={linkClass}>
              {show.license}
            </a>
          </li>
        ))}
      </ul>
      <p className="mt-4">
        Cover artwork appears inside app screenshots, including rounded thumbnails. The
        screenshots have been fitted to device frames, resized, and converted to WebP.
        Were You Raised By Wolves? uses Gertrude’s generic radio illustration, not the
        publisher’s cover.
        {` `}New Rustacean’s cover incorporates a modified Rust logo, used under the Rust
        Foundation’s{` `}
        <a
          href="https://foundation.rust-lang.org/policies/logo-policy-and-media-guide/"
          className={linkClass}
        >
          attribution license and trademark policy
        </a>
        . The Rust Foundation and Rust Project are not affiliated with Gertrude. Artwork
        licenses do not cover Gertrude’s branding or application code.
      </p>
      <a
        href="/home/podcasts-screenshots/LICENSE.txt"
        className={`mt-2 inline-block ${linkClass}`}
      >
        Artwork sources and license record
      </a>
    </div>
  </details>
);

export default HomePodcastArtworkCredits;

const linkClass = `rounded-sm underline underline-offset-4 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-violet-400`;
