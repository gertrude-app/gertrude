import React from 'react';
import cx from 'classnames';
import { target } from '../lib/keys';
import { toState } from '../lib/keys/convert';
import GradientIcon from '../GradientIcon';

interface Props {
  record: KeyRecord;
  onClick(): unknown;
  onDelete(): unknown;
}

const Key: React.FC<Props> = ({ record, onClick, onDelete }) => {
  const key = toState(record);
  let scope = ``;
  switch (key.addressScope) {
    case `singleApp`:
      scope = (key.appSlug || key.appBundleId) as string;
      break;
    case `unrestricted`:
      scope = `all apps`;
      break;
    case `webBrowsers`:
      scope = `all web browsers`;
      break;
  }

  return (
    <div
      className="py-2 px-3 rounded-xl odd:bg-gray-50 hover:bg-violet-50 cursor-pointer transition duration-100 flex justify-between items-center"
      onClick={onClick}
    >
      <div className="flex-grow relative overflow-hidden">
        <p className="text-gray-500 whitespace-nowrap">
          <GradientIcon
            size="small"
            className="sm:hidden mr-1.5"
            icon={key.keyType === `website` ? `globe` : `app-store`}
          />
          <span className="hidden sm:inline">
            <span
              className={cx(
                key.keyType === `website` ? `text-fuchsia-700` : `text-violet-700`,
                `font-bold`,
              )}
            >
              {key.keyType === `website` ? `Website` : `App`} key
            </span>
            {` `}unlocking{` `}
          </span>
          <span
            className={cx(
              target(record.key) !== `*`
                ? `font-mono px-1 text-gray-800 bg-violet-100 rounded`
                : `font-medium text-gray-800`,
            )}
          >
            {target(record.key) === `*` ? `everything` : target(record.key)}
          </span>
          <span className="hidden sm:inline">
            {` `}for{` `}
            <span
              className={cx(
                key.addressScope === `singleApp` && !key.appSlug && `font-mono px-1`,
                `font-medium text-gray-800`,
                key.addressScope === `singleApp` && `text-indigo-700`,
                key.addressScope === `unrestricted` && `text-pink-700`,
                key.addressScope === `webBrowsers` && `text-purple-700`,
              )}
            >
              {scope}
            </span>
          </span>
        </p>
      </div>
      <div className="ml-1 flex items-center">
        {key.comment && (
          <div className="text-gray-400 flex justify-center items-center rounded-full w-8 h-8 bg-transparent hover:bg-violet-100 hover:text-gray-500 shrink-0 ml-1">
            <i className="fa-solid fa-message" />
          </div>
        )}
        <button
          onClick={(event) => {
            event.stopPropagation();
            onDelete();
          }}
          className="text-gray-300 flex justify-center items-center rounded-full w-8 h-8 bg-transparent hover:bg-violet-100 hover:text-red-500 shrink-0 ml-1"
        >
          <i className="fa-solid fa-trash" />
        </button>
      </div>
    </div>
  );
};

export default Key;
