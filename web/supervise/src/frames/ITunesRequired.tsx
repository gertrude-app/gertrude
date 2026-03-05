import { Button } from '@shared/components';
import React from 'react';
import type { ITunesRequiredProps } from '../types';
import InstructionLayout from '../InstructionLayout';
import itunesImg from '../assets/itunes.png';

const img: any = itunesImg;
const imgSrc: string = typeof img === `string` ? img : img.src;

const ITUNES_URL = `https://gertrude.app/itunes`;

const ITunesRequired: React.FC<ITunesRequiredProps> = ({ deviceType, onContinue }) => (
  <InstructionLayout
    step={1}
    totalSteps={8}
    title="iTunes Required"
    subtitle={`iTunes must be installed and have run at least once in order for us to securely connect with the ${deviceType}.`}
    imageSrc={imgSrc}
    imageAlt="iTunes app"
    footer={
      <Button type="button" onClick={onContinue} color="gradient" size="large">
        iTunes has run, continue &rarr;
      </Button>
    }
  >
    <div className="flex flex-col gap-6">
      <div className="flex items-start gap-4">
        <span className="w-8 h-8 rounded-full bg-violet-100 text-violet-600 text-sm font-bold flex items-center justify-center shrink-0 mt-0.5">
          1
        </span>
        <div>
          <span className="text-base font-medium text-slate-700">Open iTunes</span>
          <p className="text-sm text-slate-500 mt-0.5">
            If iTunes is already installed, open it now before continuing.
          </p>
        </div>
      </div>
      <div className="rounded-lg border border-slate-200 bg-slate-50 px-4 py-3">
        <p className="text-sm text-slate-600">
          <span className="font-medium">Don't have iTunes?</span>
          {` `}
          <a
            href={ITUNES_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="text-violet-600 hover:text-violet-700 underline"
          >
            Download it from Apple
          </a>
          , install it, then open it before continuing.
        </p>
      </div>
    </div>
  </InstructionLayout>
);

export default ITunesRequired;
