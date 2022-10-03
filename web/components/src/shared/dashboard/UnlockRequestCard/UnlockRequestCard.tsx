import React from 'react';
import Button from '../../Button';
import { relativeTime } from '../lib/dates';

type Props = {
  url: string;
  userName: string;
  comment?: string;
  time: Date;
};

const UnlockRequestCard: React.FC<Props> = ({ url, userName, comment, time }) => (
  <div className="bg-white border p-4 rounded-xl shadow-lg mb-5">
    <div className="flex justify-between items-start mb-4">
      <h2 className="font-bold text-gray-900">{userName}</h2>
      <h3 className="text-gray-400 text-sm">{relativeTime(time)}</h3>
    </div>
    <div className="p-2 bg-violet-50 rounded-xl mt-2 flex justify-center items-center">
      <h2 className="font-mono font-medium overflow-scroll">{url}</h2>
    </div>
    {comment && (
      <div className="flex justify-center items-center mt-3">
        <p className="text-center text-gray-500 text-sm sm:text-base">"{comment}"</p>
      </div>
    )}
    <div className="flex flex-col xs:flex-row items-stretch xs:justify-between xs:items-center mt-4 w-full">
      <Button
        type="button"
        onClick={() => {}}
        color="secondary-white"
        small
        className="w-[100%] xs:w-auto mb-3"
      >
        Deny
      </Button>
      <Button
        type="button"
        onClick={() => {}}
        color="primary-violet"
        small
        className="w-[100%] xs:w-auto"
      >
        Create a key
      </Button>
    </div>
  </div>
);

export default UnlockRequestCard;
