import React from 'react';
import cx from 'classnames';
import PillBadge from '../PillBadge';

type Props = {
  shared: boolean;
  name: string;
  description?: string;
  className?: string;
  keys: number;
  editable?: boolean;
};

const KeychainCard: React.FC<Props> = ({
  shared,
  name,
  keys,
  description,
  editable = false,
  className,
}) => (
  <div className={cx(`rounded-xl shadow-lg flex`, className)}>
    <div className="p-4 bg-gradient-to-br from-violet-500 to-fuchsia-500 rounded-l-xl w-60 border border-r-0">
      <h1 className="text-white font-bold text-lg leading-6 mb-1.5">{name}</h1>
      <p className="text-sm text-white text-opacity-70">
        <span className="text-md font-bold">{keys}</span> keys
      </p>
    </div>
    <div className="flex flex-col justify-between flex-grow border border-l-0 rounded-r-xl bg-white">
      <div className="relative p-3">
        <p className="text-sm text-gray-500 mr-28">{description || `No description`}</p>
        <PillBadge
          type={shared ? `green` : `yellow`}
          small
          className="self-start absolute right-2 top-2"
        >
          <i
            className={cx(
              `fa mr-2`,
              `fa-${shared ? `users text-green-500` : `user text-yellow-500`}`,
            )}
          />
          {shared ? `Public` : `Private`}
        </PillBadge>
      </div>
      <div className="flex justify-end rounded-br-xl border-t bg-gray-50">
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
