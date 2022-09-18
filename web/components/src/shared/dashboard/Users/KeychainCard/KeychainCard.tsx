import React from 'react';
import cx from 'classnames';
import PillBadge from '../../PillBadge';
import { inflect } from '../../../lib/string';

type Props = {
  name: string;
  description?: string;
  keys: number;
  isPublic: boolean;
  onRemove(): unknown;
  removeText?: string;
  editUrl?: string;
  small?: boolean;
  selected?: boolean;
  selectable?: boolean;
};

const KeychainCard: React.FC<Props> = ({
  isPublic,
  name,
  keys,
  description,
  onRemove,
  removeText = `Remove`,
  editUrl,
  small = false,
  selected = false,
  selectable = false,
}) => (
  <div
    className={cx(
      `rounded-xl shadow-lg border bg-white flex flex-col justify-between transition duration-100`,
      selected && `bg-violet-50 border-violet-300`,
      selectable && !selected && `hover:bg-gray-50 cursor-pointer`,
      small && `min-h-[90px]`,
    )}
  >
    <div className="flex items-center flex-grow">
      <div className="w-20 shrink-0 flex justify-center items-start">
        <div className="w-10 h-10 bg-gradient-to-br from-indigo-500 to-fuchsia-500 rounded-full flex justify-center items-center text-white text-lg">
          <i className="fa-solid fa-list" />
        </div>
      </div>
      <div className="p-4 pl-0 flex-grow">
        <div
          className={cx(`flex justify-between`, small ? `items-center` : `items-start`)}
        >
          <h2 className="font-medium text-lg text-gray-900">{name}</h2>
          <div className="flex flex-col items-end flex-grow">
            <h4
              className={cx(
                `text-gray-500 shrink-0 min-w-max`,
                small && isPublic && `mb-1 mr-2`,
              )}
            >
              <span className="text-gray-600 font-medium shrink-0">{keys}</span>
              {` `}
              {inflect(`key`, keys)}
            </h4>
            {small && isPublic && <PillBadge type="green">Public</PillBadge>}
          </div>
        </div>
        {small || (
          <p
            className={cx(description ? `text-gray-600` : `text-gray-400 italic`, `mt-2`)}
          >
            {description || `No description`}
          </p>
        )}
      </div>
    </div>
    {small || (
      <div
        className={cx(
          `bg-gray-50 rounded-b-xl w-full flex justify-between items-center`,
          selected && `bg-indigo-100/40`,
        )}
      >
        <div className="flex-grow ml-3">
          {isPublic && (
            <PillBadge type={`green`} className="border">
              <i className="fa-solid fa-users mr-1 text-sm" /> Public
            </PillBadge>
          )}
        </div>
        <div className="flex items-stretch">
          {editUrl && (
            <a
              className="font-medium hover:bg-gray-100 px-4 py-2 cursor-pointer text-gray-600 transition duration-100 h-full select-none"
              href={editUrl}
            >
              Edit
            </a>
          )}
          <button
            className="font-medium hover:bg-gray-100 px-4 py-2 cursor-pointer text-red-600 transition duration-100 rounded-br-xl"
            onClick={onRemove}
          >
            {removeText}
          </button>
        </div>
      </div>
    )}
  </div>
);

export default KeychainCard;
