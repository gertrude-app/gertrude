import {
  Button,
  Card,
  ConfirmationDialog,
  EmptyState,
  Input,
  SlideOver,
  Text,
  VStack,
} from '@gertrude/ui';
import { MusicIcon, PlusIcon, SearchIcon } from 'lucide-react';
import React from 'react';
import type { MusicCurationState } from './useMusicCuration';
import MusicAlbumEditor from './MusicAlbumEditor';
import {
  ApprovedMusicRow,
  MusicLoadingRows,
  MusicSearchResult,
} from './MusicCurationCards';
import { approvedMusicItems, replacedApprovals } from './musicCurationHelpers';

const MusicCuration: React.FC<{
  personId: string;
  personName: string;
  state: MusicCurationState;
}> = ({ personId, personName, state }) => {
  const {
    query,
    setQuery,
    searchOpen,
    setSearchOpen,
    expandedAlbum,
    albumMessage,
    artistConfirmation,
    setArtistConfirmation,
    artistToRemove,
    setArtistToRemove,
    albumToRemove,
    setAlbumToRemove,
    curation,
    albumQuery,
    search,
    trackApproval,
    albumApproval,
    artistApproval,
    removeArtist,
    saveAlbum,
    removeAlbum,
    closeAlbum,
    toggleAlbum,
    closeSearch,
    leaveSearchEditor,
    album,
    onAlbumDirtyChange,
    initialAlbumSelectedTrackIds,
  } = state;
  const albumEditor = expandedAlbum && (
    <MusicAlbumEditor
      key={expandedAlbum.session}
      album={album}
      initialSelectedTrackIds={initialAlbumSelectedTrackIds}
      loading={albumQuery.isPending}
      error={
        albumQuery.isError
          ? (albumQuery.error?.userMessage ?? `Couldn't load this album.`)
          : undefined
      }
      message={albumMessage}
      saving={saveAlbum.isPending}
      onDirtyChange={onAlbumDirtyChange}
      onRetry={() => void albumQuery.refetch()}
      onClose={() => {
        closeAlbum();
      }}
      onViewArtist={(artistId) => {
        if (!closeAlbum()) return;
        setSearchOpen(false);
        requestAnimationFrame(() =>
          document
            .getElementById(`allowed-music-artist-${artistId}`)
            ?.scrollIntoView({ block: `center` }),
        );
      }}
      onSave={(detail, ids) =>
        saveAlbum.mutate({
          childId: personId,
          appleMusicAlbumId: detail.id,
          expectedRevision: detail.revision,
          selectedTrackIds: ids,
        })
      }
    />
  );
  const items = curation.data ? approvedMusicItems(curation.data) : [];
  const searchResults = search.isSuccess ? (search.data?.items ?? []) : [];
  const approving =
    trackApproval.isPending || albumApproval.isPending || artistApproval.isPending;
  const pendingId = trackApproval.isPending
    ? trackApproval.variables?.id
    : albumApproval.isPending
      ? albumApproval.variables?.id
      : artistApproval.isPending
        ? artistApproval.variables?.artist.id
        : undefined;

  return (
    <VStack gap={6}>
      <section
        aria-labelledby="allowed-music-heading"
        className="min-w-0 rounded-md border border-stone-200 bg-stone-50 p-3"
      >
        <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
          <VStack gap={0.5}>
            <Text as="h4" id="allowed-music-heading" variant="bodyStrong">
              {personName}’s allowed music
            </Text>
            <Text variant="captionMuted">
              Changes appear in Gertrude Music after the app is refreshed or reopened.
            </Text>
          </VStack>
          {!(curation.isSuccess && items.length === 0) && (
            <Button
              type="button"
              variant="primary"
              icon={PlusIcon}
              onClick={() => setSearchOpen(true)}
            >
              Add Music
            </Button>
          )}
        </div>
        {curation.isPending && (
          <>
            <Text variant="bodyMuted" role="status" className="sr-only">
              Loading allowed music…
            </Text>
            <Card as="ul" padding={0} className="overflow-hidden">
              <MusicLoadingRows count={4} />
            </Card>
          </>
        )}
        {curation.isError && (
          <div role="alert" className="flex flex-wrap items-center gap-2">
            <Text variant="bodyMuted">
              {curation.error?.userMessage ?? `Couldn't load allowed music.`}
            </Text>
            <Button type="button" size="small" onClick={() => void curation.refetch()}>
              Try again
            </Button>
          </div>
        )}
        {curation.isSuccess && items.length === 0 && (
          <EmptyState
            icon={MusicIcon}
            title="No music allowed yet"
            description={`Choose an artist, album, or track for ${personName} to play.`}
            button={{
              type: `button`,
              text: `Add Music`,
              icon: PlusIcon,
              variant: `primary`,
              onClick: () => setSearchOpen(true),
            }}
          />
        )}
        {items.length > 0 && (
          <Card as="ul" padding={0} className="overflow-hidden">
            {items.map((item) => (
              <ApprovedMusicRow
                key={`${item.kind}-${item.kind === `artist` ? item.artist.id : item.album.id}`}
                item={item}
                removingArtist={removeArtist.isPending}
                removingAlbum={removeAlbum.isPending}
                expanded={
                  item.kind === `album` &&
                  expandedAlbum?.surface === `library` &&
                  expandedAlbum.rowId === item.album.id
                }
                editor={
                  item.kind === `album` &&
                  expandedAlbum?.surface === `library` &&
                  expandedAlbum.rowId === item.album.id
                    ? albumEditor
                    : undefined
                }
                onRemoveArtist={setArtistToRemove}
                onRemoveAlbum={(album) => {
                  if (curation.data)
                    setAlbumToRemove({ album, revision: curation.data.revision });
                }}
                openAlbum={(id) => toggleAlbum(id, `library`, id)}
              />
            ))}
          </Card>
        )}
      </section>

      <SlideOver
        open={searchOpen}
        onOpenChange={(open) => {
          if (open) setSearchOpen(true);
          else closeSearch();
        }}
        ariaLabel="Add allowed music"
        heading="Add Music"
        subheading={`Find tracks, albums, or artists to allow for ${personName}.`}
        size="large"
      >
        <VStack className="h-full">
          <form
            className="flex shrink-0 gap-2 px-3 pb-4 @lg/slide:px-6"
            onSubmit={(event) => {
              event.preventDefault();
              const term = query.trim();
              if (term && !search.isPending) {
                if (expandedAlbum?.surface === `search` && !closeAlbum()) return;
                search.mutate({ childId: personId, query: term, limit: 10 });
              }
            }}
          >
            <div className="min-w-0 flex-1">
              <Input
                type="text"
                id={`music-search-${personId}`}
                label="Search Apple Music"
                value={query}
                setValue={setQuery}
                placeholder="Artist, album, or track"
              />
            </div>
            <Button
              type="submit"
              variant="primary"
              icon={SearchIcon}
              loading={search.isPending}
              disabled={!query.trim() || search.isPending}
              className="self-end"
            >
              Search
            </Button>
          </form>
          <SlideOver.Body className="px-3 @lg/slide:px-6">
            {search.status === `idle` ? (
              <Text variant="bodyMuted">
                Search Apple Music to find something to allow.
              </Text>
            ) : (
              <section aria-labelledby="music-results-heading">
                <div className="mb-3 flex items-center justify-between gap-2">
                  <Text as="h4" id="music-results-heading" variant="bodyStrong">
                    Results{` `}
                    {search.variables?.query ? `for “${search.variables.query}”` : ``}
                  </Text>
                  <Button
                    type="button"
                    size="small"
                    variant="ghost"
                    disabled={search.isPending}
                    onClick={() => {
                      if (expandedAlbum?.surface === `search` && !closeAlbum()) return;
                      search.reset();
                    }}
                  >
                    Clear
                  </Button>
                </div>
                {search.isPending && (
                  <>
                    <Text variant="bodyMuted" role="status" className="sr-only">
                      Searching Apple Music…
                    </Text>
                    <Card as="ul" padding={0} className="overflow-hidden">
                      <MusicLoadingRows />
                    </Card>
                  </>
                )}
                {search.isError && (
                  <div role="alert">
                    <Text variant="bodyMuted">
                      {search.error?.userMessage ?? `Search failed. Try again.`}
                    </Text>
                  </div>
                )}
                {search.isSuccess && searchResults.length === 0 && (
                  <Text variant="bodyMuted">
                    No artists, albums, or tracks found. Try another search.
                  </Text>
                )}
                {search.isSuccess && searchResults.length > 0 && (
                  <Card as="ul" padding={0} className="overflow-hidden">
                    {searchResults.map((item, index) => {
                      const rowId = `${item.kind}-${item.track?.id ?? item.album?.id ?? item.artist?.id ?? index}`;
                      const expanded =
                        expandedAlbum?.surface === `search` &&
                        expandedAlbum.rowId === rowId;
                      return (
                        <MusicSearchResult
                          key={rowId}
                          item={item}
                          pending={approving}
                          pendingId={pendingId}
                          expanded={expanded}
                          editor={expanded ? albumEditor : undefined}
                          allowTrack={(track) => {
                            if (leaveSearchEditor()) trackApproval.mutate(track);
                          }}
                          allowAlbum={(album) => {
                            if (leaveSearchEditor()) albumApproval.mutate(album);
                          }}
                          allowArtist={(artist) => {
                            if (leaveSearchEditor()) artistApproval.mutate({ artist });
                          }}
                          openAlbum={(id) => toggleAlbum(id, `search`, rowId)}
                        />
                      );
                    })}
                  </Card>
                )}
              </section>
            )}
          </SlideOver.Body>
          <SlideOver.Footer justify="end">
            <Button type="button" onClick={closeSearch}>
              Done
            </Button>
          </SlideOver.Footer>
        </VStack>
      </SlideOver>

      <ConfirmationDialog
        open={!!artistConfirmation}
        onOpenChange={(open) => {
          if (!open && !artistApproval.isPending) setArtistConfirmation(undefined);
        }}
        confirmationQuestion={`Allow all eligible music by ${artistConfirmation?.artist.name ?? `this artist`}?`}
        description={
          artistConfirmation &&
          `This replaces ${replacedApprovals(artistConfirmation.confirmation.albumCount, artistConfirmation.confirmation.trackCount)}. Removing the artist later will not restore those choices.`
        }
        actions={[
          { text: `Cancel`, onClick: () => setArtistConfirmation(undefined) },
          {
            text: `Allow artist`,
            variant: `primary`,
            loading: artistApproval.isPending,
            autoClose: false,
            onClick: () => {
              if (artistConfirmation)
                artistApproval.mutate({
                  artist: artistConfirmation.artist,
                  token: artistConfirmation.confirmation.token,
                });
            },
          },
        ]}
      />
      <ConfirmationDialog
        open={!!artistToRemove}
        onOpenChange={(open) => {
          if (!open && !removeArtist.isPending) setArtistToRemove(undefined);
        }}
        confirmationQuestion={`Remove ${artistToRemove?.name ?? `this artist`}?`}
        description="Music allowed through this artist will no longer be available. Album and track approvals previously replaced by this artist will not return."
        actions={[
          { text: `Cancel`, onClick: () => setArtistToRemove(undefined) },
          {
            text: `Remove artist`,
            variant: `destructive`,
            loading: removeArtist.isPending,
            autoClose: false,
            onClick: () => {
              if (artistToRemove) removeArtist.mutate(artistToRemove);
            },
          },
        ]}
      />
      <ConfirmationDialog
        open={!!albumToRemove}
        onOpenChange={(open) => {
          if (!open && !removeAlbum.isPending) setAlbumToRemove(undefined);
        }}
        confirmationQuestion={`Remove ${albumToRemove?.album.title ?? `this album`}?`}
        description={`All tracks allowed through this album will stop appearing in ${personName}’s music library.`}
        actions={[
          { text: `Cancel`, onClick: () => setAlbumToRemove(undefined) },
          {
            text: `Remove album`,
            variant: `destructive`,
            loading: removeAlbum.isPending,
            autoClose: false,
            onClick: () => {
              if (albumToRemove) removeAlbum.mutate(albumToRemove);
            },
          },
        ]}
      />
    </VStack>
  );
};

export default MusicCuration;
