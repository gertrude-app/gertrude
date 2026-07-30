import {
  ApiErrorMessage,
  ConfirmDestructiveAction,
  EmptyState,
  Loading,
  Modal,
} from '@dash/components';
import { Badge, Button, TextInput } from '@shared/components';
import cx from 'classnames';
import React, { useEffect, useRef, useState } from 'react';
import toast from 'react-hot-toast';
import type { MutationResult } from '../../hooks/mutation';
import type {
  ApproveMusicArtist_v2,
  GetMusicAlbumCuration,
  GetMusicCuration,
  PqlError,
  SaveMusicAlbumCuration,
  SearchMusicCatalog_v2,
} from '@dash/types';
import Current from '../../environment';
import { Key, useMutation, useOptimism, useQuery } from '../../hooks';

type Curation = GetMusicCuration.Output;
type CurationAlbum = Curation[`albums`][number];
type CurationArtist = Curation[`artists`][number];
type AlbumCuration = GetMusicAlbumCuration.Output;
type AlbumTrack = AlbumCuration[`tracks`][number];
type SearchItem = SearchMusicCatalog_v2.Output[`items`][number];
type SearchTrack = NonNullable<SearchItem[`track`]>;
type SearchAlbum = NonNullable<SearchItem[`album`]>;
type SearchArtist = NonNullable<SearchItem[`artist`]>;
type ArtistConfirmation = NonNullable<ApproveMusicArtist_v2.Output[`confirmation`]>;
type ArtistLike = Pick<SearchArtist, `name` | `catalogMetadata`>;
type AlbumLike = Pick<SearchAlbum, `title` | `artistName` | `trackCount` | `releaseDate`>;
type ApprovedMusicItem =
  | { kind: `artist`; createdAt: string; artist: CurationArtist }
  | { kind: `album`; createdAt: string; album: CurationAlbum };

const MusicCuration: React.FC<{
  childId: string;
  childName: string;
  className?: string;
}> = ({ childId, childName, className }) => {
  const [searchQuery, setSearchQuery] = useState(``);
  const [hasSearched, setHasSearched] = useState(false);
  const [activeAlbumId, setActiveAlbumId] = useState<string>();
  const [draftTrackIds, setDraftTrackIds] = useState<Set<string>>(new Set());
  const [albumMessage, setAlbumMessage] = useState<string>();
  const [artistConfirmation, setArtistConfirmation] = useState<{
    artist: SearchArtist;
    confirmation: ArtistConfirmation;
  }>();
  const requestedArtist = useRef<SearchArtist | undefined>(undefined);
  const optimism = useOptimism();
  const curationKey = Key.musicCuration(childId);
  const albumKey = Key.musicAlbumCuration(childId, activeAlbumId ?? `closed`);

  const curationQuery = useQuery(curationKey, () =>
    Current.api.getMusicCuration({ childId }),
  );
  const albumQuery = useQuery(
    albumKey,
    () =>
      Current.api.getMusicAlbumCuration({
        childId,
        appleMusicAlbumId: activeAlbumId ?? ``,
      }),
    { enabled: activeAlbumId !== undefined },
  );
  const searchCatalog = useMutation(
    (input: SearchMusicCatalog_v2.Input) => Current.api.searchMusicCatalog(input),
    { onSuccess: () => setHasSearched(true) },
  );

  const refreshSearch = (): void => {
    const query = searchQuery.trim();
    if (hasSearched && query) {
      searchCatalog.mutate({ childId, query, limit: 10 });
    }
  };

  const receiveCuration = (curation: Curation): void => {
    optimism.update(curationKey, curation);
    refreshSearch();
  };

  const approveTrack = useMutation(
    (track: SearchTrack) =>
      Current.api.approveMusicTrack({
        childId,
        appleMusicTrackId: track.id,
        preferredAlbumId: track.preferredAlbumId,
      }),
    {
      onSuccess: receiveCuration,
      invalidating: [curationKey],
      toast: `approve:music-track`,
    },
  );
  const approveAlbum = useMutation(
    (album: SearchAlbum) =>
      Current.api.approveMusicAlbum({
        childId,
        appleMusicAlbumId: album.id,
      }),
    {
      onSuccess: receiveCuration,
      invalidating: [curationKey],
      toast: `approve:music-album`,
    },
  );
  const approveArtist = useMutation(
    ({
      artist,
      confirmationToken,
    }: {
      artist: SearchArtist;
      confirmationToken?: string;
    }) => {
      requestedArtist.current = artist;
      return Current.api.approveMusicArtist({
        childId,
        appleMusicArtistId: artist.id,
        confirmationToken,
      });
    },
    {
      onSuccess: (output) => {
        if (output.status === `confirmationRequired` && output.confirmation) {
          if (!requestedArtist.current) return;
          setArtistConfirmation({
            artist: requestedArtist.current,
            confirmation: output.confirmation,
          });
          optimism.update(curationKey, output.curation);
          return;
        }
        requestedArtist.current = undefined;
        setArtistConfirmation(undefined);
        receiveCuration(output.curation);
        toast.success(`Artist allowed`);
      },
      onError: (error) => toast.error(error.userMessage ?? `Failed to allow artist`),
      invalidating: [curationKey],
    },
  );
  const removeArtist = useMutation(
    (artistId: string) =>
      Current.api.removeApprovedMusicArtist({
        childId,
        appleMusicArtistId: artistId,
      }),
    {
      invalidating: [curationKey],
      onSuccess: refreshSearch,
      toast: `remove:music-artist`,
    },
  );
  const saveAlbum = useMutation(
    (input: SaveMusicAlbumCuration.Input) => Current.api.saveMusicAlbumCuration(input),
    {
      onSuccess: (output) => {
        optimism.update(curationKey, output.curation);
        optimism.update(albumKey, output.album);
        setDraftTrackIds(selectedTrackIds(output.album));
        if (output.status === `conflict`) {
          setAlbumMessage(
            `This album changed in another session. Your checklist has been refreshed.`,
          );
          return;
        }
        if (output.status === `coveredByArtist`) {
          setAlbumMessage(
            `This album is now allowed through ${output.album.governingArtistName ?? `an allowed artist`}.`,
          );
          return;
        }
        setActiveAlbumId(undefined);
        setAlbumMessage(undefined);
        refreshSearch();
        toast.success(`Music selection saved`);
      },
      onError: (error) =>
        toast.error(error.userMessage ?? `Failed to save music selection`),
      invalidating: [curationKey],
    },
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

  useEffect(() => {
    if (!albumQuery.data) return;
    setDraftTrackIds(selectedTrackIds(albumQuery.data));
  }, [albumQuery.data]);

  const detail = albumQuery.data;
  const initialSelection = detail ? selectedTrackIds(detail) : new Set<string>();
  const draftChanged = !setsEqual(draftTrackIds, initialSelection);
  const canSearch = searchQuery.trim().length > 0 && !searchCatalog.isPending;
  const showSearchResults =
    hasSearched || searchCatalog.isPending || searchCatalog.isError;
  const searchItems = searchCatalog.data?.items ?? [];
  const approvedItems = mixedApprovedItems(
    curationQuery.data?.artists ?? [],
    curationQuery.data?.albums ?? [],
  );

  const searchSubmitted = (event: React.FormEvent<HTMLFormElement>): void => {
    event.preventDefault();
    const query = searchQuery.trim();
    if (!query || searchCatalog.isPending) return;
    searchCatalog.mutate({ childId, query, limit: 10 });
  };

  const clearSearchResults = (): void => {
    searchCatalog.reset();
    setHasSearched(false);
  };

  const openAlbum = (albumId: string): void => {
    setAlbumMessage(undefined);
    setActiveAlbumId(albumId);
  };

  const saveAlbumSelection = (): void => {
    if (!detail || !detail.canEdit || saveAlbum.isPending) return;
    saveAlbum.mutate({
      childId,
      appleMusicAlbumId: detail.id,
      expectedRevision: detail.revision,
      selectedTrackIds: [...draftTrackIds],
    });
  };

  return (
    <div className={className}>
      <form
        onSubmit={searchSubmitted}
        className="flex flex-col sm:flex-row gap-3 sm:items-end"
      >
        <TextInput
          type="text"
          name="music-search"
          label="Search Apple Music"
          value={searchQuery}
          setValue={setSearchQuery}
          placeholder="Artist, album, or track"
        />
        <Button type="submit" color="primary" disabled={!canSearch} className="sm:mb-px">
          {searchCatalog.isPending ? `Searching...` : `Search`}
        </Button>
      </form>

      {showSearchResults && (
        <section className="mt-8" aria-labelledby="music-search-results-heading">
          <div className="mb-3 flex items-center justify-between gap-3">
            <h2
              id="music-search-results-heading"
              className="text-xl font-bold text-slate-700"
            >
              Search results
            </h2>
            <Button
              type="button"
              color="tertiary"
              size="small"
              disabled={searchCatalog.isPending}
              onClick={clearSearchResults}
            >
              Clear results
            </Button>
          </div>
          {searchCatalog.isPending && <Loading label="Searching Apple Music…" />}
          {searchCatalog.isError && <ApiErrorMessage error={searchCatalog.error} />}
          {searchCatalog.isSuccess && searchItems.length === 0 && (
            <div className="rounded-2xl border border-dashed border-slate-200 bg-slate-50 px-5 py-8 text-center text-slate-500">
              No artists, albums, or tracks found. Try another search.
            </div>
          )}
          {searchItems.length > 0 && (
            <div className="grid gap-3">
              {searchItems.map((item, index) => (
                <SearchResultCard
                  key={`${item.kind}-${item.track?.id ?? item.album?.id ?? item.artist?.id}-${index}`}
                  item={item}
                  approveTrack={approveTrack}
                  approveAlbum={approveAlbum}
                  approveArtist={approveArtist}
                  openAlbum={openAlbum}
                />
              ))}
            </div>
          )}
        </section>
      )}

      <section className="mt-12" aria-labelledby="allowed-music-heading">
        <div className="mb-4 flex items-end justify-between gap-4">
          <h2 id="allowed-music-heading" className="text-xl font-bold text-slate-700">
            {childName}&rsquo;s allowed music
          </h2>
          {curationQuery.data && (
            <p className="hidden text-xs text-slate-400 sm:block">
              Changes appear automatically on connected devices
            </p>
          )}
        </div>
        {curationQuery.isPending && <Loading label="Loading allowed music…" />}
        {curationQuery.isError && <ApiErrorMessage error={curationQuery.error} />}
        {curationQuery.isSuccess && approvedItems.length === 0 && (
          <EmptyState
            heading="No allowed music yet"
            secondaryText="Search Apple Music above and allow an artist, an album, or just the tracks this child can play."
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
          <div className="grid grid-cols-[repeat(auto-fit,minmax(min(100%,24rem),1fr))] gap-4">
            {approvedItems.map((item) =>
              item.kind === `artist` ? (
                <ApprovedArtistCard
                  key={`artist-${item.artist.id}`}
                  artist={item.artist}
                  isRemoving={
                    removeArtist.isPending && removeArtist.variables === item.artist.id
                  }
                  onRemove={() => removeArtist.mutate(item.artist.id)}
                />
              ) : (
                <ApprovedAlbumCard
                  key={`album-${item.album.id}`}
                  album={item.album}
                  onManage={() => openAlbum(item.album.id)}
                />
              ),
            )}
          </div>
        )}
      </section>

      <AlbumCurationModal
        detail={detail}
        draftTrackIds={draftTrackIds}
        error={albumQuery.error}
        isOpen={activeAlbumId !== undefined}
        isLoading={albumQuery.isPending}
        isSaving={saveAlbum.isPending}
        message={albumMessage}
        draftChanged={draftChanged}
        onDismiss={() => setActiveAlbumId(undefined)}
        onSave={saveAlbumSelection}
        setDraftTrackIds={setDraftTrackIds}
      />

      <ConfirmDestructiveAction
        title={`Allow all music by ${artistConfirmation?.artist.name ?? `this artist`}?`}
        confirmText={approveArtist.isPending ? `Allowing...` : `Allow artist`}
        openWhenPresent={artistConfirmation}
        onDismiss={() => setArtistConfirmation(undefined)}
        onConfirm={() => {
          if (!artistConfirmation || approveArtist.isPending) return;
          approveArtist.mutate({
            artist: artistConfirmation.artist,
            confirmationToken: artistConfirmation.confirmation.token,
          });
        }}
      >
        {artistConfirmation && (
          <p>
            This will replace {replacementCountText(artistConfirmation.confirmation)}. If
            you later remove {artistConfirmation.artist.name}, those earlier choices will
            not return.
          </p>
        )}
      </ConfirmDestructiveAction>
    </div>
  );
};

const SearchResultCard: React.FC<{
  item: SearchItem;
  approveTrack: MutationResult<Curation, SearchTrack>;
  approveAlbum: MutationResult<Curation, SearchAlbum>;
  approveArtist: MutationResult<
    ApproveMusicArtist_v2.Output,
    { artist: SearchArtist; confirmationToken?: string }
  >;
  openAlbum(albumId: string): void;
}> = ({ item, approveTrack, approveAlbum, approveArtist, openAlbum }) => {
  const approvalPending =
    approveTrack.isPending || approveAlbum.isPending || approveArtist.isPending;
  if (item.track) {
    const track = item.track;
    return (
      <SearchResultShell
        artwork={<AlbumArtwork artworkUrl={track.artworkUrl} title={track.title} />}
        info={
          <div className="min-w-0 grow">
            <h3 className="truncate text-lg font-semibold text-slate-800">
              {track.title}
              <span className="text-slate-500"> · Track</span>
            </h3>
            <p className="truncate text-slate-600">
              {track.artistName} · {track.albumTitle}
            </p>
          </div>
        }
        action={
          <TrackSearchAction
            track={track}
            disabled={approvalPending}
            isPending={approveTrack.isPending && approveTrack.variables?.id === track.id}
            onAllow={() => approveTrack.mutate(track)}
            onManage={() =>
              openAlbum(track.status.managementAlbumId ?? track.preferredAlbumId)
            }
          />
        }
        appleMusicUrl={track.appleMusicUrl}
      />
    );
  }
  if (item.album) {
    const album = item.album;
    return (
      <SearchResultShell
        artwork={<AlbumArtwork artworkUrl={album.artworkUrl} title={album.title} />}
        info={<AlbumInfo album={album} showKind />}
        action={
          <AlbumSearchAction
            album={album}
            disabled={approvalPending}
            isPending={approveAlbum.isPending && approveAlbum.variables?.id === album.id}
            onAllow={() => approveAlbum.mutate(album)}
            onManage={() => openAlbum(album.id)}
          />
        }
        appleMusicUrl={album.appleMusicUrl}
      />
    );
  }
  if (item.artist) {
    const artist = item.artist;
    return (
      <SearchResultShell
        artwork={<ArtistArtwork artist={artist} />}
        info={<ArtistInfo artist={artist} />}
        action={
          <Button
            type="button"
            color="secondary"
            size="small"
            disabled={artist.status === `allowed` || approvalPending}
            onClick={() => approveArtist.mutate({ artist })}
            className="shrink-0 whitespace-nowrap"
          >
            {artist.status === `allowed`
              ? `Allowed`
              : approveArtist.isPending &&
                  approveArtist.variables?.artist.id === artist.id
                ? `Checking...`
                : `Allow artist`}
          </Button>
        }
        appleMusicUrl={artist.catalogMetadata?.appleMusicUrl}
      />
    );
  }
  return null;
};

const SearchResultShell: React.FC<{
  artwork: React.ReactNode;
  info: React.ReactNode;
  action: React.ReactNode;
  appleMusicUrl?: string;
}> = ({ artwork, info, action, appleMusicUrl }) => (
  <article
    data-test="music-search-result"
    className="min-w-0 rounded-2xl border-[0.5px] border-slate-200 bg-white p-4 shadow"
  >
    <div className="flex min-w-0 flex-col gap-4 sm:flex-row sm:items-center">
      {artwork}
      {info}
      <div className="flex shrink-0 flex-wrap gap-2 sm:ml-auto sm:flex-col sm:items-end">
        {action}
        {appleMusicUrl && (
          <Button
            type="external"
            href={appleMusicUrl}
            color="tertiary"
            size="small"
            className="shrink-0 whitespace-nowrap"
          >
            Apple Music
            <i className="fa-solid fa-arrow-up-right-from-square ml-2 text-xs" />
          </Button>
        )}
      </div>
    </div>
  </article>
);

const TrackSearchAction: React.FC<{
  track: SearchTrack;
  disabled: boolean;
  isPending: boolean;
  onAllow(): void;
  onManage(): void;
}> = ({ track, disabled, isPending, onAllow, onManage }) => {
  switch (track.status.kind) {
    case `available`:
      return (
        <Button
          type="button"
          color="secondary"
          size="small"
          onClick={onAllow}
          disabled={disabled}
        >
          {isPending ? `Adding...` : `Allow track`}
        </Button>
      );
    case `selected`:
      return (
        <Button type="button" color="secondary" size="small" onClick={onManage}>
          Allowed · Manage
        </Button>
      );
    case `allowedWithAlbum`:
      return (
        <Button type="button" color="tertiary" size="small" onClick={onManage}>
          Allowed with album
        </Button>
      );
    case `allowedWithArtist`:
      return (
        <Button type="button" color="tertiary" size="small" disabled onClick={() => {}}>
          Allowed through {track.status.governingArtistName ?? `artist`}
        </Button>
      );
  }
};

const AlbumSearchAction: React.FC<{
  album: SearchAlbum;
  disabled: boolean;
  isPending: boolean;
  onAllow(): void;
  onManage(): void;
}> = ({ album, disabled, isPending, onAllow, onManage }) => {
  switch (album.status.kind) {
    case `available`:
      return (
        <div className="flex flex-wrap justify-end gap-2">
          <Button
            type="button"
            color="secondary"
            size="small"
            onClick={onAllow}
            disabled={disabled}
          >
            {isPending ? `Adding...` : `Allow album`}
          </Button>
          <Button type="button" color="tertiary" size="small" onClick={onManage}>
            Choose tracks
          </Button>
        </div>
      );
    case `selectedTracks`:
      return (
        <Button type="button" color="secondary" size="small" onClick={onManage}>
          {trackCountText(album.status.selectedTrackCount)} allowed · Manage
        </Button>
      );
    case `wholeAlbum`:
      return (
        <Button type="button" color="secondary" size="small" onClick={onManage}>
          All tracks allowed · Manage
        </Button>
      );
    case `allowedWithArtist`:
      return (
        <Button type="button" color="tertiary" size="small" onClick={onManage}>
          Allowed through {album.status.governingArtistName ?? `artist`} · View
        </Button>
      );
  }
};

const ApprovedArtistCard: React.FC<{
  artist: CurationArtist;
  isRemoving: boolean;
  onRemove(): void;
}> = ({ artist, isRemoving, onRemove }) => (
  <article
    id={`allowed-music-artist-${artist.id}`}
    data-test="approved-music-item"
    className="min-w-0 scroll-mt-8 rounded-2xl border-[0.5px] border-violet-100 bg-gradient-to-br from-white to-violet-50/50 p-4 shadow"
  >
    <div className="flex min-w-0 items-center gap-4">
      <ArtistArtwork artist={artist} />
      <ArtistInfo artist={artist} />
    </div>
    <div className="mt-4 flex items-center justify-between gap-3 border-t border-violet-100 pt-3">
      <p className="text-sm font-medium text-violet-700">
        Current and future eligible releases
      </p>
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
  </article>
);

const ApprovedAlbumCard: React.FC<{
  album: CurationAlbum;
  onManage(): void;
  // TEMP(app-review): re-enable with the artwork-suppression toggle, see above
  // isUpdatingArtwork: boolean;
  // onToggleArtwork(): void;
}> = ({ album, onManage }) => (
  <article
    data-test="approved-music-item"
    className="group min-w-0 rounded-2xl border-[0.5px] border-slate-200 bg-white p-4 shadow transition-shadow hover:shadow-md"
  >
    <div className="flex min-w-0 items-center gap-4">
      <AlbumArtwork
        artworkUrl={album.showsArtwork ? album.artworkUrl : undefined}
        title={album.title}
      />
      <AlbumInfo
        album={{
          title: album.title,
          artistName: album.artistName,
          trackCount: album.catalogTrackCount,
          releaseDate: album.releaseDate,
        }}
        titleAccessory={
          <Badge
            type={album.scope === `wholeAlbum` ? `ok` : `info`}
            size="small"
            className="shrink-0 whitespace-nowrap"
          >
            {album.scope === `wholeAlbum`
              ? `All tracks allowed`
              : `${trackCountText(album.selectedTrackCount)} allowed`}
          </Badge>
        }
      />
    </div>
    <div className="mt-4 flex justify-end border-t border-slate-100 pt-3">
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
      <Button type="button" color="secondary" size="small" onClick={onManage}>
        Manage tracks
      </Button>
    </div>
  </article>
);

const AlbumCurationModal: React.FC<{
  detail?: AlbumCuration;
  draftTrackIds: Set<string>;
  error?: PqlError | null;
  isOpen: boolean;
  isLoading: boolean;
  isSaving: boolean;
  message?: string;
  draftChanged: boolean;
  onDismiss(): void;
  onSave(): void;
  setDraftTrackIds(value: Set<string>): void;
}> = ({
  detail,
  draftTrackIds,
  error,
  isOpen,
  isLoading,
  isSaving,
  message,
  draftChanged,
  onDismiss,
  onSave,
  setDraftTrackIds,
}) => (
  <Modal
    type="container"
    title={detail?.title ?? `Album tracks`}
    isOpen={isOpen}
    loading={isLoading}
    maximizeWidthForSmallScreens
    onDismiss={isSaving ? () => {} : onDismiss}
    primaryButton={
      detail?.canEdit
        ? {
            type: `action`,
            action: onSave,
            label: isSaving ? `Saving...` : `Save changes`,
            disabled: isSaving || !draftChanged,
          }
        : { type: `action`, action: onDismiss, label: `Done` }
    }
    secondaryButton={
      detail?.canEdit
        ? { type: `action`, action: onDismiss, label: `Cancel`, disabled: isSaving }
        : undefined
    }
  >
    <div data-test="music-album-modal">
      {error && <ApiErrorMessage error={error} />}
      {detail && (
        <>
          {detail.scope === `artist` && (
            <div className="mb-4 rounded-xl border border-violet-200 bg-violet-50 px-4 py-3 text-sm text-violet-800">
              <strong>
                All tracks are allowed because{` `}
                {detail.governingArtistName ?? `this artist`} is allowed.
              </strong>
              {` `}
              To change this album, first remove the artist from allowed music.{` `}
              {detail.governingArtistId && (
                <a
                  href={`#allowed-music-artist-${detail.governingArtistId}`}
                  onClick={onDismiss}
                  className="font-bold underline underline-offset-2"
                >
                  View artist
                </a>
              )}
            </div>
          )}
          {message && (
            <div className="mb-4 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm font-medium text-amber-800">
              {message}
            </div>
          )}
          <div className="mb-4 flex flex-col gap-3 rounded-xl bg-slate-50 p-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="font-semibold text-slate-800">{detail.artistName}</p>
              <p className="text-sm text-slate-500">
                {detail.canEdit
                  ? `${trackCountText(draftTrackIds.size)} will be allowed`
                  : `All ${trackCountText(detail.catalogTrackCount)} are allowed`}
              </p>
              {detail.canEdit && (
                <p className="text-xs text-slate-400">
                  Only selected tracks appear in Gertrude Music.
                </p>
              )}
            </div>
            {detail.canEdit && (
              <div className="flex gap-2">
                <Button
                  type="button"
                  color="tertiary"
                  size="small"
                  onClick={() => setDraftTrackIds(new Set())}
                >
                  Select none
                </Button>
                <Button
                  type="button"
                  color="tertiary"
                  size="small"
                  onClick={() =>
                    setDraftTrackIds(new Set(detail.tracks.map((track) => track.id)))
                  }
                >
                  Select all
                </Button>
              </div>
            )}
          </div>
          <AlbumTrackChecklist
            tracks={detail.tracks}
            canEdit={detail.canEdit}
            selectedTrackIds={draftTrackIds}
            setSelectedTrackIds={setDraftTrackIds}
          />
        </>
      )}
    </div>
  </Modal>
);

const AlbumTrackChecklist: React.FC<{
  tracks: AlbumTrack[];
  canEdit: boolean;
  selectedTrackIds: Set<string>;
  setSelectedTrackIds(value: Set<string>): void;
}> = ({ tracks, canEdit, selectedTrackIds, setSelectedTrackIds }) => {
  const multipleDiscs =
    new Set(tracks.map((track) => track.discNumber).filter(Boolean)).size > 1;
  return (
    <div className="max-h-[55vh] overflow-y-auto rounded-xl border border-slate-200">
      {tracks.map((track) => {
        const selected = selectedTrackIds.has(track.id);
        return (
          <label
            key={track.id}
            className={cx(
              `grid grid-cols-[1.25rem_2rem_minmax(0,1fr)_auto] items-center gap-3 border-b border-slate-100 px-3 py-3 last:border-b-0 sm:grid-cols-[1.25rem_2.5rem_minmax(0,1fr)_auto]`,
              canEdit
                ? `cursor-pointer hover:bg-violet-50/50`
                : `cursor-default bg-slate-50/40`,
            )}
          >
            <input
              data-test={`music-track-${track.id}`}
              type="checkbox"
              checked={selected}
              disabled={!canEdit}
              onChange={() => {
                const next = new Set(selectedTrackIds);
                if (selected) next.delete(track.id);
                else next.add(track.id);
                setSelectedTrackIds(next);
              }}
              className="h-4 w-4 rounded border-slate-300 text-violet-600 focus:ring-violet-500"
            />
            <span className="text-right text-sm font-semibold tabular-nums text-slate-400">
              {catalogTrackNumber(track, multipleDiscs)}
            </span>
            <span className="min-w-0">
              <span className="block truncate font-semibold text-slate-800">
                {track.title}
              </span>
              <span className="block truncate text-sm text-slate-500">
                {track.artistName}
              </span>
            </span>
            <span className="text-sm tabular-nums text-slate-400">
              {formatDuration(track.durationInMillis)}
            </span>
          </label>
        );
      })}
    </div>
  );
};

const ArtistArtwork: React.FC<{ artist: ArtistLike }> = ({ artist }) => {
  const artworkUrl = sizedAppleArtworkUrl(artist.catalogMetadata?.artwork?.url);
  return (
    <div className="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-full border border-violet-100 bg-violet-50">
      {artworkUrl ? (
        <img src={artworkUrl} alt={artist.name} className="h-full w-full object-cover" />
      ) : (
        <i className="fa-solid fa-microphone text-3xl text-violet-300" />
      )}
    </div>
  );
};

const AlbumArtwork: React.FC<{ artworkUrl?: string; title: string }> = ({
  artworkUrl,
  title,
}) => (
  <div className="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-xl border border-violet-100 bg-violet-50">
    {artworkUrl ? (
      <img src={artworkUrl} alt={title} className="h-full w-full object-cover" />
    ) : (
      <i className="fa-solid fa-music text-3xl text-violet-300" />
    )}
  </div>
);

const ArtistInfo: React.FC<{ artist: ArtistLike }> = ({ artist }) => {
  const genres = artist.catalogMetadata?.genreNames ?? [];
  const note =
    artist.catalogMetadata?.editorialNotes?.tagline ??
    artist.catalogMetadata?.editorialNotes?.short;
  return (
    <div className="min-w-0 w-full grow">
      <h3 className="block max-w-full truncate text-lg font-semibold leading-tight text-slate-800">
        {artist.name}
      </h3>
      {genres.length > 0 && (
        <p className="truncate text-slate-600">{genres.join(` • `)}</p>
      )}
      {note && <p className="mt-1 line-clamp-2 text-sm text-slate-400">{note}</p>}
    </div>
  );
};

const AlbumInfo: React.FC<{
  album: AlbumLike;
  showKind?: boolean;
  titleAccessory?: React.ReactNode;
}> = ({ album, showKind, titleAccessory }) => {
  const details = [
    album.trackCount === undefined ? undefined : trackCountText(album.trackCount),
    album.releaseDate?.slice(0, 4),
  ].filter(Boolean);
  return (
    <div className="min-w-0 w-full grow">
      <div className="flex min-w-0 items-center gap-2">
        <h3 className="min-w-0 truncate text-lg font-semibold leading-tight text-slate-800">
          {album.title}
          {showKind && <span className="text-slate-500"> · Album</span>}
        </h3>
        {titleAccessory}
      </div>
      <p className="truncate text-slate-600">{album.artistName}</p>
      {details.length > 0 && (
        <p className="mt-1 text-sm text-slate-400">{details.join(` • `)}</p>
      )}
    </div>
  );
};

function selectedTrackIds(album: AlbumCuration): Set<string> {
  return new Set(
    album.tracks.filter((track) => track.isSelected).map((track) => track.id),
  );
}

function mixedApprovedItems(
  artists: CurationArtist[],
  albums: CurationAlbum[],
): ApprovedMusicItem[] {
  return [
    ...artists.map((artist) => ({
      kind: `artist` as const,
      createdAt: artist.createdAt,
      artist,
    })),
    ...albums.map((album) => ({
      kind: `album` as const,
      createdAt: album.createdAt,
      album,
    })),
  ].sort((a, b) => Date.parse(b.createdAt) - Date.parse(a.createdAt));
}

function setsEqual(lhs: Set<string>, rhs: Set<string>): boolean {
  return lhs.size === rhs.size && [...lhs].every((value) => rhs.has(value));
}

function trackCountText(count: number): string {
  return `${count} ${count === 1 ? `track` : `tracks`}`;
}

function replacementCountText(confirmation: ArtistConfirmation): string {
  const parts = [];
  if (confirmation.albumCount > 0) {
    parts.push(
      `${confirmation.albumCount} ${confirmation.albumCount === 1 ? `album` : `albums`}`,
    );
  }
  if (confirmation.trackCount > 0) {
    parts.push(
      `${confirmation.trackCount} individual ${confirmation.trackCount === 1 ? `track` : `tracks`}`,
    );
  }
  return parts.join(` and `);
}

function catalogTrackNumber(track: AlbumTrack, multipleDiscs: boolean): string {
  if (track.trackNumber === undefined) return ``;
  if (multipleDiscs && track.discNumber !== undefined) {
    return `${track.discNumber}.${track.trackNumber}`;
  }
  return String(track.trackNumber);
}

function formatDuration(durationInMillis?: number): string {
  if (durationInMillis === undefined) return ``;
  const totalSeconds = Math.floor(durationInMillis / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = String(totalSeconds % 60).padStart(2, `0`);
  return `${minutes}:${seconds}`;
}

function sizedAppleArtworkUrl(url?: string): string | undefined {
  return url?.replace(`{w}`, `600`).replace(`{h}`, `600`);
}

export default MusicCuration;
