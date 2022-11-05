import React from 'react';
import { LoadingSpinner } from '@shared/components';

const Loading: React.FC = () => (
  <div className="flex justify-center m-12">
    <LoadingSpinner />
  </div>
);

export default Loading;
