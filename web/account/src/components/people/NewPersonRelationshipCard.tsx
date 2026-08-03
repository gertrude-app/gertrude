import { Spacer, Text, Tooltip, VStack } from '@gertrude/ui';
import cx from 'clsx';
import React from 'react';

interface Props {
  title: string;
  icon: React.ReactNode;
  selected: boolean;
  onClick: () => void;
  disabled?: boolean;
  disabledTooltip?: string;
}

const NewPersonRelationshipCard: React.FC<Props> = ({
  title,
  icon,
  selected,
  onClick,
  disabled,
  disabledTooltip,
}) => {
  const card = (
    <VStack
      as="button"
      type="button"
      align="center"
      justify="between"
      gap={2}
      aria-disabled={disabled}
      className={cx(
        `border rounded-xl p-3 w-full h-full shadow outline-none duration-150 transition-[background-color,border-color,box-shadow,scale] focus-visible:ring-2 focus-visible:ring-offset-2`,
        disabled
          ? `cursor-not-allowed border-stone-200 bg-stone-100 text-stone-400 shadow-none scale-98 focus-visible:ring-stone-300`
          : selected
            ? `cursor-pointer border-violet-500/60 shadow-violet-500/30 bg-violet-50 scale-102 @lg/main:scale-105 focus-visible:ring-violet-300`
            : `cursor-pointer bg-white border-stone-200 hover:border-stone-300 shadow-stone-300/30 hover:shadow-stone-300/70 scale-98 focus-visible:ring-violet-300`,
      )}
      aria-label={disabledTooltip ? `${title}. ${disabledTooltip}` : undefined}
      aria-pressed={selected}
      onClick={disabled ? undefined : onClick}
    >
      <Spacer />
      <div
        className={cx(
          disabled ? `text-stone-400` : selected ? `text-violet-600` : `text-stone-500`,
        )}
      >
        {icon}
      </div>
      <Spacer />
      <Text
        variant="bodyStrong"
        className={cx(`text-center select-none`, disabled && `!text-stone-400`)}
      >
        {title}
      </Text>
    </VStack>
  );

  return (
    <span className="flex w-full @lg/main:w-1/3">
      {disabledTooltip ? (
        <Tooltip content={disabledTooltip} side="top">
          {card}
        </Tooltip>
      ) : (
        card
      )}
    </span>
  );
};

export default NewPersonRelationshipCard;
