import React from 'react';
import { musicScreenshotArtwork } from '@/lib/home-music-artwork';

interface HomeMusicArtworkCreditsProps {
  isDark: boolean;
}

const HomeMusicArtworkCredits: React.FC<HomeMusicArtworkCreditsProps> = ({ isDark }) => (
  <details
    className={`mx-auto mt-6 max-w-3xl text-xs leading-6 transition-colors duration-700 ${
      isDark ? `text-stone-400` : `text-stone-600`
    }`}
  >
    <summary className="mx-auto w-fit cursor-pointer rounded-sm text-[11px] leading-5 opacity-70 decoration-current/40 underline-offset-4 transition-opacity hover:opacity-100 hover:underline focus-visible:opacity-100 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-violet-400">
      Album artwork credits
    </summary>
    <div className="mt-5">
      <p>
        Cover artwork is used under the Creative Commons licenses below, with
        rights-holder permission recorded by Wikimedia Commons. The example library does
        not imply endorsement by the artists or labels, or a judgment about albums outside
        the library.
      </p>
      <ul className="mt-4 space-y-2">
        {musicScreenshotArtwork.map((album) => (
          <li key={album.source}>
            <a
              href={album.source}
              className="rounded-sm underline underline-offset-4 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-violet-400"
            >
              {album.title} by {album.artist}
            </a>
            {` · Cover credited to ${album.credit} · `}
            <a
              href={`https://creativecommons.org/licenses/by-sa/${album.licenseVersion}/`}
              className="rounded-sm underline underline-offset-4 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-violet-400"
            >
              CC BY-SA {album.licenseVersion}
            </a>
          </li>
        ))}
      </ul>
      <p className="mt-4">
        Cover artwork appears in app screenshots, including rounded album tiles and
        playlist mosaics. Screenshots have been placed in Apple device frames, resized,
        and converted to WebP. Ben Wendel’s artist photo and the other release artwork on
        his artist page appear as Apple Music provides them, belong to their respective
        owners, and are not covered by the licenses above.
        {` `}
        Our artwork adaptations are offered under each original’s listed license. Those
        licenses do not cover Gertrude’s branding, application code, or Apple’s device
        artwork.
      </p>
      <a
        href="/music/licensed-artwork/LICENSE.txt"
        className="mt-2 inline-block rounded-sm underline underline-offset-4 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-violet-400"
      >
        Artwork sources and license record
      </a>
      <a
        href="/home/music-screenshots/LICENSE.txt"
        className="mt-2 block rounded-sm underline underline-offset-4 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-violet-400"
      >
        Screenshot and device artwork sources
      </a>
    </div>
  </details>
);

export default HomeMusicArtworkCredits;
