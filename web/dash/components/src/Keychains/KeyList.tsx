import React from 'react';
import type { Key as KeyType } from '@dash/types';
import Key from './KeyListKey';

type Props = {
  keys: KeyType[];
  editKey(id: UUID): unknown;
  deleteKey(id: UUID): unknown;
};

const KeyList: React.FC<Props> = ({ keys, editKey, deleteKey }) => (
  <div className="bg-white shadow-lg shadow-slate-300/50 border-[0.5px] border-slate-200 rounded-xl p-3">
    {keys.map((key) => (
      <Key
        key={key.id}
        record={key}
        onClick={() => editKey(key.id)}
        onDelete={() => deleteKey(key.id)}
      />
    ))}
  </div>
);

export default KeyList;
