import React from 'react';
import { musicArtwork } from '@/lib/home-music-artwork';

const HomeMusicArtworkCredits: React.FC<{ isDark: boolean }> = ({ isDark }) => (
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
        {Object.values(musicArtwork).map((album) => (
          <li key={album.src}>
            <a
              href={album.source}
              className="rounded-sm underline underline-offset-4 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-violet-400"
            >
              {album.artist} — {album.title}
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
        Images have been resized and converted to WebP. Non-square originals have been
        padded, not cropped. The illustration applies rounded masks, movement, scaling,
        shadows, opacity, brightness, and saturation effects. Our artwork adaptations are
        offered under each original’s listed license. Those licenses do not cover
        Gertrude’s branding or application code.
      </p>
      <a
        href="/music/licensed-artwork/LICENSE.txt"
        className="mt-2 inline-block rounded-sm underline underline-offset-4 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-4 focus-visible:outline-violet-400"
      >
        Artwork sources and license record
      </a>
    </div>
  </details>
);

export default HomeMusicArtworkCredits;
