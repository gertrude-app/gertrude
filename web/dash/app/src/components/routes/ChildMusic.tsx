import {
  ApiErrorMessage,
  BetaBadge,
  EmptyState,
  Loading,
  PageHeading,
} from '@dash/components';
import { Button, TextInput, Toggle } from '@shared/components';
import React, { useState } from 'react';
import { useParams } from 'react-router-dom';
import type { GetApprovedMusicAlbums, SearchMusicCatalog } from '@dash/types';
import Current from '../../environment';
import { Key, useMutation, useQuery } from '../../hooks';

type SearchAlbum = SearchMusicCatalog.Output[`albums`][number];
type ApprovedAlbum = GetApprovedMusicAlbums.Output[`albums`][number];

const ChildMusic: React.FC = () => {
  const { userId: childId = `` } = useParams<{ userId: string }>();
  const [searchQuery, setSearchQuery] = useState(``);
  const [hasSearched, setHasSearched] = useState(false);
  const approvedAlbumsKey = Key.approvedMusicAlbums(childId);

  const childQuery = useQuery(Key.child(childId), () => Current.api.getChild(childId));
  const approvedAlbumsQuery = useQuery(approvedAlbumsKey, () =>
    Current.api.getApprovedMusicAlbums(childId),
  );

  const searchAlbums = useMutation(
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
        trackCount: album.trackCount,
        showsArtwork: true,
      }),
    { invalidating: [approvedAlbumsKey], toast: `approve:music-album` },
  );

  const removeAlbum = useMutation(
    (albumId: string) =>
      Current.api.removeApprovedMusicAlbum({
        childId,
        appleMusicAlbumId: albumId,
      }),
    { invalidating: [approvedAlbumsKey], toast: `remove:music-album` },
  );

  const updateAlbumArtwork = useMutation(
    (album: ApprovedAlbum) =>
      Current.api.approveMusicAlbum({
        childId,
        appleMusicAlbumId: album.id,
        title: album.title,
        artistName: album.artistName,
        artworkUrl: album.artworkUrl,
        trackCount: album.trackCount,
        showsArtwork: !album.showsArtwork,
      }),
    { invalidating: [approvedAlbumsKey], toast: `update:music-artwork` },
  );

  const approvedAlbums = approvedAlbumsQuery.data?.albums ?? [];
  const approvedAlbumIds = new Set(approvedAlbums.map((album) => album.id));
  const searchResults = searchAlbums.data?.albums ?? [];
  const canSearch = searchQuery.trim().length > 0 && !searchAlbums.isPending;
  const showSearchResults = hasSearched || searchAlbums.isPending || searchAlbums.isError;

  const onSubmit = (event: React.FormEvent<HTMLFormElement>): void => {
    event.preventDefault();
    const query = searchQuery.trim();
    if (!query || searchAlbums.isPending) return;
    searchAlbums.mutate({ query, limit: 10 });
  };

  if (childQuery.isPending) {
    return <Loading />;
  }

  if (childQuery.isError) {
    return <ApiErrorMessage error={childQuery.error} />;
  }

  const childName = childQuery.data.name;

  return (
    <div className="max-w-4xl">
      <div className="flex items-center gap-3 md:mt-3">
        <PageHeading icon="music" className="md:mt-0">
          {childName}&rsquo;s Music
        </PageHeading>
        <BetaBadge />
      </div>

      <form
        onSubmit={onSubmit}
        className="mt-8 flex flex-col sm:flex-row gap-3 sm:items-end"
      >
        <TextInput
          type="text"
          name="music-search"
          label="Search Apple Music albums"
          value={searchQuery}
          setValue={setSearchQuery}
          placeholder="Album title or artist"
        />
        <Button type="submit" color="primary" disabled={!canSearch} className="sm:mb-px">
          {searchAlbums.isPending ? `Searching...` : `Search`}
        </Button>
      </form>

      {showSearchResults && (
        <section className="mt-8">
          <h2 className="text-xl font-bold text-slate-700 mb-3">Search results</h2>
          {searchAlbums.isPending && <Loading label="Searching albums…" />}
          {searchAlbums.isError && <ApiErrorMessage error={searchAlbums.error} />}
          {searchAlbums.isSuccess && searchResults.length === 0 && (
            <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-5 py-8 text-center text-slate-500">
              No albums found. Try another search.
            </div>
          )}
          {searchResults.length > 0 && (
            <div className="grid gap-3">
              {searchResults.map((album) => (
                <SearchResultAlbumCard
                  key={album.id}
                  album={album}
                  isApproved={approvedAlbumIds.has(album.id)}
                  isApproving={
                    approveAlbum.isPending && approveAlbum.variables?.id === album.id
                  }
                  onApprove={() => approveAlbum.mutate(album)}
                />
              ))}
            </div>
          )}
        </section>
      )}

      <section className="mt-12">
        <h2 className="text-xl font-bold text-slate-700 mb-3">
          {childName}&rsquo;s allowed albums
        </h2>
        {approvedAlbumsQuery.isPending && <Loading label="Loading allowed albums…" />}
        {approvedAlbumsQuery.isError && (
          <ApiErrorMessage error={approvedAlbumsQuery.error} />
        )}
        {approvedAlbumsQuery.isSuccess && approvedAlbums.length === 0 && (
          <EmptyState
            heading="No allowed albums yet"
            secondaryText="Search Apple Music above and add the albums this child is allowed to play."
            icon="music"
            buttonText="Search for albums"
            buttonIcon="magnifying-glass"
            action={() =>
              document
                .querySelector<HTMLInputElement>(`input[name="music-search"]`)
                ?.focus()
            }
          />
        )}
        {approvedAlbums.length > 0 && (
          <div className="grid grid-cols-[repeat(auto-fit,minmax(min(100%,26rem),1fr))] gap-4">
            {approvedAlbums.map((album) => (
              <ApprovedAlbumCard
                key={album.id}
                album={album}
                isRemoving={removeAlbum.isPending && removeAlbum.variables === album.id}
                isUpdatingArtwork={
                  updateAlbumArtwork.isPending &&
                  updateAlbumArtwork.variables?.id === album.id
                }
                onRemove={() => removeAlbum.mutate(album.id)}
                onToggleArtwork={() => updateAlbumArtwork.mutate(album)}
              />
            ))}
          </div>
        )}
      </section>
    </div>
  );
};

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

const ApprovedAlbumCard: React.FC<{
  album: ApprovedAlbum;
  isRemoving: boolean;
  isUpdatingArtwork: boolean;
  onRemove(): void;
  onToggleArtwork(): void;
}> = ({ album, isRemoving, isUpdatingArtwork, onRemove, onToggleArtwork }) => (
  <div className="min-w-0 rounded-2xl bg-white p-4 shadow border-[0.5px] border-slate-200">
    <div className="min-w-0 flex gap-4">
      <AlbumArtwork
        artworkUrl={album.showsArtwork ? album.artworkUrl : undefined}
        title={album.title}
      />
      <AlbumInfo album={album} />
    </div>
    <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
      <label className="flex items-center gap-2 text-sm font-medium text-slate-600">
        <Toggle
          enabled={album.showsArtwork}
          setEnabled={onToggleArtwork}
          small
          disabled={isUpdatingArtwork}
        />
        {isUpdatingArtwork ? `Updating artwork...` : `Show album artwork`}
      </label>
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

export default ChildMusic;
