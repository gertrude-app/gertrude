import React from 'react';
import cx from 'classnames';
import { Button } from '@shared/components';
import { relativeTime } from '@dash/datetime';
import { Api } from '@dash/types';
import GradientIcon from './GradientIcon';
import UserInputText from './UserInputText';

type Props = {
  id: UUID;
  url: string;
  userId: UUID;
  userName: string;
  status: Api.RequestStatus;
  comment?: string;
  createdAt: string;
};

const UnlockRequestCard: React.FC<Props> = ({
  id,
  url,
  userId,
  userName,
  comment,
  status,
  createdAt,
}) => (
  <div
    className={cx(`flex flex-col bg-white border p-4 rounded-xl max-w-3xl`, {
      'border-red-600/30': status === Api.RequestStatus.rejected,
      'border-green-700/40': status === Api.RequestStatus.accepted,
    })}
  >
    <div className="flex justify-between items-start mb-4">
      <h2 className="font-bold text-gray-900">{userName}</h2>
      <h3 className="text-gray-400 text-sm">{relativeTime(new Date(createdAt))}</h3>
    </div>
    <div className="py-3 px-5 bg-gray-50 rounded-xl mt-2 flex justify-center items-center">
      <h2 className="font-mono text-base whitespace-nowrap truncate">
        {url.replace(/^https?:\/\//, ``).replace(/\/$/, ``)}
      </h2>
    </div>
    {comment && (
      <div className="flex justify-center items-center mt-3">
        <p className="text-center text-gray-500 text-sm sm:text-base">
          &ldquo;{comment}&rdquo;
        </p>
      </div>
    )}
    {status === Api.RequestStatus.pending ? (
      <div className="flex flex-row space-x-3 items-stretch mt-4 w-full">
        <Button
          type="link"
          to={`/users/${userId}/unlock-requests/${id}/deny`}
          color="tertiary"
          small
          fullWidth
        >
          Deny
        </Button>
        <Button
          type="link"
          to={`/users/${userId}/unlock-requests/${id}`}
          color="secondary"
          className="whitespace-nowrap"
          small
          fullWidth
        >
          Accept &rarr;
        </Button>
      </div>
    ) : (
      <div className="mt-auto pt-4 flex items-center justify-center space-x-2">
        <GradientIcon
          className="translate-x-1 scale-75"
          size="medium"
          icon={status === Api.RequestStatus.accepted ? `thumbs-up` : `thumbs-down`}
        />
        <span className="text-gray-600">Unlock request</span>
        <UserInputText small className="translate-y-0.5">
          {status === Api.RequestStatus.accepted ? `accepted` : `rejected`}
        </UserInputText>
        .
      </div>
    )}
  </div>
);

export default UnlockRequestCard;
