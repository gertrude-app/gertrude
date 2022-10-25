import React from 'react';
import Button from '../../../../../Button';
import { relativeTime } from '../../../../lib/dates';

type Props = {
  id: UUID;
  url: string;
  userName: string;
  comment?: string;
  createdAt: string;
};

const UnlockRequestCard: React.FC<Props> = ({
  id,
  url,
  userName,
  comment,
  createdAt,
}) => (
  <div className="bg-white border p-4 rounded-xl shadow-lg mb-5">
    <div className="flex justify-between items-start mb-4">
      <h2 className="font-bold text-gray-900">{userName}</h2>
      <h3 className="text-gray-400 text-sm">{relativeTime(new Date(createdAt))}</h3>
    </div>
    <div className="py-3 px-5 bg-violet-50 rounded-xl mt-2 flex justify-center items-center">
      <h2 className="font-mono text-base whitespace-nowrap truncate">
        {url.replace(/^https?:\/\//, ``)}
      </h2>
    </div>
    {comment && (
      <div className="flex justify-center items-center mt-3">
        <p className="text-center text-gray-500 text-sm sm:text-base">
          &ldquo;{comment}&rdquo;
        </p>
      </div>
    )}
    <div className="flex flex-row space-x-3 items-stretch mt-4 w-full">
      <Button
        type="link"
        to={`/unlock-requests/${id}`}
        color="secondary-white"
        small
        fullWidth
      >
        Deny
      </Button>
      <Button
        type="link"
        to={`/unlock-requests/${id}`}
        color="primary-violet"
        small
        fullWidth
      >
        Accept &rarr;
      </Button>
    </div>
  </div>
);

export default UnlockRequestCard;
