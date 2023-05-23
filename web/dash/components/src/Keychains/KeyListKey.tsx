import React from 'react';
import cx from 'classnames';
import { target, toState } from '@dash/keys';
import type { Key as KeyType } from '@dash/types';
import GradientIcon from '../GradientIcon';

interface Props {
  record: KeyType;
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
      className="py-3 px-4 rounded-xl odd:bg-slate-50 hover:bg-slate-200 cursor-pointer transition duration-100 flex justify-between"
      onClick={onClick}
    >
      <div className="flex-grow relative overflow-x-hidden flex items-center">
        <p className="text-slate-600 font-medium whitespace-nowrap">
          <span className="hidden sm:inline">
            <span
              className={cx(
                `text-slate-900 font-bold px-1 rounded py-0.5 mr-0.5`,
                key.keyType === `website` ? `bg-fuchsia-200` : `bg-violet-200`,
              )}
            >
              {key.keyType === `website` ? `Website` : `App`} key
            </span>
            {` `}unlocking{` `}
          </span>
          <span
            className={cx(
              target(record.key) !== `*`
                ? `font-mono font-semibold text-indigo-700 px-1 bg-indigo-100 rounded`
                : `font-bold text-slate-800`,
            )}
          >
            {target(record.key) === `*` ? (
              <>
                <span className="sm:hidden font-mono px-1 text-slate-800 bg-violet-100 rounded">
                  {scope}
                </span>
                <span className="hidden sm:inline">everything</span>
              </>
            ) : (
              target(record.key)
            )}
          </span>
          <span className="hidden sm:inline">
            {` `}for{` `}
            <span
              className={cx(
                key.addressScope === `singleApp` && !key.appSlug && `font-mono px-1`,
                `font-bold text-slate-800 underline underline-offset-2 decoration-fuchsia-500`,
                // key.addressScope === `singleApp` && `text-indigo-700`,
                // key.addressScope === `unrestricted` && `text-fuchsia-700`,
                // key.addressScope === `webBrowsers` && `text-violet-700`,
              )}
            >
              {scope}
            </span>
          </span>
        </p>
      </div>
      <div className="ml-1 flex items-center">
        {key.comment && (
          <div
            className="text-slate-400 flex justify-center items-center rounded-full w-8 h-8 bg-transparent hover:bg-slate-100 hover:text-slate-500 shrink-0 ml-1"
            data-tooltip-content={key.comment}
            data-tooltip-id="key-comment"
          >
            <i className="fa-solid fa-message" />
          </div>
        )}
        <button
          onClick={(event) => {
            event.stopPropagation();
            onDelete();
          }}
          className="text-slate-400 flex justify-center items-center rounded-full w-8 h-8 bg-transparent hover:bg-red-50 hover:text-red-500 shrink-0 ml-1"
        >
          <i className="fa-solid fa-trash" />
        </button>
      </div>
    </div>
  );
};

export default Key;
