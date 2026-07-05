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
  <button
    type="button"
    className={cx(
      `border rounded-xl p-3 flex flex-col items-center @lg/main:w-1/3 shadow gap-2 justify-between duration-150 cursor-pointer transition-[background-color,border-color,box-shadow,scale]`,
      selected
        ? `border-violet-500/60 shadow-violet-500/30 bg-violet-50 scale-102 @lg/main:scale-105`
        : `bg-white border-stone-200 hover:border-stone-300 shadow-stone-300/30 hover:shadow-stone-300/70 scale-98`,
    )}
    aria-pressed={selected}
    onClick={onClick}
  >
    <div />
    <div className={cx(selected ? `text-violet-600` : `text-stone-500`)}>{icon}</div>
    <div />
    <span className="text-center font-medium text-stone-900 leading-5.5 text-sm select-none">
      {title}
    </span>
  </button>
);

export default NewPersonRelationshipCard;
