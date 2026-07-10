import { ApiErrorMessage, EmptyState, Loading } from '@dash/components';
import { Button, TextInput } from '@shared/components';
import React, { useState } from 'react';
import type {
  GetApprovedMusicAlbums,
  GetApprovedMusicArtists,
  SearchMusicCatalog,
} from '@dash/types';
import Current from '../../environment';
import { Key, useMutation, useQuery } from '../../hooks';

type SearchAlbum = SearchMusicCatalog.Output[`albums`][number];
type SearchArtist = SearchMusicCatalog.Output[`artists`][number];
type ApprovedAlbum = GetApprovedMusicAlbums.Output[`albums`][number];
type ApprovedArtist = GetApprovedMusicArtists.Output[`artists`][number];
type ArtistLike = Pick<SearchArtist, `name` | `catalogMetadata`>;
type ApprovedMusicItem =
  | {
      kind: `artist`;
      id: string;
      createdAt?: string;
      sequence: number;
      artist: ApprovedArtist;
    }
  | {
      kind: `album`;
      id: string;
      createdAt?: string;
      sequence: number;
      album: ApprovedAlbum;
    };

const MusicCuration: React.FC<{
  childId: string;
  childName: string;
  className?: string;
}> = ({ childId, childName, className }) => {
  const [searchQuery, setSearchQuery] = useState(``);
  const [hasSearched, setHasSearched] = useState(false);
  const approvedAlbumsKey = Key.approvedMusicAlbums(childId);
  const approvedArtistsKey = Key.approvedMusicArtists(childId);

  const approvedAlbumsQuery = useQuery(approvedAlbumsKey, () =>
    Current.api.getApprovedMusicAlbums(childId),
  );
  const approvedArtistsQuery = useQuery(approvedArtistsKey, () =>
    Current.api.getApprovedMusicArtists(childId),
  );

  const searchCatalog = useMutation(
    (input: SearchMusicCatalog.Input) => Current.api.searchMusicCatalog(input),
    {
      onSuccess: () => setHasSearched(true),
    },
  );

  const approveAlbum = useMutation(
    (album: SearchAlbum) =>
      Current.api.approveMusicAlbum({
        childId,
        appleMusicAlbumId: album.id,
        title: album.title,
        artistName: album.artistName,
        artworkUrl: album.artworkUrl,
        artwork: album.artwork,
        trackCount: album.trackCount,
        showsArtwork: true,
      }),
    { invalidating: [approvedAlbumsKey], toast: `approve:music-album` },
  );

  const approveArtist = useMutation(
    (artist: SearchArtist) =>
      Current.api.approveMusicArtist({
        childId,
        appleMusicArtistId: artist.id,
        name: artist.name,
        catalogMetadata: artist.catalogMetadata,
      }),
    { invalidating: [approvedArtistsKey], toast: `approve:music-artist` },
  );

  const removeAlbum = useMutation(
    (albumId: string) =>
      Current.api.removeApprovedMusicAlbum({
        childId,
        appleMusicAlbumId: albumId,
      }),
    { invalidating: [approvedAlbumsKey], toast: `remove:music-album` },
  );

  const removeArtist = useMutation(
    (artistId: string) =>
      Current.api.removeApprovedMusicArtist({
        childId,
        appleMusicArtistId: artistId,
      }),
    { invalidating: [approvedArtistsKey], toast: `remove:music-artist` },
  );

  // TEMP(app-review): the "show album artwork" toggle drives the iOS app's lock-screen /
  // control-center artwork suppression, which relies on the private MediaRemote framework
  // (App Store 2.5.1 risk) and is compiled out for the TestFlight/review build. Hidden so
  // reviewers don't see a non-functioning control. Re-enable alongside the
  // GERTRUDE_MUSIC_NOW_PLAYING_OVERRIDE flag in swift/music/lib-tca after review.
  // const updateAlbumArtwork = useMutation(
  //   (album: ApprovedAlbum) =>
  //     Current.api.approveMusicAlbum({
  //       childId,
  //       appleMusicAlbumId: album.id,
  //       title: album.title,
  //       artistName: album.artistName,
  //       artworkUrl: album.artworkUrl,
  //       trackCount: album.trackCount,
  //       showsArtwork: !album.showsArtwork,
  //     }),
  //   { invalidating: [approvedAlbumsKey], toast: `update:music-artwork` },
  // );

  const approvedAlbums = approvedAlbumsQuery.data?.albums ?? [];
  const approvedArtists = approvedArtistsQuery.data?.artists ?? [];
  const approvedAlbumIds = new Set(approvedAlbums.map((album) => album.id));
  const approvedArtistIds = new Set(approvedArtists.map((artist) => artist.id));
  const approvedItems = mixedApprovedItems(approvedArtists, approvedAlbums);
  const searchItems = searchCatalog.data?.items ?? [];
  const canSearch = searchQuery.trim().length > 0 && !searchCatalog.isPending;
  const showSearchResults =
    hasSearched || searchCatalog.isPending || searchCatalog.isError;
  const hasSearchResults = searchItems.length > 0;
  const approvedMusicIsPending =
    approvedAlbumsQuery.isPending || approvedArtistsQuery.isPending;
  const approvedMusicIsSuccess =
    approvedAlbumsQuery.isSuccess && approvedArtistsQuery.isSuccess;
  const hasApprovedMusic = approvedItems.length > 0;

  const onSubmit = (event: React.FormEvent<HTMLFormElement>): void => {
    event.preventDefault();
    const query = searchQuery.trim();
    if (!query || searchCatalog.isPending) return;
    searchCatalog.mutate({ query, limit: 10 });
  };

  return (
    <div className={className}>
      <form onSubmit={onSubmit} className="flex flex-col sm:flex-row gap-3 sm:items-end">
        <TextInput
          type="text"
          name="music-search"
          label="Search Apple Music"
          value={searchQuery}
          setValue={setSearchQuery}
          placeholder="Artist or album"
        />
        <Button type="submit" color="primary" disabled={!canSearch} className="sm:mb-px">
          {searchCatalog.isPending ? `Searching...` : `Search`}
        </Button>
      </form>

      {showSearchResults && (
        <section className="mt-8">
          <h2 className="text-xl font-bold text-slate-700 mb-3">Search results</h2>
          {searchCatalog.isPending && <Loading label="Searching Apple Music…" />}
          {searchCatalog.isError && <ApiErrorMessage error={searchCatalog.error} />}
          {searchCatalog.isSuccess && !hasSearchResults && (
            <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-5 py-8 text-center text-slate-500">
              No artists or albums found. Try another search.
            </div>
          )}
          {searchItems.length > 0 && (
            <div className="grid gap-3">
              {searchItems.map((item, index) => {
                const artist = item.artist;
                if (item.kind === `artist` && artist) {
                  return (
                    <SearchResultArtistCard
                      key={`artist-${artist.id}-${index}`}
                      artist={artist}
                      isApproved={approvedArtistIds.has(artist.id)}
                      isApproving={
                        approveArtist.isPending &&
                        approveArtist.variables?.id === artist.id
                      }
                      onApprove={() => approveArtist.mutate(artist)}
                    />
                  );
                }
                const album = item.album;
                if (item.kind === `album` && album) {
                  return (
                    <SearchResultAlbumCard
                      key={`album-${album.id}-${index}`}
                      album={album}
                      isApproved={approvedAlbumIds.has(album.id)}
                      isApproving={
                        approveAlbum.isPending && approveAlbum.variables?.id === album.id
                      }
                      onApprove={() => approveAlbum.mutate(album)}
                    />
                  );
                }
                return null;
              })}
            </div>
          )}
        </section>
      )}

      <section className="mt-12">
        <h2 className="text-xl font-bold text-slate-700 mb-3">
          {childName}&rsquo;s allowed music
        </h2>
        {approvedMusicIsPending && <Loading label="Loading allowed music…" />}
        {approvedAlbumsQuery.isError && (
          <ApiErrorMessage error={approvedAlbumsQuery.error} />
        )}
        {approvedArtistsQuery.isError && (
          <ApiErrorMessage error={approvedArtistsQuery.error} />
        )}
        {approvedMusicIsSuccess && !hasApprovedMusic && (
          <EmptyState
            heading="No allowed music yet"
            secondaryText="Search Apple Music above and add the artists or albums this child is allowed to play. Allowed artists include their current and future eligible releases."
            icon="music"
            buttonText="Search for music"
            buttonIcon="magnifying-glass"
            action={() =>
              document
                .querySelector<HTMLInputElement>(`input[name="music-search"]`)
                ?.focus()
            }
          />
        )}
        {approvedItems.length > 0 && (
          <div className="grid grid-cols-[repeat(auto-fit,minmax(min(100%,26rem),1fr))] gap-4">
            {approvedItems.map((item) =>
              item.kind === `artist` ? (
                <ApprovedArtistCard
                  key={`artist-${item.id}`}
                  artist={item.artist}
                  isRemoving={
                    removeArtist.isPending && removeArtist.variables === item.id
                  }
                  onRemove={() => removeArtist.mutate(item.id)}
                />
              ) : (
                <ApprovedAlbumCard
                  key={`album-${item.id}`}
                  album={item.album}
                  isRemoving={removeAlbum.isPending && removeAlbum.variables === item.id}
                  onRemove={() => removeAlbum.mutate(item.id)}
                />
              ),
            )}
          </div>
        )}
      </section>
    </div>
  );
};

const SearchResultArtistCard: React.FC<{
  artist: SearchArtist;
  isApproved: boolean;
  isApproving: boolean;
  onApprove(): void;
}> = ({ artist, isApproved, isApproving, onApprove }) => (
  <div className="min-w-0 flex flex-col sm:flex-row sm:items-center gap-4 rounded-2xl bg-white p-4 shadow border-[0.5px] border-slate-200">
    <ArtistArtwork artist={artist} />
    <ArtistInfo artist={artist} />
    <div className="flex flex-wrap sm:flex-nowrap sm:flex-col gap-2 sm:items-end sm:ml-auto sm:shrink-0">
      <Button
        type="button"
        color="secondary"
        size="small"
        disabled={isApproved || isApproving}
        onClick={onApprove}
        className="shrink-0 whitespace-nowrap"
      >
        {isApproved ? `Allowed` : isApproving ? `Adding...` : `Allow artist`}
      </Button>
      {artist.catalogMetadata?.appleMusicUrl && (
        <Button
          type="external"
          href={artist.catalogMetadata.appleMusicUrl}
          color="tertiary"
          size="small"
          className="shrink-0 whitespace-nowrap sm:mt-1"
        >
          Apple Music
          <i className="fa-solid fa-arrow-up-right-from-square ml-2 text-xs" />
        </Button>
      )}
    </div>
  </div>
);

const SearchResultAlbumCard: React.FC<{
  album: SearchAlbum;
  isApproved: boolean;
  isApproving: boolean;
  onApprove(): void;
}> = ({ album, isApproved, isApproving, onApprove }) => (
  <div className="min-w-0 flex flex-col sm:flex-row sm:items-center gap-4 rounded-2xl bg-white p-4 shadow border-[0.5px] border-slate-200">
    <AlbumArtwork artworkUrl={album.artworkUrl} title={album.title} />
    <AlbumInfo album={album} />
    <div className="flex flex-wrap sm:flex-nowrap sm:flex-col gap-2 sm:items-end sm:ml-auto sm:shrink-0">
      <Button
        type="button"
        color="secondary"
        size="small"
        disabled={isApproved || isApproving}
        onClick={onApprove}
        className="shrink-0 whitespace-nowrap"
      >
        {isApproved ? `Allowed` : isApproving ? `Adding...` : `Allow album`}
      </Button>
      {album.appleMusicUrl && (
        <Button
          type="external"
          href={album.appleMusicUrl}
          color="tertiary"
          size="small"
          className="shrink-0 whitespace-nowrap sm:mt-1"
        >
          Apple Music
          <i className="fa-solid fa-arrow-up-right-from-square ml-2 text-xs" />
        </Button>
      )}
    </div>
  </div>
);

const ApprovedArtistCard: React.FC<{
  artist: ApprovedArtist;
  isRemoving: boolean;
  onRemove(): void;
}> = ({ artist, isRemoving, onRemove }) => (
  <div
    data-test="approved-music-item"
    className="min-w-0 rounded-2xl bg-white p-4 shadow border-[0.5px] border-slate-200"
  >
    <div className="min-w-0 flex gap-4">
      <ArtistArtwork artist={artist} />
      <ArtistInfo artist={artist} />
    </div>
    <p className="mt-3 text-sm font-medium text-slate-500">
      Allows all current and future eligible releases by this artist.
    </p>
    <div className="mt-4 flex justify-end">
      <Button
        type="button"
        color="warning"
        size="small"
        disabled={isRemoving}
        onClick={onRemove}
        className="shrink-0 whitespace-nowrap"
      >
        {isRemoving ? `Removing...` : `Remove`}
      </Button>
    </div>
  </div>
);

const ApprovedAlbumCard: React.FC<{
  album: ApprovedAlbum;
  isRemoving: boolean;
  onRemove(): void;
  // TEMP(app-review): re-enable with the artwork-suppression toggle, see above
  // isUpdatingArtwork: boolean;
  // onToggleArtwork(): void;
}> = ({ album, isRemoving, onRemove }) => (
  <div
    data-test="approved-music-item"
    className="min-w-0 rounded-2xl bg-white p-4 shadow border-[0.5px] border-slate-200"
  >
    <div className="min-w-0 flex gap-4">
      <AlbumArtwork
        artworkUrl={album.showsArtwork ? album.artworkUrl : undefined}
        title={album.title}
      />
      <AlbumInfo album={album} />
    </div>
    <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      {/* TEMP(app-review): artwork-suppression toggle hidden, see updateAlbumArtwork above
      <label className="flex items-center gap-2 text-sm font-medium text-slate-600">
        <Toggle
          enabled={album.showsArtwork}
          setEnabled={onToggleArtwork}
          small
          disabled={isUpdatingArtwork}
        />
        {isUpdatingArtwork ? `Updating artwork...` : `Show album artwork`}
      </label>
      */}
      <Button
        type="button"
        color="warning"
        size="small"
        disabled={isRemoving}
        onClick={onRemove}
        className="shrink-0 whitespace-nowrap sm:ml-auto"
      >
        {isRemoving ? `Removing...` : `Remove`}
      </Button>
    </div>
  </div>
);

const ArtistArtwork: React.FC<{
  artist: ArtistLike;
}> = ({ artist }) => {
  const artworkUrl = sizedAppleArtworkUrl(artist.catalogMetadata?.artwork?.url);

  return (
    <div className="h-20 w-20 shrink-0 overflow-hidden rounded-full bg-violet-50 flex items-center justify-center border border-violet-100">
      {artworkUrl ? (
        <img src={artworkUrl} alt={artist.name} className="h-full w-full object-cover" />
      ) : (
        <i className="fa-solid fa-microphone text-3xl text-violet-300" />
      )}
    </div>
  );
};

const AlbumArtwork: React.FC<{
  artworkUrl?: string;
  title: string;
}> = ({ artworkUrl, title }) => (
  <div className="h-20 w-20 shrink-0 overflow-hidden rounded-xl bg-violet-50 flex items-center justify-center border border-violet-100">
    {artworkUrl ? (
      <img src={artworkUrl} alt={title} className="h-full w-full object-cover" />
    ) : (
      <i className="fa-solid fa-music text-3xl text-violet-300" />
    )}
  </div>
);

const ArtistInfo: React.FC<{
  artist: ArtistLike;
}> = ({ artist }) => {
  const genres = artist.catalogMetadata?.genreNames ?? [];
  const note =
    artist.catalogMetadata?.editorialNotes?.tagline ??
    artist.catalogMetadata?.editorialNotes?.short;

  return (
    <div className="min-w-0 w-full flex-grow">
      <h3 className="block max-w-full truncate text-lg font-semibold leading-tight text-slate-800">
        {artist.name}
      </h3>
      {genres.length > 0 && (
        <p className="text-slate-600 truncate">{genres.join(` • `)}</p>
      )}
      {note && <p className="text-sm text-slate-400 mt-1 line-clamp-2">{note}</p>}
    </div>
  );
};

const AlbumInfo: React.FC<{
  album: Pick<SearchAlbum, `title` | `artistName` | `trackCount` | `releaseDate`>;
}> = ({ album }) => {
  const details = [
    album.trackCount === undefined ? undefined : `${album.trackCount} tracks`,
    album.releaseDate?.slice(0, 4),
  ].filter(Boolean);

  return (
    <div className="min-w-0 w-full flex-grow">
      <h3 className="block max-w-full truncate text-lg font-semibold leading-tight text-slate-800">
        {album.title}
      </h3>
      <p className="text-slate-600 truncate">{album.artistName}</p>
      {details.length > 0 && (
        <p className="text-sm text-slate-400 mt-1">{details.join(` • `)}</p>
      )}
    </div>
  );
};

function mixedApprovedItems(
  artists: ApprovedArtist[],
  albums: ApprovedAlbum[],
): ApprovedMusicItem[] {
  return [
    ...artists.map((artist, index) => ({
      kind: `artist` as const,
      id: artist.id,
      createdAt: artist.createdAt,
      sequence: index,
      artist,
    })),
    ...albums.map((album, index) => ({
      kind: `album` as const,
      id: album.id,
      createdAt: album.createdAt,
      sequence: artists.length + index,
      album,
    })),
  ].sort(compareApprovedMusicItems);
}

function compareApprovedMusicItems(a: ApprovedMusicItem, b: ApprovedMusicItem): number {
  const timeA = createdAtSortTime(a.createdAt);
  const timeB = createdAtSortTime(b.createdAt);
  return timeB - timeA || a.sequence - b.sequence;
}

function createdAtSortTime(createdAt?: string): number {
  if (!createdAt) return Number.NEGATIVE_INFINITY;
  const time = Date.parse(createdAt);
  return Number.isNaN(time) ? Number.NEGATIVE_INFINITY : time;
}

function sizedAppleArtworkUrl(url?: string): string | undefined {
  return url?.replace(`{w}`, `600`).replace(`{h}`, `600`);
}

export default MusicCuration;
