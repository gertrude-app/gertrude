import { Button, EmptyState, Input, SlideOver } from '@gertrude/ui';
import { MusicIcon } from 'lucide-react';
import React from 'react';
import type { AllowedAlbum } from '#/components/types';
import AllowedAlbumCard from './AllowedAlbumCard';
import { albumKey } from '#/components/utils';

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  catalog: AllowedAlbum[];
  allowedAlbums: AllowedAlbum[];
  onAdd: (albums: AllowedAlbum[]) => void;
}

const albumMatchesSearchQuery = (album: AllowedAlbum, query: string): boolean => {
  const normalizedQuery = query.trim().toLowerCase();

  if (!normalizedQuery) {
    return true;
  }

  return `${album.title} ${album.artist}`.toLowerCase().includes(normalizedQuery);
};

const AddAllowedAlbumsSlideOver: React.FC<Props> = ({
  open,
  onOpenChange,
  catalog,
  allowedAlbums,
  onAdd,
}) => {
  const [albumSearchQuery, setAlbumSearchQuery] = React.useState(``);
  const [selectedAlbumKeys, setSelectedAlbumKeys] = React.useState<string[]>([]);
  const allowedAlbumKeys = allowedAlbums.map(albumKey);
  const filteredAlbumCatalog = catalog.filter((album) =>
    albumMatchesSearchQuery(album, albumSearchQuery),
  );
  const selectedAlbums = catalog.filter((album) =>
    selectedAlbumKeys.includes(albumKey(album)),
  );
  const close = (): void => {
    setSelectedAlbumKeys([]);
    setAlbumSearchQuery(``);
    onOpenChange(false);
  };
  const toggleSelectedAlbum = (album: AllowedAlbum): void => {
    const key = albumKey(album);

    if (allowedAlbumKeys.includes(key)) {
      return;
    }

    setSelectedAlbumKeys((currentKeys) =>
      currentKeys.includes(key)
        ? currentKeys.filter((currentKey) => currentKey !== key)
        : [...currentKeys, key],
    );
  };
  const addSelectedAlbums = (): void => {
    const albumsToAdd = selectedAlbums.filter(
      (album) => !allowedAlbumKeys.includes(albumKey(album)),
    );

    if (albumsToAdd.length === 0) {
      return;
    }

    onAdd(albumsToAdd);
    close();
  };

  return (
    <SlideOver
      open={open}
      onOpenChange={(nextOpen) => {
        if (nextOpen) {
          onOpenChange(true);
        } else {
          close();
        }
      }}
      ariaLabel="Add allowed albums"
      heading="Add allowed albums"
      subheading="Search for albums to allow in Gertrude Music."
      size="large"
    >
      <div className="flex h-full flex-col">
        <div className="shrink-0 px-3 pb-4 @lg/slide:px-6">
          <Input
            type="text"
            value={albumSearchQuery}
            setValue={setAlbumSearchQuery}
            placeholder="Search albums or artists..."
          />
        </div>
        <div className="min-h-0 flex-1 overflow-y-auto px-3 pb-4 @lg/slide:px-6">
          {filteredAlbumCatalog.length > 0 ? (
            <div className="grid grid-cols-2 gap-4 @md/slide:grid-cols-3">
              {filteredAlbumCatalog.map((album) => {
                const key = albumKey(album);
                const selected = selectedAlbumKeys.includes(key);
                const alreadyAllowed = allowedAlbumKeys.includes(key);

                return (
                  <AllowedAlbumCard
                    key={key}
                    album={album}
                    forceShowArtwork
                    selected={selected}
                    disabled={alreadyAllowed}
                    disabledLabel={alreadyAllowed ? `Already added` : undefined}
                    onSelect={() => toggleSelectedAlbum(album)}
                  />
                );
              })}
            </div>
          ) : (
            <EmptyState
              icon={MusicIcon}
              title="No Albums Found"
              description="Try a different album title or artist."
            />
          )}
        </div>
        <div className="flex shrink-0 items-center justify-between gap-3 border-t border-stone-200 bg-stone-50/95 px-3 py-3 @lg/slide:px-6 @lg/slide:py-4">
          <span className="text-sm text-stone-600">
            {selectedAlbums.length === 0
              ? `Select one or more albums`
              : `${selectedAlbums.length} album${selectedAlbums.length === 1 ? `` : `s`} selected`}
          </span>
          <Button
            type="button"
            variant="primary"
            disabled={selectedAlbums.length === 0}
            onClick={addSelectedAlbums}
          >
            {selectedAlbums.length === 0
              ? `Add Album`
              : `Add ${selectedAlbums.length} Album${selectedAlbums.length === 1 ? `` : `s`}`}
          </Button>
        </div>
      </div>
    </SlideOver>
  );
};

export default AddAllowedAlbumsSlideOver;
