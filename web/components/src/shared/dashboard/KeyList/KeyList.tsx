import React from 'react';
import Key from '../Key/Key';

type Props = {
  keys: KeyRecord[];
};

const KeyList: React.FC<Props> = ({ keys }) => (
  <div className="bg-white shadow-lg border rounded-xl p-3">
    {keys.map((key) => (
      <Key record={key} />
    ))}
  </div>
);

export default KeyList;
