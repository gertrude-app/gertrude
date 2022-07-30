import React from 'react';
import Button from '../Button';

type Props = {
  className?: string;
  strokes: string;
  date: Date;
  application: string;
};

const KeystrokesViewer: React.FC<Props> = ({ className, strokes, date, application }) => (
  <div className="border rounded-xl shadow-lg bg-white">
    <div className="flex justify-between pt-3 px-5 rounded-t-xl">
      <h2 className="text-gray-600 font-medium">
        Application: <span className="font-bold">{application}</span>
      </h2>
      <h2 className="text-gray-600 font-medium">{formatTime(date)}</h2>
    </div>
    <p className="bg-gray-900 text-gray-400 p-6 m-4 rounded-lg font-mono">
      {strokes.split('\n').map((line) => (
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

function formatTime(date: Date) {
  const hours = date.getHours();
  const legibleHours = hours > 12 ? hours - 12 : hours;
  const minutes = date.getMinutes();
  const seconds = date.getSeconds();
  return `${legibleHours}:${minutes}:${seconds} ${hours > 12 ? 'PM' : 'AM'}`;
}
