import React from 'react';
import cx from 'classnames';
import PillBadge from '../../PillBadge';
import { Link } from 'react-router-dom';
import { inflect } from '../../../lib/string';

type Props = {
  name: string;
  description?: string;
  keys: number;
  isPublic: boolean;
  onRemove(): unknown;
  removeText?: string;
  editUrl?: string;
};

const KeychainCard: React.FC<Props> = ({
  isPublic,
  name,
  keys,
  description,
  onRemove,
  removeText = `Remove`,
  editUrl,
}) => (
  <div
    className={cx(`rounded-xl shadow-lg border bg-white flex flex-col justify-between`)}
  >
    <div className="flex items-center">
      <div className="w-20 shrink-0 flex justify-center items-start">
        <div className="w-10 h-10 bg-gradient-to-br from-indigo-500 to-fuchsia-500 rounded-full flex justify-center items-center text-white text-lg">
          <i className="fa-solid fa-list" />
        </div>
      </div>
      <div className="p-4 pl-0 flex-grow">
        <div className="flex justify-between items-start">
          <h2 className="font-medium text-lg text-gray-900">{name}</h2>
          <h4 className="text-gray-500 shrink-0">
            <span className="text-gray-600 font-medium">{keys}</span>{' '}
            {inflect('key', keys)}
          </h4>
        </div>
        <p className={cx(description ? `text-gray-600` : `text-gray-400 italic`, 'mt-2')}>
          {description || 'No description'}
        </p>
      </div>
    </div>
    <div className="bg-gray-50 rounded-b-xl w-full flex justify-between items-center">
      <div className="flex-grow ml-3">
        {isPublic && (
          <PillBadge type={'green'} className="border">
            <i className="fa-solid fa-users mr-1 text-sm" /> Public
          </PillBadge>
        )}
      </div>
      <div>
        <a
          className="font-medium hover:bg-gray-100 px-4 py-2 cursor-pointer text-gray-600 transition duration-100"
          href={editUrl}
        >
          Edit
        </a>
        <button
          className="font-medium hover:bg-gray-100 px-4 py-2 cursor-pointer text-red-600 transition duration-100"
          onClick={onRemove}
        >
          {removeText}
        </button>
      </div>
    </div>
  </div>
);

export default KeychainCard;
