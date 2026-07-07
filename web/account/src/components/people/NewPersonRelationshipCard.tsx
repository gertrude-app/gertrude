import { Spacer, Text, VStack } from '@gertrude/ui';
import cx from 'clsx';
import React from 'react';

interface Props {
  title: string;
  icon: React.ReactNode;
  selected: boolean;
  onClick: () => void;
}

const NewPersonRelationshipCard: React.FC<Props> = ({
  title,
  icon,
  selected,
  onClick,
}) => (
  <VStack
    as="button"
    type="button"
    align="center"
    justify="between"
    gap={2}
    className={cx(
      `border rounded-xl p-3 @lg/main:w-1/3 shadow duration-150 cursor-pointer transition-[background-color,border-color,box-shadow,scale]`,
      selected
        ? `border-violet-500/60 shadow-violet-500/30 bg-violet-50 scale-102 @lg/main:scale-105`
        : `bg-white border-stone-200 hover:border-stone-300 shadow-stone-300/30 hover:shadow-stone-300/70 scale-98`,
    )}
    aria-pressed={selected}
    onClick={onClick}
  >
    <Spacer />
    <div className={cx(selected ? `text-violet-600` : `text-stone-500`)}>{icon}</div>
    <Spacer />
    <Text variant="bodyStrong" className="text-center select-none">
      {title}
    </Text>
  </VStack>
);

export default NewPersonRelationshipCard;
