import React from 'react';
import cx from 'classnames';
import PillBadge from '../PillBadge';

type Props = {
  title: string;
  description: string;
  selected: boolean;
  badges?: { text: string; color: 'green' | 'red' | 'yellow' | 'blue' }[];
  onClick(): void;
};

const SelectableListItem: React.FC<Props> = ({
  title,
  description,
  selected,
  onClick,
  badges,
}) => (
  <button
    className={cx(
      `flex w-full text-left transition duration-100 rounded-xl outline-none focus:ring-2 focus:ring-violet-400`,
      selected ? `bg-violet-50` : `hover:bg-gray-50`,
    )}
    onClick={onClick}
  >
    <div
      className={cx(`w-12 self-stretch flex flex-shrink-0 justify-center items-center`)}
    >
      <div
        className={cx(
          `rounded-full flex justify-center items-center text-white [transition:100ms]`,
          selected
            ? `border-none w-6 h-6 bg-gradient-to-br from-indigo-500 to-fuchsia-500`
            : `w-5 h-5 border-2 `,
        )}
      >
        <i className="fa-solid fa-check text-sm" />
      </div>
    </div>
    <div className="flex-grow p-3">
      <h3 className="font-bold leading-tight">{title}</h3>
      <p className="w-fit text-gray-500 text-sm mt-1 leading-snug">{description}</p>
      {badges && (
        <div className="flex mt-2 space-x-2">
          {badges.map((badge) => (
            <PillBadge key={badge.color} small className="border" type={badge.color}>
              {badge.text}
            </PillBadge>
          ))}
        </div>
      )}
    </div>
  </button>
);

export default SelectableListItem;
