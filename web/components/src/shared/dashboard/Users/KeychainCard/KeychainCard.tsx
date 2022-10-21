import React from 'react';
import cx from 'classnames';
import { inflect } from '../../lib/string';
import PillBadge from '../../PillBadge';
import GradientIcon from '../../GradientIcon/GradientIcon';

type Props = {
  name: string;
  description?: string | null;
  numKeys: number;
  isPublic: boolean;
  remove?: { text: string; handler: () => unknown };
  editUrl?: string;
  small?: boolean;
  selected?: boolean;
  selectable?: boolean;
  onSelect?: () => unknown;
};

const KeychainCard: React.FC<Props> = ({
  isPublic,
  name,
  numKeys,
  description,
  remove,
  editUrl,
  small = false,
  selected = false,
  selectable = false,
  onSelect,
}) => (
  <div
    className={cx(
      `rounded-xl shadow-lg border bg-white flex flex-col justify-between transition duration-100`,
      selected && `bg-violet-50 border-violet-300`,
      selectable && !selected && `hover:bg-gray-50 cursor-pointer`,
      small && `min-h-[77px]`,
    )}
    onClick={selectable ? onSelect : undefined}
  >
    <div className="flex items-stretch flex-grow">
      <div
        className={cx('w-16 xs:w-20 shrink-0 py-4 flex justify-center items-center mr-2')}
      >
        <GradientIcon icon="list" size="medium" className="mx-0" />
      </div>
      <div className="pr-4 py-4 flex flex-col justify-center flex-grow">
        <div className="flex flex-col md:flex-row justify-between md:items-center relative right-0">
          <h2 className="text-left font-semibold text-lg leading-6 text-gray-900 sm:whitespace-normal">
            {name}
          </h2>
          <div className="flex items-center space-x-2 shrink-0 mr-8">
            <h4 className="text-gray-500 shrink-0">
              <span className="font-bold text-gray-600">{numKeys}</span>
              {` `}
              {inflect(`key`, numKeys)}
            </h4>
            {small && isPublic && (
              <PillBadge small type="green">
                Public
              </PillBadge>
            )}
          </div>
        </div>
        {small || (
          <p
            className={cx(
              description ? `text-gray-600 leading-tight` : `text-gray-400 italic`,
              `mt-1.5 mb-1`,
            )}
          >
            {description || `No description`}
          </p>
        )}
      </div>
    </div>
    {small || (
      <div
        className={cx(
          `bg-gray-50 rounded-b-xl w-full flex justify-between`,
          selected && `bg-indigo-100/40`,
        )}
      >
        <div className="flex-grow ml-3">
          {isPublic && (
            <PillBadge type="green" className="border my-2">
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
          {remove && (
            <button
              className="font-medium hover:bg-gray-100 px-4 py-2 cursor-pointer text-red-600 transition duration-100 rounded-br-xl"
              onClick={remove.handler}
            >
              {remove.text}
            </button>
          )}
        </div>
      </div>
    )}
  </div>
);

export default KeychainCard;
