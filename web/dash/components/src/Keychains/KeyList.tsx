import { toState } from '@dash/keys';
import cx from 'classnames';
import React from 'react';
import type { Key as KeyType } from '@dash/types';
import Key from './KeyListKey';

type AppRef = {
  slug: string;
  name: string;
  bundleIds?: Array<{ bundleId: string }>;
};

type Props = {
  keys: KeyType[];
  apps?: AppRef[];
  editKey(id: UUID): unknown;
  deleteKey(id: UUID): unknown;
  viewMode: `list` | `table`;
};

const KeyList: React.FC<Props> = ({ keys, apps, editKey, deleteKey, viewMode }) => (
  <div className="bg-slate-100 border border-slate-200 rounded-t-none border-t-0 rounded-3xl p-6 lg:p-8 flex flex-col">
    <div className={cx(viewMode === `table` && `xl:hidden`)}>
      {keys.map((key) => (
        <Key
          key={key.id}
          record={key}
          appName={resolveAppName(key, apps)}
          onClick={() => editKey(key.id)}
          onDelete={() => deleteKey(key.id)}
          type="list"
        />
      ))}
    </div>
    <div
      className={cx(
        viewMode === `table` && `xl:grid`,
        `hidden gap-2 [grid-template-columns:14%_26%_22%_20%_10%_3%]`,
      )}
    >
      <TableHeading>Key type</TableHeading>
      <TableHeading>Key target</TableHeading>
      <TableHeading>Key scope</TableHeading>
      <TableHeading>Comment</TableHeading>
      <div />
      <div />
      {keys.map((key) => (
        <Key
          key={key.id}
          record={key}
          appName={resolveAppName(key, apps)}
          onClick={() => editKey(key.id)}
          onDelete={() => deleteKey(key.id)}
          type="table"
        />
      ))}
    </div>
  </div>
);

function resolveAppName(record: KeyType, apps?: AppRef[]): string | undefined {
  if (!apps || apps.length === 0) return undefined;
  const key = toState(record);
  if (key.addressScope !== `singleApp`) return undefined;
  if (key.appSlug) {
    return apps.find((a) => a.slug === key.appSlug)?.name;
  }
  if (key.appBundleId) {
    return apps.find((a) =>
      (a.bundleIds ?? []).some((b) => b.bundleId === key.appBundleId),
    )?.name;
  }
  return undefined;
}

export default KeyList;

interface TableHeadingProps {
  children: React.ReactNode;
  className?: string;
}

const TableHeading: React.FC<TableHeadingProps> = ({ children }) => (
  <div
    className={cx(`p-4 bg-white text-left rounded-lg border-[0.5px] border-slate-200`)}
  >
    <h4 className="font-bold text-slate-900">{children}</h4>
  </div>
);
