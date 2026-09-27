import type { GetMusicAlbumCuration, GetMusicCuration } from '@shared/pairql/src/account';

type Curation = GetMusicCuration.Output;
export type ApprovedMusicItem =
  | { kind: `artist`; createdAt: string; artist: Curation[`artists`][number] }
  | { kind: `album`; createdAt: string; album: Curation[`albums`][number] };

export function approvedMusicItems(curation: Curation): ApprovedMusicItem[] {
  return [
    ...curation.artists.map((artist) => ({
      kind: `artist` as const,
      createdAt: artist.createdAt,
      artist,
    })),
    ...curation.albums.map((album) => ({
      kind: `album` as const,
      createdAt: album.createdAt,
      album,
    })),
  ].sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));
}

export function selectedTrackIds(album: GetMusicAlbumCuration.Output): Set<string> {
  return new Set(
    album.tracks.filter((track) => track.isSelected).map((track) => track.id),
  );
}

export function sameIds(a: Set<string>, b: Set<string>): boolean {
  return a.size === b.size && [...a].every((id) => b.has(id));
}

export function trackCount(count: number): string {
  return `${count} ${count === 1 ? `track` : `tracks`}`;
}

export function replacedApprovals(albumCount: number, trackCount: number): string {
  return [
    albumCount > 0 ? `${albumCount} ${albumCount === 1 ? `album` : `albums`}` : undefined,
    trackCount > 0
      ? `${trackCount} individual ${trackCount === 1 ? `track` : `tracks`}`
      : undefined,
  ]
    .filter(Boolean)
    .join(` and `);
}

export function artworkUrl(url?: string): string | undefined {
  return url?.replace(`{w}`, `300`).replace(`{h}`, `300`);
}

export function trackNumber(
  track: GetMusicAlbumCuration.Output[`tracks`][number],
  multipleDiscs: boolean,
): string {
  if (track.trackNumber === undefined) return ``;
  return multipleDiscs && track.discNumber !== undefined
    ? `${track.discNumber}.${track.trackNumber}`
    : String(track.trackNumber);
}

export function duration(millis?: number): string {
  if (millis === undefined) return ``;
  const seconds = Math.floor(millis / 1000);
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, `0`)}`;
}
