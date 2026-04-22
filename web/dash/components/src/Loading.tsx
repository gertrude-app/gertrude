import { Loading as LoadingAnimation } from '@shared/components';
import React from 'react';

interface Props {
  label?: string;
}

const Loading: React.FC<Props> = ({ label = `Loading page content…` }) => (
  <div
    role="status"
    aria-live="polite"
    aria-busy="true"
    className="flex justify-center m-12"
  >
    <LoadingAnimation />
    <span className="sr-only">{label}</span>
  </div>
);

export default Loading;
