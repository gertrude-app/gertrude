import React from 'react';
import Key from '../Key/Key';

type Props = {
  className?: string;
  keys: KeyRecord[];
};

const KeyList: React.FC<Props> = ({ className, keys }) => (
  <div>
    {keys.map((key) => (
      <Key record={key} />
    ))}
  </div>
);

export default KeyList;
