import React from 'react';
import type { Key as KeyType } from '@dash/types';
import Key from './KeyListKey';

type Props = {
  keys: KeyType[];
  editKey(id: UUID): unknown;
  deleteKey(id: UUID): unknown;
};

const KeyList: React.FC<Props> = ({ keys, editKey, deleteKey }) => (
  <div className="bg-white shadow-lg border-[0.5px] rounded-xl p-3">
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
