import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { describe, expect, it } from 'vitest';
import { chosenAlbumIds, musicArtwork, musicMarqueeIds } from '../home-music-artwork';

const publicDir = fileURLToPath(new URL(`../../public/`, import.meta.url));
const artworkDir = path.join(publicDir, `music/licensed-artwork`);

describe(`homepage music artwork`, () => {
  it(`ships exactly the licensed images referenced by the catalog`, () => {
    const filenames = Object.values(musicArtwork).map((album) => {
      expect(album.src).toMatch(/^\/music\/licensed-artwork\/[^/]+\.webp$/);
      expect(fs.statSync(path.join(publicDir, album.src)).size).toBeGreaterThan(0);
      return path.basename(album.src);
    });
    expect(
      fs
        .readdirSync(artworkDir)
        .filter((name) => name.endsWith(`.webp`))
        .sort(),
    ).toEqual(filenames.sort());
  });

  it(`includes source, attribution, license, and permission evidence for every cover`, () => {
    const licenseRecord = fs.readFileSync(path.join(artworkDir, `LICENSE.txt`), `utf8`);
    for (const album of Object.values(musicArtwork)) {
      const record = licenseRecord
        .split(`\n\n`)
        .find((block) => block.includes(`File: ${path.basename(album.src)}\n`));
      expect(record).toContain(album.credit);
      expect(record).toContain(album.source);
      expect(record).toContain(`CC BY-SA ${album.licenseVersion}`);
      expect(record).toContain(album.permissionTicket);
      expect(album.source).toMatch(/^https:\/\/commons.wikimedia.org\/wiki\/File:/);
      expect(album.permissionTicket).toMatch(/^\d{16}$/);
    }
  });

  it(`shows at least eighteen covers from nine artists, with at most three per artist`, () => {
    const albums = Object.values(musicArtwork);
    const artistCounts = new Map<string, number>();
    for (const album of albums) {
      const artist = album.artist.replace(/^The /, ``);
      artistCounts.set(artist, (artistCounts.get(artist) ?? 0) + 1);
    }
    expect(albums.length).toBeGreaterThanOrEqual(18);
    expect(artistCounts.size).toBeGreaterThanOrEqual(9);
    expect(Math.max(...artistCounts.values())).toBeLessThanOrEqual(3);
  });

  it(`selects six different artists for the example library`, () => {
    const artists = chosenAlbumIds.map((id) =>
      musicArtwork[id].artist.replace(/^The /, ``),
    );
    expect(new Set(artists).size).toBe(6);
  });

  it(`does not repeat a cover within a marquee row`, () => {
    for (const row of musicMarqueeIds) {
      expect(new Set(row).size).toBe(row.length);
    }
  });

  it(`uses the full catalog and lifts each selected album from exactly one row slot`, () => {
    const rowIds = musicMarqueeIds.flat();
    expect(new Set(rowIds)).toEqual(new Set(Object.keys(musicArtwork)));
    expect(new Set(chosenAlbumIds).size).toBe(6);
    for (const id of chosenAlbumIds) {
      expect(rowIds.filter((rowId) => rowId === id)).toHaveLength(1);
    }
  });

  it(`preserves four marquee tracks and a selection originating from each`, () => {
    const selectedIds = new Set<string>(chosenAlbumIds);
    expect(musicMarqueeIds.map((row) => row.length)).toEqual([8, 8, 8, 7]);
    for (const row of musicMarqueeIds) {
      expect(row.some((id) => selectedIds.has(id))).toBe(true);
    }
  });
});
