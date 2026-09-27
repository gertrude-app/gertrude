import { describe, expect, test } from 'vitest';
import type { GetMusicAlbumCuration, GetMusicCuration } from '@shared/pairql/src/account';
import {
  approvedMusicItems,
  artworkUrl,
  duration,
  replacedApprovals,
  sameIds,
  selectedTrackIds,
  trackNumber,
} from '../musicCurationHelpers';

describe(`music curation presentation`, () => {
  test(`mixes album and artist grants newest first`, () => {
    const curation: GetMusicCuration.Output = {
      revision: 3,
      albums: [
        {
          id: `album-1`,
          title: `Album`,
          artistName: `Singer`,
          catalogTrackCount: 4,
          selectedTrackCount: 2,
          scope: `selectedTracks`,
          showsArtwork: true,
          createdAt: `2026-01-01T00:00:00Z`,
        },
      ],
      artists: [{ id: `artist-1`, name: `Singer`, createdAt: `2026-02-01T00:00:00Z` }],
    };
    expect(approvedMusicItems(curation).map((item) => item.kind)).toEqual([
      `artist`,
      `album`,
    ]);
  });

  test(`tracks use server selection and keep album order and disc numbers`, () => {
    const album = {
      tracks: [
        {
          id: `a`,
          title: `Song A`,
          artistName: `Singer`,
          isSelected: true,
          trackNumber: 1,
          discNumber: 1,
        },
        {
          id: `b`,
          title: `Song B`,
          artistName: `Singer`,
          isSelected: false,
          trackNumber: 1,
          discNumber: 2,
        },
      ],
    } as GetMusicAlbumCuration.Output;
    expect([...selectedTrackIds(album)]).toEqual([`a`]);
    expect(sameIds(new Set([`b`, `a`]), new Set([`a`, `b`]))).toBe(true);
    expect(sameIds(selectedTrackIds(album), new Set([`b`]))).toBe(false);
    expect(trackNumber(album.tracks[1]!, true)).toBe(`2.1`);
    expect(duration(239_000)).toBe(`3:59`);
  });

  test(`artist replacement warning counts only the approvals it replaces`, () => {
    expect(replacedApprovals(1, 0)).toBe(`1 album`);
    expect(replacedApprovals(2, 1)).toBe(`2 albums and 1 individual track`);
  });

  test(`expands Apple artwork size placeholders`, () => {
    expect(artworkUrl(`https://example.com/{w}x{h}bb.jpg`)).toBe(
      `https://example.com/300x300bb.jpg`,
    );
  });
});
