import { target, toState } from '@dash/keys';
import { ClockIcon } from '@heroicons/react/24/solid';
import { Button } from '@shared/components';
import cx from 'classnames';
import React from 'react';
import type { Key as KeyType } from '@dash/types';
import { TrashBtn } from '../Forms';

interface Props {
  record: KeyType;
  appName?: string;
  onClick(): unknown;
  onDelete(): unknown;
  type: `list` | `table`;
}

const Key: React.FC<Props> = ({ record, appName, onClick, onDelete, type }) => {
  const key = toState(record);
  const isSkeleton = record.key.type === `skeleton`;
  const handleClick = isSkeleton ? () => {} : onClick;
  let scope = ``;
  switch (key.addressScope) {
    case `singleApp`:
      scope = appName || ((key.appSlug || key.appBundleId) as string);
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
        className={cx(
          `py-3 px-4 rounded-xl odd:bg-slate-50 hover:bg-slate-200 transition-[background-color] duration-100 flex justify-between`,
          !isSkeleton && `cursor-pointer`,
        )}
        onClick={handleClick}
      >
        <div className="flex-grow relative overflow-x-hidden flex items-center">
          <p className="text-slate-600 font-medium whitespace-nowrap">
            <span className="hidden sm:inline">
              <span
                className={cx(
                  `text-slate-900 font-bold px-1 rounded py-0.5 mr-0.5`,
                  isSkeleton ? `bg-violet-200` : `bg-fuchsia-200`,
                )}
              >
                {isSkeleton ? `App` : `Website`} key
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
                  key.addressScope === `singleApp` &&
                    !key.appSlug &&
                    !appName &&
                    `font-mono px-1`,
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
          <TrashBtn onClick={onDelete} />
        </div>
      </div>
    );
  }
  return (
    <>
      <TableCell onClick={handleClick} className={cx(`flex justify-center items-center`)}>
        <span
          className={cx(
            `rounded-full px-4 py-0.5 font-medium text-white`,
            isSkeleton ? `bg-violet-400` : `bg-fuchsia-400`,
          )}
        >
          {isSkeleton ? `App` : `Website`}
        </span>
      </TableCell>
      <TableCell onClick={handleClick} className="max-w-[280px] overflow-hidden relative">
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
      <TableCell onClick={handleClick} className="relative">
        <div className="absolute h-full w-12 top-auto bottom-0 right-0 rounded-r-lg bg-gradient-to-r from-transparent via-slate-50 to-slate-50" />
        <span className="underline decoration-fuchsia-500 underline-offset-2 font-semibold whitespace-nowrap">
          {scope}
        </span>
      </TableCell>
      <TableCell onClick={handleClick} className="flex">
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
      <TableCell onClick={handleClick} className="px-1 bg-transparent border-none">
        <Button type="button" onClick={onDelete} color="warning" size="small">
          Delete
        </Button>
      </TableCell>
      <TableCell onClick={handleClick} className="pl-1 bg-transparent border-none">
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
      `p-4 bg-slate-50 rounded-lg border-[0.5px] border-slate-200 duration-200 cursor-pointer flex justify-start items-center overflow-hidden`,
      className,
    )}
    onClick={onClick}
  >
    {children}
  </div>
);
