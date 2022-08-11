import React from 'react';
import Button from '../../Button';
import { formatTime } from '../../lib/dates';

type Props = {
  className?: string;
  strokes: string;
  date: Date;
  application: string;
};

const KeystrokesViewer: React.FC<Props> = ({ className, strokes, date, application }) => (
  <div
    className={`border-y md:border-x2 md:rounded-xl md:shadow-lg bg-white max-w-7xl ${className}`}
  >
    <div className="flex justify-between pt-3 px-5 rounded-t-xl">
      <h2 className="text-gray-600 font-medium">
        Application: <span className="font-bold">{application}</span>
      </h2>
      <h2 className="text-gray-600 font-medium">{formatTime(date)}</h2>
    </div>
    <p className="bg-gray-900 bg-gradient-to-br from-transparent via-transparent to-violet-900/30 text-gray-400 p-6 my-4 mx-0 md:mx-4 md:rounded-lg font-mono">
      {strokes.split(`\n`).map((line) => (
        <p>{line}</p>
      ))}
    </p>
    <div className="p-4 pt-0 flex justify-end">
      <Button color="secondary-white" small type="button" onClick={() => {}}>
        Approve
      </Button>
    </div>
  </div>
);

export default KeystrokesViewer;
