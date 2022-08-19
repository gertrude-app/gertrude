import React from 'react';
import Button from '../../../../../Button';
import ActivityItemTime from '../ActivityItemTime';

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
    <div className="flex justify-between pt-3 px-5 rounded-t-xl bg-zred-400">
      <h2 className="text-gray-600 font-medium -ml-0.5">
        Application: <span className="font-bold text-violet-700">{application}</span>
      </h2>
    </div>
    <div className="bg-gray-900 bg-gradient-to-br from-transparent via-transparent to-violet-900/30 text-gray-400 p-6 mt-2 sm:mt-3 mb-4 mx-0 md:mx-4 md:rounded-lg font-mono">
      {strokes.split(`\n`).map((line, idx) => (
        <p key={`line-${idx}`}>{line}</p>
      ))}
    </div>
    <div className="p-4 pt-0 flex justify-between">
      <ActivityItemTime date={date} />
      <Button color="secondary-white" small type="button" onClick={() => {}}>
        Approve
      </Button>
    </div>
  </div>
);

export default KeystrokesViewer;
