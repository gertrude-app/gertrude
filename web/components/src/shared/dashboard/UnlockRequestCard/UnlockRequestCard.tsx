import React from 'react';
import Button from '../../Button';
import { relativeTime } from '../lib/dates';

type Props = {
  url: string;
  userName: string;
  comment?: string;
  createdAt: string;
};

const UnlockRequestCard: React.FC<Props> = ({ url, userName, comment, createdAt }) => (
  <div className="bg-white border p-4 rounded-xl shadow-lg mb-5">
    <div className="flex justify-between items-start mb-4">
      <h2 className="font-bold text-gray-900">{userName}</h2>
      <h3 className="text-gray-400 text-sm">{relativeTime(new Date(createdAt))}</h3>
    </div>
    <div className="p-2 bg-violet-50 rounded-xl mt-2 flex justify-center items-center">
      <h2 className="font-mono text-sm overflow-hidden text-ellipses">
        {url.replace(/^https?:\/\//, ``)}
      </h2>
    </div>
    {comment && (
      <div className="flex justify-center items-center mt-3">
        <p className="text-center text-gray-500 text-sm sm:text-base">"{comment}"</p>
      </div>
    )}
    <div className="flex flex-col items-stretch mt-4 w-full space-y-3">
      <Button type="button" onClick={() => {}} color="secondary-white" small fullWidth>
        Deny
      </Button>
      <Button type="button" fullWidth onClick={() => {}} color="primary-violet" small>
        Create a key
      </Button>
    </div>
  </div>
);

export default UnlockRequestCard;
