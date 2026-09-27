import { Banner, Button, HStack, Skeleton, Text, VStack } from '@gertrude/ui';
import { CheckIcon } from 'lucide-react';
import React from 'react';
import type { GetMusicAlbumCuration } from '@shared/pairql/src/account';
import {
  duration,
  sameIds,
  selectedTrackIds,
  trackCount,
  trackNumber,
} from './musicCurationHelpers';

type Album = GetMusicAlbumCuration.Output;

interface Props {
  album?: Album;
  initialSelectedTrackIds?: string[];
  loading: boolean;
  error?: string;
  message?: string;
  saving: boolean;
  onDirtyChange: (dirty: boolean) => void;
  onRetry: () => void;
  onClose: () => void;
  onViewArtist: (artistId: string) => void;
  onSave: (album: Album, ids: string[]) => void;
}

const MusicAlbumEditor: React.FC<Props> = ({
  album,
  initialSelectedTrackIds,
  loading,
  error,
  message,
  saving,
  onDirtyChange,
  onRetry,
  onClose,
  onViewArtist,
  onSave,
}) => {
  const [selected, setSelected] = React.useState<Set<string>>(() =>
    initialSelectedTrackIds
      ? new Set(initialSelectedTrackIds)
      : album
        ? selectedTrackIds(album)
        : new Set(),
  );
  React.useEffect(() => {
    if (album)
      setSelected(
        initialSelectedTrackIds
          ? new Set(initialSelectedTrackIds)
          : selectedTrackIds(album),
      );
  }, [album, initialSelectedTrackIds]);
  const changed = !!album && !sameIds(selected, selectedTrackIds(album));
  React.useEffect(() => {
    onDirtyChange(changed);
    return () => onDirtyChange(false);
  }, [changed, onDirtyChange]);
  const multipleDiscs =
    new Set(album?.tracks.map((track) => track.discNumber).filter(Boolean)).size > 1;

  return (
    <VStack gap={4}>
      <HStack justify="between" align="center" wrap gap={2} className="-mb-2">
        <Text as="h5" variant="bodyStrong">
          Choose tracks
        </Text>
        {loading && <Skeleton className="h-7 w-32" radius="small" />}
        {album?.canEdit && album.tracks.length > 0 && (
          <Button
            type="button"
            size="small"
            variant="ghost"
            disabled={saving || selected.size === album.tracks.length}
            onClick={() => setSelected(new Set(album.tracks.map((track) => track.id)))}
          >
            Select all {trackCount(album.tracks.length)}
          </Button>
        )}
      </HStack>
      {loading && (
        <div role="status">
          <Text variant="bodyMuted" className="sr-only">
            Loading album tracks…
          </Text>
          <div
            aria-hidden="true"
            className="overflow-hidden rounded-xl border border-stone-200 bg-white"
          >
            {Array.from({ length: 4 }, (_, index) => (
              <div
                key={index}
                className="flex items-center gap-2 border-b border-stone-100 px-4 py-2 last:border-0 @lg/main:gap-3 @lg/slide:gap-3"
              >
                <Skeleton className="h-3 w-5 shrink-0" radius="small" />
                <Skeleton className="h-4 w-4 shrink-0" radius="small" />
                <div className="min-w-0 flex-1">
                  <Skeleton
                    className={`h-4 max-w-full ${index % 2 === 0 ? `w-36` : `w-48`}`}
                  />
                </div>
                <Skeleton className="h-3 w-8 shrink-0" radius="small" />
              </div>
            ))}
          </div>
        </div>
      )}
      {error && (
        <VStack gap={2} role="alert">
          <Text variant="bodyMuted">{error}</Text>
          <Button type="button" size="small" onClick={onRetry}>
            Try again
          </Button>
        </VStack>
      )}
      {album && (
        <>
          {album.scope === `artist` && (
            <Banner variant="neutral">
              All tracks are allowed through{` `}
              {album.governingArtistName ?? `an allowed artist`}. Remove the artist first
              to change this album.
              {album.governingArtistId && (
                <a
                  href={`#allowed-music-artist-${album.governingArtistId}`}
                  onClick={(event) => {
                    event.preventDefault();
                    if (album.governingArtistId) onViewArtist(album.governingArtistId);
                  }}
                  className="ml-1 underline"
                >
                  View artist
                </a>
              )}
            </Banner>
          )}
          {message && (
            <div role="status">
              <Banner variant="warning">{message}</Banner>
            </div>
          )}
          {album.canEdit && selected.size === 0 && changed && (
            <Text variant="bodyMuted">
              Saving with no tracks selected removes this album from allowed music.
            </Text>
          )}
          <div className="overflow-hidden rounded-xl border border-stone-200 bg-white">
            {album.tracks.map((track) => {
              const checked = selected.has(track.id);
              const disabled = !album.canEdit || saving;
              return (
                <label
                  key={track.id}
                  className={`flex select-none items-center gap-2 border-b border-stone-100 px-4 py-2 last:border-0 @lg/main:gap-3 @lg/slide:gap-3 ${disabled ? `cursor-default` : `cursor-pointer hover:bg-stone-50`}`}
                >
                  <span className="w-5 shrink-0 text-left text-xs tabular-nums text-stone-500">
                    {trackNumber(track, multipleDiscs)}
                  </span>
                  <input
                    type="checkbox"
                    className="peer sr-only"
                    checked={checked}
                    disabled={disabled}
                    aria-label={`${track.title}${track.contentRating === `explicit` ? `, explicit` : ``}`}
                    onChange={(event) => {
                      const next = new Set(selected);
                      if (event.target.checked) next.add(track.id);
                      else next.delete(track.id);
                      setSelected(next);
                    }}
                  />
                  <span
                    aria-hidden="true"
                    className={`flex h-4 w-4 shrink-0 items-center justify-center rounded-[4px] border peer-focus-visible:ring-2 peer-focus-visible:ring-violet-300/80 peer-focus-visible:ring-offset-2 ${checked ? `border-violet-600 bg-violet-500 text-white` : `border-stone-300 bg-white`}`}
                  >
                    {checked && <CheckIcon className="h-3 w-3" strokeWidth={3} />}
                  </span>
                  <span className="min-w-0 flex-1 break-words text-[13px] font-medium leading-5 text-stone-900">
                    {track.title}
                    {track.contentRating === `explicit` && (
                      <span
                        aria-hidden="true"
                        title="Explicit"
                        className="relative -top-px ml-1 inline-flex h-3.5 w-3.5 items-center justify-center rounded-[2px] border border-stone-400 align-middle text-[9px] font-bold leading-none text-stone-600"
                      >
                        E
                      </span>
                    )}
                  </span>
                  <span className="shrink-0 text-xs tabular-nums text-stone-500">
                    {duration(track.durationInMillis)}
                  </span>
                </label>
              );
            })}
          </div>
        </>
      )}
      <HStack justify="end" wrap gap={2}>
        <Button
          type="button"
          size="small"
          variant="ghost"
          disabled={saving}
          onClick={onClose}
        >
          {changed ? `Discard changes` : `Close`}
        </Button>
        {album?.canEdit && (
          <Button
            type="button"
            size="small"
            variant="primary"
            disabled={!changed || saving}
            loading={saving}
            onClick={() => onSave(album, [...selected])}
          >
            {selected.size === 0 ? `Remove album approval` : `Save selection`}
          </Button>
        )}
      </HStack>
    </VStack>
  );
};

export default MusicAlbumEditor;
