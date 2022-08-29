import React from 'react';
import cx from 'classnames';
import PillBadge from '../../PillBadge';

type Props = {
  name: string;
  description?: string;
  keys: number;
  isPublic: boolean;
  editable?: boolean;
};

const KeychainCard: React.FC<Props> = ({
  isPublic,
  name,
  keys,
  description,
  editable = false,
}) => (
  <div className={cx(`rounded-xl shadow-lg flex`)}>
    <div className="p-4 bg-gradient-to-br from-violet-500 to-fuchsia-500 rounded-l-xl w-60 border border-r-0">
      <h1 className="text-white font-bold text-lg leading-6 mb-1.5">{name}</h1>
      <p className="text-sm text-white text-opacity-70">
        <span className="text-md font-bold">{keys}</span> keys
      </p>
    </div>
    <div className="flex flex-col justify-between flex-grow border border-l-0 rounded-r-xl bg-white">
      <div className="relative p-3 flex justify-end sm:justify-start">
        <p className="text-sm text-gray-500 mr-28 hidden sm:block">
          {description || <i className="text-gray-400 antialiased">No description</i>}
        </p>
        {isPublic && (
          <PillBadge type="green" small className="sm:absolute sm:right-2 top-2">
            <i className={cx(`fa mr-2`, `fa-users text-green-500`)} />
            Public
          </PillBadge>
        )}
      </div>
      <div className="flex justify-end rounded-br-xl border-t bg-gray-50 pl-8 sm:pl-0">
        {editable && (
          <button className="px-5 py-2 text-gray-500 font-medium hover:bg-gray-100 transition duration-100">
            Edit
          </button>
        )}
        <button className="px-5 py-2 text-red-500 font-medium hover:bg-red-50 transition duration-100 rounded-br-xl">
          Remove
        </button>
      </div>
    </div>
  </div>
);

export default KeychainCard;
