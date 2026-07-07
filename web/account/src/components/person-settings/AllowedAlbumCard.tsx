import {
  Button,
  Card,
  DropdownMenu,
  DropdownMenuItem,
  HStack,
  Text,
  VStack,
} from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon, EllipsisIcon, EyeIcon, EyeOffIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { AllowedAlbum } from '#/components/types';

type Props = {
  album: AllowedAlbum;
  forceShowArtwork?: boolean;
  selected?: boolean;
  disabled?: boolean;
  disabledLabel?: string;
  onSelect?: () => void;
  onToggleAlbumArt?: () => void;
  onRemove?: () => void;
};

const AllowedAlbumCard: React.FC<Props> = ({
  album,
  forceShowArtwork,
  selected = false,
  disabled = false,
  disabledLabel,
  onSelect,
  onToggleAlbumArt,
  onRemove,
}) => {
  const showArtwork = forceShowArtwork || album.showAlbumArt;
  const content = (
    <>
      <div
        className={cx(
          `max-h-52 flex justify-center relative overflow-hidden rounded-md border border-stone-300`,
          !showArtwork && `bg-stone-100`,
        )}
      >
        {showArtwork && (
          <img
            src={album.artworkUrl}
            alt=""
            className="absolute w-full h-full blur opacity-40"
          />
        )}
        {showArtwork ? (
          <img
            src={album.artworkUrl}
            alt=""
            className="aspect-square rounded-md h-full relative"
          />
        ) : (
          <HStack
            justify="center"
            className="aspect-square rounded-md h-full bg-stone-200/80 relative"
          >
            <img
              src={album.artworkUrl}
              alt=""
              className="aspect-square rounded-md h-full opacity-0"
            />
            <EyeOffIcon className="text-stone-400/80 w-8 h-8 absolute" />
          </HStack>
        )}
        {selected && !disabled && (
          <HStack
            justify="center"
            className="absolute right-2 top-2 h-5 w-5 rounded-full border border-violet-200 bg-violet-500 text-white shadow shadow-violet-500/30"
          >
            <CheckIcon className="h-3 w-3" strokeWidth={3} />
          </HStack>
        )}
      </div>
      <HStack justify="between" gap={2} className="flex-grow">
        <VStack className="min-w-0">
          <Text variant="bodyStrong" truncate>
            {album.title}
          </Text>
          <Text variant="captionMuted" truncate className="-mt-0.5">
            {album.artist}
          </Text>
          {disabledLabel && (
            <Text
              variant="captionSubtleStrong"
              className="mt-1 inline-flex w-fit rounded-full bg-stone-200 px-2 py-0.5"
            >
              {disabledLabel}
            </Text>
          )}
        </VStack>
        {(onToggleAlbumArt || onRemove) && (
          <DropdownMenu
            trigger={
              <Button type="button" onClick={() => {}} icon={EllipsisIcon} size="small" />
            }
          >
            {onToggleAlbumArt && (
              <DropdownMenuItem
                title={album.showAlbumArt ? `Block Album Art` : `Show Album Art`}
                icon={album.showAlbumArt ? EyeOffIcon : EyeIcon}
                onSelect={onToggleAlbumArt}
              />
            )}
            {onRemove && (
              <DropdownMenuItem
                title="Remove Album"
                icon={TrashIcon}
                onSelect={onRemove}
                destructive
              />
            )}
          </DropdownMenu>
        )}
      </HStack>
    </>
  );

  if (onSelect) {
    return (
      <Card
        as="button"
        type="button"
        interactive
        selected={selected}
        disabled={disabled}
        aria-pressed={selected}
        onClick={onSelect}
        padding={2}
        className="relative flex w-full flex-col gap-2 text-left"
      >
        {content}
      </Card>
    );
  }

  return (
    <Card padding={2} className="relative flex flex-col gap-2">
      {content}
    </Card>
  );
};

export default AllowedAlbumCard;
