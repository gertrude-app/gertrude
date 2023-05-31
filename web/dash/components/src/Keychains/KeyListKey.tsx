import React from 'react';
import cx from 'classnames';
import { target, toState } from '@dash/keys';
import { Button } from '@shared/components';
import { ClockIcon } from '@heroicons/react/24/solid';
import type { Key as KeyType } from '@dash/types';

interface Props {
  record: KeyType;
  onClick(): unknown;
  onDelete(): unknown;
  type: 'list' | 'table';
}

const Key: React.FC<Props> = ({ record, onClick, onDelete, type }) => {
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

  if (type === `list`) {
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
  }
  return (
    <>
      <TableCell onClick={onClick} className={cx(`flex justify-center items-center`)}>
        <span
          className={cx(
            `rounded-full px-4 py-0.5 font-medium text-white`,
            key.keyType === `website` ? `bg-fuchsia-400` : ` bg-violet-400`,
          )}
        >
          {key.keyType === `website` ? `Website` : `App`}
        </span>
      </TableCell>
      <TableCell onClick={onClick} className="max-w-[280px] overflow-hidden relative">
        <div className="absolute h-full w-12 top-auto bottom-0 right-0 rounded-r-lg bg-gradient-to-r from-transparent via-slate-50 to-slate-50" />
        <span
          className={cx(
            target(record.key) !== `*`
              ? `font-mono font-semibold text-indigo-700 px-1 bg-indigo-100 rounded whitespace-nowrap`
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
      </TableCell>
      <TableCell onClick={onClick} className="relative">
        <div className="absolute h-full w-12 top-auto bottom-0 right-0 rounded-r-lg bg-gradient-to-r from-transparent via-slate-50 to-slate-50" />
        <span className="underline decoration-fuchsia-500 underline-offset-2 font-semibold whitespace-nowrap">
          {scope}
        </span>
      </TableCell>
      <TableCell onClick={onClick} className="flex">
        <span
          className={cx(
            `font-medium italic`,
            !key.comment
              ? `flex-grow flex justify-center text-slate-400`
              : `text-slate-600`,
          )}
        >
          {key.comment
            ? key.comment.length > 30
              ? key.comment.substring(0, 30) + `...`
              : key.comment
            : `none`}
        </span>
      </TableCell>
      <TableCell onClick={onClick} className="px-1 bg-transparent border-none">
        <Button type="button" onClick={onDelete} color="warning" size="small">
          Delete
        </Button>
      </TableCell>
      <TableCell onClick={onClick} className="pl-1 bg-transparent border-none">
        {key.expiration && <ClockIcon className="w-5 shrink-0 text-slate-400" />}
      </TableCell>
    </>
  );
};

export default Key;

interface TableCellProps {
  children: React.ReactNode;
  onClick(): unknown;
  className?: string;
}

const TableCell: React.FC<TableCellProps> = ({ children, className, onClick }) => (
  <div
    className={cx(
      `p-4 bg-slate-50 rounded-lg border-[0.5px] border-slate-200 transition duration-200 cursor-pointer flex justify-start items-center overflow-hidden`,
      className,
    )}
    onClick={onClick}
  >
    {children}
  </div>
);
