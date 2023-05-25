import React, { useState } from 'react';
import cx from 'classnames';
import type { Key as KeyType } from '@dash/types';
import Key from './KeyListKey';

type Props = {
  keys: KeyType[];
  editKey(id: UUID): unknown;
  deleteKey(id: UUID): unknown;
  viewMode: 'list' | 'table';
};

const KeyList: React.FC<Props> = ({ keys, editKey, deleteKey, viewMode }) => {
  return (
    <div className="bg-slate-100 border border-slate-200 rounded-t-none border-t-0 rounded-3xl p-6 lg:p-8 flex flex-col">
      {viewMode === 'list' ? (
        keys.map((key) => (
          <Key
            key={key.id}
            record={key}
            onClick={() => editKey(key.id)}
            onDelete={() => deleteKey(key.id)}
            type="list"
          />
        ))
      ) : (
        <table className="">
          <thead>
            <tr>
              <TableHeading index={0}>Key type</TableHeading>
              <TableHeading index={1}>Key target</TableHeading>
              <TableHeading index={2}>Key scope</TableHeading>
              <TableHeading index={3}>Comment</TableHeading>
            </tr>
          </thead>
          <tbody>
            {keys.map((key, i) => (
              <Key
                key={key.id}
                record={key}
                onClick={() => editKey(key.id)}
                onDelete={() => deleteKey(key.id)}
                type="table"
                isLast={i === keys.length - 1}
              />
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
};

export default KeyList;

interface TableHeadingProps {
  children: React.ReactNode;
  index: number;
}

const TableHeading: React.FC<TableHeadingProps> = ({ children, index }) => {
  return (
    <th className="p-1">
      <div
        className={cx(
          'p-4 bg-white text-left rounded-lg border-[0.5px] border-slate-200',
          index === 0 && 'rounded-tl-2xl',
          index === 3 && 'rounded-tr-2xl',
        )}
      >
        {children}
      </div>
    </th>
  );
};
