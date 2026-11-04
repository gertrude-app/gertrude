import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';
import { podcastArtwork } from '../home-podcast-artwork';

const artworkBytes = (src: string): Buffer =>
  readFileSync(new URL(`../../public${src}`, import.meta.url));

const licenseRecord = readFileSync(
  new URL(`../../public/podcasts/licensed-artwork/LICENSE.txt`, import.meta.url),
  `utf8`,
);

describe(`homepage podcast artwork`, () => {
  it(`provides eleven distinct local covers with source and license records`, () => {
    const shows = Object.values(podcastArtwork);
    expect(shows).toHaveLength(11);
    expect(new Set(shows.map((show) => show.src)).size).toBe(shows.length);
    expect(new Set(shows.map((show) => show.feedUrl)).size).toBe(shows.length);
    for (const show of shows) {
      expect(show.src).toMatch(/^\/podcasts\/licensed-artwork\/[a-z-]+\.webp$/);
      expect(show.credit.length).toBeGreaterThan(0);
      for (const url of [show.source, show.licenseUrl, show.showUrl, show.feedUrl]) {
        expect(new URL(url).protocol).toBe(`https:`);
      }
      expect(licenseRecord).toContain(show.source);
      expect(licenseRecord).toContain(show.src.split(`/`).at(-1));
      const bytes = artworkBytes(show.src);
      expect(bytes.toString(`ascii`, 0, 4)).toBe(`RIFF`);
      expect(bytes.toString(`ascii`, 8, 12)).toBe(`WEBP`);
    }
  });

  it(`preserves the exact publisher bytes for no-derivatives covers`, () => {
    const originals = Object.values(podcastArtwork).filter(
      (show) => show.license === `CC BY-ND 4.0`,
    );
    expect(originals).toHaveLength(5);
    for (const show of originals) {
      expect(show.frameColor).toMatch(/^#[0-9a-f]{6}$/);
      expect(createHash(`sha256`).update(artworkBytes(show.src)).digest(`hex`)).toBe(
        show.originalSha256,
      );
      expect(licenseRecord).toContain(show.originalSha256);
    }
  });

  it(`uses only two public-domain audiobook feeds alongside nine regular podcasts`, () => {
    const books = Object.values(podcastArtwork).filter((show) =>
      show.feedUrl.startsWith(`https://librivox.org/rss/`),
    );
    expect(books).toHaveLength(2);
    for (const book of books) expect(book.license).toBe(`Public domain`);
  });
});
