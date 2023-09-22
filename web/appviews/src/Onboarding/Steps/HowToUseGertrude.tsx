import React from 'react';
import { Button } from '@shared/components';
import type { AppEvent } from '../onboarding-store';

interface Props {
  emit(event: AppEvent): unknown;
}

const HowToUseGertrude: React.FC<Props> = ({ emit }) => (
  <div className="h-full flex flex-col justify-center items-center p-12">
    <h1 className="text-3xl font-bold">How to use Gertrude</h1>
    <p className="text-lg text-slate-500 mt-2 text-center">
      The 7-minute video below walks you through the basics of using Gertrude, including:
    </p>
    <ul className="flex flex-wrap gap-2 mt-4 justify-center">
      <ListItem index={1}>How to unblock parts of the internet</ListItem>
      <ListItem index={2}>How to see what your child is doing online</ListItem>
      <ListItem index={3}>How to suspend the filter temporarily</ListItem>
    </ul>
    <iframe
      className="my-8 rounded-2xl"
      width="500"
      height="280"
      src="https://www.youtube-nocookie.com/embed/ytN1HhQX3xo?rel=0"
      title="YouTube video player"
      allowFullScreen
    />
    <Button
      type="button"
      onClick={() => emit({ case: `primaryBtnClicked` })}
      color="primary"
      size="large"
    >
      Finish <i className="fas fa-arrow-right ml-2" />
    </Button>
  </div>
);

export default HowToUseGertrude;

interface ListItemProps {
  children?: React.ReactNode;
  index: number;
}

const ListItem: React.FC<ListItemProps> = ({ children, index }) => (
  <li className="flex items-center border border-slate-200 p-1.5 rounded-2xl">
    <div className="bg-violet-100 text-violet-600 font-bold w-7 h-7 rounded-full flex justify-center items-center">
      {index}
    </div>
    <span className="ml-4 mr-2 text-slate-500">{children}</span>
  </li>
);
