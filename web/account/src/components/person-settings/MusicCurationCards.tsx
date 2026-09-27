import { Button, HStack, Skeleton, Text, Tooltip, VStack } from '@gertrude/ui';
import { ArrowUpRightIcon, Disc3Icon, TrashIcon, UserIcon } from 'lucide-react';
import React from 'react';
import type { ApprovedMusicItem } from './musicCurationHelpers';
import type { GetMusicCuration, SearchMusicCatalog_v2 } from '@shared/pairql/src/account';
import { artworkUrl, trackCount } from './musicCurationHelpers';

type SearchItem = SearchMusicCatalog_v2.Output[`items`][number];
type Track = NonNullable<SearchItem[`track`]>;
type Album = NonNullable<SearchItem[`album`]>;
type Artist = NonNullable<SearchItem[`artist`]>;

const musicRowClassName = `border-t border-stone-200 first:border-t-0`;
const musicRowContentClassName = `flex flex-wrap items-center gap-x-3 gap-y-2 px-3 py-3 @lg/main:px-4 @lg/slide:px-4`;
const musicRowPanelClassName = `border-t border-stone-200 bg-stone-50/60 px-3 pt-2 pb-4 @lg/main:px-4 @lg/slide:px-4`;

export const MusicLoadingRows: React.FC<{ count?: number }> = ({ count = 3 }) => (
  <>
    {Array.from({ length: count }, (_, index) => (
      <li key={index} className={musicRowClassName} aria-hidden="true">
        <div className={musicRowContentClassName}>
          <Skeleton className="h-9 w-9 shrink-0" radius="small" />
          <VStack gap={1.5} className="min-w-36 flex-1">
            <Skeleton className={`h-4 max-w-full ${index % 2 === 0 ? `w-32` : `w-44`}`} />
            <Skeleton className="h-3 w-28" />
          </VStack>
          <Skeleton className="ml-auto h-7 w-24 shrink-0" radius="small" />
        </div>
      </li>
    ))}
  </>
);

const AlbumTrackExpansion: React.FC<{
  id: string;
  label: string;
  open: boolean;
  editor?: React.ReactNode;
}> = ({ id, label, open, editor }) => {
  const [retainedEditor, setRetainedEditor] = React.useState(editor);
  const [visible, setVisible] = React.useState(false);

  React.useEffect(() => {
    if (editor) setRetainedEditor(editor);
  }, [editor]);

  React.useEffect(() => {
    if (open) {
      let secondFrame: number | undefined;
      const firstFrame = requestAnimationFrame(() => {
        secondFrame = requestAnimationFrame(() => setVisible(true));
      });
      return () => {
        cancelAnimationFrame(firstFrame);
        if (secondFrame !== undefined) cancelAnimationFrame(secondFrame);
      };
    }
    setVisible(false);
    const timeout = window.setTimeout(() => setRetainedEditor(undefined), 210);
    return () => window.clearTimeout(timeout);
  }, [open]);

  return (
    <div
      id={id}
      role="region"
      aria-label={label}
      aria-hidden={!open}
      inert={!open}
      className={`overflow-hidden [interpolate-size:allow-keywords] transition-[height,opacity] duration-[180ms] ease-in-out motion-reduce:transition-none ${visible ? `h-auto opacity-100` : `h-0 opacity-0 pointer-events-none`}`}
    >
      {(editor || retainedEditor) && (
        <div className={musicRowPanelClassName}>{editor ?? retainedEditor}</div>
      )}
    </div>
  );
};

export const MusicArtwork: React.FC<{
  url?: string;
  artist?: boolean;
  hidden?: boolean;
  name: string;
}> = ({ url, artist = false, hidden = false, name }) => {
  const imageUrl = !hidden ? artworkUrl(url) : undefined;
  const shape = artist ? `rounded-full` : `rounded-[3px]`;
  return (
    <div className="relative h-9 w-9 shrink-0">
      {imageUrl ? (
        <>
          <img
            src={imageUrl}
            alt=""
            aria-hidden="true"
            className={`absolute inset-0 h-full w-full object-cover blur-xs opacity-40 ${shape}`}
          />
          <img
            src={imageUrl}
            alt=""
            className={`relative h-full w-full object-cover shadow shadow-stone-300/30 ${shape}`}
          />
        </>
      ) : (
        <div
          className={`flex h-full w-full items-center justify-center bg-stone-100 text-stone-500 ${shape}`}
        >
          {artist ? (
            <UserIcon size={18} aria-label={`Artwork unavailable for ${name}`} />
          ) : (
            <Disc3Icon
              size={18}
              aria-label={
                hidden ? `Artwork hidden for ${name}` : `Artwork unavailable for ${name}`
              }
            />
          )}
        </div>
      )}
    </div>
  );
};

const CatalogLink: React.FC<{ url?: string }> = ({ url }) =>
  url ? (
    <a
      href={url}
      target="_blank"
      rel="noopener noreferrer"
      className="inline-flex items-center gap-1 text-xs font-medium text-stone-500 underline-offset-2 hover:text-violet-700 hover:underline focus-visible:rounded focus-visible:outline-2 focus-visible:outline-violet-500"
    >
      View on Apple Music <ArrowUpRightIcon size={12} />
    </a>
  ) : null;

const ResultActions: React.FC<{
  item: SearchItem;
  pending: boolean;
  pendingId?: string;
  allowTrack: (track: Track) => void;
  allowAlbum: (album: Album) => void;
  allowArtist: (artist: Artist) => void;
  openAlbum: (id: string) => void;
  expanded: boolean;
  panelId: string;
}> = ({
  item,
  pending,
  pendingId,
  allowTrack,
  allowAlbum,
  allowArtist,
  openAlbum,
  expanded,
  panelId,
}) => {
  if (item.track) {
    const track = item.track;
    const status = track.status;
    if (status.kind === `allowedWithArtist`) {
      return (
        <Text variant="captionMuted">
          Allowed through {status.governingArtistName ?? `artist`}
        </Text>
      );
    }
    if (status.kind !== `available`) {
      return (
        <Button
          type="button"
          size="small"
          aria-expanded={expanded}
          aria-controls={panelId}
          onClick={() => openAlbum(status.managementAlbumId ?? track.preferredAlbumId)}
        >
          {expanded
            ? `Hide tracks`
            : status.kind === `selected`
              ? `Allowed · Manage tracks`
              : `Allowed with album · Manage`}
        </Button>
      );
    }
    return (
      <Button
        type="button"
        size="small"
        disabled={pending}
        loading={pendingId === track.id}
        onClick={() => allowTrack(track)}
      >
        Allow track
      </Button>
    );
  }
  if (item.album) {
    const album = item.album;
    const status = album.status;
    if (status.kind === `allowedWithArtist`) {
      return (
        <Button
          type="button"
          size="small"
          aria-expanded={expanded}
          aria-controls={panelId}
          onClick={() => openAlbum(album.id)}
        >
          {expanded ? `Hide tracks` : `Allowed through artist · View`}
        </Button>
      );
    }
    if (status.kind !== `available`) {
      return (
        <Button
          type="button"
          size="small"
          aria-expanded={expanded}
          aria-controls={panelId}
          onClick={() => openAlbum(album.id)}
        >
          {expanded
            ? `Hide tracks`
            : status.kind === `wholeAlbum`
              ? `All tracks allowed · Manage`
              : `${trackCount(status.selectedTrackCount)} allowed · Manage`}
        </Button>
      );
    }
    return (
      <HStack wrap gap={2}>
        <Button
          type="button"
          size="small"
          variant="ghost"
          aria-expanded={expanded}
          aria-controls={panelId}
          onClick={() => openAlbum(album.id)}
        >
          {expanded ? `Hide tracks` : `Choose tracks`}
        </Button>
        <Button
          type="button"
          size="small"
          disabled={pending}
          loading={pendingId === album.id}
          onClick={() => allowAlbum(album)}
        >
          Allow album
        </Button>
      </HStack>
    );
  }
  if (item.artist) {
    const artist = item.artist;
    return artist.status === `allowed` ? (
      <Text variant="captionMuted">Artist allowed</Text>
    ) : (
      <Button
        type="button"
        size="small"
        disabled={pending}
        loading={pendingId === artist.id}
        onClick={() => allowArtist(artist)}
      >
        Allow artist
      </Button>
    );
  }
  return null;
};

export const MusicSearchResult: React.FC<{
  item: SearchItem;
  pending: boolean;
  pendingId?: string;
  expanded: boolean;
  editor?: React.ReactNode;
  allowTrack: (track: Track) => void;
  allowAlbum: (album: Album) => void;
  allowArtist: (artist: Artist) => void;
  openAlbum: (id: string) => void;
}> = ({ item, expanded, editor, ...actions }) => {
  const panelId = React.useId();
  const track = item.track;
  const album = item.album;
  const artist = item.artist;
  const name = track?.title ?? album?.title ?? artist?.name;
  if (!name) return null;
  const url =
    track?.artworkUrl ??
    track?.artwork?.url ??
    album?.artworkUrl ??
    album?.artwork?.url ??
    artist?.catalogMetadata?.artwork?.url;
  const link =
    track?.appleMusicUrl ??
    album?.appleMusicUrl ??
    artist?.catalogMetadata?.appleMusicUrl;
  return (
    <li className={musicRowClassName}>
      <div className={musicRowContentClassName}>
        <MusicArtwork url={url} artist={!!artist} name={name} />
        <VStack gap={0.5} className="min-w-36 flex-1">
          <Text as="h4" variant="bodyStrong" className="break-words">
            {name}
          </Text>
          <Text variant="captionMuted" className="break-words">
            <span className="font-semibold text-stone-700">
              {track ? `Track` : album ? `Album` : `Artist`}
            </span>
            {track && ` · ${track.artistName} · ${track.albumTitle}`}
            {album &&
              ` · ${album.artistName}${album.trackCount === undefined ? `` : ` · ${trackCount(album.trackCount)}`}`}
            {artist?.catalogMetadata?.genreNames?.length
              ? ` · ${artist.catalogMetadata.genreNames.join(` · `)}`
              : ``}
            {track?.contentRating === `explicit` && ` · Explicit`}
          </Text>
          <CatalogLink url={link} />
        </VStack>
        <div className="ml-auto shrink-0">
          <ResultActions item={item} expanded={expanded} panelId={panelId} {...actions} />
        </div>
      </div>
      <AlbumTrackExpansion
        id={panelId}
        label={`${album?.title ?? track?.albumTitle ?? name} track selection`}
        open={expanded}
        editor={editor}
      />
    </li>
  );
};

export const ApprovedMusicRow: React.FC<{
  item: ApprovedMusicItem;
  removingArtist: boolean;
  removingAlbum: boolean;
  expanded: boolean;
  editor?: React.ReactNode;
  onRemoveArtist: (artist: GetMusicCuration.Output[`artists`][number]) => void;
  onRemoveAlbum: (album: GetMusicCuration.Output[`albums`][number]) => void;
  openAlbum: (id: string) => void;
}> = ({
  item,
  removingArtist,
  removingAlbum,
  expanded,
  editor,
  onRemoveArtist,
  onRemoveAlbum,
  openAlbum,
}) => {
  const panelId = React.useId();
  if (item.kind === `artist`) {
    const artist = item.artist;
    return (
      <li
        id={`allowed-music-artist-${artist.id}`}
        className={`${musicRowClassName} scroll-mt-6`}
      >
        <div className={musicRowContentClassName}>
          <MusicArtwork
            artist
            name={artist.name}
            url={artist.catalogMetadata?.artwork?.url}
          />
          <VStack gap={0.5} className="min-w-36 flex-1">
            <Text as="h4" variant="bodyStrong" className="break-words">
              {artist.name}
            </Text>
            <Text variant="captionMuted">
              Artist · Current and future eligible releases
            </Text>
          </VStack>
          <Tooltip content="Remove artist">
            <Button
              type="button"
              size="small"
              variant="ghost"
              icon={TrashIcon}
              ariaLabel={`Remove ${artist.name}`}
              className="ml-auto shrink-0"
              disabled={removingArtist}
              onClick={() => onRemoveArtist(artist)}
            />
          </Tooltip>
        </div>
      </li>
    );
  }
  const album = item.album;
  return (
    <li className={musicRowClassName}>
      <div className={musicRowContentClassName}>
        <MusicArtwork
          name={album.title}
          url={album.artworkUrl ?? album.artwork?.url}
          hidden={!album.showsArtwork}
        />
        <VStack gap={0.5} className="min-w-36 flex-1">
          <Text as="h4" variant="bodyStrong" className="break-words">
            {album.title}
          </Text>
          <Text variant="captionMuted" className="break-words">
            {album.artistName} ·{` `}
            <span className="font-semibold text-stone-700">
              {album.scope === `wholeAlbum`
                ? `Whole album`
                : `${trackCount(album.selectedTrackCount)} allowed`}
            </span>
          </Text>
        </VStack>
        <HStack gap={2} wrap className="ml-auto">
          <Button
            type="button"
            size="small"
            aria-expanded={expanded}
            aria-controls={panelId}
            onClick={() => openAlbum(album.id)}
          >
            {expanded ? `Hide tracks` : `Manage tracks`}
          </Button>
          <Tooltip content="Remove album">
            <Button
              type="button"
              size="small"
              variant="ghost"
              icon={TrashIcon}
              ariaLabel={`Remove ${album.title}`}
              disabled={removingAlbum}
              onClick={() => onRemoveAlbum(album)}
            />
          </Tooltip>
        </HStack>
      </div>
      <AlbumTrackExpansion
        id={panelId}
        label={`${album.title} track selection`}
        open={expanded}
        editor={editor}
      />
    </li>
  );
};
