import React from 'react';
import { useParams } from 'react-router-dom';

const Keychain: React.FC = () => {
  const { keychainId: id } = useParams<{ keychainId: string }>();
  return (
    <h1>
      Keychain <pre>{id}</pre>
    </h1>
  );
};

export default Keychain;
