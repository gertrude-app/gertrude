import React from 'react';
import Modal from './Modal';

const Loading: React.FC = () => (
  <Modal
    type="default"
    title=""
    loading
    isOpen={true}
    onPrimaryClick={() => {}}
    onSecondaryClick={() => {}}
  />
);

export default Loading;
