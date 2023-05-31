import React from 'react';
import { Loading as LoadingAnimation } from '@shared/components';

const Loading: React.FC = () => (
  <div className="flex justify-center m-12">
    <LoadingAnimation />
  </div>
);

export default Loading;
