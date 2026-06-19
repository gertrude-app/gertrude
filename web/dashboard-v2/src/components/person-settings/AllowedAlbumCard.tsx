import { Button, DropdownMenu, DropdownMenuItem } from '@gertrude/ui';
import cx from 'clsx';
import { CheckIcon, EllipsisIcon, EyeIcon, EyeOffIcon, TrashIcon } from 'lucide-react';
import React from 'react';
import type { PersonIosSettingsConfiguration } from '#/lib/mock';

type Album = PersonIosSettingsConfiguration[`allowedAlbums`][number];

type Props = {
  album: Album;
  forceShowArtwork?: boolean;
  selected?: boolean;
  disabled?: boolean;
  disabledLabel?: string;
  onSelect?: () => void;
  onToggleAlbumArt?: () => void;
  onRemove?: () => void;
};

const getCardClasses = (
  selected: boolean,
  disabled: boolean,
  selectable = false,
): string =>
  cx(
    `relative flex flex-col rounded-xl border p-2 gap-2 shadow transition-[background-color,border-color,box-shadow,opacity] duration-150`,
    disabled
      ? `cursor-not-allowed border-stone-200 bg-stone-100/70 opacity-60 shadow-transparent`
      : selected
        ? `cursor-pointer border-violet-300 bg-violet-50 shadow-violet-300/30 hover:border-violet-400 hover:shadow-violet-300/50`
        : `border-stone-200 bg-white shadow-stone-300/30`,
    !disabled && selectable && `cursor-pointer`,
    !disabled && !selected && `hover:border-stone-400/70 hover:shadow-stone-300/70`,
  );

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
          <div className="aspect-square rounded-md h-full flex justify-center items-center bg-stone-200/80 relative">
            <img
              src={album.artworkUrl}
              alt=""
              className="aspect-square rounded-md h-full opacity-0"
            />
            <EyeOffIcon className="text-stone-400/80 w-8 h-8 absolute" />
          </div>
        )}
        {selected && !disabled && (
          <span className="absolute right-2 top-2 flex h-5 w-5 items-center justify-center rounded-full border border-violet-200 bg-violet-500 text-white shadow shadow-violet-500/30">
            <CheckIcon className="h-3 w-3" strokeWidth={3} />
          </span>
        )}
      </div>
      <div className="flex justify-between items-center gap-2 flex-grow">
        <div className="flex min-w-0 flex-col">
          <span className="truncate text-sm font-medium text-stone-800 leading-5">
            {album.title}
          </span>
          <span className="truncate text-xs text-stone-500 leading-5 -mt-0.5">
            {album.artist}
          </span>
          {disabledLabel && (
            <span className="mt-1 inline-flex w-fit rounded-full bg-stone-200 px-2 py-0.5 text-xs font-medium text-stone-600">
              {disabledLabel}
            </span>
          )}
        </div>
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
      </div>
    </>
  );

  if (onSelect) {
    return (
      <button
        type="button"
        disabled={disabled}
        aria-pressed={selected}
        onClick={onSelect}
        className={cx(getCardClasses(selected, disabled, true), `w-full text-left`)}
      >
        {content}
      </button>
    );
  }

  return <div className={getCardClasses(false, false)}>{content}</div>;
};

export default AllowedAlbumCard;
