import React from 'react';
import type { AppEvent } from '../onboarding-store';

interface Props {
  emit(event: AppEvent): unknown;
}

const HowToUseGertrude: React.FC<Props> = ({ emit }) => (
  <div>
    <h1 className="text-3xl">How to Use Gertrude</h1>
    <p>
      The 7-minute video below walks you through the basics of using Gertrude, including:
    </p>
    <ul className="list-disc list-inside">
      <li>How to unblock parts of the internet</li>
      <li>How to see what your child is doing online</li>
      <li>How to suspend the filter temporarily</li>
    </ul>
    <iframe
      className="my-4"
      width="560"
      height="315"
      src="https://www.youtube-nocookie.com/embed/ytN1HhQX3xo?rel=0"
      title="YouTube video player"
      frameBorder="0"
      allowFullScreen
    />

    <button
      className="bg-blue-500 text-white font-bold py-2 px-4"
      onClick={() => emit({ case: `primaryBtnClicked` })}
    >
      Finish &rarr;
    </button>
  </div>
);

export default HowToUseGertrude;
